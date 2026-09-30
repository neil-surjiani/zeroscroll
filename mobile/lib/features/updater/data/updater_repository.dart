import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/apk_hash_verifier.dart';
import '../domain/download_progress.dart';
import '../domain/update_check_result.dart';
import '../domain/updater_exceptions.dart';
import '../domain/version_comparator.dart';
import '../domain/version_manifest.dart';
import 'updater_service.dart';

/// Repository for sideload application updates.
abstract class UpdaterRepository {
  Future<UpdateCheckResult> checkForUpdate({bool force = false});
  Future<File> downloadApk(
    VersionManifest manifest, {
    void Function(DownloadProgress)? onProgress,
    Completer<void>? cancelSignal,
  });
  Future<bool> verifyAndInstall(File apkFile, VersionManifest manifest);
  Future<bool> requestInstallPermission();
  Future<bool> canRequestPackageInstalls();
}

/// Sideload-specific updater repository implementation.
class SideloadUpdaterRepository implements UpdaterRepository {
  SideloadUpdaterRepository({
    required this.flavorConfig,
    UpdaterNativeService? nativeService,
    http.Client? httpClient,
    PackageInfo? packageInfo,
    SharedPreferences? prefs,
    String? versionUrl,
    String? cacheDirectoryPath,
  })  : nativeService = nativeService ?? MethodChannelUpdaterNativeService(),
        _httpClient = httpClient ?? http.Client(),
        _packageInfo = packageInfo,
        _prefs = prefs,
        _versionUrl = versionUrl ?? AppConstants.versionCheckUrl,
        _cacheDirectoryPath = cacheDirectoryPath;

  final FlavorConfig flavorConfig;
  final UpdaterNativeService nativeService;
  final http.Client _httpClient;
  PackageInfo? _packageInfo;
  SharedPreferences? _prefs;
  final String _versionUrl;
  final String? _cacheDirectoryPath;

  static const String _keyLastUpdateCheck = 'zeroscroll_last_update_check';

  Future<PackageInfo> _getPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> _getCachePath() async {
    final customPath = _cacheDirectoryPath;
    if (customPath != null) return customPath;
    final cacheDir = await getApplicationCacheDirectory();
    return cacheDir.path;
  }

  @override
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) async {
    // 1. Safety guard: Strictly disabled on Google Play builds
    if (!flavorConfig.canSelfUpdate) {
      return UpdateCheckResult.disabled();
    }

    final prefs = await _getPrefs();
    final now = DateTime.now();

    // 2. Check 24-hour rate limit unless forced
    if (!force) {
      final lastCheckMillis = prefs.getInt(_keyLastUpdateCheck);
      if (lastCheckMillis != null) {
        final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
        if (now.difference(lastCheck) < AppConstants.updaterRefreshInterval) {
          // Checked recently, return noUpdate without redundant network hit
          final pkg = await _getPackageInfo();
          final build = int.tryParse(pkg.buildNumber) ?? 0;
          return UpdateCheckResult.noUpdate(
            currentBuild: build,
            currentVersion: pkg.version,
          );
        }
      }
    }

    // 3. Validate endpoint security: HTTPS only (or loopback in test environments)
    final isSecure = _versionUrl.startsWith('https://') ||
        _versionUrl.startsWith('http://127.0.0.1') ||
        _versionUrl.startsWith('http://localhost');
    if (!isSecure) {
      return UpdateCheckResult.error('Update URL must use secure HTTPS.');
    }

    try {
      final response = await _httpClient.get(
        Uri.parse(_versionUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return UpdateCheckResult.error(
          'Failed to check for updates (HTTP ${response.statusCode}).',
        );
      }

      if (response.bodyBytes.length > AppConstants.maxVersionManifestBytes) {
        return UpdateCheckResult.error('Version manifest payload exceeds size limit.');
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return UpdateCheckResult.error('Invalid version manifest JSON structure.');
      }

      final manifest = VersionManifest.fromJson(decoded);
      final pkg = await _getPackageInfo();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

      // Record check timestamp
      await prefs.setInt(_keyLastUpdateCheck, now.millisecondsSinceEpoch);

      final evaluation = VersionComparator.evaluate(
        currentBuild: currentBuild,
        manifest: manifest,
      );

      switch (evaluation) {
        case UpdateType.mandatory:
          return UpdateCheckResult.required(
            manifest: manifest,
            currentBuild: currentBuild,
            currentVersion: pkg.version,
          );
        case UpdateType.optional:
          return UpdateCheckResult.available(
            manifest: manifest,
            currentBuild: currentBuild,
            currentVersion: pkg.version,
          );
        case UpdateType.none:
          return UpdateCheckResult.noUpdate(
            currentBuild: currentBuild,
            currentVersion: pkg.version,
          );
      }
    } catch (e) {
      return UpdateCheckResult.error('Update check failed: $e');
    }
  }

  @override
  Future<File> downloadApk(
    VersionManifest manifest, {
    void Function(DownloadProgress)? onProgress,
    Completer<void>? cancelSignal,
  }) async {
    if (!flavorConfig.canSelfUpdate) {
      throw const UpdaterException('Self-updating is disabled on this build flavor.');
    }

    // Storage check: ensure at least 50 MB available
    final availableBytes = await nativeService.getAvailableStorageBytes();
    if (availableBytes < 50 * 1024 * 1024) {
      throw const LowStorageException();
    }

    final cachePath = await _getCachePath();
    final updatesDir = Directory('$cachePath/updates');
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }

    final targetFile = File('${updatesDir.path}/zeroscroll-${manifest.latestBuild}.apk');
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    final request = http.Request('GET', Uri.parse(manifest.apkUrl));
    final response = await _httpClient.send(request);

    if (response.statusCode != 200) {
      throw NetworkUpdateException('Failed to download APK (HTTP ${response.statusCode})');
    }

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;
    final fileSink = targetFile.openWrite();

    try {
      final subscription = response.stream.listen(null);

      final streamCompleter = Completer<void>();

      subscription.onData((chunk) {
        if (cancelSignal?.isCompleted ?? false) {
          subscription.cancel();
          streamCompleter.completeError(const UserCanceledException());
          return;
        }
        fileSink.add(chunk);
        receivedBytes += chunk.length;
        onProgress?.call(
          DownloadProgress(
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            isCompleted: false,
          ),
        );
      });

      subscription.onError((err) {
        streamCompleter.completeError(NetworkUpdateException('Download failed: $err'));
      });

      subscription.onDone(() {
        if (!streamCompleter.isCompleted) {
          streamCompleter.complete();
        }
      });

      if (cancelSignal != null) {
        cancelSignal.future.then((_) {
          if (!streamCompleter.isCompleted) {
            subscription.cancel();
            streamCompleter.completeError(const UserCanceledException());
          }
        });
      }

      await streamCompleter.future;
      await fileSink.flush();
      await fileSink.close();

      onProgress?.call(
        DownloadProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes > 0 ? totalBytes : receivedBytes,
          isCompleted: true,
        ),
      );

      return targetFile;
    } catch (e) {
      await fileSink.close();
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      if (e is UpdaterException) rethrow;
      throw NetworkUpdateException('APK download failed: $e');
    }
  }

  @override
  Future<bool> verifyAndInstall(File apkFile, VersionManifest manifest) async {
    if (!flavorConfig.canSelfUpdate) {
      throw const UpdaterException('Self-updating is disabled on this build flavor.');
    }

    // 1. Hash verification: SHA-256 against manifest
    final isHashValid = await ApkHashVerifier.verifyFile(
      file: apkFile,
      expectedSha256: manifest.sha256,
    );

    if (!isHashValid) {
      // ApkHashVerifier automatically deleted the invalid file
      throw const HashMismatchException();
    }

    // 2. Signature verification: Compare signing certs against installed app
    final isSignatureValid = await nativeService.verifyApkSignature(apkFile.path);
    if (!isSignatureValid) {
      if (await apkFile.exists()) {
        try {
          await apkFile.delete();
        } catch (_) {}
      }
      throw const SignatureMismatchException();
    }

    // 3. Check "install unknown apps" permission
    final canInstall = await nativeService.canRequestPackageInstalls();
    if (!canInstall) {
      throw const InstallerPermissionException();
    }

    // 4. Launch package installer
    final result = await nativeService.installApk(apkFile.path);
    return result['success'] == true;
  }

  @override
  Future<bool> requestInstallPermission() async {
    return nativeService.openInstallPermissionSettings();
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    return nativeService.canRequestPackageInstalls();
  }
}

/// Fallback no-op repository for Play Store flavor.
class PlayUpdaterRepository implements UpdaterRepository {
  const PlayUpdaterRepository();

  @override
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) async {
    return UpdateCheckResult.disabled();
  }

  @override
  Future<File> downloadApk(
    VersionManifest manifest, {
    void Function(DownloadProgress)? onProgress,
    Completer<void>? cancelSignal,
  }) async {
    throw const UpdaterException('Updater is not available in the Play Store build.');
  }

  @override
  Future<bool> verifyAndInstall(File apkFile, VersionManifest manifest) async {
    throw const UpdaterException('Updater is not available in the Play Store build.');
  }

  @override
  Future<bool> requestInstallPermission() async => false;

  @override
  Future<bool> canRequestPackageInstalls() async => false;
}

final updaterRepositoryProvider = Provider<UpdaterRepository>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  if (!flavor.canSelfUpdate) {
    return const PlayUpdaterRepository();
  }
  final nativeService = ref.watch(updaterNativeServiceProvider);
  return SideloadUpdaterRepository(
    flavorConfig: flavor,
    nativeService: nativeService,
  );
});
