class AIPrompts {
  static String noteSummaryPrompt(String noteText) {
    return '''
Please summarize the following academic note into 2-3 concise points.
Focus on the most important key takeaways.
    
Note Text:
$noteText
''';
  }

  static String noteQuizPrompt(String noteText, String difficulty) {
    return '''
Generate a short 3-question multiple choice quiz based on this note.
The difficulty should be: $difficulty.
    
Note Text:
$noteText

Format your output as:
Q1. [Question]
A) [Option]
B) [Option]
C) [Option]
D) [Option]
Answer: [Correct Option]
''';
  }

  static String eventRecommendationPrompt(String eventsJson, String userContext) {
    return '''
Based on the following events available on campus:
$eventsJson

And the user context/interests:
$userContext

Recommend 2 events they should attend and briefly explain why.
''';
  }

  static String lostFoundTipsPrompt(String itemContext) {
    return '''
The user has lost/found an item:
$itemContext

Give 3 brief, practical tips on what they should do next to retrieve it or return it safely on a college campus.
''';
  }
}
