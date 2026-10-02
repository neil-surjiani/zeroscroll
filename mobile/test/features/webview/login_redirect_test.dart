import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/settings/domain/feature_preferences.dart';

void main() {
  group('Login Flow & Direct Messages Redirection Tests', () {
    late String guardJs;
    late Map<String, dynamic> defaultConfigJson;
    late RouteConfig defaultConfig;

    setUpAll(() {
      final guardJsFile = File('assets/js/guard.js');
      expect(guardJsFile.existsSync(), isTrue, reason: 'guard.js must exist');
      guardJs = guardJsFile.readAsStringSync();

      final configFile = File('assets/default_config.json');
      expect(configFile.existsSync(), isTrue, reason: 'default_config.json must exist');
      defaultConfigJson = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      defaultConfig = RouteConfig.fromJson(defaultConfigJson);
    });

    test('guard.js defines isRootHomePath to isolate root home navigations', () {
      expect(
        guardJs.contains('function isRootHomePath(path)'),
        isTrue,
        reason: 'guard.js must define isRootHomePath to handle root navigation without false blocked alerts',
      );
    });

    test('guard.js includes zeroscroll-home-redirecting CSS to prevent feed flashing', () {
      expect(
        guardJs.contains('zeroscroll-home-redirecting'),
        isTrue,
        reason: 'guard.js must hide feed content during root-to-inbox redirect',
      );
      expect(
        guardJs.contains('html.zeroscroll-home-redirecting body'),
        isTrue,
      );
    });

    test('guard.js includes login success detection via fetch and XMLHttpRequest', () {
      expect(
        guardJs.contains('notifyLoginSuccess'),
        isTrue,
        reason: 'guard.js must define notifyLoginSuccess to bridge login events to Flutter',
      );
      expect(
        guardJs.contains('onLoginSuccess'),
        isTrue,
        reason: 'guard.js must invoke onLoginSuccess handler on authentication completion',
      );
      expect(
        guardJs.contains('/login/ajax/'),
        isTrue,
        reason: 'guard.js must inspect login AJAX responses',
      );
      expect(
        guardJs.contains('data.authenticated === true'),
        isTrue,
        reason: 'guard.js must check authentication status flag from login endpoint',
      );
    });

    test('guard.js includes checkOnetapPrompt for auto-advancing past save-login screen', () {
      expect(
        guardJs.contains('checkOnetapPrompt'),
        isTrue,
        reason: 'guard.js must detect and handle /accounts/onetap prompt',
      );
    });

    test('guard.js History API interception redirects root navigation directly to fallbackPath', () {
      expect(
        guardJs.contains('if (isRootHomePath(targetPath))'),
        isTrue,
        reason: 'pushState and replaceState must catch root navigation and replace location to fallbackPath',
      );
    });

    test('guard.js click listener catches root home navigation and redirects to DMs', () {
      expect(
        guardJs.contains('if (isRootHomePath(targetPath))'),
        isTrue,
      );
    });

    test('default_config.json contains zeroscroll-home-redirecting CSS guard rule', () {
      final extraCss = defaultConfigJson['extraCss'] as String? ?? '';
      expect(
        extraCss.contains('zeroscroll-home-redirecting'),
        isTrue,
        reason: 'default_config.json must bundle home-redirecting shielding rule',
      );
    });

    test('defaultConfig allowedPaths permits Instagram login and challenge routes', () {
      final effective = defaultConfig.computeEffectiveConfig(const FeaturePreferences());
      expect(effective.isPathAllowed('/accounts/login/'), isTrue);
      expect(effective.isPathAllowed('/accounts/onetap/'), isTrue);
      expect(effective.isPathAllowed('/challenge/'), isTrue);
      expect(effective.isPathAllowed('/two_factor/'), isTrue);
      expect(effective.isPathAllowed('/direct/inbox/'), isTrue);
    });
  });
}
