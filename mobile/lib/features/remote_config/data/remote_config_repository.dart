import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../security/presentation/providers/debug_log_provider.dart';
import '../domain/kill_switch_config.dart';
import '../domain/remote_config_validator.dart';
import '../domain/route_config.dart';

/// Origin source of the currently loaded route configuration.
enum ConfigSource {
  remote,
  cached,
  bundled,
  inMemoryFallback,
}

/// Repository contract for fetching, validating, caching, and serving RouteConfig.
abstract class RouteConfigRepository {
  Future<RouteConfig> getRouteConfig({bool forceRefresh = false});
  Future<String> getGuardJs();
  Future<void> refreshConfig();

  ConfigSource get currentSource;
  DateTime? get lastFetchedAt;
  String? get lastFetchError;
  int? get activeVersion;
  Stream<RouteConfig> get configStream;
  void dispose();
}

/// Production implementation of RouteConfigRepository with 3-tier precedence:
/// 1. Remote (HTTPS, <= 50 KB, valid schema & regexes, version monotonicity).
/// 2. Cached (Local SharedPreferences storage).
/// 3. Bundled Default (assets/default_config.json).
/// 4. In-Memory Safe Fallback (never crash).
class HttpRouteConfigRepository implements RouteConfigRepository {
  /// Preloaded guard script string populated during app bootstrap for instantaneous startup.
  static String? preloadedGuardJs;

  HttpRouteConfigRepository({
    http.Client? httpClient,
    SharedPreferences? sharedPreferences,
    AssetBundle? assetBundle,
    String? configUrl,
    String? currentAppVersion,
    void Function(String message, String level)? logger,
    bool enablePeriodicTimer = true,
  })  : _httpClient = httpClient,
        _sharedPreferences = sharedPreferences,
        _assetBundle = assetBundle,
        _configUrl = configUrl ?? AppConstants.remoteConfigUrl,
        _currentAppVersion = currentAppVersion,
        _logger = logger,
        _enablePeriodicTimer = enablePeriodicTimer {
    if (_enablePeriodicTimer) {
      _startPeriodicTimer();
    }
  }

  static const String keyCachedConfigJson = 'zeroscroll_cached_route_config_json';
  static const String keyCachedConfigTimestamp =
      'zeroscroll_cached_route_config_timestamp';

  final http.Client? _httpClient;
  SharedPreferences? _sharedPreferences;
  final AssetBundle? _assetBundle;
  final String _configUrl;
  String? _currentAppVersion;
  final void Function(String message, String level)? _logger;
  final bool _enablePeriodicTimer;

  RouteConfig? _activeConfig;
  String? _cachedGuardJs;
  ConfigSource _currentSource = ConfigSource.bundled;
  DateTime? _lastFetchedAt;
  String? _lastFetchError;
  Timer? _refreshTimer;

  final StreamController<RouteConfig> _configStreamController =
      StreamController<RouteConfig>.broadcast();

  @override
  ConfigSource get currentSource => _currentSource;

  @override
  DateTime? get lastFetchedAt => _lastFetchedAt;

  @override
  String? get lastFetchError => _lastFetchError;

  @override
  int? get activeVersion => _activeConfig?.version;

  @override
  Stream<RouteConfig> get configStream => _configStreamController.stream;

  void _log(String message, String level) {
    _logger?.call(message, level);
  }

  void _startPeriodicTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      AppConstants.remoteConfigRefreshInterval,
      (_) => getRouteConfig(forceRefresh: true),
    );
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_sharedPreferences != null) {
      return _sharedPreferences!;
    }
    _sharedPreferences = await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  AssetBundle _getBundle() => _assetBundle ?? rootBundle;

  Future<String> _getAppVersion() async {
    if (_currentAppVersion != null && _currentAppVersion!.isNotEmpty) {
      return _currentAppVersion!;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _currentAppVersion = info.version;
      return _currentAppVersion!;
    } catch (_) {
      _currentAppVersion = '1.0.0';
      return _currentAppVersion!;
    }
  }

  @override
  Future<RouteConfig> getRouteConfig({bool forceRefresh = false}) async {
    // If we have an active config and this is not a force refresh and it is not stale, return it
    if (!forceRefresh && _activeConfig != null) {
      final fetchedAt = _lastFetchedAt;
      if (fetchedAt != null &&
          DateTime.now().difference(fetchedAt) <
              AppConstants.remoteConfigRefreshInterval) {
        return _activeConfig!;
      }
    }

    final appVersion = await _getAppVersion();
    final prefs = await _getPrefs();
    final cachedJson = prefs.getString(keyCachedConfigJson);
    int? cachedVersion;
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        cachedVersion = decoded['version'] as int?;
      } catch (_) {}
    }

    // ==========================================
    // TIER 1: Remote Fetch
    // ==========================================
    RouteConfig? remoteConfig;
    try {
      remoteConfig = await _fetchRemote(
        cachedVersion: cachedVersion,
        appVersion: appVersion,
      );
    } catch (e) {
      _lastFetchError = 'Remote fetch error: $e';
      _log(_lastFetchError!, 'warn');
    }

    if (remoteConfig != null) {
      _activeConfig = remoteConfig;
      _currentSource = ConfigSource.remote;
      _lastFetchedAt = DateTime.now();
      _lastFetchError = null;
      _configStreamController.add(remoteConfig);
      _log(
        'Remote config v${remoteConfig.version} applied successfully.',
        'info',
      );
      return _activeConfig!;
    }

    // ==========================================
    // TIER 2: Cached Local Storage
    // ==========================================
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final cacheValidation = RemoteConfigValidator.validate(
        rawJson: cachedJson,
        sourceUrl: _configUrl,
        currentAppVersion: appVersion,
      );

      if (cacheValidation.isValid) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          final parsed = RouteConfig.fromJson(decoded);
          _activeConfig = parsed;
          _currentSource = ConfigSource.cached;
          _log(
            'Applied cached config v${parsed.version} from local storage.',
            'info',
          );
          return _activeConfig!;
        } catch (e) {
          _log('Failed to parse cached config: $e', 'warn');
        }
      } else {
        _log(
          'Cached config validation failed: ${cacheValidation.errorMessage}',
          'warn',
        );
      }
    }

    // ==========================================
    // TIER 3: Bundled Asset (default_config.json)
    // ==========================================
    try {
      final jsonString = await _getBundle().loadString(
        'assets/default_config.json',
      );
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final bundled = RouteConfig.fromJson(decoded);
      _activeConfig = bundled;
      _currentSource = ConfigSource.bundled;
      _log('Applied bundled default config v${bundled.version}.', 'info');
      return _activeConfig!;
    } catch (e) {
      _log('Failed to load bundled default config asset: $e', 'warn');
    }

    // ==========================================
    // TIER 4: Safe In-Memory Hardcoded Fallback
    // ==========================================
    _activeConfig = _inMemoryFallbackConfig;
    _currentSource = ConfigSource.inMemoryFallback;
    _log('Applied in-memory safe fallback config.', 'info');
    return _activeConfig!;
  }

  Future<RouteConfig?> _fetchRemote({
    required int? cachedVersion,
    required String appVersion,
  }) async {
    // 1. HTTPS Scheme check
    if (!_configUrl.toLowerCase().startsWith('https://')) {
      _lastFetchError =
          'Remote config URL must use HTTPS. Provided: $_configUrl';
      _log(_lastFetchError!, 'warn');
      return null;
    }

    final client = _httpClient ?? http.Client();
    http.Response response;
    try {
      response = await client
          .get(Uri.parse(_configUrl))
          .timeout(const Duration(seconds: 10));
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }

    if (response.statusCode != 200) {
      _lastFetchError =
          'Remote config HTTP error: received status ${response.statusCode}';
      _log(_lastFetchError!, 'warn');
      return null;
    }

    final body = response.body;

    // 2. Validate payload size, schema, regexes, semver, and monotonicity
    final validation = RemoteConfigValidator.validate(
      rawJson: body,
      sourceUrl: _configUrl,
      cachedVersion: cachedVersion,
      currentAppVersion: appVersion,
    );

    if (!validation.isValid) {
      _lastFetchError =
          'Remote config rejected: ${validation.errorMessage}';
      _log(_lastFetchError!, 'warn');
      return null;
    }

    // 3. Save valid payload into cache
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final routeConfig = RouteConfig.fromJson(decoded);

    final prefs = await _getPrefs();
    await prefs.setString(keyCachedConfigJson, body);
    await prefs.setInt(
      keyCachedConfigTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );

    return routeConfig;
  }

  @override
  Future<String> getGuardJs() async {
    if (_cachedGuardJs != null) {
      return _cachedGuardJs!;
    }
    if (preloadedGuardJs != null && preloadedGuardJs!.isNotEmpty) {
      _cachedGuardJs = preloadedGuardJs;
      return _cachedGuardJs!;
    }
    try {
      _cachedGuardJs = await _getBundle().loadString('assets/js/guard.js');
      return _cachedGuardJs!;
    } catch (e) {
      _log('Failed to load assets/js/guard.js: $e', 'error');
      return '';
    }
  }

  @override
  Future<void> refreshConfig() async {
    _cachedGuardJs = null;
    _activeConfig = null;
    await getRouteConfig(forceRefresh: true);
    await getGuardJs();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _configStreamController.close();
  }

  static const RouteConfig _inMemoryFallbackConfig = RouteConfig(
    version: 1,
    minAppVersion: '1.0.0',
    killSwitch: KillSwitchConfig(),
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
}

/// AssetRouteConfigRepository kept as alias / backward compatibility.
typedef AssetRouteConfigRepository = HttpRouteConfigRepository;

final routeConfigRepositoryProvider = Provider<RouteConfigRepository>((ref) {
  final debugNotifier = ref.watch(debugLogProvider.notifier);
  final repo = HttpRouteConfigRepository(
    logger: (message, level) => debugNotifier.addConsoleLog(message, level),
  );
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final routeConfigProvider = FutureProvider<RouteConfig>((ref) async {
  final repo = ref.watch(routeConfigRepositoryProvider);
  final sub = repo.configStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    sub.cancel();
  });
  return repo.getRouteConfig();
});

final guardJsProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(routeConfigRepositoryProvider);
  return repo.getGuardJs();
});
