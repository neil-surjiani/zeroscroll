/// Global application constants.
class AppConstants {
  AppConstants._();

  /// Official application name.
  static const String appName = 'ZeroScroll';

  /// Android application package ID.
  static const String packageId = 'com.apexventures.zeroscroll';

  /// Minimum supported Android SDK version.
  static const int minSdk = 26;

  /// Build-time overridable remote configuration URL (HTTPS only).
  static const String remoteConfigUrl = String.fromEnvironment(
    'CONFIG_URL',
    defaultValue:
        'https://raw.githubusercontent.com/apexventures/zeroscroll-config/main/config.json',
  );

  /// Periodic fetch interval for remote config in the foreground (12 hours).
  static const Duration remoteConfigRefreshInterval = Duration(hours: 12);

  /// Max payload size for remote config in bytes (50 KB = 51,200 bytes).
  static const int maxRemoteConfigBytes = 50 * 1024;

  /// Default remote configuration URL (kept for backward compatibility).
  static const String defaultRemoteConfigUrl = remoteConfigUrl;

  /// Build-time overridable version check endpoint URL for sideload self-updates (HTTPS only).
  static const String versionCheckUrl = String.fromEnvironment(
    'VERSION_URL',
    defaultValue:
        'https://raw.githubusercontent.com/apexventures/zeroscroll-config/main/version.json',
  );

  /// Default version check endpoint URL (kept for backward compatibility).
  static const String defaultVersionCheckUrl = versionCheckUrl;

  /// Periodic interval for checking updates in the foreground (24 hours).
  static const Duration updaterRefreshInterval = Duration(hours: 24);

  /// Max payload size for version manifest in bytes (20 KB).
  static const int maxVersionManifestBytes = 20 * 1024;
}
