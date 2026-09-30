/// Configuration model for remote emergency kill switch.
class KillSwitchConfig {
  const KillSwitchConfig({
    this.enabled = false,
    this.message = 'ZeroScroll is paused while we fix an Instagram change',
  });

  /// Whether the kill switch is currently active.
  final bool enabled;

  /// Friendly user-facing message explaining why the app is paused.
  final String message;

  factory KillSwitchConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const KillSwitchConfig();
    }
    final rawMessage = json['message'] as String?;
    return KillSwitchConfig(
      enabled: json['enabled'] as bool? ?? false,
      message: (rawMessage != null && rawMessage.trim().isNotEmpty)
          ? rawMessage.trim()
          : 'ZeroScroll is paused while we fix an Instagram change',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message': message,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KillSwitchConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          message == other.message;

  @override
  int get hashCode => Object.hash(enabled, message);

  @override
  String toString() => 'KillSwitchConfig(enabled: $enabled, message: "$message")';
}
