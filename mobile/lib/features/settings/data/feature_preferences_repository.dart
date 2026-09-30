import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../limits/data/database/app_database.dart';
import '../../limits/data/limits_repository.dart';
import '../domain/feature_preferences.dart';

/// Contract for persisting user feature preferences on-device in Drift.
abstract class FeaturePreferencesRepository {
  Future<FeaturePreferences> getPreferences();
  Future<void> savePreferences(FeaturePreferences preferences);
}

/// Drift SQLite backed feature preferences repository.
class DriftFeaturePreferencesRepository implements FeaturePreferencesRepository {
  DriftFeaturePreferencesRepository(this._db);

  final AppDatabase _db;
  static const String _key = 'feature_preferences';

  @override
  Future<FeaturePreferences> getPreferences() async {
    final raw = await _db.getSetting(_key);
    if (raw == null || raw.isEmpty) {
      return const FeaturePreferences();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FeaturePreferences.fromJson(json);
    } catch (_) {
      return const FeaturePreferences();
    }
  }

  @override
  Future<void> savePreferences(FeaturePreferences preferences) async {
    final raw = jsonEncode(preferences.toJson());
    await _db.setSetting(_key, raw);
  }
}

/// In-memory implementation of [FeaturePreferencesRepository] for tests and fallbacks.
class LocalFeaturePreferencesRepository implements FeaturePreferencesRepository {
  LocalFeaturePreferencesRepository([FeaturePreferences? initial])
      : _prefs = initial ?? const FeaturePreferences();

  FeaturePreferences _prefs;

  @override
  Future<FeaturePreferences> getPreferences() async => _prefs;

  @override
  Future<void> savePreferences(FeaturePreferences preferences) async {
    _prefs = preferences;
  }
}

/// Provider for [FeaturePreferencesRepository] backed by Drift.
final featurePreferencesRepositoryProvider =
    Provider<FeaturePreferencesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFeaturePreferencesRepository(db);
});
