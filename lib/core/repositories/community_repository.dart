import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRepository {
  SupabaseClient get supabase => Supabase.instance.client;

  // 1. Fetch communities for current campus
  Stream<List<Map<String, dynamic>>> watchCommunities(String campusId) {
    return supabase
        .from('communities')
        .stream(primaryKey: ['id'])
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
  }

  // 2. Create a community
  Future<void> createCommunity({
    required String campusId,
    required String name,
    required String description,
    required bool isPrivate,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await supabase.from('communities').insert({
      'campus_id': campusId,
      'creator_id': user.id,
      'name': name,
      'description': description,
      'is_private': isPrivate,
      'avatar_url': avatarUrl,
    }).select().single();

    // Auto-join as admin
    await supabase.from('community_members').insert({
      'community_id': response['id'],
      'user_id': user.id,
      'role': 'admin',
    });
  }

  // 3. Join logic
  Future<void> joinCommunity(String communityId, bool isPrivate) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (isPrivate) {
      await supabase.from('community_requests').insert({
        'community_id': communityId,
        'user_id': user.id,
        'status': 'pending',
      });
    } else {
      await supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': user.id,
        'role': 'member',
      });
    }
  }

  // 4. Message Streaming
  Stream<List<Map<String, dynamic>>> watchMessages(String communityId) {
    return supabase
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: false);
  }

  // 5. Send Message (Generalized)
  Future<void> sendMessage({
    required String communityId,
    String? content,
    required String type, // 'text', 'image', 'voice'
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    String? fileUrl;

    // Handle File Upload if not a plain text message
    if (type != 'text' && (filePath != null || fileBytes != null)) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${type == 'voice' ? 'voice.m4a' : 'img.jpg'}';
      final storagePath = 'messages/$communityId/$fileName';

      if (kIsWeb && fileBytes != null) {
        await supabase.storage.from('community_assets').uploadBinary(storagePath, fileBytes);
      } else if (filePath != null) {
        await supabase.storage.from('community_assets').upload(storagePath, File(filePath));
      }
      
      fileUrl = supabase.storage.from('community_assets').getPublicUrl(storagePath);
    }

    await supabase.from('community_messages').insert({
      'community_id': communityId,
      'sender_id': user.id,
      'content': content,
      'message_type': type,
      'file_url': fileUrl,
    });
  }

  // Check membership status
  Future<String?> getMembershipStatus(String communityId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('community_members')
        .select('role')
        .eq('community_id', communityId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (data != null) return 'member';

    final request = await supabase
        .from('community_requests')
        .select('status')
        .eq('community_id', communityId)
        .eq('user_id', user.id)
        .maybeSingle();

    return request?['status'];
  }

  // --- NEW: ADMIN AUTHORITIES ---

  // Verify Campus PIN
  Future<bool> verifyCampusPin(String campusId, String pin) async {
    final data = await supabase
        .from('campuses')
        .select('join_pin')
        .eq('id', campusId)
        .single();
    
    return data['join_pin'] == pin;
  }

  // Kick Member
  Future<void> kickMember(String communityId, String userId) async {
    await supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  // Manage Join Requests
  Future<void> handleRequest(String requestId, bool accept) async {
    if (accept) {
      final req = await supabase.from('community_requests').select().eq('id', requestId).single();
      // Add to members
      await supabase.from('community_members').insert({
        'community_id': req['community_id'],
        'user_id': req['user_id'],
        'role': 'member',
      });
      // Delete request
      await supabase.from('community_requests').delete().eq('id', requestId);
    } else {
      await supabase.from('community_requests').update({'status': 'rejected'}).eq('id', requestId);
    }
  }

  // Toggle Announcement
  Future<void> sendAnnouncement(String communityId, String content) async {
    await sendMessage(
      communityId: communityId,
      type: 'text',
      content: '📢 ANNOUNCEMENT: $content',
    );
  }
}
