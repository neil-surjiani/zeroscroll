import 'dart:convert';
import '../../../../core/constants/app_constants.dart';

/// Result object for remote configuration validation.
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  factory ValidationResult.success() => const ValidationResult._(isValid: true);

  factory ValidationResult.failure(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);

  @override
  String toString() =>
      isValid ? 'ValidationResult.success' : 'ValidationResult.failure($errorMessage)';
}

/// Strict validator for remote configuration payloads before they are applied.
///
/// Enforces:
/// 1. HTTPS URL only.
/// 2. Payload size <= 50 KB (51,200 bytes).
/// 3. Valid JSON object and required schema fields.
/// 4. All regular expressions compile safely inside try/catch.
/// 5. Rejection of candidate configs with a lower version than the cached one.
/// 6. Verification of [minAppVersion] against current app version if present.
class RemoteConfigValidator {
  RemoteConfigValidator._();

  /// Validates a raw JSON payload string against all security and structural constraints.
  static ValidationResult validate({
    required String rawJson,
    required String sourceUrl,
    int? cachedVersion,
    String? currentAppVersion,
  }) {
    // 1. HTTPS Check
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      return ValidationResult.failure(
        'Insecure URL scheme: remote configuration must be fetched via HTTPS.',
      );
    }

    // 2. Payload size check (Max 50 KB = 51,200 bytes)
    final byteLength = utf8.encode(rawJson).length;
    if (byteLength > AppConstants.maxRemoteConfigBytes) {
      return ValidationResult.failure(
        'Payload size ($byteLength bytes) exceeds maximum allowed limit of '
        '${AppConstants.maxRemoteConfigBytes} bytes (50 KB).',
      );
    }

    // 3. JSON Schema check
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      return ValidationResult.failure('Malformed JSON payload: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      return ValidationResult.failure(
        'Invalid config schema: root object must be a JSON map.',
      );
    }

    // Version field validation
    final version = decoded['version'];
    if (version is! int || version <= 0) {
      return ValidationResult.failure(
        'Invalid or missing "version" field. Must be a positive integer.',
      );
    }

    // 4. Version monotonicity: reject candidate with lower version than cached
    if (cachedVersion != null && version < cachedVersion) {
      return ValidationResult.failure(
        'Version rollback rejected: candidate version ($version) is lower than cached version ($cachedVersion).',
      );
    }

    // 5. minAppVersion check
    final minAppVersion = decoded['minAppVersion'];
    if (minAppVersion != null) {
      if (minAppVersion is! String) {
        return ValidationResult.failure(
          'Invalid "minAppVersion" field: must be a semver string.',
        );
      }
      if (currentAppVersion != null && currentAppVersion.isNotEmpty) {
        if (compareSemver(currentAppVersion, minAppVersion) < 0) {
          return ValidationResult.failure(
            'App version incompatibility: current app ($currentAppVersion) is '
            'older than required minAppVersion ($minAppVersion).',
          );
        }
      }
    }

    // Allowed paths list validation & regex check
    final allowedPaths = decoded['allowedPaths'];
    if (allowedPaths != null && allowedPaths is! List) {
      return ValidationResult.failure(
        'Invalid "allowedPaths" field: must be a list of strings.',
      );
    }
    if (allowedPaths is List) {
      for (final item in allowedPaths) {
        if (item is! String) {
          return ValidationResult.failure(
            'Invalid item in "allowedPaths": all elements must be regex strings.',
          );
        }
        try {
          RegExp(item);
        } catch (e) {
          return ValidationResult.failure(
            'Invalid regex in "allowedPaths" ("$item"): $e',
          );
        }
      }
    }

    // Always blocked paths list validation & regex check
    final alwaysBlockedPaths = decoded['alwaysBlockedPaths'];
    if (alwaysBlockedPaths != null && alwaysBlockedPaths is! List) {
      return ValidationResult.failure(
        'Invalid "alwaysBlockedPaths" field: must be a list of strings.',
      );
    }
    if (alwaysBlockedPaths is List) {
      for (final item in alwaysBlockedPaths) {
        if (item is! String) {
          return ValidationResult.failure(
            'Invalid item in "alwaysBlockedPaths": all elements must be regex strings.',
          );
        }
        try {
          RegExp(item);
        } catch (e) {
          return ValidationResult.failure(
            'Invalid regex in "alwaysBlockedPaths" ("$item"): $e',
          );
        }
      }
    }

    // Hide selectors validation
    final hideSelectors = decoded['hideSelectors'];
    if (hideSelectors != null && hideSelectors is! List) {
      return ValidationResult.failure(
        'Invalid "hideSelectors" field: must be a list of strings.',
      );
    }

    // Fallback path validation
    final fallbackPath = decoded['fallbackPath'];
    if (fallbackPath != null &&
        (fallbackPath is! String || !fallbackPath.startsWith('/'))) {
      return ValidationResult.failure(
        'Invalid "fallbackPath" field: must be a non-empty string starting with "/".',
      );
    }

    // Kill switch structure check
    final killSwitch = decoded['killSwitch'];
    if (killSwitch != null && killSwitch is! Map) {
      return ValidationResult.failure(
        'Invalid "killSwitch" field: must be an object with {enabled, message}.',
      );
    }

    // Viewer rules validation
    final viewerRules = decoded['viewerModeRules'] ?? decoded['viewerConfig'];
    if (viewerRules != null) {
      if (viewerRules is! Map) {
        return ValidationResult.failure(
          'Invalid "viewerModeRules" field: must be an object.',
        );
      }
      final pathPatterns = viewerRules['pathPatterns'];
      if (pathPatterns is List) {
        for (final item in pathPatterns) {
          if (item is! String) {
            return ValidationResult.failure(
              'Invalid item in viewerModeRules pathPatterns: must be a string.',
            );
          }
          try {
            RegExp(item);
          } catch (e) {
            return ValidationResult.failure(
              'Invalid regex in viewerModeRules pathPatterns ("$item"): $e',
            );
          }
        }
      }
    }

    // Feature groups validation
    final featureGroups = decoded['featureGroups'];
    if (featureGroups != null) {
      if (featureGroups is! Map) {
        return ValidationResult.failure(
          'Invalid "featureGroups" field: must be an object map of groups.',
        );
      }
      for (final entry in featureGroups.entries) {
        final groupName = entry.key;
        final groupData = entry.value;
        if (groupData is! Map) {
          return ValidationResult.failure(
            'Invalid feature group "$groupName": must be an object.',
          );
        }
        final allowed = groupData['allowedPaths'];
        if (allowed != null) {
          if (allowed is! List) {
            return ValidationResult.failure(
              'Invalid allowedPaths in feature group "$groupName": must be a list.',
            );
          }
          for (final p in allowed) {
            if (p is! String) {
              return ValidationResult.failure(
                'Invalid regex item in feature group "$groupName" allowedPaths.',
              );
            }
            try {
              RegExp(p);
            } catch (e) {
              return ValidationResult.failure(
                'Invalid regex in feature group "$groupName" allowedPaths ("$p"): $e',
              );
            }
          }
        }
        final blocked = groupData['blockedPaths'];
        if (blocked != null) {
          if (blocked is! List) {
            return ValidationResult.failure(
              'Invalid blockedPaths in feature group "$groupName": must be a list.',
            );
          }
          for (final p in blocked) {
            if (p is! String) {
              return ValidationResult.failure(
                'Invalid regex item in feature group "$groupName" blockedPaths.',
              );
            }
            try {
              RegExp(p);
            } catch (e) {
              return ValidationResult.failure(
                'Invalid regex in feature group "$groupName" blockedPaths ("$p"): $e',
              );
            }
          }
        }
        final hide = groupData['hideSelectors'];
        if (hide != null && hide is! List) {
          return ValidationResult.failure(
            'Invalid hideSelectors in feature group "$groupName": must be a list.',
          );
        }
      }
    }

    return ValidationResult.success();
  }

  /// Compares two semver strings (e.g., "1.2.3+4" vs "1.2.0").
  /// Returns negative if v1 < v2, zero if v1 == v2, positive if v1 > v2.
  static int compareSemver(String v1, String v2) {
    final clean1 = v1.split('+').first.split('-').first.trim();
    final clean2 = v2.split('+').first.split('-').first.trim();

    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }
}
