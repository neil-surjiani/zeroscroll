/// Security and authentication status domain entity.
class SecurityStatus {
  const SecurityStatus({
    this.isBiometricsAvailable = false,
    this.isAppLocked = false,
    this.isAuthenticated = true,
  });

  final bool isBiometricsAvailable;
  final bool isAppLocked;
  final bool isAuthenticated;

  SecurityStatus copyWith({
    bool? isBiometricsAvailable,
    bool? isAppLocked,
    bool? isAuthenticated,
  }) {
    return SecurityStatus(
      isBiometricsAvailable:
          isBiometricsAvailable ?? this.isBiometricsAvailable,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
