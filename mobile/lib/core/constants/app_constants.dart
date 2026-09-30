/// Global application constants.
class AppConstants {
  AppConstants._();

  /// Official application name.
  static const String appName = 'ZeroScroll';

  /// Android application package ID.
  static const String packageId = 'com.apexventures.zeroscroll';

  /// Minimum supported Android SDK version.
  static const int minSdk = 26;

  /// Default remote configuration URL (HTTPS only).
  static const String defaultRemoteConfigUrl =
      'https://raw.githubusercontent.com/apexventures/zeroscroll-config/main/config.json';

  /// Version check endpoint URL for sideload self-updates (HTTPS only).
  static const String defaultVersionCheckUrl =
      'https://raw.githubusercontent.com/apexventures/zeroscroll-config/main/version.json';
}
