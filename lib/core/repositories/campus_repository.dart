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

  // Join a campus with details and security PIN
  Future<void> joinCampus({
    required String campusId,
    required String uid,
    required String course,
    required String branch,
    String? pin,
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

    // 2. Enforce Single Campus Logic (Student can only be in one college)
    final count = await getJoinedCampusCount();
    if (count >= 1) {
      throw Exception('You are already a member of a campus. Please leave your current campus to join a new one.');
    }

    // 3. Security Check: Verify PIN if set. Select the whole row so older
    // databases without campuses.join_pin do not fail with a missing column.
    final campusData = await _supabase
        .from('campuses')
        .select()
        .eq('id', campusId)
        .maybeSingle();
    
    final requiredPin = campusData != null && campusData.containsKey('join_pin')
        ? campusData['join_pin']?.toString()
        : null;
    if (requiredPin != null && requiredPin.isNotEmpty) {
      if (pin == null || pin.trim() != requiredPin.trim()) {
        throw Exception('Invalid Campus PIN. Please ask your campus administrator for the correct PIN.');
      }
    }

    // 4. New join
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

      return List<Map<String, dynamic>>.from(response as List);
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
    var query = _supabase
        .from('lost_found')
        .stream(primaryKey: ['id']);
    if (campusId != null) {
      return query.eq('campus_id', campusId).order('created_at', ascending: false);
    }
    return query.order('created_at', ascending: false);
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

  // Helper to safely parse Supabase timestamps to UTC
  DateTime _parseTimestamp(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
      dateStr = '${dateStr}Z';
    }
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  // Isolated Campus Feed Stream for Dashboard
  Stream<List<Map<String, dynamic>>> getRecentActivityStream({
    String? campusId,
  }) {
    return _supabase
        .from('campus_feed_posts') // Main trigger
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
      final List<Map<String, dynamic>> activities = [];

      try {
        var feedPostsQuery = _supabase.from('campus_feed_posts_with_profiles').select();
        if (campusId != null) {
          feedPostsQuery = feedPostsQuery.eq('campus_id', campusId);
        }
        final feedPosts = await feedPostsQuery.order('created_at', ascending: false).limit(30);
        for (var p in feedPosts) {
          activities.add({
            'id': p['id'],
            'type': 'feed_post',
            'title': p['caption'] ?? 'Social Post',
            'subtitle': 'Shared a new photo',
            'created_at': _parseTimestamp(p['created_at']),
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
      return activities;
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
    if (type == 'feed_post') {
      return toggleFeedPostLike(activityId);
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String table;
    String columnId;
    
    if (type == 'event') {
      table = 'event_likes';
      columnId = 'event_id';
    } else if (type == 'lost_found') {
      table = 'lost_found_likes';
      columnId = 'item_id';
    } else {
      table = 'note_likes';
      columnId = 'note_id';
    }

    try {
      final existing = await _supabase
          .from(table)
          .select('id')
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
    if (type == 'feed_post') {
      return hasLikedFeedPost(activityId);
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    String table;
    String columnId;
    
    if (type == 'event') {
      table = 'event_likes';
      columnId = 'event_id';
    } else if (type == 'lost_found') {
      table = 'lost_found_likes';
      columnId = 'item_id';
    } else {
      table = 'note_likes';
      columnId = 'note_id';
    }

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

  Future<int> getLikesCount(String activityId, String type) async {
    if (type == 'feed_post') {
      return getFeedPostLikesCount(activityId);
    }

    String table;
    String columnId;
    
    if (type == 'event') {
      table = 'event_likes';
      columnId = 'event_id';
    } else if (type == 'lost_found') {
      table = 'lost_found_likes';
      columnId = 'item_id';
    } else {
      table = 'note_likes';
      columnId = 'note_id';
    }

    try {
      final response = await _supabase
          .from(table)
          .select('id')
          .eq(columnId, activityId);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getFeedPostLikesCount(String postId) async {
    try {
      final response = await _supabase
          .from('feed_post_likes')
          .select('id')
          .eq('post_id', postId);
      return (response as List).length;
    } catch (_) {
      return 0;
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

      if (existing != null) {
        await _supabase
            .from('feed_post_likes')
            .delete()
            .eq('id', existing['id']);
      } else {
        await _supabase
            .from('feed_post_likes')
            .insert({'post_id': postId, 'user_id': user.id});
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

  Future<int> getUserContributionCount(String userId) async {
    try {
      final results = await Future.wait([
        _supabase.from('academic_notes').select('id').eq('author_id', userId),
        _supabase.from('campus_events').select('id').eq('author_id', userId),
        _supabase.from('lost_found').select('id').eq('posted_by', userId),
        _supabase.from('campus_feed_posts').select('id').eq('author_id', userId),
      ]);

      int total = 0;
      for (var res in results) {
        if (res is List) {
          total += res.length;
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error fetching contribution count: $e');
      return 0;
    }
  }

  Future<void> resolveLostFoundItem(String itemId, bool isResolved) async {
    try {
      await _supabase
          .from('lost_found')
          .update({'is_resolved': isResolved})
          .eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
