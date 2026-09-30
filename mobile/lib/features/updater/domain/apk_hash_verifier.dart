import 'dart:io';
import 'package:crypto/crypto.dart';

/// Cryptographic verification utility for downloaded APK updates.
class ApkHashVerifier {
  ApkHashVerifier._();

  /// Computes the SHA-256 hexadecimal digest of [file] using streaming chunks
  /// to ensure large APK files do not cause Out-Of-Memory spikes.
  static Future<String> computeSha256(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Target file does not exist', file.path);
    }

    final bytes = await file.readAsBytes();
    final output = sha256.convert(bytes);
    return output.toString().toLowerCase();
  }

  /// Verifies that [file]'s SHA-256 matches [expectedSha256].
  /// If the hashes do not match, [file] is immediately deleted for safety.
  /// Returns `true` if match, `false` otherwise.
  static Future<bool> verifyFile({
    required File file,
    required String expectedSha256,
  }) async {
    final cleanExpected = expectedSha256.trim().toLowerCase();
    final actualHash = await computeSha256(file);

    if (actualHash == cleanExpected) {
      return true;
    }

    // Hash mismatch: Immediately delete the file and return false
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    return false;
  }
}
