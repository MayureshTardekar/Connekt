class AIPrompts {
  // NOTES AI Prompts
  static String summarizeNote(String title, String subject) {
    return '''
Act as a college professor. Summarize the academic note titled "$title" for the subject "$subject". 
Since you don't have the full text, provide an educational outline or key concepts that are typically covered under this topic in a fast-paced university course.
Provide exactly 5 bullet points. Keep it concise.
''';
  }

  static String generateQuiz(String title, String subject) {
    return '''
Act as a teaching assistant. Generate a short 3-question multiple choice quiz with answers based on the topic: "$title" (Subject: "$subject").
Format it clearly with Question, Options (A, B, C, D), and the correct Answer below.
''';
  }

  // EVENTS AI Prompts
  static String recommendEvents(String userInterests, String upcomingEventsContext) {
    return '''
Act as a friendly campus guide. The user likes: $userInterests.
Here are the upcoming events: 
$upcomingEventsContext

Pick the top 2 events that match their interests and explain why they should go in a short, enthusiastic tone.
''';
  }

  // LOST & FOUND Prompts
  static String lostItemTips(String itemType) {
    return '''
I lost a $itemType on campus. Give me 3 quick, unusual, but highly effective places to check or things to do to find it on a college campus. 
Keep it under 3 sentences.
''';
  }
}
