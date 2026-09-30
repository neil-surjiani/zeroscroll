import 'version_manifest.dart';

/// Classification of the required update action.
enum UpdateType {
  /// App is on the latest build.
  none,

  /// Newer build available; non-blocking update card with changelog.
  optional,

  /// Current build is below minSupportedBuild; blocking update screen required.
  mandatory,
}

/// Utility for comparing app build numbers and versions.
class VersionComparator {
  VersionComparator._();

  /// Determines if [latestBuild] is strictly newer than [currentBuild].
  static bool isNewer({
    required int currentBuild,
    required int latestBuild,
  }) {
    return latestBuild > currentBuild;
  }

  /// Determines if [currentBuild] is obsolete (below [minSupportedBuild]).
  static bool isMandatory({
    required int currentBuild,
    required int minSupportedBuild,
  }) {
    return currentBuild < minSupportedBuild;
  }

  /// Evaluates the update state for [currentBuild] against [manifest].
  static UpdateType evaluate({
    required int currentBuild,
    required VersionManifest manifest,
  }) {
    if (isMandatory(
      currentBuild: currentBuild,
      minSupportedBuild: manifest.minSupportedBuild,
    )) {
      return UpdateType.mandatory;
    }

    if (isNewer(
      currentBuild: currentBuild,
      latestBuild: manifest.latestBuild,
    )) {
      return UpdateType.optional;
    }

    return UpdateType.none;
  }

  /// Compares two semver strings (e.g. "1.0.1" vs "1.0.0").
  /// Returns positive if [v1] > [v2], negative if [v1] < [v2], 0 if equal.
  static int compareSemver(String v1, String v2) {
    final parts1 = _cleanSemver(v1);
    final parts2 = _cleanSemver(v2);

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }

  static List<int> _cleanSemver(String version) {
    // Strip trailing +build or -pre suffixes
    final clean = version.split('+').first.split('-').first.replaceAll(RegExp(r'[^0-9.]'), '');
    return clean
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }
}
