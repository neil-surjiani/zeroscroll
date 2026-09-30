import 'dart:convert';

/// Single authoritative configuration model driving the 3-layer ZeroScroll route guard.
class RouteConfig {
  const RouteConfig({
    required this.version,
    required this.userAgent,
    required this.fallbackPath,
    required this.allowedPaths,
    required this.alwaysBlockedPaths,
    required this.hideSelectors,
    this.customCss = '',
    this.externalAllowedHosts = const [
      'instagram.com',
      'facebook.com',
      'meta.com',
      'fbcdn.net',
    ],
  });

  final int version;
  final String userAgent;
  final String fallbackPath;
  final List<String> allowedPaths;
  final List<String> alwaysBlockedPaths;
  final List<String> hideSelectors;
  final String customCss;
  final List<String> externalAllowedHosts;

  /// Validates whether a given URL path is permitted under the guard rules.
  ///
  /// Priority:
  /// 1. If [path] matches any pattern in [alwaysBlockedPaths], it is strictly rejected.
  /// 2. If [path] matches any pattern in [allowedPaths], it is approved.
  /// 3. Default deny: any other path (such as profiles or discovery) is rejected.
  bool isPathAllowed(String path) {
    final clean = _normalizePath(path);

    // 1. Check always blocked paths first
    for (final pattern in alwaysBlockedPaths) {
      try {
        final regex = RegExp(pattern);
        if (regex.hasMatch(clean)) {
          return false;
        }
      } catch (_) {
        // Continue if an individual regex is malformed
      }
    }

    // 2. Check allowed paths
    for (final pattern in allowedPaths) {
      try {
        final regex = RegExp(pattern);
        if (regex.hasMatch(clean)) {
          return true;
        }
      } catch (_) {
        // Continue if an individual regex is malformed
      }
    }

    // 3. Default deny
    return false;
  }

  /// Checks whether a given host is permitted to load inside the WebView.
  bool isHostAllowed(String host) {
    final lowerHost = host.toLowerCase();
    for (final allowed in externalAllowedHosts) {
      if (lowerHost == allowed || lowerHost.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  /// Normalizes incoming path by stripping query parameters and trailing anchors.
  static String _normalizePath(String rawPath) {
    var p = rawPath.trim();
    if (p.isEmpty) return '/';

    // Strip query parameters and fragment
    final queryIndex = p.indexOf('?');
    if (queryIndex != -1) {
      p = p.substring(0, queryIndex);
    }
    final hashIndex = p.indexOf('#');
    if (hashIndex != -1) {
      p = p.substring(0, hashIndex);
    }

    if (!p.startsWith('/')) {
      p = '/$p';
    }
    return p;
  }

  factory RouteConfig.fromJson(Map<String, dynamic> json) {
    return RouteConfig(
      version: json['version'] as int? ?? 1,
      userAgent: json['userAgent'] as String? ?? '',
      fallbackPath: json['fallbackPath'] as String? ?? '/direct/inbox/',
      allowedPaths: List<String>.from(json['allowedPaths'] as List? ?? []),
      alwaysBlockedPaths: List<String>.from(
        json['alwaysBlockedPaths'] as List? ?? [],
      ),
      hideSelectors: List<String>.from(json['hideSelectors'] as List? ?? []),
      customCss: json['customCss'] as String? ?? '',
      externalAllowedHosts: json['externalAllowedHosts'] != null
          ? List<String>.from(json['externalAllowedHosts'] as List)
          : const ['instagram.com', 'facebook.com', 'meta.com', 'fbcdn.net'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'userAgent': userAgent,
      'fallbackPath': fallbackPath,
      'allowedPaths': allowedPaths,
      'alwaysBlockedPaths': alwaysBlockedPaths,
      'hideSelectors': hideSelectors,
      'customCss': customCss,
      'externalAllowedHosts': externalAllowedHosts,
    };
  }

  /// Generates a JSON string suitable for injecting into JavaScript.
  String toJsonString() => jsonEncode(toJson());
}
