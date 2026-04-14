import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import 'dart:convert';
import '../ai/ai_prompts.dart';

class AIRepository {
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash-lite-001',
    'gemini-2.5-pro',
  ];

  Future<String> getChatResponse(String message, {String? context}) async {
    if (AppConfig.geminiApiKey.isEmpty || AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      return 'AI Assistant is currently unavailable. Please check the Gemini API Key configuration.';
    }

    final prompt = context != null 
        ? 'You are the Connekt AI Assistant. Context about the app state: $context\n\nUser: $message'
        : message;
        
    final content = [Content.text(prompt)];

    String lastError = '';

    for (String modelName in _fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: AppConfig.geminiApiKey,
        );
        final response = await model.generateContent(content);
        return response.text ?? 'I\'m sorry, I couldn\'t generate a response.';
      } catch (e) {
        lastError = '($modelName) $e';
        print('AI Error using $modelName: $e. Falling back...');
        // Continue to the next fallback model in the list
      }
    }

    return 'AI Error (All models exhausted): $lastError';
  }

  Future<String> summarizeAppState({
    required List<AcademicNote> notes,
    required List<CampusEvent> events,
    required List<LostItem> lostFound,
  }) async {
    final context = '''
    Connekt App Current State Summary:
    Recent Notes: ${notes.take(5).map((n) => "${n.title} [Subject: ${n.category}]").join(', ')}
    Upcoming Events: ${events.take(5).map((e) => "${e.title} at ${e.location}").join(', ')}
    Lost & Found Items: ${lostFound.take(5).map((i) => "${i.type}: ${i.title} at ${i.location}").join(', ')}
    
    Task: Create a friendly 2-3 sentence campus update for the user dashboard. 
    Focus on: What to study (notes), What to attend (events), and any alerts (lost items).
    ''';

    return getChatResponse('Summarize campus activity concisely.', context: context);
  }

  Future<String> summarizeNote(String noteText) async {
    if (noteText.trim().isEmpty) return 'No note context provided.';
    return getChatResponse(AIPrompts.noteSummaryPrompt(noteText));
  }

  Future<String> generateQuiz(String noteText, String difficulty) async {
    if (noteText.trim().isEmpty) return 'No note context provided to generate a quiz.';
    return getChatResponse(AIPrompts.noteQuizPrompt(noteText, difficulty));
  }

  Future<String> recommendEvents(List<CampusEvent> events, String userContext) async {
    if (events.isEmpty) return 'No events available for recommendations.';
    if (userContext.trim().isEmpty) userContext = 'A student looking for fun/educational activities.';
    final eventsJson = jsonEncode(events.map((e) => {'title': e.title, 'category': e.category, 'date': e.dateTime.toIso8601String(), 'location': e.location}).toList());
    return getChatResponse(AIPrompts.eventRecommendationPrompt(eventsJson, userContext));
  }

  Future<String> lostFoundTips(LostItem item) async {
    final itemContext = '${item.type}: ${item.title} at ${item.location} on ${item.createdAt}';
    return getChatResponse(AIPrompts.lostFoundTipsPrompt(itemContext));
  }
}
