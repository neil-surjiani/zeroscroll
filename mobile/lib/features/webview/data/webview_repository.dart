import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository interface for persisting WebView preferences and session flags locally.
abstract class WebviewRepository {
  Future<bool> isSessionActive();
  Future<void> clearSessionData();
}

/// Local implementation of [WebviewRepository].
class LocalWebviewRepository implements WebviewRepository {
  bool _sessionActive = false;

  @override
  Future<bool> isSessionActive() async => _sessionActive;

  @override
  Future<void> clearSessionData() async {
    _sessionActive = false;
  }
}

final webviewRepositoryProvider = Provider<WebviewRepository>((ref) {
  return LocalWebviewRepository();
});
