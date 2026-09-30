import 'version_manifest.dart';

enum UpdateCheckStatus {
  noUpdate,
  updateAvailable,
  updateRequired,
  disabled,
  error,
}

/// Result returned from checking for application updates.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.manifest,
    this.errorMessage,
    this.currentBuild = 0,
    this.currentVersion = '',
  });

  final UpdateCheckStatus status;
  final VersionManifest? manifest;
  final String? errorMessage;
  final int currentBuild;
  final String currentVersion;

  bool get hasUpdate =>
      status == UpdateCheckStatus.updateAvailable ||
      status == UpdateCheckStatus.updateRequired;

  bool get isMandatory => status == UpdateCheckStatus.updateRequired;

  factory UpdateCheckResult.noUpdate({
    required int currentBuild,
    required String currentVersion,
  }) =>
      UpdateCheckResult(
        status: UpdateCheckStatus.noUpdate,
        currentBuild: currentBuild,
        currentVersion: currentVersion,
      );

  factory UpdateCheckResult.available({
    required VersionManifest manifest,
    required int currentBuild,
    required String currentVersion,
  }) =>
      UpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        manifest: manifest,
        currentBuild: currentBuild,
        currentVersion: currentVersion,
      );

  factory UpdateCheckResult.required({
    required VersionManifest manifest,
    required int currentBuild,
    required String currentVersion,
  }) =>
      UpdateCheckResult(
        status: UpdateCheckStatus.updateRequired,
        manifest: manifest,
        currentBuild: currentBuild,
        currentVersion: currentVersion,
      );

  factory UpdateCheckResult.disabled() => const UpdateCheckResult(
        status: UpdateCheckStatus.disabled,
      );

  factory UpdateCheckResult.error(String message) => UpdateCheckResult(
        status: UpdateCheckStatus.error,
        errorMessage: message,
      );
}
