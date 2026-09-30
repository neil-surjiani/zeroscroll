import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logging and Data Leak Sanitization Verification', () {
    test('No production Dart code calls print(), debugPrint(), or stdout/err in lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      final disallowedPatterns = [
        RegExp(r'\bprint\s*\('),
        RegExp(r'\bdebugPrint\s*\('),
        RegExp(r'\bstdout\.(write|writeln)\s*\('),
        RegExp(r'\bstderr\.(write|writeln)\s*\('),
      ];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          // Skip comments
          if (line.startsWith('//') || line.startsWith('/*') || line.startsWith('*')) {
            continue;
          }

          for (final pattern in disallowedPatterns) {
            if (pattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1} contains disallowed console logging: $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Production code must not contain unfiltered print or console logging.\n'
            'Violations found:\n${violations.join('\n')}',
      );
    });

    test('Kotlin logging is strictly guarded by BuildConfig.DEBUG/isDebug and never contains sensitive data', () {
      final kotlinDir = Directory('android/app/src/main/kotlin');
      if (!kotlinDir.existsSync()) {
        final altKotlinDir = Directory('mobile/android/app/src/main/kotlin');
        if (!altKotlinDir.existsSync()) return;
      }

      final targetDir = kotlinDir.existsSync()
          ? kotlinDir
          : Directory('mobile/android/app/src/main/kotlin');

      final ktFiles = targetDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt'));

      final violations = <String>[];
      final sensitivePatterns = [
        RegExp(r'\b(messageText|threadId|thread_id|notification\.body|notification\.text|notification\.title|rawPayload)\b', caseSensitive: false),
        RegExp(r'/direct/t/'),
      ];

      for (final file in ktFiles) {
        final content = file.readAsStringSync();
        if (content.contains('println(') || content.contains('System.out.print')) {
          violations.add('${file.path} contains raw println/print statements');
        }

        final logMatches = RegExp(r'Log\.[dveiw]\s*\((.*?)\);?', dotAll: true).allMatches(content);
        for (final match in logMatches) {
          final logStatement = match.group(0) ?? '';
          for (final pattern in sensitivePatterns) {
            if (pattern.hasMatch(logStatement)) {
              violations.add('${file.path} logs sensitive data: $logStatement');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Native Android production code must never log sensitive message or notification data.\n'
            'Violations found:\n${violations.join('\n')}',
      );
    });

    test('No code path logs message text, URLs with thread ids, or notification text', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final sensitivePatterns = [
        RegExp(r'log\([^)]*(messageText|threadId|thread_id|notification\.body|notification\.text|notification\.title|rawPayload)[^)]*\)', caseSensitive: false),
        RegExp(r'log\([^)]*\/direct\/t\/[^)]*\)', caseSensitive: false),
      ];

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final pattern in sensitivePatterns) {
          if (pattern.hasMatch(content)) {
            violations.add('${file.path} contains logging referencing sensitive user content or thread IDs!');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'No log call may reference sensitive message text, thread IDs, or notification content.\n'
            'Violations:\n${violations.join('\n')}',
      );
    });
  });
}
