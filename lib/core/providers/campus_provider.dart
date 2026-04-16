import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/campus_model.dart';
import '../models/ghost_post.dart';
import '../models/lost_item.dart';
import '../repositories/campus_repository.dart';
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


// Selection logic with persistence
final selectedCampusIdProvider = StateNotifierProvider<CampusSelectionNotifier, String?>((ref) {
  return CampusSelectionNotifier(ref);
});

class CampusSelectionNotifier extends StateNotifier<String?> {
  final Ref ref;
  static const _prefKey = 'selected_campus_id';

  CampusSelectionNotifier(this.ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefKey);
    
    if (savedId != null) {
      state = savedId;
      return;
    }

    // Try auto-selection if only one campus joined
    _autoSelectIfNeeded();
  }

  void _autoSelectIfNeeded() {
    // If we're already selected, do nothing
    if (state != null) return;

    ref.listen(myCampusesProvider, (prev, next) {
      next.whenData((memberships) {
        // If state is still null and we have any memberships, pick the first one
        if (state == null && memberships.isNotEmpty) {
          final firstId = memberships.first['campus_id'];
          selectCampus(firstId);
        }
      });
    }, fireImmediately: true);
  }

  Future<void> selectCampus(String? id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_prefKey, id);
    } else {
      await prefs.remove(_prefKey);
    }
  }
}

final selectedCampusProvider = Provider<Map<String, dynamic>?>((ref) {
  final id = ref.watch(selectedCampusIdProvider);
  if (id == null) return null;

  // Use .value to get data even if it's loading (stale data)
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

final joinedCampusCountProvider = Provider<int>((ref) {
  return ref.watch(myMembershipsProvider).value?.length ?? 0;
});

// Streams
final campusEventsProvider = StreamProvider<List<CampusEvent>>((ref) {
  final selectedCampusId = ref.watch(selectedCampusIdProvider);
  if (selectedCampusId == null) return Stream.value(const <CampusEvent>[]);

  return ref
      .watch(campusRepositoryProvider)
      .watchEvents(campusId: selectedCampusId)
      .map((list) => list.map((json) => CampusEvent.fromMap(json)).toList());
});

final lostFoundProvider = StreamProvider<List<LostItem>>((ref) {
  final selectedCampusId = ref.watch(selectedCampusIdProvider);
  if (selectedCampusId == null) return Stream.value(const <LostItem>[]);

  return ref
      .watch(campusRepositoryProvider)
      .watchLostFoundItems(campusId: selectedCampusId)
      .map((list) => list.map((json) => LostItem.fromMap(json)).toList());
});

final academicNotesProvider = StreamProvider<List<AcademicNote>>((ref) {
  final selectedCampusId = ref.watch(selectedCampusIdProvider);
  if (selectedCampusId == null) return Stream.value(const <AcademicNote>[]);

  return ref
      .watch(campusRepositoryProvider)
      .watchNotes(campusId: selectedCampusId)
      .map((list) => list.map((json) => AcademicNote.fromMap(json)).toList());
});

final ghostPostsProvider = StreamProvider<List<GhostPost>>((ref) {
  return ref.watch(ghostRepositoryProvider).watchPosts();
});
