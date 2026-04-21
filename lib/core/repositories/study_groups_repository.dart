import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyGroupsRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> watchGroupMessages(String groupId) {
    return _supabase
        .from('study_group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String messageType,
    required String content,
    String? fileUrl,
    String? fileName,
    String? replyToId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Fetch sender name from profiles
    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    
    final senderName = profile?['full_name'] ?? 
                      user.userMetadata?['display_name'] ?? 
                      user.email?.split('@')[0] ?? 'User';

    await _supabase.from('study_group_messages').insert({
      'group_id': groupId,
      'sender_id': user.id,
      'sender_name': senderName,
      'message_type': messageType,
      'content': content,
      'file_url': fileUrl,
      'file_name': fileName,
      'reply_to_id': replyToId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String?> uploadGroupFile(Uint8List bytes, String fileName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final path = 'study_groups/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from('campus_assets').uploadBinary(path, bytes);
    return _supabase.storage.from('campus_assets').getPublicUrl(path);
  }

  Future<void> toggleGroupMessageReaction(String messageId, String emoji) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final msg = await _supabase.from('study_group_messages').select('reactions').eq('id', messageId).single();
    Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});

    List users = reactions[emoji] ?? [];
    if (users.contains(user.id)) {
      users.remove(user.id);
    } else {
      users.add(user.id);
    }

    if (users.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = users;
    }

    await _supabase.from('study_group_messages').update({'reactions': reactions}).eq('id', messageId);
  }

  Future<void> setGroupMessagePinned(String messageId, bool isPinned) async {
    await _supabase.from('study_group_messages').update({'is_pinned': isPinned}).eq('id', messageId);
  }

  Future<void> deleteGroupMessage(String messageId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('study_group_messages').delete().eq('id', messageId).eq('sender_id', user.id);
  }

  /// Stream all study groups for a given campus
  Stream<List<Map<String, dynamic>>> getGroupsStream(String campusId) {
    return _supabase
        .from('study_groups')
        .stream(primaryKey: ['id'])
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
  }

  /// Request to join a study group (creates a pending membership)
  Future<void> requestToJoin(String groupId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('study_group_members').upsert({
      'group_id': groupId,
      'user_id': user.id,
      'status': 'pending',
    }, onConflict: 'group_id, user_id');
  }

  /// Approve a pending member (change status to approved)
  Future<void> approveMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .update({'status': 'approved'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  /// Remove a member from a study group
  Future<void> removeMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }
}
