import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/remote_config_validator.dart';

void main() {
  group('RemoteConfigValidator', () {
    const validUrl = 'https://example.com/config.json';
    const sampleValidJson = '''
    {
      "version": 2,
      "minAppVersion": "1.0.0",
      "killSwitch": {
        "enabled": false,
        "message": "ZeroScroll is paused"
      },
      "userAgent": "Mozilla/5.0 Pixel",
      "fallbackPath": "/direct/inbox/",
      "allowedPaths": [
        "^/direct/",
        "^/reel/[^/]+/?\$"
      ],
      "alwaysBlockedPaths": [
        "^/\$",
        "^/explore"
      ],
      "hideSelectors": [
        "a[href='/']"
      ],
      "extraCss": "a { display: none; }",
      "viewerModeRules": {
        "enabled": true,
        "pathPatterns": [
          "^/reel/[^/]+/?\$"
        ]
      }
    }
    ''';

    test('valid configuration payload passes all checks', () {
      final result = RemoteConfigValidator.validate(
        rawJson: sampleValidJson,
        sourceUrl: validUrl,
        cachedVersion: 1,
        currentAppVersion: '1.0.0',
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('rejects non-HTTPS source URLs', () {
      final result = RemoteConfigValidator.validate(
        rawJson: sampleValidJson,
        sourceUrl: 'http://example.com/config.json',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('HTTPS'));
    });

    test('rejects payloads exceeding 50 KB limit', () {
      // 50 KB = 51,200 bytes. Generate 52,000 bytes payload
      final largePadding = 'a' * 52000;
      final largeJson = '''
      {
        "version": 2,
        "userAgent": "Test",
        "fallbackPath": "/direct/inbox/",
        "allowedPaths": ["^/direct/"],
        "alwaysBlockedPaths": ["^/\$"],
        "hideSelectors": [],
        "extraCss": "/* $largePadding */"
      }
      ''';

      final result = RemoteConfigValidator.validate(
        rawJson: largeJson,
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('50 KB'));
    });

    test('rejects malformed non-JSON string', () {
      final result = RemoteConfigValidator.validate(
        rawJson: 'not a valid json { broken',
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Malformed JSON'));
    });

    test('rejects JSON root that is not a Map', () {
      final result = RemoteConfigValidator.validate(
        rawJson: '["version", 1]',
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('must be a JSON map'));
    });

    test('rejects missing or non-positive version', () {
      final resultZero = RemoteConfigValidator.validate(
        rawJson: '{"version": 0, "fallbackPath": "/direct/inbox/"}',
        sourceUrl: validUrl,
      );
      expect(resultZero.isValid, isFalse);

      final resultNegative = RemoteConfigValidator.validate(
        rawJson: '{"version": -1, "fallbackPath": "/direct/inbox/"}',
        sourceUrl: validUrl,
      );
      expect(resultNegative.isValid, isFalse);

      final resultString = RemoteConfigValidator.validate(
        rawJson: '{"version": "two", "fallbackPath": "/direct/inbox/"}',
        sourceUrl: validUrl,
      );
      expect(resultString.isValid, isFalse);
    });

    test('rejects version rollback when candidate version is lower than cached', () {
      final result = RemoteConfigValidator.validate(
        rawJson: sampleValidJson, // version is 2
        sourceUrl: validUrl,
        cachedVersion: 3, // cached is 3
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Version rollback rejected'));
    });

    test('accepts candidate version equal to or greater than cached version', () {
      final resultEqual = RemoteConfigValidator.validate(
        rawJson: sampleValidJson, // version is 2
        sourceUrl: validUrl,
        cachedVersion: 2,
      );
      expect(resultEqual.isValid, isTrue);

      final resultGreater = RemoteConfigValidator.validate(
        rawJson: sampleValidJson, // version is 2
        sourceUrl: validUrl,
        cachedVersion: 1,
      );
      expect(resultGreater.isValid, isTrue);
    });

    test('rejects config when current app is older than minAppVersion', () {
      final result = RemoteConfigValidator.validate(
        rawJson: sampleValidJson, // minAppVersion is "1.0.0"
        sourceUrl: validUrl,
        currentAppVersion: '0.9.0',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('App version incompatibility'));
    });

    test('accepts config when current app satisfies minAppVersion', () {
      final result = RemoteConfigValidator.validate(
        rawJson: sampleValidJson, // minAppVersion is "1.0.0"
        sourceUrl: validUrl,
        currentAppVersion: '1.2.0',
      );
      expect(result.isValid, isTrue);
    });

    test('rejects invalid regular expressions in allowedPaths', () {
      final brokenRegexJson = jsonEncode({
        'version': 2,
        'userAgent': 'Test',
        'fallbackPath': '/direct/inbox/',
        'allowedPaths': ['[unclosed-bracket('],
        'alwaysBlockedPaths': ['^/\$'],
        'hideSelectors': [],
      });

      final result = RemoteConfigValidator.validate(
        rawJson: brokenRegexJson,
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid regex in "allowedPaths"'));
    });

    test('rejects invalid regular expressions in alwaysBlockedPaths', () {
      final brokenRegexJson = jsonEncode({
        'version': 2,
        'userAgent': 'Test',
        'fallbackPath': '/direct/inbox/',
        'allowedPaths': ['^/direct/'],
        'alwaysBlockedPaths': ['*bad-quantifier'],
        'hideSelectors': [],
      });

      final result = RemoteConfigValidator.validate(
        rawJson: brokenRegexJson,
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid regex in "alwaysBlockedPaths"'));
    });

    test('rejects invalid regular expressions in viewerModeRules.pathPatterns', () {
      final brokenRegexJson = jsonEncode({
        'version': 2,
        'userAgent': 'Test',
        'fallbackPath': '/direct/inbox/',
        'allowedPaths': ['^/direct/'],
        'alwaysBlockedPaths': ['^/\$'],
        'hideSelectors': [],
        'viewerModeRules': {
          'enabled': true,
          'pathPatterns': ['(invalid-parenthesis'],
        },
      });

      final result = RemoteConfigValidator.validate(
        rawJson: brokenRegexJson,
        sourceUrl: validUrl,
      );
      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        contains('Invalid regex in viewerModeRules pathPatterns'),
      );
    });

    group('Semver Comparison Helper', () {
      test('correctly compares semantic versions', () {
        expect(RemoteConfigValidator.compareSemver('1.0.0', '1.0.0'), 0);
        expect(RemoteConfigValidator.compareSemver('1.0.1', '1.0.0'), greaterThan(0));
        expect(RemoteConfigValidator.compareSemver('1.0.0', '1.1.0'), lessThan(0));
        expect(RemoteConfigValidator.compareSemver('2.0.0', '1.9.9'), greaterThan(0));
        expect(RemoteConfigValidator.compareSemver('1.0.0+5', '1.0.0+2'), 0);
        expect(RemoteConfigValidator.compareSemver('1.0.0-beta', '1.0.0'), 0);
      });
    });
  });
}
