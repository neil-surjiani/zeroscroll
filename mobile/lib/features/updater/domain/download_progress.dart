/// Progress information during an APK update download.
class DownloadProgress {
  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    this.isCompleted = false,
  });

  final int receivedBytes;
  final int totalBytes;
  final bool isCompleted;

  double get percentage {
    if (totalBytes <= 0) return 0.0;
    final progress = receivedBytes / totalBytes;
    return progress.clamp(0.0, 1.0);
  }

  String get formattedReceived => _formatBytes(receivedBytes);
  String get formattedTotal => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
