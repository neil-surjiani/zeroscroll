/// Global constants and URL paths for the WebView container.
class WebViewConstants {
  WebViewConstants._();

  /// Modern mobile Chrome user agent string on Android.
  static const String defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

  /// Initial entrypoint URL displaying Direct Messages inbox.
  static const String directInboxUrl =
      'https://www.instagram.com/direct/inbox/';

  /// Direct notifications / activity feed URL.
  static const String notificationsUrl =
      'https://www.instagram.com/notifications/';

  /// Fallback login URL.
  static const String loginUrl = 'https://www.instagram.com/accounts/login/';

  /// Base host domain allowed for in-app navigation.
  static const String allowedHost = 'instagram.com';
}
