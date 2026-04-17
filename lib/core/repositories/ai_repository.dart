import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AIRepository {
  int _warningCount = 0;
  final List<Map<String, dynamic>> _history = [];
  dynamic lastError;

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

  // General chat response
  Future<String> getChatResponse(String message, {String? context}) async {
    if (_warningCount >= 3) {
      return "⚠️ ACCESS RESTRICTED: You have received 3 warnings for policy violations.";
    }

    final fullSystemInstruction =
        _systemInstructionText +
        (context != null
            ? "\n\nACTUAL CAMPUS DATA (TRUST THIS AS GROUND TRUTH):\n$context"
            : "");

    // --- PHASE 1 & 2: GROK/GROQ/NVIDIA (NATIVE ONLY) ---
    // These fail on Web due to CORS. We skip them to avoid "Failed to fetch" lag.
    if (!kIsWeb) {
      // 1. Try GROK (xAI)
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
        } catch (e) {
          debugPrint('Grok Primary Error: $e');
        }
      }

      // 2. Try GROQ (LPU)
      if (AppConfig.groqApiKey.isNotEmpty) {
        try {
          final response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': 'llama3-70b-8192',
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
        } catch (e) {
          debugPrint('Groq Secondary Error: $e');
        }
      }

      // 3. Try NVIDIA
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
        } catch (e) {
          debugPrint('NVIDIA Secondary Error: $e');
        }
      }
    }

    // --- PHASE 3: GEMINI (NATIVE & WEB) ---
    // Last resort or browser-only fallback.
    if (AppConfig.geminiApiKey.isNotEmpty) {
      try {
        final keys = [
          AppConfig.geminiApiKey,
          AppConfig.geminiApiKeyBackup,
          AppConfig.geminiApiKeyTertiary,
        ];

        for (var key in keys) {
          if (key.isEmpty || key.contains('YOUR_API_KEY')) continue;

          try {
            final generativeModel = GenerativeModel(
              model: 'gemini-1.5-flash-latest',
              apiKey: key,
              systemInstruction: Content.system(fullSystemInstruction),
            );

            final geminiResponse = await generativeModel.generateContent([
              Content.text(message),
            ]);

            if (geminiResponse.text != null) {
              final text = geminiResponse.text!;
              if (text.contains('WARNING')) _warningCount++;
              return text;
            }
          } catch (e) {
            debugPrint('Gemini SDK Attempt failed: $e');
            // Try REST fallback if SDK failed
            final responseText = await _tryGeminiRest(key, fullSystemInstruction, message);
            if (responseText != null) {
               if (responseText.contains('WARNING')) _warningCount++;
               return responseText;
            }
          }
        }
      } catch (e) {
        debugPrint('Gemini Total Failure: $e');
        lastError = e;
      }
    }

    final webNotice = kIsWeb
        ? " (Note: Grok/Groq/NVIDIA are locked on Web due to CORS)"
        : "";
    return "AI is currently unavailable. Please check your internet connection or API configuration. Error: $lastError$webNotice";
  }

  Future<String?> _tryGeminiRest(String key, String system, String message) async {
     try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$key',
        );
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': message},
                ],
              },
            ],
            'systemInstruction': {
              'parts': [
                {'text': system},
              ],
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates'][0]['content']['parts'][0]['text'] as String?;
        }
     } catch (e) {
        debugPrint('Gemini REST Fallback error: $e');
     }
     return null;
  }

  // Summarize overall app state for the dashboard
  Future<String> summarizeAppState({
    required List<dynamic> notes,
    required List<dynamic> events,
    required List<dynamic> lostFound,
  }) async {
    try {
      final prompt =
          """
      Please provide a very short (max 2 sentences) summary of what's happening on campus based on this data. 
      If a user asks about lost items later, use this data to answer them accurately.
      
      NEW NOTES: ${notes.map((n) => "${n.title} by ${n.author}").join(", ")}
      UPCOMING EVENTS: ${events.map((e) => "${e.title} on ${e.date}").join(", ")}
      LOST & FOUND ITEMS: ${lostFound.map((i) => "${i.name} found at ${i.location}").join(", ")}
      """;

      final generativeModel = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: AppConfig.geminiApiKey,
      );

      final response = await generativeModel.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? "Successfully synced with campus data.";
    } catch (e) {
      return "Campus data synced. I'm ready to help!";
    }
  }

  void addToHistory(String query, String response) {
    _history.insert(0, {
      'query': query,
      'response': response,
      'timestamp': DateTime.now(),
    });
    // Keep only last 20
    if (_history.length > 20) _history.removeLast();
  }

  List<Map<String, dynamic>> getRecentHistory() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return _history
        .where((s) => (s['timestamp'] as DateTime).isAfter(cutoff))
        .toList();
  }
}
