class AppConfig {
  /// Defines whether the app should use mock data repositories or live backend.
  /// Set this to false when integrating Firebase / Real backend.
  static const bool useMockBackend = false;

  /// Defines whether to log analytics and app events locally.
  static const bool enableLogging = true;

  // Supabase Configuration
  static const String supabaseUrl = 'https://jqevsymgsahaijijgqif.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZXZzeW1nc2FoYWlqaWpncWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwNTY3OTMsImV4cCI6MjA5MTYzMjc5M30.nfl8ERMTJeSfp3A_6OwagoNWszwJfzNW01rbbtX6PCU';
}
