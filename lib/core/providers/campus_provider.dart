import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ghost_repository.dart';
import '../repositories/notes_repository.dart';
import '../repositories/campus_repository.dart';
import '../models/ghost_post.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';

// --- Ghost Repository & Provider ---
final ghostRepositoryProvider = Provider<GhostRepository>((ref) {
  return GhostRepository();
});

final ghostPostsProvider = StreamProvider<List<GhostPost>>((ref) {
  return ref.watch(ghostRepositoryProvider).watchPosts();
});

// --- Notes Repository & Provider ---
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

final academicNotesProvider = StreamProvider<List<AcademicNote>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

// --- Campus Repository (Events, Lost & Found) ---
final campusRepositoryProvider = Provider<CampusRepository>((ref) {
  return CampusRepository();
});

final campusEventsProvider = StreamProvider<List<CampusEvent>>((ref) {
  return ref.watch(campusRepositoryProvider).watchEvents();
});

final lostFoundProvider = StreamProvider<List<LostItem>>((ref) {
  return ref.watch(campusRepositoryProvider).watchLostFoundItems();
});
