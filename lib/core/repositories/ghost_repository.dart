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
      return [];
    }
  }

  Stream<List<GhostPost>> watchPosts() {
    // Cutoff is the start of the current day in UTC (12:00 AM UTC / 5:30 AM IST)
    final now = DateTime.now().toUtc();
    final logicCutoff = DateTime.utc(now.year, now.month, now.day);
    
    return _supabase
        .from('ghost_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((post) => GhostPost.fromMap(post))
            .where((post) => post.createdAt.isAfter(logicCutoff.subtract(const Duration(seconds: 1)))) // Buff for same-second posts
            .toList());
  }

  Future<void> createPost(GhostPost post) async {
    try {
      await _supabase.from('ghost_posts').insert(post.toMap());
    } catch (e) {
      AppLogger.error('Error creating ghost post: $e');
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
      // If table doesnt exist yet, we just log it
    }
  }
}
