class AppConfig {
  /// Defines whether the app should use mock data repositories or live backend.
  /// Set this to false when integrating Firebase / Real backend.
  static const bool useMockBackend = true;

  /// Defines whether to log analytics and app events locally.
  static const bool enableLogging = true;
}
