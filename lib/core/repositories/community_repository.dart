import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/reactions_json.dart';

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
    String? replyToId,
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
        final bytes = await XFile(filePath).readAsBytes();
        await supabase.storage.from('community_assets').uploadBinary(storagePath, bytes);
      }
      
      fileUrl = supabase.storage.from('community_assets').getPublicUrl(storagePath);
    }

    await supabase.from('community_messages').insert({
      'community_id': communityId,
      'sender_id': user.id,
      'content': content,
      'message_type': type,
      'file_url': fileUrl,
      'reply_to_id': replyToId,
    });
  }

  // --- REACTIONS ---
  Future<void> toggleReaction(String messageId, String emoji) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final message = await supabase
          .from('community_messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      var reactions = parseReactionsJson(message['reactions']);

      if (!reactions.containsKey(emoji)) {
        reactions[emoji] = [user.id];
      } else if (reactions[emoji]!.contains(user.id)) {
        reactions[emoji]!.remove(user.id);
        if (reactions[emoji]!.isEmpty) reactions.remove(emoji);
      } else {
        reactions[emoji]!.add(user.id);
      }

      await supabase
          .from('community_messages')
          .update({'reactions': reactionsToJsonb(reactions)})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Reaction error: $e');
    }
  }

  // --- DELETE MESSAGE ---
  Future<void> deleteMessage(String messageId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('community_messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', user.id);
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

  /// Whether this campus requires a non-empty [campuses.join_pin] before joining.
  Future<bool> campusRequiresJoinPin(String campusId) async {
    final data = await supabase
        .from('campuses')
        .select('join_pin')
        .eq('id', campusId)
        .single();
    final p = data['join_pin'];
    return p != null && p.toString().trim().isNotEmpty;
  }

  /// Institute PIN check for campus entry. If [join_pin] is null/empty in DB, any PIN is accepted (no gate).
  Future<bool> verifyCampusPin(String campusId, String pin) async {
    final data = await supabase
        .from('campuses')
        .select('join_pin')
        .eq('id', campusId)
        .single();

    final expected = data['join_pin'];
    if (expected == null || expected.toString().trim().isEmpty) {
      return true;
    }
    return expected.toString().trim() == pin.trim();
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
