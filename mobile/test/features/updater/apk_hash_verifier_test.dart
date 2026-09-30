import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/updater/domain/apk_hash_verifier.dart';

void main() {
  group('ApkHashVerifier Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('apk_hash_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('computeSha256 accurately computes SHA-256 hash using streaming chunks', () async {
      final file = File('${tempDir.path}/test_apk.bin');
      const fileContent = 'ZeroScroll safe APK payload for verification';
      await file.writeAsString(fileContent);

      final expectedHash = sha256.convert(utf8.encode(fileContent)).toString().toLowerCase();
      final actualHash = await ApkHashVerifier.computeSha256(file);

      expect(actualHash, equals(expectedHash));
    });

    test('verifyFile returns true and preserves file when SHA-256 matches', () async {
      final file = File('${tempDir.path}/valid_apk.bin');
      const fileContent = 'Legitimate APK content';
      await file.writeAsString(fileContent);

      final expectedHash = sha256.convert(utf8.encode(fileContent)).toString().toLowerCase();

      final isValid = await ApkHashVerifier.verifyFile(
        file: file,
        expectedSha256: expectedHash,
      );

      expect(isValid, isTrue);
      expect(await file.exists(), isTrue);
    });

    test('verifyFile returns false and immediately deletes file when SHA-256 mismatches', () async {
      final file = File('${tempDir.path}/tampered_apk.bin');
      await file.writeAsString('Tampered malicious payload');

      final expectedHash = 'b' * 64; // Different hash

      final isValid = await ApkHashVerifier.verifyFile(
        file: file,
        expectedSha256: expectedHash,
      );

      expect(isValid, isFalse);
      // Crucial security requirement: Corrupt/tampered files must be deleted immediately
      expect(await file.exists(), isFalse);
    });

    test('computeSha256 throws FileSystemException when file does not exist', () async {
      final nonExistentFile = File('${tempDir.path}/non_existent.bin');
      expect(
        () => ApkHashVerifier.computeSha256(nonExistentFile),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
