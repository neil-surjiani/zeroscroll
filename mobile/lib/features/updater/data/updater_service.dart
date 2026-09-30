import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native platform bridge interface for package installation and security verification.
abstract class UpdaterNativeService {
  Future<bool> canRequestPackageInstalls();
  Future<bool> openInstallPermissionSettings();
  Future<bool> verifyApkSignature(String filePath);
  Future<Map<String, dynamic>> installApk(String filePath);
  Future<int> getAvailableStorageBytes();
}

/// Production Android MethodChannel implementation of [UpdaterNativeService].
class MethodChannelUpdaterNativeService implements UpdaterNativeService {
  static const MethodChannel _channel =
      MethodChannel('com.apexventures.zeroscroll/updater');

  @override
  Future<bool> canRequestPackageInstalls() async {
    try {
      final result = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> verifyApkSignature(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('verifyApkSignature', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> installApk(String filePath) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('installApk', {
        'filePath': filePath,
      });
      return result ?? {'success': false, 'status': 'unknown'};
    } catch (e) {
      return {'success': false, 'status': 'error', 'error': e.toString()};
    }
  }

  @override
  Future<int> getAvailableStorageBytes() async {
    try {
      final result = await _channel.invokeMethod<int>('getAvailableStorageBytes');
      return result ?? (500 * 1024 * 1024); // Fallback to 500 MB
    } catch (_) {
      return 500 * 1024 * 1024;
    }
  }
}

/// Test/mock implementation of [UpdaterNativeService].
class MockUpdaterNativeService implements UpdaterNativeService {
  MockUpdaterNativeService({
    this.canInstall = true,
    this.signatureValid = true,
    this.availableStorage = 500 * 1024 * 1024,
    this.installSuccess = true,
  });

  bool canInstall;
  bool signatureValid;
  int availableStorage;
  bool installSuccess;

  int canInstallCalls = 0;
  int openSettingsCalls = 0;
  int verifySignatureCalls = 0;
  int installCalls = 0;

  @override
  Future<bool> canRequestPackageInstalls() async {
    canInstallCalls++;
    return canInstall;
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<bool> verifyApkSignature(String filePath) async {
    verifySignatureCalls++;
    return signatureValid;
  }

  @override
  Future<Map<String, dynamic>> installApk(String filePath) async {
    installCalls++;
    if (!canInstall) {
      return {'success': false, 'status': 'permission_required'};
    }
    return {
      'success': installSuccess,
      'status': installSuccess ? 'installer_launched' : 'error',
    };
  }

  @override
  Future<int> getAvailableStorageBytes() async => availableStorage;
}

final updaterNativeServiceProvider = Provider<UpdaterNativeService>((ref) {
  return MethodChannelUpdaterNativeService();
});
