import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/onboarding/data/onboarding_repository.dart';
import 'package:zeroscroll/main.dart';
import 'helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  testWidgets('ZeroScrollApp smoke test renders Home screen and navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          onboardingRepositoryProvider.overrideWithValue(
            LocalOnboardingRepository(initialCompleted: true),
          ),
        ],
        child: const ZeroScrollApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify app title and flavor badge
    expect(find.text('ZeroScroll'), findsWidgets);
    expect(find.text('PLAY'), findsOneWidget);

    // Verify 3 navigation destinations
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify top slim stats bar is present
    expect(find.textContaining('in app'), findsOneWidget);
    expect(find.textContaining('reels opened'), findsOneWidget);

    // Switch tab to Activity
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Activity Feed'), findsOneWidget);
    expect(find.text('Native Alerts'), findsOneWidget);

    // Switch tab to Settings
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('LIMITS & FOCUS'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);

    // Tap Log Out and verify confirmation dialog appears
    expect(find.byKey(const ValueKey('settings_logout_tile')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings_logout_tile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Log Out of ZeroScroll?'), findsOneWidget);

    // Cancel logout
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Log Out of ZeroScroll?'), findsNothing);

    // Return to Messages tab
    await tester.tap(find.text('Messages'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('test_in_app_webview')), findsWidgets);
  });
}
