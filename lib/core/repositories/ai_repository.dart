import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import '../ai/ai_prompts.dart';

class AIRepository {
  List<String> _availableModels = [];
  bool _isFetchingModels = false;
  String? _lastSuccessfulResponse;
  
  // Throttle/Debounce parameters
  DateTime? _lastRequestTime;

  Future<void> _fetchAvailableModels() async {
    if (_availableModels.isNotEmpty || _isFetchingModels) return;
    if (AppConfig.geminiApiKey.isEmpty || AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') return;

    _isFetchingModels = true;
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\${AppConfig.geminiApiKey}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List;
        
        List<String> validModels = [];
        for (var model in models) {
          if (model['supportedGenerationMethods']?.contains('generateContent') == true) {
            String name = model['name'].toString().replaceFirst('models/', '');
            // Prioritize flash models for free tier
            if (name.contains('flash')) {
              validModels.insert(0, name);
            } else {
              validModels.add(name);
            }
          }
        }
        _availableModels = validModels;
        print('Dynamically loaded Gemini models: \$_availableModels');
      }
    } catch (e) {
      print('Failed to fetch models dynamically: \$e');
    } finally {
      _isFetchingModels = false;
    }
  }

  Future<String> getChatResponse(String message, {String? context}) async {
    if (AppConfig.geminiApiKey.isEmpty || AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      return 'Oops! Configure your AI connection to continue mapping out the campus.';
    }

    // Basic Debounce/Rate limiting (500ms)
    final now = DateTime.now();
    if (_lastRequestTime != null && now.difference(_lastRequestTime!).inMilliseconds < 500) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _lastRequestTime = DateTime.now();

    // Fetch models if list is empty
    if (_availableModels.isEmpty) {
      await _fetchAvailableModels();
    }
    
    // Fallback if no models available dynamically
    List<String> modelsToTry = _availableModels.isNotEmpty 
        ? _availableModels 
        : ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-2.0-flash-lite'];

    final prompt = context != null 
        ? 'System Instruction: You are the friendly Connekt AI Assistant for a college campus. Help the user concisely. Context: \$context\n\nUser: \$message'
        : 'System Instruction: You are the friendly Connekt AI Assistant for a college campus. Respond concisely.\n\nUser: \$message';

    final body = json.encode({
      "contents": [{
        "parts": [{"text": prompt}]
      }]
    });

    for (String modelName in modelsToTry) {
      int retries = 0;
      while (retries < 3) {
        try {
          final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/\$modelName:generateContent?key=\${AppConfig.geminiApiKey}');
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            try {
              final text = data['candidates'][0]['content']['parts'][0]['text'];
              if (text != null) {
                 _lastSuccessfulResponse = text;
                 return text; 
              }
            } catch (_) {} // Safety catch for parse
          } else if (response.statusCode == 429 || response.statusCode == 503) {
            // Rate limited or overloaded: Retry backoff (1s, 2s, 4s)
            retries++;
            // Calculate delay: 1, 2, 4 seconds
            final delaySeconds = (1 << (retries - 1));
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          } else {
             // Other error (404, 400), don't retry same model
             print('Model \$modelName failed with \${response.statusCode}: \${response.body}');
             break;
          }
        } catch (e) {
          print('Network error connecting to \$modelName: \$e');
          break; // move to next model
        }
      }
    }

    // IF ALL MODELS EXHAUSTED / FAILED: NEVER expose raw errors. Return Connekt specific usable response
    if (_lastSuccessfulResponse != null) {
      return "I'm a bit overwhelmed right now, but previously I noticed this: \n\n\$_lastSuccessfulResponse";
    }
    
    return "Campus servers are super busy right now taking a coffee break! ☕\n\nMeanwhile, check out the Lost & Found section or browse upcoming campus events. Please try again in a minute.";
  }

  Future<String> summarizeAppState({
    required List<AcademicNote> notes,
    required List<CampusEvent> events,
    required List<LostItem> lostFound,
  }) async {
    final context = '''
    Connekt App Current State Summary:
    Recent Notes: \${notes.take(5).map((n) => "\${n.title} [Subject: \${n.category}]").join(', ')}
    Upcoming Events: \${events.take(5).map((e) => "\${e.title} at \${e.location}").join(', ')}
    Lost & Found: \${lostFound.take(5).map((i) => "\${i.type}: \${i.title} at \${i.location}").join(', ')}
    
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
    final itemContext = '\${item.type}: \${item.title} at \${item.location} on \${item.createdAt}';
    return getChatResponse(AIPrompts.lostFoundTipsPrompt(itemContext));
  }
}
