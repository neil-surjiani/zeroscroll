import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/updater/domain/version_comparator.dart';
import 'package:zeroscroll/features/updater/domain/version_manifest.dart';

void main() {
  group('VersionComparator Unit Tests', () {
    test('isNewer returns true only when latestBuild > currentBuild', () {
      expect(VersionComparator.isNewer(currentBuild: 1, latestBuild: 2), isTrue);
      expect(VersionComparator.isNewer(currentBuild: 5, latestBuild: 10), isTrue);
      expect(VersionComparator.isNewer(currentBuild: 2, latestBuild: 2), isFalse);
      expect(VersionComparator.isNewer(currentBuild: 5, latestBuild: 3), isFalse);
    });

    test('isMandatory returns true only when currentBuild < minSupportedBuild', () {
      expect(VersionComparator.isMandatory(currentBuild: 1, minSupportedBuild: 2), isTrue);
      expect(VersionComparator.isMandatory(currentBuild: 2, minSupportedBuild: 2), isFalse);
      expect(VersionComparator.isMandatory(currentBuild: 5, minSupportedBuild: 2), isFalse);
    });

    test('evaluate returns UpdateType.mandatory when below minSupportedBuild', () {
      final manifest = VersionManifest(
        latestVersion: '2.0.0',
        latestBuild: 10,
        minSupportedBuild: 5,
        apkUrl: 'https://example.com/app.apk',
        sha256: 'a' * 64,
        changelog: 'Breaking security update',
        releasedAt: DateTime.now(),
      );

      final evaluation = VersionComparator.evaluate(
        currentBuild: 4,
        manifest: manifest,
      );
      expect(evaluation, equals(UpdateType.mandatory));
    });

    test('evaluate returns UpdateType.optional when newer build exists and meets minSupportedBuild', () {
      final manifest = VersionManifest(
        latestVersion: '1.2.0',
        latestBuild: 5,
        minSupportedBuild: 2,
        apkUrl: 'https://example.com/app.apk',
        sha256: 'a' * 64,
        changelog: 'Performance improvements',
        releasedAt: DateTime.now(),
      );

      final evaluation = VersionComparator.evaluate(
        currentBuild: 3,
        manifest: manifest,
      );
      expect(evaluation, equals(UpdateType.optional));
    });

    test('evaluate returns UpdateType.none when current build is latest or newer', () {
      final manifest = VersionManifest(
        latestVersion: '1.1.0',
        latestBuild: 5,
        minSupportedBuild: 2,
        apkUrl: 'https://example.com/app.apk',
        sha256: 'a' * 64,
        changelog: 'Minor fix',
        releasedAt: DateTime.now(),
      );

      expect(
        VersionComparator.evaluate(currentBuild: 5, manifest: manifest),
        equals(UpdateType.none),
      );
      expect(
        VersionComparator.evaluate(currentBuild: 6, manifest: manifest),
        equals(UpdateType.none),
      );
    });

    test('compareSemver accurately compares semver strings', () {
      expect(VersionComparator.compareSemver('1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionComparator.compareSemver('1.1.0', '1.0.9'), greaterThan(0));
      expect(VersionComparator.compareSemver('2.0.0', '1.9.9'), greaterThan(0));
      expect(VersionComparator.compareSemver('1.0.0', '1.0.0'), equals(0));
      expect(VersionComparator.compareSemver('1.0.0', '1.0.1'), lessThan(0));
      expect(VersionComparator.compareSemver('1.0.0+1', '1.0.0+2'), equals(0));
    });
  });
}
