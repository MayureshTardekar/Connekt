/// Google Generative Language API — **v1beta** (required for Gemini 2.0 Flash REST).
///
/// Matches typical `GEMINI_BASE_URL` / `GEMINI_CHAT_MODEL` usage from AI Studio / Node.
abstract final class GeminiApiConfig {
  /// No trailing slash — path continues with `/{model}:generateContent`.
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// **Only** chat model for this app (no 1.5 fallback).
  static const String chatModel = 'gemini-2.0-flash';

  /// `POST .../v1beta/models/{model}:generateContent?key=API_KEY`
  static Uri generateContentUri(String modelId, String apiKey) {
    return Uri.parse('$baseUrl/$modelId:generateContent?key=$apiKey');
  }
}
