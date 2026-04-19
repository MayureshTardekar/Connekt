import 'package:flutter/foundation.dart';

class AppConfig {
  /// Defines whether the app should use mock data repositories or live backend.
  /// Now automatically defaults to true if Supabase configuration is missing.
  /// Defines whether the app should use mock data repositories or live backend.
  static bool get useMockBackend {
    return const bool.fromEnvironment('USE_MOCK_BACKEND', defaultValue: false);
  }

  /// Defines whether to log analytics and app events locally.
  static const bool enableLogging = true;

  // Supabase Configuration
  // ACTION: Replace with your own Supabase project details
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jqevsymgsahaijijgqif.supabase.co', 
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxZXZzeW1nc2FoYWlqaWpncWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwNTY3OTMsImV4cCI6MjA5MTYzMjc5M30.nfl8ERMTJeSfp3A_6OwagoNWszwJfzNW01rbbtX6PCU',
  );

  // Gemini Configuration
  // ACTION: Replace with your Google AI Studio API Key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyD15gKjnQWrbtfAy4deTHVj6IFhIubDk1A',
  );
  static const String geminiApiKeyBackup = String.fromEnvironment(
    'GEMINI_API_KEY_BACKUP',
    defaultValue: 'AIzaSyAfy9TdW6oUFucM6B-BQ9by4HXzim10iVE',
  );

  // Redirect URLs
  /// Optional override (e.g. staging). If empty on web, [oauthRedirectUrl] uses the
  /// current browser origin so the port matches `flutter run` (avoids localhost:3000
  /// when the dev server is on another port).
  static const String webRedirectUrlOverride = String.fromEnvironment(
    'WEB_REDIRECT_URL',
    defaultValue: '',
  );
  static const String nativeRedirectUrl = 'io.supabase.connekt://login-callback';

  /// Supabase OAuth `redirectTo`: must be listed under Auth → URL Configuration → Redirect URLs.
  static String get oauthRedirectUrl {
    if (!kIsWeb) return nativeRedirectUrl;
    if (webRedirectUrlOverride.isNotEmpty) return webRedirectUrlOverride;
    final u = Uri.base.replace(queryParameters: {}, fragment: '');
    if (u.path.isEmpty || u.path == '/') {
      return u.origin;
    }
    return u.toString();
  }

  // Fallback / Helper getters
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && 
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  // Grok/Other settings remain as environment variables or placeholders
  static const String xaiApiKey = String.fromEnvironment('XAI_API_KEY');
  static const String nvidiaApiKey = String.fromEnvironment('NVIDIA_API_KEY');
  /// Fallback when Gemini quota/404 fails (native only; override with `--dart-define=GROQ_API_KEY=` in CI).
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue:
        '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',
  );
  static const String geminiApiKeyTertiary =
      String.fromEnvironment('GEMINI_API_KEY_TERTIARY');

  /// True if [key] looks like a real user-supplied key (not empty / placeholder).
  static bool keyLooksConfigured(String key) {
    final t = key.trim();
    if (t.isEmpty) return false;
    final lower = t.toLowerCase();
    if (lower.contains('your_api_key') ||
        lower.contains('your_key_here') ||
        lower == 'your_xai_key_here') {
      return false;
    }
    return t.length >= 20;
  }

  /// At least one Gemini key from env / defaults is usable.
  static bool get hasConfiguredGeminiKey =>
      keyLooksConfigured(geminiApiKey) ||
      keyLooksConfigured(geminiApiKeyBackup) ||
      keyLooksConfigured(geminiApiKeyTertiary);

  /// Native-only providers (skipped on web due to CORS).
  static bool get hasNativeNonGeminiProvider {
    final xai = xaiApiKey.trim();
    final xaiOk = xai.isNotEmpty && xai != 'YOUR_XAI_KEY_HERE';
    return xaiOk ||
        groqApiKey.trim().isNotEmpty ||
        nvidiaApiKey.trim().isNotEmpty;
  }
}
