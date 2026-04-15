import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ai_repository.dart';
import 'campus_provider.dart';

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository();
});

final aiChatResponseProvider = FutureProvider.family<String, String>((
  ref,
  message,
) async {
  final repository = ref.read(aiRepositoryProvider);
  return repository.getChatResponse(message);
});

final campusSummaryProvider = FutureProvider<String>((ref) async {
  final aiRepo = ref.watch(aiRepositoryProvider);

  // Watch all campus data streams
  final notes = ref.watch(academicNotesProvider).value ?? [];
  final events = ref.watch(campusEventsProvider).value ?? [];
  final lostFound = ref.watch(lostFoundProvider).value ?? [];

  // If we have some data, summarize it
  return aiRepo.summarizeAppState(
    notes: notes,
    events: events,
    lostFound: lostFound,
  );
});
