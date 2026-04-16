import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ghost_post.dart';
import '../network/logger.dart';

class GhostRepository {
  final _supabase = Supabase.instance.client;

  Future<List<GhostPost>> getPosts() async {
    try {
      final response = await _supabase
          .from('ghost_posts')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((post) => GhostPost.fromMap(post)).toList();
    } catch (e) {
      AppLogger.error('Error fetching ghost posts: $e');
      rethrow;
    }
  }

  Stream<List<GhostPost>> watchPosts() {
    // Show posts from the last 24 hours for a more active experience
    final now = DateTime.now().toUtc();
    final logicCutoff = now.subtract(const Duration(hours: 24));

    return _supabase
        .from('ghost_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      try {
        return data.map((json) {
          try {
            return GhostPost.fromMap(json);
          } catch (e) {
            debugPrint('Error parsing ghost post record: $e');
            return null;
          }
        }).whereType<GhostPost>().where((post) {
          // Filter out very old posts for a cleaner global chat experience
          return post.createdAt.toUtc().isAfter(logicCutoff);
        }).toList();
      } catch (e) {
        debugPrint('Ghost stream mapping error: $e');
        return [];
      }
    });
  }

  Future<void> createPost(GhostPost post) async {
    try {
      await _supabase.from('ghost_posts').insert(post.toMap());
    } catch (e) {
      AppLogger.error('Error creating ghost post: $e');
      rethrow;
    }
  }

  Future<void> reportPost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // In a real app, this would insert into a 'reports' table
      // and a server-side trigger would increment strikes on the author's profile.
      await _supabase.from('ghost_reports').insert({
        'post_id': postId,
        'reported_by': user.id,
        'reason': 'Offensive/Inappropriate',
      });
      AppLogger.info('Post $postId reported by ${user.id}');
    } catch (e) {
      AppLogger.error('Error reporting post: $e');
      rethrow;
    }
  }
}
