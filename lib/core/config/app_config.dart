class AppConfig {
  /// Defines whether the app should use mock data repositories or live backend.
  /// Set this to false when integrating Firebase / Real backend.
  static const bool useMockBackend = false;

  /// Defines whether to log analytics and app events locally.
  static const bool enableLogging = true;

  // Supabase Configuration
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // xAI (Grok) Configuration
  static const String xaiApiKey = String.fromEnvironment('XAI_API_KEY');

  // NVIDIA Configuration
  static const String nvidiaApiKey = String.fromEnvironment(
    'NVIDIA_API_KEY',
  );

  // Groq Configuration
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
  );

  // Gemini Configuration
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );
  static const String geminiApiKeyBackup = String.fromEnvironment(
    'GEMINI_API_KEY_BACKUP',
  );
  static const String geminiApiKeyTertiary = String.fromEnvironment(
    'GEMINI_API_KEY_TERTIARY',
  );

  static String get supabaseUrl => _requiredValue(
    'SUPABASE_URL',
    _supabaseUrl,
  );

  static String get supabaseAnonKey => _requiredValue(
    'SUPABASE_ANON_KEY',
    _supabaseAnonKey,
  );

  static String _requiredValue(String key, String value) {
    if (value.isEmpty) {
      throw StateError(
        'Missing required build-time environment variable: $key. '
        'Pass it with --dart-define=$key=...',
      );
    }
    return value;
  }
}
