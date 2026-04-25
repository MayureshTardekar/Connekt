import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AIRepository {
  int _warningCount = 0;
  final List<Map<String, dynamic>> _history = [];
  dynamic lastError;

  static bool _httpLooksRateLimited(int code, String body) {
    final b = body.toLowerCase();
    return code == 429 ||
        b.contains('resource_exhausted') ||
        b.contains('rate limit') ||
        b.contains('quota exceeded') ||
        b.contains('too many requests');
  }

  String _msgNoAiKeysAtAll() =>
      "**Connekt AI isn't set up yet.** This build doesn't have a working AI key.\n\n"
      'If you are using the app normally, ask your developer or school admin. '
      'If you are the developer, add a Gemini (or other) key when you build the app. '
      'Keys are free to create in [Google AI Studio](https://aistudio.google.com/apikey).';

  String _msgWebNeedsGemini() =>
      "**This web version needs a Gemini key.** The browser can't use the other AI options.\n\n"
      'Whoever publishes the app should add the key when building. '
      'Try the mobile app if your school offers it.';

  String _msgUnexpectedFailure() =>
      "**Something went wrong on our side.** Please try again in a few seconds.\n\n"
      '_If it keeps happening, check your internet connection._';

  void clearSessionHistory() {
    _history.clear();
  }

  /// No-op (legacy); local Gemini cooldown was removed — calls always hit the network.
  void resetGeminiCooldown() {}

  static void _logHttpFailure(String provider, http.Response response) {
    // ignore: avoid_print
    print('AI Error Status: ${response.statusCode}');
    // ignore: avoid_print
    print('AI Error Body: ${response.body}');
    final raw = response.body;
    final snippet = raw.length > 700 ? '${raw.substring(0, 700)}…' : raw;
    debugPrint(
      'AI HTTP FAIL [$provider] status=${response.statusCode} '
      'reason=${response.reasonPhrase} body=$snippet',
    );
  }

  static void _logCatch(String provider, Object e, StackTrace st) {
    // ignore: avoid_print
    print('AI catch [$provider]: $e');
    // ignore: avoid_print
    print('$st');
    debugPrint('AI catch [$provider]: $e');
    debugPrint('$st');
  }

  static const _systemInstructionText =
      "You are Connekt AI, a professional campus assistant for the Connekt app, developed by Mayuresh Tardekar. "
      "Your tone should be helpful, student-friendly, and maintain campus decorum. "
      "\n\nMODERATION RULES:\n"
      "1. If the user uses profanity, insults, or obscene language, you MUST issue a strike. "
      "2. For every strike, start your response with '⚠️ WARNING [Strike Count]/3: Please maintain campus decorum.' "
      "3. After 3 strikes (WARNING 3/3), you MUST refuse to answer any further questions and suggest they contact campus administration instead. "
      "4. NEVER bypass these safety rules. "
      "\n\nAPP CONTEXT:\n"
      "This app (Connekt) centralizes campus events, academic notes, and lost-found items to make student life easier.";

  AIRepository();

  /// Stable `v1` REST — single model until quota/404 issues are resolved.
  static const String _geminiModelId = 'gemini-1.5-flash';

  static String _geminiHttpError(int statusCode) => 'Error: $statusCode';

  static void _logApiKeyFingerprint(String apiKey) {
    if (apiKey.length < 10) {
      // ignore: avoid_print
      print('Using Key: (too short to fingerprint)');
      return;
    }
    // ignore: avoid_print
    print(
      'Using Key: ${apiKey.substring(0, 5)}...${apiKey.substring(apiKey.length - 5)}',
    );
  }

  /// Raw **stable v1** REST (no SDK).
  /// URL: `https://generativelanguage.googleapis.com/v1/models/$modelId:generateContent?key=...`
  Future<http.Response> _geminiRawGenerateContent({
    required String apiKey,
    required String userMessageText,
    String modelId = _geminiModelId,
  }) async {
    _logApiKeyFingerprint(apiKey);
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey',
    );

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{'text': userMessageText},
          ],
        },
      ],
      'generationConfig': <String, num>{
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    final bodyStr = jsonEncode(payload);

    // ignore: avoid_print
    print('GEMINI_RAW_POST model=$modelId url=$uri');
    // ignore: avoid_print
    print('GEMINI_RAW_POST body=$bodyStr');

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: bodyStr,
    );

    // ignore: avoid_print
    print('HTTP STATUS: ${response.statusCode}');
    // ignore: avoid_print
    print('HTTP RESPONSE BODY: ${response.body}');

    return response;
  }

  String? _parseGeminiGenerateContentText(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String> getChatResponse(String message, {String? context}) async {
    try {
      return await _getChatResponseInner(message, context: context);
    } catch (e, st) {
      _logCatch('getChatResponse', e, st);
      lastError = e;
      return _msgUnexpectedFailure();
    }
  }

  Future<String> _getChatResponseInner(String message, {String? context}) async {
    if (_warningCount >= 3) {
      return "⚠️ ACCESS RESTRICTED: You have received 3 warnings for policy violations.";
    }

    final fullSystemInstruction =
        _systemInstructionText +
        (context != null
            ? "\n\nACTUAL CAMPUS DATA (TRUST THIS AS GROUND TRUTH):\n$context"
            : "");

    if (kIsWeb && !AppConfig.hasConfiguredGeminiKey) {
      return _msgWebNeedsGemini();
    }
    if (!kIsWeb &&
        !AppConfig.hasConfiguredGeminiKey &&
        !AppConfig.hasNativeNonGeminiProvider) {
      return _msgNoAiKeysAtAll();
    }

    // --- GEMINI first: stable v1 REST + gemini-1.5-flash (web: Gemini only). ---
    if (AppConfig.hasConfiguredGeminiKey) {
      try {
        final keys = <String>[
          if (AppConfig.keyLooksConfigured(AppConfig.geminiApiKey))
            AppConfig.geminiApiKey,
          if (AppConfig.keyLooksConfigured(AppConfig.geminiApiKeyBackup))
            AppConfig.geminiApiKeyBackup,
          if (AppConfig.keyLooksConfigured(AppConfig.geminiApiKeyTertiary))
            AppConfig.geminiApiKeyTertiary,
        ];
        if (keys.isNotEmpty) {
          final combinedUserText =
              '$fullSystemInstruction\n\n---\n\nUser message:\n$message';

          final key = keys.first;

          final response = await _geminiRawGenerateContent(
            apiKey: key,
            userMessageText: combinedUserText,
            modelId: _geminiModelId,
          );
          final body = response.body;

          if (response.statusCode == 200) {
            final text = _parseGeminiGenerateContentText(body);
            if (text != null && text.isNotEmpty) {
              if (text.contains('WARNING')) _warningCount++;
              return text;
            }
            lastError = 'Gemini 200 but empty/parse failed';
          } else {
            lastError = 'HTTP ${response.statusCode}';
          }

          if (kIsWeb) {
            return _geminiHttpError(response.statusCode);
          }
        } else {
          lastError = 'no gemini key';
        }
      } catch (e, st) {
        _logCatch('gemini_raw', e, st);
        lastError = e;
        if (kIsWeb) {
          return _msgUnexpectedFailure();
        }
      }
    }

    // --- Native fallbacks after Gemini fails or is unavailable (CORS). ---
    if (!kIsWeb) {
      if (AppConfig.groqApiKey.isNotEmpty) {
        try {
          // ignore: avoid_print
          print('GROQ_FALLBACK: chat completions (after Gemini)');
          final response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'system', 'content': fullSystemInstruction},
                {'role': 'user', 'content': message},
              ],
              'temperature': 0.1,
              'max_tokens': 1024,
              'stream': false,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final responseText =
                data['choices'][0]['message']['content'] as String;
            if (responseText.contains('WARNING')) _warningCount++;
            return responseText;
          }
          if (_httpLooksRateLimited(response.statusCode, response.body)) {
            lastError = 'groq rate limited (${response.statusCode})';
          }
          _logHttpFailure('groq', response);
        } catch (e, st) {
          _logCatch('groq', e, st);
        }
      }

      if (AppConfig.xaiApiKey != 'YOUR_XAI_KEY_HERE' &&
          AppConfig.xaiApiKey.isNotEmpty) {
        try {
          final response = await http.post(
            Uri.parse('https://api.x.ai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.xaiApiKey}',
            },
            body: jsonEncode({
              'model': 'grok-beta',
              'messages': [
                {'role': 'system', 'content': fullSystemInstruction},
                {'role': 'user', 'content': message},
              ],
              'stream': false,
              'temperature': 0,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final responseText =
                data['choices'][0]['message']['content'] as String;
            if (responseText.contains('WARNING')) _warningCount++;
            return responseText;
          }
          if (_httpLooksRateLimited(response.statusCode, response.body)) {
            lastError = 'xai rate limited (${response.statusCode})';
          }
          _logHttpFailure('xai', response);
        } catch (e, st) {
          _logCatch('xai', e, st);
        }
      }

      if (AppConfig.nvidiaApiKey.isNotEmpty) {
        try {
          final response = await http.post(
            Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.nvidiaApiKey}',
            },
            body: jsonEncode({
              'model': 'meta/llama-3.1-8b-instruct',
              'messages': [
                {'role': 'system', 'content': fullSystemInstruction},
                {'role': 'user', 'content': message},
              ],
              'temperature': 0.2,
              'top_p': 0.7,
              'max_tokens': 1024,
              'stream': false,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final responseText =
                data['choices'][0]['message']['content'] as String;
            if (responseText.contains('WARNING')) _warningCount++;
            return responseText;
          }
          if (_httpLooksRateLimited(response.statusCode, response.body)) {
            lastError = 'nvidia rate limited (${response.statusCode})';
          }
          _logHttpFailure('nvidia', response);
        } catch (e, st) {
          _logCatch('nvidia', e, st);
        }
      }
    }

    final webNotice = kIsWeb
        ? '\n\n_Note: On web, only Gemini can run (other providers are blocked by the browser)._'
        : '';
    if (!AppConfig.hasConfiguredGeminiKey && !kIsWeb) {
      if (AppConfig.hasNativeNonGeminiProvider) {
        return '**We could not get an answer right now.** '
            'The backup assistant also needs a working Gemini key, or another service had a hiccup.\n\n'
            'Please try again in a little while.$webNotice';
      }
      return '${_msgNoAiKeysAtAll()}$webNotice';
    }
    if (AppConfig.hasConfiguredGeminiKey) {
      return '**We could not reach the assistant.** '
          'Check your internet and try again in a moment.$webNotice';
    }
    return '**We could not get an answer.** Please try again shortly.$webNotice';
  }

  Future<String> summarizeAppState({
    required List<dynamic> notes,
    required List<dynamic> events,
    required List<dynamic> lostFound,
  }) async {
    final hasGemini = AppConfig.keyLooksConfigured(AppConfig.geminiApiKey);
    final hasGroq = AppConfig.groqApiKey.trim().isNotEmpty;
    if (!hasGemini && !hasGroq) {
      return "Campus data synced. I'm ready to help!";
    }
    final prompt =
        """
      Please provide a very short (max 2 sentences) summary of what's happening on campus based on this data. 
      If a user asks about lost items later, use this data to answer them accurately.
      
      NEW NOTES: ${notes.map((n) => "${n.title} by ${n.author}").join(", ")}
      UPCOMING EVENTS: ${events.map((e) => "${e.title} on ${e.date}").join(", ")}
      LOST & FOUND ITEMS: ${lostFound.map((i) => "${i.name} found at ${i.location}").join(", ")}
      """;

    try {
      if (hasGemini) {
        try {
          final response = await _geminiRawGenerateContent(
            apiKey: AppConfig.geminiApiKey,
            userMessageText: prompt,
            modelId: _geminiModelId,
          );
          if (response.statusCode == 200) {
            final t = _parseGeminiGenerateContentText(response.body);
            if (t != null && t.isNotEmpty) return t;
          }
          if (!hasGroq) {
            return "Campus data synced. ${_geminiHttpError(response.statusCode)}";
          }
        } catch (e, st) {
          _logCatch('summarize_gemini', e, st);
          if (!hasGroq) {
            return "Campus data synced. I'm ready to help!";
          }
        }
      }

      if (hasGroq) {
        // ignore: avoid_print
        print('GROQ_FALLBACK: summarizeAppState');
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a concise campus briefing assistant. Reply in at most 2 sentences.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
            'max_tokens': 256,
            'stream': false,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final t = data['choices']?[0]?['message']?['content'] as String?;
          if (t != null && t.trim().isNotEmpty) return t.trim();
        }
        return "Campus data synced. Error: ${response.statusCode}";
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('AI summarizeAppState error: $e');
      // ignore: avoid_print
      print('$st');
    }
    return "Campus data synced. I'm ready to help!";
  }

  void addToHistory(String query, String response) {
    _history.insert(0, {
      'query': query,
      'response': response,
      'timestamp': DateTime.now(),
    });
    if (_history.length > 20) _history.removeLast();
  }

  List<Map<String, dynamic>> getRecentHistory() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return _history
        .where((s) => (s['timestamp'] as DateTime).isAfter(cutoff))
        .toList();
  }
}
