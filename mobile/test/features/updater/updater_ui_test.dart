import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/settings/data/settings_repository.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';
import 'package:zeroscroll/features/updater/data/updater_repository.dart';
import 'package:zeroscroll/features/updater/domain/download_progress.dart';
import 'package:zeroscroll/features/updater/domain/update_check_result.dart';
import 'package:zeroscroll/features/updater/domain/version_manifest.dart';
import 'package:zeroscroll/features/updater/presentation/providers/updater_provider.dart';
import 'package:zeroscroll/features/updater/presentation/screens/blocking_update_screen.dart';
import 'package:zeroscroll/features/updater/presentation/widgets/update_available_card.dart';

class FakeUpdaterRepository implements UpdaterRepository {
  FakeUpdaterRepository({
    this.checkResult,
  });

  UpdateCheckResult? checkResult;
  int checkForUpdateCalls = 0;
  int downloadCalls = 0;
  int verifyAndInstallCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) async {
    checkForUpdateCalls++;
    return checkResult ??
        UpdateCheckResult.available(
          manifest: VersionManifest(
            latestVersion: '1.2.0',
            latestBuild: 2,
            minSupportedBuild: 1,
            apkUrl: 'https://example.com/app.apk',
            sha256: 'a' * 64,
            changelog: 'Added battery efficiency',
            releasedAt: DateTime.now(),
          ),
          currentBuild: 1,
          currentVersion: '1.0.0',
        );
  }

  @override
  Future<File> downloadApk(
    VersionManifest manifest, {
    void Function(DownloadProgress)? onProgress,
    Completer<void>? cancelSignal,
  }) async {
    downloadCalls++;
    onProgress?.call(
      const DownloadProgress(
        receivedBytes: 5000,
        totalBytes: 10000,
        isCompleted: false,
      ),
    );
    return File('fake_app.apk');
  }

  @override
  Future<bool> verifyAndInstall(File apkFile, VersionManifest manifest) async {
    verifyAndInstallCalls++;
    return true;
  }

  @override
  Future<bool> requestInstallPermission() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<bool> canRequestPackageInstalls() async => true;
}

void main() {
  group('Updater UI & Widgets Tests', () {
    testWidgets('UpdateAvailableCard renders details and handles user interactions', (
      tester,
    ) async {
      final fakeRepo = FakeUpdaterRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updaterRepositoryProvider.overrideWithValue(fakeRepo),
            flavorConfigProvider.overrideWithValue(FlavorConfig.sideload()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UpdateAvailableCard(),
            ),
          ),
        ),
      );

      // Trigger update check
      final element = tester.element(find.byType(UpdateAvailableCard));
      final container = ProviderScope.containerOf(element);
      await container.read(updaterProvider.notifier).checkForUpdate(force: true);
      await tester.pumpAndSettle();

      // Card is visible
      expect(find.byKey(const ValueKey('update_available_card')), findsOneWidget);
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('Added battery efficiency'), findsOneWidget);

      // Dismiss button hides card
      await tester.tap(find.byKey(const ValueKey('update_card_dismiss_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('update_available_card')), findsNothing);
    });

    testWidgets('BlockingUpdateScreen displays required update notice and controls', (
      tester,
    ) async {
      final fakeRepo = FakeUpdaterRepository(
        checkResult: UpdateCheckResult.required(
          manifest: VersionManifest(
            latestVersion: '2.0.0',
            latestBuild: 5,
            minSupportedBuild: 4,
            apkUrl: 'https://example.com/app.apk',
            sha256: 'a' * 64,
            changelog: 'Mandatory security protocol upgrade',
            releasedAt: DateTime.now(),
          ),
          currentBuild: 1,
          currentVersion: '1.0.0',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updaterRepositoryProvider.overrideWithValue(fakeRepo),
            flavorConfigProvider.overrideWithValue(FlavorConfig.sideload()),
          ],
          child: const MaterialApp(
            home: BlockingUpdateScreen(),
          ),
        ),
      );

      final element = tester.element(find.byType(BlockingUpdateScreen));
      final container = ProviderScope.containerOf(element);
      await container.read(updaterProvider.notifier).checkForUpdate(force: true);
      await tester.pumpAndSettle();

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Version 2.0.0'), findsOneWidget);
      expect(find.text('Mandatory security protocol upgrade'), findsOneWidget);
      expect(find.byKey(const ValueKey('blocking_update_download_btn')), findsOneWidget);

      // Tapping download starts download
      await tester.tap(find.byKey(const ValueKey('blocking_update_download_btn')));
      await tester.pump();
      expect(fakeRepo.downloadCalls, equals(1));
    });

    testWidgets('SettingsScreen displays updater options only on Sideload flavor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeUpdaterRepository();
      final settingsRepo = LocalSettingsRepository();

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SettingsScreen()),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updaterRepositoryProvider.overrideWithValue(fakeRepo),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            flavorConfigProvider.overrideWithValue(FlavorConfig.sideload()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to About section
      final checkTileFinder = find.byKey(const ValueKey('settings_check_updates_tile'));
      await tester.scrollUntilVisible(checkTileFinder, 300);
      expect(checkTileFinder, findsOneWidget);

      // Tap Check for Updates
      await tester.tap(checkTileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(fakeRepo.checkForUpdateCalls, equals(1));
    });

    testWidgets('SettingsScreen hides updater tile on Google Play flavor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsRepo = LocalSettingsRepository();

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SettingsScreen()),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for Updates tile must NOT exist on Play flavor
      expect(find.byKey(const ValueKey('settings_check_updates_tile')), findsNothing);
      expect(find.text('Google Play Release'), findsOneWidget);
    });
  });
}
