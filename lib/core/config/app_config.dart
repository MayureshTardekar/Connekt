import 'package:flutter/foundation.dart';

class AppConfig {
  /// Whether the app should use mock data repositories or live backend.
  static bool get useMockBackend {
    const isMock = bool.fromEnvironment('USE_MOCK_BACKEND', defaultValue: false);
    return isMock || !isSupabaseConfigured;
  }

  /// Whether to log analytics and app events locally.
  static const bool enableLogging = true;

  // Supabase — set at build time: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // Never commit real values; use CI secrets for release builds.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Gemini / AI — set at build time, e.g. --dart-define=GEMINI_API_KEY=...
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiApiKeyBackup =
      String.fromEnvironment('GEMINI_API_KEY_BACKUP');
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

  static const String xaiApiKey = String.fromEnvironment('XAI_API_KEY');
  static const String nvidiaApiKey = String.fromEnvironment('NVIDIA_API_KEY');
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
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

  /// At least one Gemini key from env is usable.
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
