import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/webview/domain/webview_mode.dart';
import 'package:zeroscroll/features/webview/presentation/providers/webview_provider.dart';

void main() {
  group('WebviewNotifier & WebviewState', () {
    test('initial state has default values', () {
      final notifier = WebviewNotifier();
      final state = notifier.state;

      expect(state.mode, WebviewMode.directMessages);
      expect(state.isLoading, isTrue);
      expect(state.progress, 0.0);
      expect(state.isOffline, isFalse);
      expect(state.isSslError, isFalse);
      expect(state.hasHttpError, isFalse);
      expect(state.canGoBack, isFalse);
      expect(state.hasAnyError, isFalse);
    });

    test('onLoadStart sets loading and resets errors', () {
      final notifier = WebviewNotifier();
      notifier.onOfflineError('Connection lost');
      expect(notifier.state.isOffline, isTrue);

      notifier.onLoadStart('https://www.instagram.com/direct/inbox/');
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.isOffline, isFalse);
      expect(
        notifier.state.currentUrl,
        'https://www.instagram.com/direct/inbox/',
      );
    });

    test('onProgressChanged updates progress and loading state', () {
      final notifier = WebviewNotifier();
      notifier.onProgressChanged(65);

      expect(notifier.state.progress, 0.65);
      expect(notifier.state.isLoading, isTrue);

      notifier.onProgressChanged(100);
      expect(notifier.state.progress, 1.0);
      expect(notifier.state.isLoading, isFalse);
    });

    test('onLoadStop marks loading complete and updates canGoBack', () {
      final notifier = WebviewNotifier();
      notifier.onLoadStop(
        'https://www.instagram.com/direct/t/123/',
        canGoBack: true,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.progress, 1.0);
      expect(notifier.state.canGoBack, isTrue);
      expect(
        notifier.state.currentUrl,
        'https://www.instagram.com/direct/t/123/',
      );
    });

    test('onOfflineError updates offline error state', () {
      final notifier = WebviewNotifier();
      notifier.onOfflineError('DNS failed');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isOffline, isTrue);
      expect(notifier.state.errorMessage, 'DNS failed');
      expect(notifier.state.hasAnyError, isTrue);
    });

    test('onSslError updates SSL error state', () {
      final notifier = WebviewNotifier();
      notifier.onSslError('Invalid cert');

      expect(notifier.state.isSslError, isTrue);
      expect(notifier.state.errorMessage, 'Invalid cert');
      expect(notifier.state.hasAnyError, isTrue);
    });

    test('onHttpError updates HTTP error status code', () {
      final notifier = WebviewNotifier();
      notifier.onHttpError(500, 'Server Error');

      expect(notifier.state.hasHttpError, isTrue);
      expect(notifier.state.httpStatusCode, 500);
      expect(notifier.state.hasAnyError, isTrue);
    });
  });
}
