import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import 'dart:convert';
import '../ai/ai_prompts.dart';

class AIRepository {
  GenerativeModel? _model;
  
  void _initModel() {
    if (_model != null) return;
    if (AppConfig.geminiApiKey.isEmpty || AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') return;
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.geminiApiKey,
    );
  }

  Future<String> getChatResponse(String message, {String? context}) async {
    _initModel();
    if (_model == null) {
      return 'AI Assistant is currently unavailable. Please check the Gemini API Key configuration in lib/core/config/app_config.dart.';
    }

    try {
      final prompt = context != null 
          ? 'You are the Connekt AI Assistant. Context about the app state: $context\n\nUser: $message'
          : message;
          
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? 'I\'m sorry, I couldn\'t generate a response.';
    } catch (e) {
      return 'AI Error: $e';
    }
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
    final eventsJson = jsonEncode(events.map((e) => {'title': e.title, 'category': e.category, 'date': e.date, 'location': e.location}).toList());
    return getChatResponse(AIPrompts.eventRecommendationPrompt(eventsJson, userContext));
  }

  Future<String> lostFoundTips(LostItem item) async {
    final itemContext = '${item.type}: ${item.title} at ${item.location} on ${item.date}';
    return getChatResponse(AIPrompts.lostFoundTipsPrompt(itemContext));
  }
}
