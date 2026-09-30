import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
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
        ],
        child: const ZeroScrollApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify app title and flavor badge
    expect(find.text('ZeroScroll'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);

    // Verify navigation destinations
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Limits'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Switch tab to Activity
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Activity & Notifications'), findsOneWidget);

    // Switch tab to Limits
    await tester.tap(find.byIcon(Icons.hourglass_empty));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Intentional Usage Limits'), findsOneWidget);

    // Switch tab to Settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PREFERENCES'), findsOneWidget);

    // Scroll until Log Out is visible if necessary
    await tester.scrollUntilVisible(
      find.text('Log Out'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Log Out'), findsOneWidget);

    // Tap Log Out and verify confirmation dialog appears
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Log Out of ZeroScroll?'), findsOneWidget);

    // Cancel logout
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Log Out of ZeroScroll?'), findsNothing);

    // Return to Messages tab
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('test_in_app_webview')), findsOneWidget);
  });
}
