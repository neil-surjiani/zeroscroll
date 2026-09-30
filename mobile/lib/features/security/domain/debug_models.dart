/// Represents a single blocked navigation event recorded by the route guard.
class BlockedNavigationEntry {
  const BlockedNavigationEntry({
    required this.timestamp,
    required this.path,
    required this.url,
  });

  final DateTime timestamp;
  final String path;
  final String url;
}

/// Represents a console message captured from the WebView instance.
class ConsoleLogEntry {
  const ConsoleLogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  final DateTime timestamp;
  final String message;
  final String level;
}
