import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../data/feature_preferences_repository.dart';
import '../../domain/feature_preferences.dart';

/// StateNotifier providing reactive updates for user-configured feature preferences.
class FeaturePreferencesNotifier extends StateNotifier<FeaturePreferences> {
  FeaturePreferencesNotifier(this._repository, [this._notificationsRepo])
      : super(const FeaturePreferences()) {
    _load();
  }

  final FeaturePreferencesRepository _repository;
  final NotificationsRepository? _notificationsRepo;

  Future<void> _load() async {
    final prefs = await _repository.getPreferences();
    state = prefs;
    // Check if any scheduled 24h loosening is now due
    await checkAndApplyPendingLoosening();
    // Sync notification filter to native Android on startup
    _notificationsRepo?.setNotificationFilter(
      messagesOnly: state.messagesOnlyNotifications,
    );
  }

  Future<void> updatePreferences(FeaturePreferences prefs) async {
    await _repository.savePreferences(prefs);
    state = prefs;
    // Sync notification filter setting to native Kotlin listener
    _notificationsRepo?.setNotificationFilter(
      messagesOnly: prefs.messagesOnlyNotifications,
    );
  }

  Future<void> scheduleLoosening(FeaturePreferences target) async {
    final releaseTime = DateTime.now().add(const Duration(hours: 24));
    final updated = state.copyWith(
      pendingLooseningJson: jsonEncode(target.toJson()),
      pendingLooseningReleaseTime: releaseTime,
    );
    await updatePreferences(updated);
  }

  Future<void> cancelPendingLoosening() async {
    final updated = state.copyWith(
      clearPendingLooseningJson: true,
      clearPendingLooseningReleaseTime: true,
    );
    await updatePreferences(updated);
  }

  Future<void> checkAndApplyPendingLoosening([DateTime? now]) async {
    final current = state;
    if (current.hasPendingLoosening) {
      final effectiveNow = now ?? DateTime.now();
      if (effectiveNow.isAfter(current.pendingLooseningReleaseTime!) ||
          effectiveNow.isAtSameMomentAs(current.pendingLooseningReleaseTime!)) {
        try {
          final decoded = jsonDecode(current.pendingLooseningJson!)
              as Map<String, dynamic>;
          final target = FeaturePreferences.fromJson(decoded).copyWith(
            clearPendingLooseningJson: true,
            clearPendingLooseningReleaseTime: true,
          );
          await updatePreferences(target);
        } catch (_) {
          await cancelPendingLoosening();
        }
      }
    }
  }

  Future<void> setStoriesViewMode(StoriesViewMode mode) async {
    final updated = state.copyWith(storiesViewMode: mode);
    await updatePreferences(updated);
  }

  Future<void> setDailyStoryLimit(int? limit) async {
    final updated = state.copyWith(
      dailyStoryLimit: limit,
      clearDailyStoryLimit: limit == null,
    );
    await updatePreferences(updated);
  }

  Future<void> setReelsFromDmsEnabled(bool enabled) async {
    final updated = state.copyWith(reelsFromDmsEnabled: enabled);
    await updatePreferences(updated);
  }

  Future<void> setDailyReelLimit(int? limit) async {
    final updated = state.copyWith(
      dailyReelLimit: limit,
      clearDailyReelLimit: limit == null,
    );
    await updatePreferences(updated);
  }

  Future<void> setStoriesPostingEnabled(bool enabled) async {
    final updated = state.copyWith(storiesPostingEnabled: enabled);
    await updatePreferences(updated);
  }

  Future<void> setSharedPostsFromDmsEnabled(bool enabled) async {
    final updated = state.copyWith(sharedPostsFromDmsEnabled: enabled);
    await updatePreferences(updated);
  }

  Future<void> setMessagesOnlyNotifications(bool messagesOnly) async {
    final updated = state.copyWith(messagesOnlyNotifications: messagesOnly);
    await updatePreferences(updated);
  }

  Future<void> setDelayLoosening24h(bool delay) async {
    final updated = state.copyWith(delayLoosening24h: delay);
    await updatePreferences(updated);
  }

  Future<void> setHasChosenFeatures(bool chosen) async {
    final updated = state.copyWith(hasChosenFeatures: chosen);
    await updatePreferences(updated);
  }
}

/// Provider for [FeaturePreferences] state.
final featurePreferencesProvider =
    StateNotifierProvider<FeaturePreferencesNotifier, FeaturePreferences>(
  (ref) {
    final repo = ref.watch(featurePreferencesRepositoryProvider);
    final notificationsRepo = ref.watch(notificationsRepositoryProvider);
    return FeaturePreferencesNotifier(repo, notificationsRepo);
  },
);
