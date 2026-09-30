/// Version manifest data model fetched from the version check endpoint (`version.json`).
class VersionManifest {
  const VersionManifest({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.apkUrl,
    required this.sha256,
    required this.changelog,
    required this.releasedAt,
  });

  /// Human-readable version string (e.g. "1.0.1").
  final String latestVersion;

  /// Android versionCode integer for comparison (e.g. 2).
  final int latestBuild;

  /// Minimum supported build integer. If current build < minSupportedBuild,
  /// a blocking update is required.
  final int minSupportedBuild;

  /// HTTPS direct download URL for the sideload release APK.
  final String apkUrl;

  /// Expected SHA-256 hexadecimal hash of the APK (64 characters).
  final String sha256;

  /// Release notes and changelog markdown.
  final String changelog;

  /// Timestamp when this release was published.
  final DateTime releasedAt;

  static final RegExp _sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Parses and validates [json] against the version manifest schema.
  /// Throws [FormatException] if validation fails.
  factory VersionManifest.fromJson(Map<String, dynamic> json) {
    final latestVersion = json['latestVersion'] as String?;
    if (latestVersion == null || latestVersion.trim().isEmpty) {
      throw const FormatException('latestVersion must be a non-empty string');
    }

    final latestBuild = json['latestBuild'] as num?;
    if (latestBuild == null || latestBuild.toInt() <= 0) {
      throw const FormatException('latestBuild must be a positive integer');
    }

    final minSupportedBuild = json['minSupportedBuild'] as num?;
    if (minSupportedBuild == null || minSupportedBuild.toInt() <= 0) {
      throw const FormatException('minSupportedBuild must be a positive integer');
    }

    final apkUrl = json['apkUrl'] as String?;
    if (apkUrl == null || !apkUrl.startsWith('https://')) {
      throw const FormatException('apkUrl must be a secure HTTPS URL');
    }

    final sha = json['sha256'] as String?;
    if (sha == null || !_sha256Regex.hasMatch(sha.trim())) {
      throw const FormatException('sha256 must be a valid 64-character hex string');
    }

    final changelog = (json['changelog'] as String?) ?? '';

    final releasedAtRaw = json['releasedAt'] as String?;
    DateTime releasedAt;
    if (releasedAtRaw != null) {
      final parsed = DateTime.tryParse(releasedAtRaw);
      if (parsed == null) {
        throw FormatException('Invalid releasedAt timestamp format: $releasedAtRaw');
      }
      releasedAt = parsed;
    } else {
      releasedAt = DateTime.now();
    }

    return VersionManifest(
      latestVersion: latestVersion.trim(),
      latestBuild: latestBuild.toInt(),
      minSupportedBuild: minSupportedBuild.toInt(),
      apkUrl: apkUrl.trim(),
      sha256: sha.trim().toLowerCase(),
      changelog: changelog.trim(),
      releasedAt: releasedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'latestVersion': latestVersion,
    'latestBuild': latestBuild,
    'minSupportedBuild': minSupportedBuild,
    'apkUrl': apkUrl,
    'sha256': sha256,
    'changelog': changelog,
    'releasedAt': releasedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionManifest &&
          runtimeType == other.runtimeType &&
          latestVersion == other.latestVersion &&
          latestBuild == other.latestBuild &&
          minSupportedBuild == other.minSupportedBuild &&
          apkUrl == other.apkUrl &&
          sha256 == other.sha256 &&
          changelog == other.changelog &&
          releasedAt == other.releasedAt;

  @override
  int get hashCode =>
      latestVersion.hashCode ^
      latestBuild.hashCode ^
      minSupportedBuild.hashCode ^
      apkUrl.hashCode ^
      sha256.hashCode ^
      changelog.hashCode ^
      releasedAt.hashCode;
}
