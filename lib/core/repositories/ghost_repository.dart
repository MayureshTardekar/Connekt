import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ghost_post.dart';

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
      print('Error fetching ghost posts: $e');
      return [];
    }
  }

  Stream<List<GhostPost>> watchPosts() {
    return _supabase
        .from('ghost_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((post) => GhostPost.fromMap(post)).toList());
  }

  Future<void> createPost(GhostPost post) async {
    try {
      await _supabase.from('ghost_posts').insert(post.toMap());
    } catch (e) {
      print('Error creating ghost post: $e');
    }
  }
}
