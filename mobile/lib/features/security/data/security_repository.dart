import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Repository interface for biometrics and local application security.
abstract class SecurityRepository {
  Future<bool> canCheckBiometrics();
  Future<bool> authenticate();
  Future<void> setSecureFlag(bool enabled);
  Future<bool> isSecureFlagEnabled();
}

/// Implementation of [SecurityRepository] utilizing `local_auth` and native MethodChannel.
class LocalAuthSecurityRepository implements SecurityRepository {
  LocalAuthSecurityRepository({
    LocalAuthentication? auth,
    MethodChannel? methodChannel,
  })  : _auth = auth ?? LocalAuthentication(),
        _channel = methodChannel ??
            const MethodChannel('com.apexventures.zeroscroll/security');

  final LocalAuthentication _auth;
  final MethodChannel _channel;
  bool _mockSecureFlag = false;

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock ZeroScroll to access your messages',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setSecureFlag(bool enabled) async {
    _mockSecureFlag = enabled;
    try {
      await _channel.invokeMethod<bool>('setSecureFlag', {'enabled': enabled});
    } catch (_) {}
  }

  @override
  Future<bool> isSecureFlagEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isSecureFlagEnabled');
      return res ?? _mockSecureFlag;
    } catch (_) {
      return _mockSecureFlag;
    }
  }
}

/// In-memory implementation of [SecurityRepository] for unit tests.
class MockSecurityRepository implements SecurityRepository {
  MockSecurityRepository({
    this.canCheck = true,
    this.authResult = true,
    bool initialSecureFlag = false,
  }) : _secureFlag = initialSecureFlag;

  bool canCheck;
  bool authResult;
  bool _secureFlag;
  int authCalls = 0;
  int setSecureFlagCalls = 0;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<bool> authenticate() async {
    authCalls++;
    return authResult;
  }

  @override
  Future<void> setSecureFlag(bool enabled) async {
    setSecureFlagCalls++;
    _secureFlag = enabled;
  }

  @override
  Future<bool> isSecureFlagEnabled() async => _secureFlag;
}

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return LocalAuthSecurityRepository();
});
