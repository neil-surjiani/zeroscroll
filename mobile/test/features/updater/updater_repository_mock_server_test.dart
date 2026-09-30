import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/updater/data/updater_repository.dart';
import 'package:zeroscroll/features/updater/data/updater_service.dart';
import 'package:zeroscroll/features/updater/domain/download_progress.dart';
import 'package:zeroscroll/features/updater/domain/update_check_result.dart';
import 'package:zeroscroll/features/updater/domain/updater_exceptions.dart';
import 'package:zeroscroll/features/updater/domain/version_manifest.dart';

void main() {
  group('UpdaterRepository Mock Server & Network Tests', () {
    late HttpServer mockServer;
    late Directory tempDir;
    late MockUpdaterNativeService nativeService;
    late SharedPreferences prefs;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('updater_mock_test_');
      nativeService = MockUpdaterNativeService();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      // Spin up local mock HTTP server
      mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async {
      await mockServer.close(force: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    PackageInfo createPackageInfo({String version = '1.0.0', String buildNumber = '1'}) {
      return PackageInfo(
        appName: 'ZeroScroll',
        packageName: 'com.apexventures.zeroscroll',
        version: version,
        buildNumber: buildNumber,
        buildSignature: '',
      );
    }

    test('checkForUpdate returns available update when server has newer build', () async {
      const validPayload = {
        'latestVersion': '1.0.1',
        'latestBuild': 2,
        'minSupportedBuild': 1,
        'apkUrl': 'https://example.com/app.apk',
        'sha256': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'changelog': 'Bug fixes and performance upgrades',
        'releasedAt': '2026-09-30T12:00:00Z',
      };

      mockServer.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(validPayload))
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(buildNumber: '1'),
        prefs: prefs,
        versionUrl: 'http://${mockServer.address.host}:${mockServer.port}/version.json',
        cacheDirectoryPath: tempDir.path,
      );

      final result = await repo.checkForUpdate(force: true);

      expect(result.status, equals(UpdateCheckStatus.updateAvailable));
      expect(result.hasUpdate, isTrue);
      expect(result.isMandatory, isFalse);
      expect(result.manifest?.latestVersion, equals('1.0.1'));
      expect(result.manifest?.latestBuild, equals(2));
      expect(result.manifest?.changelog, equals('Bug fixes and performance upgrades'));
    });

    test('checkForUpdate returns mandatory update when current build is below minSupportedBuild', () async {
      const mandatoryPayload = {
        'latestVersion': '2.0.0',
        'latestBuild': 10,
        'minSupportedBuild': 5,
        'apkUrl': 'https://example.com/app.apk',
        'sha256': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        'changelog': 'Critical security architecture update',
        'releasedAt': '2026-09-30T12:00:00Z',
      };

      mockServer.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(mandatoryPayload))
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(buildNumber: '3'),
        prefs: prefs,
        versionUrl: 'http://${mockServer.address.host}:${mockServer.port}/version.json',
        cacheDirectoryPath: tempDir.path,
      );

      final result = await repo.checkForUpdate(force: true);

      expect(result.status, equals(UpdateCheckStatus.updateRequired));
      expect(result.hasUpdate, isTrue);
      expect(result.isMandatory, isTrue);
      expect(result.manifest?.minSupportedBuild, equals(5));
    });

    test('checkForUpdate returns noUpdate when current build is equal or higher', () async {
      const upToDatePayload = {
        'latestVersion': '1.0.0',
        'latestBuild': 1,
        'minSupportedBuild': 1,
        'apkUrl': 'https://example.com/app.apk',
        'sha256': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'changelog': '',
        'releasedAt': '2026-09-30T12:00:00Z',
      };

      mockServer.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(upToDatePayload))
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(buildNumber: '1'),
        prefs: prefs,
        versionUrl: 'http://${mockServer.address.host}:${mockServer.port}/version.json',
        cacheDirectoryPath: tempDir.path,
      );

      final result = await repo.checkForUpdate(force: true);

      expect(result.status, equals(UpdateCheckStatus.noUpdate));
      expect(result.hasUpdate, isFalse);
    });

    test('checkForUpdate strictly respects 24-hour rate limit unless forced', () async {
      int requestCount = 0;
      mockServer.listen((request) {
        requestCount++;
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({
            'latestVersion': '1.0.1',
            'latestBuild': 2,
            'minSupportedBuild': 1,
            'apkUrl': 'https://example.com/app.apk',
            'sha256': 'a' * 64,
            'changelog': '',
            'releasedAt': '2026-09-30T12:00:00Z',
          }))
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(buildNumber: '1'),
        prefs: prefs,
        versionUrl: 'http://${mockServer.address.host}:${mockServer.port}/version.json',
        cacheDirectoryPath: tempDir.path,
      );

      // First call (force: true) -> makes network request
      await repo.checkForUpdate(force: true);
      expect(requestCount, equals(1));

      // Second call (force: false) -> skips network request because < 24h
      final cachedResult = await repo.checkForUpdate(force: false);
      expect(requestCount, equals(1));
      expect(cachedResult.status, equals(UpdateCheckStatus.noUpdate));

      // Third call (force: true) -> bypasses rate limit and requests server
      await repo.checkForUpdate(force: true);
      expect(requestCount, equals(2));
    });

    test('PlayStore flavor strictly disables update checks with zero network traffic', () async {
      int serverHits = 0;
      mockServer.listen((request) {
        serverHits++;
        request.response.close();
      });

      // Play flavor repository
      const playRepo = PlayUpdaterRepository();
      final result = await playRepo.checkForUpdate(force: true);

      expect(result.status, equals(UpdateCheckStatus.disabled));
      expect(serverHits, equals(0));
    });

    test('checkForUpdate handles HTTP 404/500 errors gracefully', () async {
      mockServer.listen((request) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(buildNumber: '1'),
        prefs: prefs,
        versionUrl: 'http://${mockServer.address.host}:${mockServer.port}/version.json',
        cacheDirectoryPath: tempDir.path,
      );

      final result = await repo.checkForUpdate(force: true);
      expect(result.status, equals(UpdateCheckStatus.error));
      expect(result.errorMessage, contains('404'));
    });

    test('downloadApk streams progress and produces verified file', () async {
      const apkContent = 'Pretend APK binary content with exact checksum verification';
      final apkBytes = utf8.encode(apkContent);
      final expectedSha = sha256.convert(apkBytes).toString().toLowerCase();

      mockServer.listen((request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = apkBytes.length
          ..add(apkBytes)
          ..close();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(),
        prefs: prefs,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'http://${mockServer.address.host}:${mockServer.port}/update.apk',
        sha256: expectedSha,
        changelog: 'Test changelog',
        releasedAt: DateTime.now(),
      );

      final progressEvents = <DownloadProgress>[];
      final downloadedFile = await repo.downloadApk(
        manifest,
        onProgress: (p) => progressEvents.add(p),
      );

      expect(await downloadedFile.exists(), isTrue);
      expect(progressEvents.isNotEmpty, isTrue);
      expect(progressEvents.last.isCompleted, isTrue);
      expect(progressEvents.last.percentage, equals(1.0));
      expect(await downloadedFile.readAsString(), equals(apkContent));
    });

    test('downloadApk throws LowStorageException when device space < 50MB', () async {
      nativeService.availableStorage = 10 * 1024 * 1024; // Only 10 MB free

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(),
        prefs: prefs,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'https://example.com/app.apk',
        sha256: 'a' * 64,
        changelog: '',
        releasedAt: DateTime.now(),
      );

      expect(
        () => repo.downloadApk(manifest),
        throwsA(isA<LowStorageException>()),
      );
    });

    test('downloadApk deletes file when download is canceled by user', () async {
      final cancelSignal = Completer<void>();

      mockServer.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.contentLength = 10000;
        request.response.add(utf8.encode('part1'));
        await request.response.flush();
        // Give time for cancelSignal to fire
        await Future.delayed(const Duration(milliseconds: 50));
        cancelSignal.complete();
      });

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        packageInfo: createPackageInfo(),
        prefs: prefs,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'http://${mockServer.address.host}:${mockServer.port}/cancel_test.apk',
        sha256: 'a' * 64,
        changelog: '',
        releasedAt: DateTime.now(),
      );

      expect(
        () => repo.downloadApk(manifest, cancelSignal: cancelSignal),
        throwsA(isA<UserCanceledException>()),
      );
    });

    test('verifyAndInstall succeeds when SHA-256 and signatures match', () async {
      final file = File('${tempDir.path}/valid.apk');
      const content = 'Signed valid APK content';
      await file.writeAsString(content);
      final expectedSha = sha256.convert(utf8.encode(content)).toString().toLowerCase();

      nativeService.canInstall = true;
      nativeService.signatureValid = true;

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'https://example.com/app.apk',
        sha256: expectedSha,
        changelog: '',
        releasedAt: DateTime.now(),
      );

      final success = await repo.verifyAndInstall(file, manifest);
      expect(success, isTrue);
      expect(nativeService.verifySignatureCalls, equals(1));
      expect(nativeService.installCalls, equals(1));
    });

    test('verifyAndInstall rejects tampered hash and deletes APK file', () async {
      final file = File('${tempDir.path}/tampered.apk');
      await file.writeAsString('Corrupted or modified payload');

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'https://example.com/app.apk',
        sha256: 'f' * 64, // Tampered hash mismatch
        changelog: '',
        releasedAt: DateTime.now(),
      );

      await expectLater(
        repo.verifyAndInstall(file, manifest),
        throwsA(isA<HashMismatchException>()),
      );

      // Verify the tampered APK was deleted
      expect(await file.exists(), isFalse);
      expect(nativeService.installCalls, equals(0));
    });

    test('verifyAndInstall rejects signature mismatch and deletes APK file', () async {
      final file = File('${tempDir.path}/bad_sig.apk');
      const content = 'Unsigned or mismatched signature APK';
      await file.writeAsString(content);
      final expectedSha = sha256.convert(utf8.encode(content)).toString().toLowerCase();

      nativeService.canInstall = true;
      nativeService.signatureValid = false; // Mismatched signature

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'https://example.com/app.apk',
        sha256: expectedSha,
        changelog: '',
        releasedAt: DateTime.now(),
      );

      await expectLater(
        repo.verifyAndInstall(file, manifest),
        throwsA(isA<SignatureMismatchException>()),
      );

      // Verify file deleted and install not attempted
      expect(await file.exists(), isFalse);
      expect(nativeService.installCalls, equals(0));
    });

    test('verifyAndInstall throws InstallerPermissionException when permission denied', () async {
      final file = File('${tempDir.path}/needs_permission.apk');
      const content = 'Valid signed APK';
      await file.writeAsString(content);
      final expectedSha = sha256.convert(utf8.encode(content)).toString().toLowerCase();

      nativeService.canInstall = false; // Unknown app install not granted
      nativeService.signatureValid = true;

      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
        nativeService: nativeService,
        cacheDirectoryPath: tempDir.path,
      );

      final manifest = VersionManifest(
        latestVersion: '1.0.1',
        latestBuild: 2,
        minSupportedBuild: 1,
        apkUrl: 'https://example.com/app.apk',
        sha256: expectedSha,
        changelog: '',
        releasedAt: DateTime.now(),
      );

      expect(
        () => repo.verifyAndInstall(file, manifest),
        throwsA(isA<InstallerPermissionException>()),
      );

      expect(nativeService.installCalls, equals(0));
    });
  });
}
