/// Base exception for updater operations.
class UpdaterException implements Exception {
  const UpdaterException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkUpdateException extends UpdaterException {
  const NetworkUpdateException([super.message = 'Network connection failed while checking for updates.']);
}

class HashMismatchException extends UpdaterException {
  const HashMismatchException([
    super.message = 'Security verification failed: downloaded APK hash does not match manifest. File removed.',
  ]);
}

class SignatureMismatchException extends UpdaterException {
  const SignatureMismatchException([
    super.message = 'Security verification failed: APK signing certificate does not match the installed app. File removed.',
  ]);
}

class LowStorageException extends UpdaterException {
  const LowStorageException([
    super.message = 'Insufficient device storage space to download the update.',
  ]);
}

class UserCanceledException extends UpdaterException {
  const UserCanceledException([
    super.message = 'Download was canceled.',
  ]);
}

class InstallerPermissionException extends UpdaterException {
  const InstallerPermissionException([
    super.message = 'Permission to install unknown apps is required to apply the update.',
  ]);
}
