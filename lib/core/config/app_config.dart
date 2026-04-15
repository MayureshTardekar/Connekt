class AppConfig {
  /// Defines whether the app should use mock data repositories or live backend.
  static const bool useMockBackend = false;

  /// Defines whether to log analytics and app events locally.
  static const bool enableLogging = true;

  // Supabase Configuration
  static const String supabaseUrl = 'https://jqevsymgsahaijijgqif.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZXZzeW1nc2FoYWlqaWpncWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwNTY3OTMsImV4cCI6MjA5MTYzMjc5M30.nfl8ERMTJeSfp3A_6OwagoNWszwJfzNW01rbbtX6PCU';

  // Gemini Configuration
  static const String geminiApiKey = 'AIzaSyD15gKjnQWrbtfAy4deTHVj6IFhIubDk1A'; 
  static const String geminiApiKeyBackup = 'AIzaSyAfy9TdW6oUFucM6B-BQ9by4HXzim10iVE';

  // Fallback / Helper getters
  static bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Grok/Other settings remain as environment variables or placeholders if not provided
  static const String xaiApiKey = String.fromEnvironment('XAI_API_KEY');
  static const String nvidiaApiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String geminiApiKeyTertiary = String.fromEnvironment('GEMINI_API_KEY_TERTIARY');
}
