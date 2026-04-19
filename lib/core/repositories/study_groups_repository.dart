import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/reactions_json.dart';

class StudyGroupsRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Fetch all groups for the current campus
  Stream<List<Map<String, dynamic>>> getGroupsStream(String campusId) {
    return _supabase
        .from('study_groups')
        .stream(primaryKey: ['id'])
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
  }

  // Request to join a group
  Future<void> requestToJoin(String groupId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Check if already requested or member
    final existing = await _supabase
        .from('study_group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Request already sent or already a member.');
    }

    await _supabase.from('study_group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'status': 'pending',
    });
  }

  // Approve a member (Owner only)
  Future<void> approveMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .update({'status': 'approved'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Kick a member or Reject request
  Future<void> removeMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Check membership status
  Future<String?> getMembershipStatus(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('study_group_members')
        .select('status')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return data?['status'];
  }

  Stream<List<Map<String, dynamic>>> watchGroupMessages(String groupId) {
    return _supabase
        .from('study_group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: true)
        .map((rows) {
          final list = List<Map<String, dynamic>>.from(rows);
          list.sort((a, b) {
            final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return ta.compareTo(tb);
          });
          return list;
        });
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String messageType,
    String? content,
    String? fileUrl,
    String? fileName,
    String? replyToId,
  }) async {
    final user = _supabase.auth.currentUser!;
    await _supabase.from('study_group_messages').insert({
      'group_id': groupId,
      'sender_id': user.id,
      'message_type': messageType,
      'content': content,
      'file_url': fileUrl,
      'file_name': fileName,
      'reply_to_id': replyToId,
    });
  }

  Future<String?> uploadGroupFile(Uint8List bytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path =
        'study_group_files/${user.id}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      await _supabase.storage.from('community_assets').uploadBinary(path, bytes);
      return _supabase.storage.from('community_assets').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleGroupMessageReaction(String messageId, String emoji) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final message = await _supabase
          .from('study_group_messages')
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

      await _supabase
          .from('study_group_messages')
          .update({'reactions': reactionsToJsonb(reactions)})
          .eq('id', messageId);
    } catch (e, st) {
      debugPrint('Study group reaction error: $e\n$st');
    }
  }

  Future<void> deleteGroupMessage(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase
        .from('study_group_messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', user.id);
  }

  Future<void> setGroupMessagePinned(String messageId, bool pinned) async {
    await _supabase
        .from('study_group_messages')
        .update({'is_pinned': pinned})
        .eq('id', messageId);
  }
}
