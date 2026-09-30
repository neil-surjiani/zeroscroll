/// Information regarding an available application update.
class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool hasUpdate;
}
