import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/route_config.dart';

/// Repository contract for fetching and caching RouteConfig and guard script assets.
abstract class RouteConfigRepository {
  Future<RouteConfig> getRouteConfig();
  Future<String> getGuardJs();
  Future<void> refreshConfig();
}

/// Implementation that loads bundled JSON and JS assets from the asset bundle.
class AssetRouteConfigRepository implements RouteConfigRepository {
  RouteConfig? _cachedConfig;
  String? _cachedGuardJs;

  @override
  Future<RouteConfig> getRouteConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/default_config.json',
      );
      final Map<String, dynamic> decoded =
          jsonDecode(jsonString) as Map<String, dynamic>;
      _cachedConfig = RouteConfig.fromJson(decoded);
      return _cachedConfig!;
    } catch (_) {
      // Fallback in-memory config if asset loading fails
      _cachedConfig = const RouteConfig(
        version: 1,
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        fallbackPath: '/direct/inbox/',
        allowedPaths: [
          r'^/direct/',
          r'^/accounts/login',
          r'^/accounts/activity',
          r'^/accounts/onetap',
          r'^/challenge/',
          r'^/two_factor/',
          r'^/accounts/suspended',
          r'^/reel/[^/]+/?$',
          r'^/reels/[^/]+/?$',
          r'^/p/[^/]+/?$',
        ],
        alwaysBlockedPaths: [
          r'^/$',
          r'^/explore',
          r'^/reels/?$',
          r'^/stories/',
          r'^/accounts/edit',
          r'^/(?!direct|accounts|challenge|two_factor|reel|reels|p|legal|static)[a-zA-Z0-9._]+/?$',
        ],
        hideSelectors: [
          "a[href='/']",
          "a[href^='/explore']",
          "a[href^='/reels']",
          "a[aria-label='Home']",
          "a[aria-label='Search']",
          "a[aria-label='Reels']",
          "section[aria-label='Stories']",
          "div[aria-label*='Stories']",
        ],
      );
      return _cachedConfig!;
    }
  }

  @override
  Future<String> getGuardJs() async {
    if (_cachedGuardJs != null) {
      return _cachedGuardJs!;
    }

    try {
      _cachedGuardJs = await rootBundle.loadString('assets/js/guard.js');
      return _cachedGuardJs!;
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> refreshConfig() async {
    _cachedConfig = null;
    _cachedGuardJs = null;
    await getRouteConfig();
    await getGuardJs();
  }
}

final routeConfigRepositoryProvider = Provider<RouteConfigRepository>((ref) {
  return AssetRouteConfigRepository();
});

final routeConfigProvider = FutureProvider<RouteConfig>((ref) async {
  final repo = ref.watch(routeConfigRepositoryProvider);
  return repo.getRouteConfig();
});

final guardJsProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(routeConfigRepositoryProvider);
  return repo.getGuardJs();
});
