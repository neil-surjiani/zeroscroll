/// Security and authentication status domain entity.
class SecurityStatus {
  const SecurityStatus({
    this.isBiometricsAvailable = false,
    this.isAppLocked = false,
    this.isAuthenticated = true,
    this.isSecureFlagEnabled = false,
  });

  final bool isBiometricsAvailable;
  final bool isAppLocked;
  final bool isAuthenticated;
  final bool isSecureFlagEnabled;

  SecurityStatus copyWith({
    bool? isBiometricsAvailable,
    bool? isAppLocked,
    bool? isAuthenticated,
    bool? isSecureFlagEnabled,
  }) {
    return SecurityStatus(
      isBiometricsAvailable:
          isBiometricsAvailable ?? this.isBiometricsAvailable,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSecureFlagEnabled: isSecureFlagEnabled ?? this.isSecureFlagEnabled,
    );
  }
}
