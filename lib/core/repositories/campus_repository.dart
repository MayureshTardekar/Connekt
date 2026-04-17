import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_model.dart';

class CampusRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<Campus>> getAllCampuses() async {
    try {
      final response = await _supabase.from('campuses').select().order('name');
      return (response as List).map((json) {
        try {
          return Campus.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing campus: $e');
          return null;
        }
      }).whereType<Campus>().toList();
    } catch (e) {
      debugPrint('Failed to fetch campuses: $e');
      rethrow;
    }
  }

  // Check how many campuses user has joined
  Future<int> getJoinedCampusCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await _supabase
        .from('campus_members')
        .select('id')
        .eq('user_id', user.id);

    return (response as List).length;
  }

  Future<Campus> createCampus(String name) async {
    final user = _supabase.auth.currentUser;

    // Check if name already exists (Case insensitive check would be better but simple eq for now)
    final existing = await _supabase
        .from('campuses')
        .select()
        .eq('name', name)
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'A campus with this name already exists. Please join it instead!',
      );
    }

    final response = await _supabase
        .from('campuses')
        .insert({'name': name, 'created_by': user?.id})
        .select()
        .single();

    return Campus.fromJson(response);
  }

  // Join a campus with details
  Future<void> joinCampus({
    required String campusId,
    required String uid,
    required String course,
    required String branch,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Check if already joined this specific campus
    final existingMembership = await _supabase
        .from('campus_members')
        .select()
        .eq('user_id', user.id)
        .eq('campus_id', campusId)
        .maybeSingle();

    // If already a member, just return (UI will redirect)
    if (existingMembership != null) return;

    // 2. Check total joined count
    final count = await getJoinedCampusCount();
    if (count >= 3) {
      throw Exception('Limit reached: You can join at most 3 campuses');
    }

    // 3. New join
    await _supabase.from('campus_members').insert({
      'campus_id': campusId,
      'user_id': user.id,
      'uid': uid,
      'course': course,
      'branch': branch,
    });
  }

  Future<List<Map<String, dynamic>>> getMyCampuses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('campus_members')
          .select('*, campuses(*)')
          .eq('user_id', user.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting my campuses: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyMemberships() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('campus_members')
        .select('*, campuses(name)')
        .eq('user_id', user.id);

    return response;
  }

  Stream<List<Map<String, dynamic>>> watchEvents({String? campusId}) {
    var query = _supabase.from('campus_events').stream(primaryKey: ['id']);
    if (campusId != null) {
      return query.eq('campus_id', campusId).order('created_at', ascending: false);
    }
    return query.order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> watchLostFoundItems({String? campusId}) {
    // Note: Database schema for lost_found currently lacks campus_id column.
    return _supabase
        .from('lost_found')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> watchNotes({String? campusId}) {
     var query = _supabase.from('notes_with_profiles').stream(primaryKey: ['id']);
     if (campusId != null) {
       return query.eq('campus_id', campusId).order('created_at', ascending: false);
     }
     return query.order('created_at', ascending: false);
  }

  // Check if user is a member of any campus
  Future<bool> isMemberOfAnyCampus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase
        .from('campus_members')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  // Combined Recent Activity Stream for Dashboard
  Stream<List<Map<String, dynamic>>> getRecentActivityStream({
    String? campusId,
  }) {
    // We combine multiple sources into a single activity feed
    final notesStream = _supabase
        .from('academic_notes')
        .stream(primaryKey: ['id']);

    return notesStream.order('created_at', ascending: false).limit(10).asyncMap((
      notes,
    ) async {
      final List<Map<String, dynamic>> activities = [];

      // Process Notes
      for (var n in notes) {
        activities.add({
          'type': 'note',
          'title': n['title'],
          'subtitle': 'Shared a new note in ${n['category']}',
          'created_at': DateTime.parse(n['created_at']),
          // We can't easily join in streams, but we can store the ID and let UI/Model handle it or use a View
          'author': n['author_name'] ?? n['author'] ?? 'Student', 
          'author_avatar': n['author_avatar'],
          'image_url': n['file_url'],
        });
      }

      // Fetch Events
      try {
        var eventsQuery = _supabase.from('events_with_profiles').select();
        if (campusId != null) {
          eventsQuery = eventsQuery.eq('campus_id', campusId);
        }
        
        final events = await eventsQuery.order('created_at', ascending: false).limit(5);
        for (var e in events) {
          activities.add({
            'type': 'event',
            'title': e['title'],
            'subtitle': 'Organizing a campus event: ${e['location']}',
            'created_at': DateTime.parse(e['created_at'] ?? e['date_time']),
            'author': e['author_name'] ?? e['organizer'] ?? 'Student',
            'author_avatar': e['author_avatar'],
            'image_url': e['image_url'],
          });
        }
      } catch (e) {
        debugPrint('Error fetching events for feed: $e');
      }

      // Sort final list by recency
      activities.sort(
        (a, b) => (b['created_at'] as DateTime).compareTo(
          a['created_at'] as DateTime,
        ),
      );
      return activities.take(15).toList();
    });
  }

  // Upload academic note
  Future<void> uploadNote({
    required String campusId,
    required String title,
    required String subject,
    required String description,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload file to storage
    final storagePath =
        'notes/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from('academic_resources')
        .uploadBinary(
          storagePath,
          fileBytes as dynamic,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );

    final fileUrl = _supabase.storage
        .from('academic_resources')
        .getPublicUrl(storagePath);

    // 2. Insert record
    await _supabase.from('academic_notes').insert({
      'campus_id': campusId,
      'title': title,
      'category': subject,
      'description': description,
      'file_url': fileUrl,
      'author_id': user.id,
      'author': user.userMetadata?['full_name'] ?? 
                user.userMetadata?['display_name'] ?? 
                user.email?.split('@')[0] ?? 'Student',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Update academic note
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String description,
    required String category,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('academic_notes').update({
      'title': title,
      'description': description,
      'category': category,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', noteId).eq('author_id', user.id); // Security: only author can update
  }

  // Create campus event
  Future<void> createEvent({
    required String campusId,
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required String category,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('campus_events').insert({
      'campus_id': campusId,
      'title': title,
      'description': description,
      'location': location,
      'date_time': dateTime.toIso8601String(),
      'category': category,
      'author_id': user.id, // Better tracking
      'organizer': user.userMetadata?['display_name'] ?? user.email?.split('@')[0] ?? 'Student',
      'image_url': imageUrl,
      'attendees': 0,
    });
  }

  // Report lost/found item
  Future<void> reportLostFoundItem({
    required String campusId,
    required String title,
    required String description,
    required String location,
    required String type,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('lost_found').insert({
      // Removed campus_id
      'title': title,
      'description': description,
      'location': location,
      'type': type,
      'status': 'Open',
      'image_url': imageUrl,
      'posted_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- Management Methods ---

  Future<int> getMemberCount(String campusId) async {
    final response = await _supabase
        .from('campus_members')
        .select('id')
        .eq('campus_id', campusId);
    return (response as List).length;
  }

  Future<List<Map<String, dynamic>>> getCampusMembers(String campusId) async {
    final response = await _supabase
        .from('campus_members')
        .select('*, profiles(full_name, avatar_url)')
        .eq('campus_id', campusId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateCampusBanner(String campusId, String imageUrl) async {
    // We assume the column banner_url exists or we use a fallback metadata approach
    // For now, we try to update the campuses table
    await _supabase
        .from('campuses')
        .update({'banner_url': imageUrl})
        .eq('id', campusId);
  }

  Future<String> uploadCampusBanner(String campusId, List<int> fileBytes) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final storagePath = 'banners/$campusId.jpg';
    await _supabase.storage.from('campus_assets').uploadBinary(
          storagePath,
          fileBytes as dynamic,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _supabase.storage.from('campus_assets').getPublicUrl(storagePath);
  }

  // --- Likes Logic ---

  Future<void> toggleLike(String activityId, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final table = type == 'event' ? 'event_likes' : 'note_likes';
    final columnId = type == 'event' ? 'event_id' : 'note_id';

    try {
      final existing = await _supabase
          .from(table)
          .select()
          .eq(columnId, activityId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        await _supabase.from(table).delete().eq('id', existing['id']);
      } else {
        await _supabase.from(table).insert({
          columnId: activityId,
          'user_id': user.id,
        });
      }
    } catch (e) {
      debugPrint('Like error: $e. Table $table might be missing.');
    }
  }

  Future<bool> hasLiked(String activityId, String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final table = type == 'event' ? 'event_likes' : 'note_likes';
    final columnId = type == 'event' ? 'event_id' : 'note_id';

    try {
      final response = await _supabase
          .from(table)
          .select('id')
          .eq(columnId, activityId)
          .eq('user_id', user.id)
          .maybeSingle();
      return response != null;
    } catch (_) {
      return false;
    }
  }
}
