import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Repository interface for biometrics and local application security.
abstract class SecurityRepository {
  Future<bool> canCheckBiometrics();
  Future<bool> authenticate();
}

/// Implementation of [SecurityRepository] utilizing `local_auth`.
class LocalAuthSecurityRepository implements SecurityRepository {
  LocalAuthSecurityRepository([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

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
}

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return LocalAuthSecurityRepository();
});
