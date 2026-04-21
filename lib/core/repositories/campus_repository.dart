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

  // Combined Recent Activity Stream for Dashboard (kept clean for now)
  Stream<List<Map<String, dynamic>>> getRecentActivityStream({
    String? campusId,
  }) {
    final notesStream = campusId != null
        ? _supabase
            .from('notes_with_profiles')
            .stream(primaryKey: ['id'])
            .eq('campus_id', campusId)
        : _supabase
            .from('notes_with_profiles')
            .stream(primaryKey: ['id']);

    return notesStream
        .order('created_at', ascending: false)
        .limit(10)
        .asyncMap((notes) async {
      final List<Map<String, dynamic>> activities = [];

      for (var n in notes) {
        activities.add({
          'id': n['id'],
          'type': 'note',
          'title': n['title'] ?? 'Note',
          'subtitle': 'Shared a note in ${n['category'] ?? 'General'}',
          'created_at': DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now(),
          'author': n['author_name'] ?? n['author'] ?? 'Student',
          'author_id': n['author_id'],
          'author_avatar': n['author_avatar'],
          'image_url': n['file_url'],
          'location': null,
          'status': null,
        });
      }

      try {
        var eventsQuery = _supabase.from('events_with_profiles').select();
        if (campusId != null) {
          eventsQuery = eventsQuery.eq('campus_id', campusId);
        }
        final events =
            await eventsQuery.order('created_at', ascending: false).limit(10);
        for (var e in events) {
          activities.add({
            'id': e['id'],
            'type': 'event',
            'title': e['title'] ?? 'Event',
            'subtitle': 'New event at ${e['location'] ?? 'Campus'}',
            'created_at':
                DateTime.tryParse(e['created_at'] ?? e['event_date'] ?? '') ??
                    DateTime.now(),
            'author': e['author_name'] ?? e['organizer'] ?? 'Student',
            'author_id': e['author_id'],
            'author_avatar': e['author_avatar'],
            'image_url': e['image_url'],
            'location': e['location'],
            'status': null,
          });
        }
      } catch (e) {
        debugPrint('Error fetching events for feed: $e');
      }

      try {
        var lostQuery = _supabase.from('lost_items_with_profiles').select();
        if (campusId != null) {
          lostQuery = lostQuery.eq('campus_id', campusId);
        }
        final lostItems =
            await lostQuery.order('created_at', ascending: false).limit(10);
        for (var li in lostItems) {
          final isLost = li['type']?.toString().toLowerCase() == 'lost';
          activities.add({
            'id': li['id'],
            'type': 'lost_found',
            'title': li['title'] ?? 'Lost/Found Item',
            'subtitle':
                '${isLost ? 'Lost' : 'Found'} an item at ${li['location'] ?? 'Campus'}',
            'created_at':
                DateTime.tryParse(li['created_at'] ?? '') ?? DateTime.now(),
            'author': li['author_name'] ?? 'Student',
            'author_id': li['posted_by'],
            'author_avatar': li['author_avatar'],
            'image_url': li['image_url'],
            'location': li['location'],
            'status': li['status'] ?? 'Open',
            'item_type': li['type'],
          });
        }
      } catch (e) {
        debugPrint('Error fetching lost items for feed: $e');
      }

      // NEW: Fetch campus feed posts (the Instagram style images)
      try {
        var feedPostsQuery = _supabase.from('campus_feed_posts_with_profiles').select();
        if (campusId != null) {
          feedPostsQuery = feedPostsQuery.eq('campus_id', campusId);
        }
        final feedPosts = await feedPostsQuery.order('created_at', ascending: false).limit(10);
        for (var p in feedPosts) {
          activities.add({
            'id': p['id'],
            'type': 'feed_post',
            'title': p['caption'] ?? 'Social Post',
            'subtitle': 'Shared a new photo',
            'created_at': DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
            'author': p['author_full_name'] ?? p['author_display_name'] ?? 'Student',
            'author_id': p['author_id'],
            'author_avatar': p['author_avatar_url'],
            'image_url': p['image_url'],
            'likes_count': p['likes_count'] ?? 0,
            'location': null,
            'status': null,
          });
        }
      } catch (e) {
        debugPrint('Error fetching feed posts for activity: $e');
      }

      activities.sort(
        (a, b) => (b['created_at'] as DateTime)
            .compareTo(a['created_at'] as DateTime),
      );
      return activities.take(30).toList();
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

    final storagePath =
        'notes/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage.from('academic_resources').uploadBinary(
          storagePath,
          fileBytes as dynamic,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );

    final fileUrl =
        _supabase.storage.from('academic_resources').getPublicUrl(storagePath);

    await _supabase.from('academic_notes').insert({
      'campus_id': campusId,
      'title': title,
      'category': subject,
      'description': description,
      'file_url': fileUrl,
      'author_id': user.id,
      'author': user.userMetadata?['full_name'] ??
          user.userMetadata?['display_name'] ??
          user.email?.split('@')[0] ??
          'Student',
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

    await _supabase
        .from('academic_notes')
        .update({
          'title': title,
          'description': description,
          'category': category,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', noteId)
        .eq('author_id', user.id);
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
      'event_date': dateTime.toIso8601String(),
      'category': category,
      'author_id': user.id,
      'organizer': user.userMetadata?['display_name'] ??
          user.email?.split('@')[0] ??
          'Student',
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

    final row = <String, dynamic>{
      'campus_id': campusId,
      'title': title,
      'description': description,
      'location': location,
      'type': type,
      'status': 'Open',
      'posted_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      row['image_url'] = imageUrl;
    }
    await _supabase.from('lost_found').insert(row);
  }

  /// Upload an image for Lost & Found
  Future<String> uploadLostFoundImage(List<int> bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName = 'lostfound_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = 'lost_found/$fileName';

    await _supabase.storage.from('campus_assets').uploadBinary(
          storagePath,
          bytes as dynamic,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: false,
          ),
        );

    return _supabase.storage.from('campus_assets').getPublicUrl(storagePath);
  }

  Future<void> markItemAsFound(String itemId) async {
    await _supabase
        .from('lost_found')
        .update({'status': 'Found'})
        .eq('id', itemId);
  }

  Future<void> deleteFeedPost(String postId) async {
    await _supabase
        .from('campus_feed_posts')
        .delete()
        .eq('id', postId);
  }

  Future<void> deleteNote(String noteId) async {
    await _supabase.from('academic_notes').delete().eq('id', noteId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('campus_events').delete().eq('id', eventId);
  }

  Future<void> deleteLostFoundItem(String itemId) async {
    await _supabase.from('lost_found').delete().eq('id', itemId);
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
    await _supabase
        .from('campuses')
        .update({'banner_url': imageUrl})
        .eq('id', campusId);
  }

  Future<String> uploadCampusBanner(
      String campusId, List<int> fileBytes) async {
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

  /// Get real statistics for a campus
  Future<Map<String, dynamic>> getCampusStats(String campusId) async {
    try {
      final notesRes = await _supabase
          .from('academic_notes')
          .select('id')
          .eq('campus_id', campusId);
      final notesCount = notesRes.length;

      final eventsRes = await _supabase
          .from('campus_events')
          .select('id')
          .eq('campus_id', campusId);
      final eventsCount = eventsRes.length;

      final lostRes = await _supabase
          .from('lost_found')
          .select('id')
          .eq('campus_id', campusId);
      final lostCount = lostRes.length;

      final weekAgo =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final recentNotesRes = await _supabase
          .from('academic_notes')
          .select('id')
          .eq('campus_id', campusId)
          .gt('created_at', weekAgo);
      final recentActivity = recentNotesRes.length;
      final totalActivity = notesCount + eventsCount;

      String engagement = 'Low';
      if (recentActivity > 10) {
        engagement = 'Elite';
      } else if (recentActivity > 5) {
        engagement = 'High';
      } else if (recentActivity > 2) {
        engagement = 'Moderate';
      }

      return {
        'notes_count': notesCount,
        'events_count': eventsCount,
        'lost_count': lostCount,
        'engagement': engagement,
        'growth': recentActivity > 0
            ? '+${((recentActivity / (totalActivity > 0 ? totalActivity : 1)) * 100).toInt()}%'
            : '0%',
      };
    } catch (e) {
      return {
        'notes_count': 0,
        'events_count': 0,
        'lost_count': 0,
        'engagement': 'New',
        'growth': '0%',
      };
    }
  }

  // ─── Campus Social Feed ───────────────────────────────────────────────────────

  /// Real-time stream of photo posts for the campus social wall
  Stream<List<Map<String, dynamic>>> watchCampusFeedPosts(String campusId) {
    return _supabase
        .from('campus_feed_posts')
        .stream(primaryKey: ['id'])
        .eq('campus_id', campusId)
        .order('created_at', ascending: false)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  /// Create a social feed post (image required, caption optional)
  Future<void> createFeedPost({
    required String campusId,
    required String imageUrl,
    String? caption,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('campus_feed_posts').insert({
      'campus_id': campusId,
      'author_id': user.id,
      'image_url': imageUrl,
      'caption': caption,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> uploadFeedPostImage(Uint8List bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final fileName =
        'feed_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'feed/$fileName';

    try {
      await _supabase.storage.from('campus_assets').uploadBinary(path, bytes);
      return _supabase.storage.from('campus_assets').getPublicUrl(path);
    } catch (e) {
      debugPrint('Feed image upload error: $e');
      return null;
    }
  }

  /// Toggle like on a feed post
  Future<void> toggleFeedPostLike(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await _supabase
          .from('feed_post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      final row = await _supabase
          .from('campus_feed_posts')
          .select('likes_count')
          .eq('id', postId)
          .single();
      final current = (row['likes_count'] as int?) ?? 0;

      if (existing != null) {
        await _supabase
            .from('feed_post_likes')
            .delete()
            .eq('id', existing['id']);
        await _supabase
            .from('campus_feed_posts')
            .update({'likes_count': (current - 1).clamp(0, 999999)})
            .eq('id', postId);
      } else {
        await _supabase
            .from('feed_post_likes')
            .insert({'post_id': postId, 'user_id': user.id});
        await _supabase
            .from('campus_feed_posts')
            .update({'likes_count': current + 1})
            .eq('id', postId);
      }
    } catch (e) {
      debugPrint('Feed like error: $e');
    }
  }

  /// Check if current user has liked a specific feed post
  Future<bool> hasLikedFeedPost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      final result = await _supabase
          .from('feed_post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
