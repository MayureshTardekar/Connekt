import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/campus_repository.dart';
import '../models/campus_model.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import '../models/ghost_post.dart';

import '../repositories/ghost_repository.dart';

final campusRepositoryProvider = Provider((ref) => CampusRepository());
final ghostRepositoryProvider = Provider((ref) => GhostRepository());

// Campus general providers
final allCampusesProvider = FutureProvider<List<Campus>>((ref) {
  return ref.watch(campusRepositoryProvider).getAllCampuses();
});

final myCampusesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(campusRepositoryProvider).getMyCampuses();
});

// Selection logic
final selectedCampusIdProvider = StateProvider<String?>((ref) => null);

final selectedCampusProvider = Provider<Map<String, dynamic>?>((ref) {
  final id = ref.watch(selectedCampusIdProvider);
  if (id == null) return null;
  
  final memberships = ref.watch(myCampusesProvider).value ?? [];
  try {
    return memberships.firstWhere((m) => m['campus_id'] == id);
  } catch (_) {
    return null;
  }
});

// Provider to fetch specific tags (UID, Branch, Course) for the current user
final myMembershipsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(campusRepositoryProvider).getMyMemberships();
});

// Streams
final campusEventsProvider = StreamProvider<List<CampusEvent>>((ref) {
  return ref.watch(campusRepositoryProvider).watchEvents().map(
    (list) => list.map((json) => CampusEvent.fromMap(json)).toList(),
  );
});

final lostFoundProvider = StreamProvider<List<LostItem>>((ref) {
  return ref.watch(campusRepositoryProvider).watchLostFoundItems().map(
    (list) => list.map((json) => LostItem.fromMap(json)).toList(),
  );
});

final academicNotesProvider = StreamProvider<List<AcademicNote>>((ref) {
  return ref.watch(campusRepositoryProvider).watchNotes().map(
    (list) => list.map((json) => AcademicNote.fromMap(json)).toList(),
  );
});

final ghostPostsProvider = StreamProvider<List<GhostPost>>((ref) {
  return ref.watch(ghostRepositoryProvider).watchPosts();
});
