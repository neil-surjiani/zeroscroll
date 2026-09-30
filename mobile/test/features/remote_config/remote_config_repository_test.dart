import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeroscroll/features/remote_config/data/remote_config_repository.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';

class MockHttpClient extends http.BaseClient {
  MockHttpClient(this._handler);
  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final streamedBody = await request.finalize().toBytes();
    final httpRequest = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = streamedBody;
    final response = await _handler(httpRequest);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle({
    this.defaultConfigJson,
    this.guardJsText,
    this.shouldThrow = false,
  });

  final String? defaultConfigJson;
  final String? guardJsText;
  final bool shouldThrow;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (shouldThrow) throw Exception('Asset loading failed');
    if (key == 'assets/default_config.json') {
      return defaultConfigJson ??
          '''
          {
            "version": 1,
            "userAgent": "TestBundledAgent",
            "fallbackPath": "/direct/inbox/",
            "allowedPaths": ["^/direct/"],
            "alwaysBlockedPaths": ["^/\$"],
            "hideSelectors": ["a[href='/']"]
          }
          ''';
    }
    if (key == 'assets/js/guard.js') {
      return guardJsText ?? '// Mock guard js';
    }
    throw Exception('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpRouteConfigRepository 3-Tier Precedence & Caching', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    const validRemoteJsonV2 = '''
    {
      "version": 2,
      "minAppVersion": "1.0.0",
      "killSwitch": {
        "enabled": false,
        "message": "Paused"
      },
      "userAgent": "RemoteUserAgent/2.0",
      "fallbackPath": "/direct/inbox/",
      "allowedPaths": ["^/direct/"],
      "alwaysBlockedPaths": ["^/\$"],
      "hideSelectors": ["a[href='/']"],
      "extraCss": "div.banner { display: none; }"
    }
    ''';

    test('TIER 1: Remote fetch succeeds and updates local SharedPreferences cache', () async {
      final mockClient = MockHttpClient((req) async {
        expect(req.url.scheme, 'https');
        return http.Response(validRemoteJsonV2, 200);
      });

      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(),
        configUrl: 'https://example.com/config.json',
        currentAppVersion: '1.0.0',
        enablePeriodicTimer: false,
      );

      final config = await repo.getRouteConfig();

      expect(config.version, 2);
      expect(config.userAgent, 'RemoteUserAgent/2.0');
      expect(repo.currentSource, ConfigSource.remote);
      expect(repo.lastFetchError, isNull);

      // Verify cached in SharedPreferences
      final cachedJson = prefs.getString(HttpRouteConfigRepository.keyCachedConfigJson);
      expect(cachedJson, isNotNull);
      final decoded = jsonDecode(cachedJson!) as Map<String, dynamic>;
      expect(decoded['version'], 2);

      repo.dispose();
    });

    test('TIER 2: Remote fetch fails; falls back to cached config in SharedPreferences', () async {
      const cachedJsonV3 = '''
      {
        "version": 3,
        "userAgent": "CachedUserAgent/3.0",
        "fallbackPath": "/direct/inbox/",
        "allowedPaths": ["^/direct/"],
        "alwaysBlockedPaths": ["^/\$"],
        "hideSelectors": []
      }
      ''';
      await prefs.setString(HttpRouteConfigRepository.keyCachedConfigJson, cachedJsonV3);

      final mockClient = MockHttpClient((req) async {
        return http.Response('Server Error', 500);
      });

      final logs = <String>[];
      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(),
        configUrl: 'https://example.com/config.json',
        logger: (msg, level) => logs.add('[$level] $msg'),
        enablePeriodicTimer: false,
      );

      final config = await repo.getRouteConfig();

      expect(config.version, 3);
      expect(config.userAgent, 'CachedUserAgent/3.0');
      expect(repo.currentSource, ConfigSource.cached);
      expect(repo.lastFetchError, contains('500'));
      expect(logs.any((l) => l.contains('500')), isTrue);

      repo.dispose();
    });

    test('TIER 3: Remote fails and no cache exists; falls back to bundled default asset', () async {
      final mockClient = MockHttpClient((req) async {
        throw http.ClientException('Network unreachable');
      });

      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(),
        configUrl: 'https://example.com/config.json',
        enablePeriodicTimer: false,
      );

      final config = await repo.getRouteConfig();

      expect(config.version, 1);
      expect(config.userAgent, 'TestBundledAgent');
      expect(repo.currentSource, ConfigSource.bundled);

      repo.dispose();
    });

    test('TIER 4: Remote fails, cache is empty, and bundled asset throws; safe in-memory fallback', () async {
      final mockClient = MockHttpClient((req) async {
        throw http.ClientException('No Internet');
      });

      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(shouldThrow: true),
        configUrl: 'https://example.com/config.json',
        enablePeriodicTimer: false,
      );

      final config = await repo.getRouteConfig();

      expect(config.version, 1);
      expect(repo.currentSource, ConfigSource.inMemoryFallback);
      expect(config.fallbackPath, '/direct/inbox/');

      repo.dispose();
    });

    test('Rejects remote candidate with lower version and falls back safely', () async {
      // Pre-seed cache with version 5
      const cachedV5 = '''
      {
        "version": 5,
        "userAgent": "CachedAgentV5",
        "fallbackPath": "/direct/inbox/",
        "allowedPaths": ["^/direct/"],
        "alwaysBlockedPaths": ["^/\$"],
        "hideSelectors": []
      }
      ''';
      await prefs.setString(HttpRouteConfigRepository.keyCachedConfigJson, cachedV5);

      // Remote returns version 4 (downgrade/rollback)
      const remoteV4 = '''
      {
        "version": 4,
        "userAgent": "RemoteAgentV4",
        "fallbackPath": "/direct/inbox/",
        "allowedPaths": ["^/direct/"],
        "alwaysBlockedPaths": ["^/\$"],
        "hideSelectors": []
      }
      ''';

      final mockClient = MockHttpClient((req) async {
        return http.Response(remoteV4, 200);
      });

      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(),
        configUrl: 'https://example.com/config.json',
        enablePeriodicTimer: false,
      );

      final config = await repo.getRouteConfig();

      // Should reject v4 and stay on cached v5
      expect(config.version, 5);
      expect(config.userAgent, 'CachedAgentV5');
      expect(repo.currentSource, ConfigSource.cached);
      expect(repo.lastFetchError, contains('Version rollback rejected'));

      repo.dispose();
    });

    test('Loads guard.js script asset and caches in memory', () async {
      final repo = HttpRouteConfigRepository(
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(guardJsText: 'window.__TEST_GUARD__ = true;'),
        enablePeriodicTimer: false,
      );

      final script = await repo.getGuardJs();
      expect(script, 'window.__TEST_GUARD__ = true;');

      repo.dispose();
    });

    test('Notifies configStream when a new remote config is successfully applied', () async {
      final mockClient = MockHttpClient((req) async {
        return http.Response(validRemoteJsonV2, 200);
      });

      final repo = HttpRouteConfigRepository(
        httpClient: mockClient,
        sharedPreferences: prefs,
        assetBundle: TestAssetBundle(),
        configUrl: 'https://example.com/config.json',
        enablePeriodicTimer: false,
      );

      RouteConfig? streamedConfig;
      final sub = repo.configStream.listen((cfg) {
        streamedConfig = cfg;
      });

      await repo.getRouteConfig();
      await Future<void>.delayed(Duration.zero);

      expect(streamedConfig, isNotNull);
      expect(streamedConfig!.version, 2);

      await sub.cancel();
      repo.dispose();
    });
  });
}
