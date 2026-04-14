import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';

class AIRepository {
  final GenerativeModel _model;
  int _warningCount = 0;
  final List<Map<String, dynamic>> _history = [];

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

  static final _systemInstruction = Content.system(_systemInstructionText);

  AIRepository()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: AppConfig.geminiApiKey,
          systemInstruction: _systemInstruction,
        );

  // General chat response
  Future<String> getChatResponse(String message) async {
    if (_warningCount >= 3) {
      return "⚠️ ACCESS RESTRICTED: You have received 3 warnings for policy violations.";
    }

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
                {'role': 'system', 'content': _systemInstructionText},
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
                {'role': 'system', 'content': _systemInstructionText},
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
          debugPrint('Groq Error: $e');
        }
      }

      // 3. Try NVIDIA (NIM)
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
                {'role': 'system', 'content': _systemInstructionText},
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

    // --- PHASE 4: FALLBACK TO GEMINI (DIRECT v1 HTTP) ---
    // We bypass the SDK here because it forces v1beta, which is currently failing.
    final keys = [
      AppConfig.geminiApiKey,
      AppConfig.geminiApiKeyBackup,
      AppConfig.geminiApiKeyTertiary,
    ];

    Object? lastError;

    for (var key in keys) {
      if (key.isEmpty || key.contains('AIza')) {
        // Double check it's a real key (placeholder check)
        if (key.length < 20) continue;
      } else {
        continue;
      }

      try {
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': message}
                ]
              }
            ],
            'systemInstruction': {
              'parts': [
                {'text': _systemInstructionText}
              ]
            },
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final responseText =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          if (responseText.contains('WARNING')) _warningCount++;
          return responseText;
        } else {
          // If v1beta fails, try v1 stable
          final v1Response = await http.post(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$key'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': message}
                  ]
                }
              ],
              // Note: v1 stable might have different system instruction support
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 1024,
              }
            }),
          );

          if (v1Response.statusCode == 200) {
            final data = jsonDecode(v1Response.body);
            final responseText =
                data['candidates'][0]['content']['parts'][0]['text'] as String;
            if (responseText.contains('WARNING')) _warningCount++;
            return responseText;
          }
          debugPrint('Gemini HTTP v1/v1beta Failed for key: ${key.substring(0, 5)}... Status: ${v1Response.statusCode}');
        }
      } catch (e) {
        debugPrint('Gemini HTTP Error: $e');
        lastError = e;
      }
    }

    final webNotice =
        kIsWeb ? " (Note: Grok/Groq/NVIDIA are locked on Web due to CORS)" : "";
    return "AI is offline. All protocols (Grok/Gemini/NVIDIA) failed$webNotice. Please check network/keys. Error: $lastError";
  }

  // Summarize overall app state for the dashboard
  Future<String> summarizeAppState({
    required List<dynamic> notes,
    required List<dynamic> events,
    required List<dynamic> lostFound,
  }) async {
    try {
      final prompt = """
      Please provide a very short (max 2 sentences) summary of what's happening on campus based on this data:
      - New notes: ${notes.length}
      - Upcoming events: ${events.length}
      - Lost & Found items: ${lostFound.length}

      If there is nothing new, encourage the student to start a group or post a note.
      """;

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Connecting to campus life...";
    } catch (e) {
      return "Stay connected with your campus peers!";
    }
  }

  Future<String> getAnalysis({
    required String query,
    required List<AcademicNote> notes,
    required List<CampusEvent> events,
    required List<LostItem> items,
  }) async {
    try {
      if (_warningCount >= 3) {
        return "⚠️ ACCESS RESTRICTED: You have received 3 warnings for policy violations.";
      }

      final context = """
      Campus Activity Data:
      - Notes: ${notes.map((n) => n.title).join(', ')}
      - Lost Items: ${items.map((i) => i.title).join(', ')}
      - Events: ${events.map((e) => e.title).join(', ')}
      """;

      final content = [Content.text("$context\n\nUser Question: $query")];
      final response = await _model.generateContent(content);
      
      final responseText = response.text ?? "I'm having trouble thinking right now. Try again!";

      if (responseText.contains('WARNING')) {
        _warningCount++;
      }

      return responseText;
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      return "AI service is temporarily unavailable.";
    }
  }

  void resetChat() {
    _warningCount = 0;
  }

  void addToHistory(String query, String response) {
    _history.insert(0, {
      'query': query,
      'response': response,
      'timestamp': DateTime.now(),
    });
    // Cleanup internal
    _history.removeWhere((session) => 
      DateTime.now().difference(session['timestamp'] as DateTime).inHours > 48);
  }

  List<Map<String, dynamic>> getRecentHistory() {
     return _history.where((session) => 
      DateTime.now().difference(session['timestamp'] as DateTime).inHours <= 48).toList();
  }
}
