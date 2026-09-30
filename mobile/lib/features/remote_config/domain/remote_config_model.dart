/// Data model representing remote configuration parameters for WebView guards.
class RemoteConfigModel {
  const RemoteConfigModel({
    required this.version,
    required this.allowedRoutePatterns,
    required this.blockedRoutePatterns,
    required this.hiddenElementSelectors,
    required this.injectedCss,
    required this.injectedJs,
  });

  final int version;
  final List<String> allowedRoutePatterns;
  final List<String> blockedRoutePatterns;
  final List<String> hiddenElementSelectors;
  final String injectedCss;
  final String injectedJs;

  /// Default safe fallback configuration bundled with the app.
  factory RemoteConfigModel.defaults() {
    return const RemoteConfigModel(
      version: 1,
      allowedRoutePatterns: [
        r'^/direct/inbox/?$',
        r'^/direct/t/.*$',
        r'^/notifications/?$',
        r'^/accounts/activity/?$',
      ],
      blockedRoutePatterns: [
        r'^/$',
        r'^/explore/.*$',
        r'^/reels/.*$',
        r'^/stories/.*$',
      ],
      hiddenElementSelectors: [
        "a[href='/']",
        "a[href*='/explore/']",
        "a[href*='/reels/']",
      ],
      injectedCss: '/* Injected guard styles */',
      injectedJs: '/* Injected guard scripts */',
    );
  }

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfigModel(
      version: json['version'] as int? ?? 1,
      allowedRoutePatterns: List<String>.from(
        json['allowedRoutePatterns'] as List? ?? [],
      ),
      blockedRoutePatterns: List<String>.from(
        json['blockedRoutePatterns'] as List? ?? [],
      ),
      hiddenElementSelectors: List<String>.from(
        json['hiddenElementSelectors'] as List? ?? [],
      ),
      injectedCss: json['injectedCss'] as String? ?? '',
      injectedJs: json['injectedJs'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'allowedRoutePatterns': allowedRoutePatterns,
      'blockedRoutePatterns': blockedRoutePatterns,
      'hiddenElementSelectors': hiddenElementSelectors,
      'injectedCss': injectedCss,
      'injectedJs': injectedJs,
    };
  }
}
