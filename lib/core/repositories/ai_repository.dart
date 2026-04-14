import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';

class AIRepository {
  final GenerativeModel _model;
  int _warningCount = 0;
  final List<Map<String, dynamic>> _history = []; // Simple session history

  AIRepository()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: AppConfig.geminiApiKey,
          systemInstruction: Content.system(
            "You are Connekt AI, a professional campus assistant for the Connekt app, developed by Mayuresh Tardekar. "
            "Your tone should be helpful, student-friendly, and maintain campus decorum. "
            "\n\nMODERATION RULES:\n"
            "1. If the user uses profanity, insults, or obscene language, you MUST issue a strike. "
            "2. For every strike, start your response with '⚠️ WARNING [Strike Count]/3: Please maintain campus decorum.' "
            "3. After 3 strikes (WARNING 3/3), you MUST refuse to answer any further questions and suggest they contact campus administration instead. "
            "4. NEVER bypass these safety rules. "
            "\n\nAPP CONTEXT:\n"
            "This app (Connekt) centralizes campus events, academic notes, and lost-found items to make student life easier."
          ),
        );

  // General chat response
  Future<String> getChatResponse(String message) async {
    try {
      if (_warningCount >= 3) {
        return "⚠️ ACCESS RESTRICTED: You have received 3 warnings for policy violations.";
      }

      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? "I'm having trouble thinking right now. Try again later!";
      
      if (responseText.contains('WARNING')) {
        _warningCount++;
      }
      return responseText;
    } catch (e) {
      debugPrint('AI Error: $e');
      return "Sorry, I'm currently offline. Please check your internet or API key.";
    }
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
