import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/security/presentation/providers/debug_log_provider.dart';

void main() {
  group('DebugLogNotifier', () {
    test('caps blocked navigations at 50 items', () {
      final notifier = DebugLogNotifier();

      for (var i = 0; i < 60; i++) {
        notifier.addBlockedNavigation('/blocked/$i', 'https://example.com/$i');
      }

      expect(notifier.state.blockedNavigations.length, 50);
      expect(notifier.state.blockedNavigations.first.path, '/blocked/59');
    });

    test('caps console logs at 100 items', () {
      final notifier = DebugLogNotifier();

      for (var i = 0; i < 110; i++) {
        notifier.addConsoleLog('Message $i', 'log');
      }

      expect(notifier.state.consoleLogs.length, 100);
      expect(notifier.state.consoleLogs.first.message, 'Message 109');
    });

    test('generates formatted debug report', () {
      final notifier = DebugLogNotifier();
      notifier.setConfigVersion(2);
      notifier.setCurrentUrl('https://www.instagram.com/direct/inbox/');
      notifier.addBlockedNavigation(
        '/explore/',
        'https://www.instagram.com/explore/',
      );
      notifier.addConsoleLog('ZeroScroll ready', 'info');

      final report = notifier.generateDebugReport();
      expect(report, contains('Active Config Version: 2'));
      expect(
        report,
        contains('Current Active URL: https://www.instagram.com/direct/inbox/'),
      );
      expect(report, contains('Path: "/explore/"'));
      expect(report, contains('[INFO]: ZeroScroll ready'));
    });
  });
}
