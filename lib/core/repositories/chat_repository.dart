import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../config/app_config.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../network/logger.dart';
import '../utils/reactions_json.dart';

class ChatRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Fetch all conversations
  Future<List<ChatConversation>> getConversations() async {
    AppLogger.info('Fetching conversations...');
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .order('last_message_time', ascending: false);

      return response
          .where((json) => json['is_archived'] != true)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get conversations: $e');
      throw Exception('Failed to load conversations: $e');
    }
  }

  // Create an official announcement channel
  Future<void> createAnnouncementChannel({
    required String title,
    required String campusId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channelId = 'announce_${DateTime.now().millisecondsSinceEpoch}';

    await _supabase.from('chat_conversations').insert({
      'id': channelId,
      'other_user_name': title,
      'is_official': true,
      'campus_id': campusId,
      'last_message': 'Channel created',
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Real-time stream of conversations
  Stream<List<ChatConversation>> watchConversations() {
    return _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: false)
        .map(
          (data) => data
              .where((json) => json['is_archived'] != true)
              .map((json) => ChatConversation.fromJson(json))
              .toList(),
        );
  }

  // Fetch all messages for a specific conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true);

      final userId = _supabase.auth.currentUser?.id;
      return response.map((json) {
        final msg = ChatMessage.fromJson(json);
        return msg.copyWith(
          isFromMe: msg.senderId == userId || msg.senderId == 'me',
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // Real-time stream of messages (returns ChatMessage models)
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    final userId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true)
        .map(
          (data) => data.map((json) {
            final msg = ChatMessage.fromJson(json);
            return msg.copyWith(
              isFromMe: msg.senderId == userId || msg.senderId == 'me',
            );
          }).toList(),
        );
  }

  /// Raw stream of DM messages as Maps — used by ChatDetailScreen
  Stream<List<Map<String, dynamic>>> watchRawMessages(String receiverId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);
    // Use a consistent conversation ID derived from both user IDs
    final ids = [currentUserId, receiverId]..sort();
    final conversationId = ids.join('_');
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: false)
        .map((data) => data.map((e) {
              final m = Map<String, dynamic>.from(e);
              // Standardize keys for the UI
              m['content'] = e['content'] ?? e['text'] ?? '';
              m['created_at'] = e['created_at'] ?? e['timestamp'] ?? DateTime.now().toUtc().toIso8601String();
              m['sender_name'] ??= 'User';
              return m;
            }).toList());
  }

  /// Send a direct message to another user (used by ChatDetailScreen)
  Future<void> sendDirectMessage({
    required String receiverId,
    required String content,
    String? replyToId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    final senderName = profile?['full_name'] ??
        user.userMetadata?['display_name'] ??
        user.email?.split('@').first ??
        'User';

    // Consistent conversation ID: sorted user IDs joined by _
    final ids = [user.id, receiverId]..sort();
    final conversationId = ids.join('_');

    await _supabase.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'sender_name': senderName,
      'text': content,
      'content': content, // Redundant but safe if migration is run
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'reply_to_id': replyToId,
    });
  }

  // Send a new message (legacy — used by ChatTab's existing flow)
  Future<void> sendMessage(
    String conversationId,
    ChatMessage message, {
    ChatConversation? conversation,
  }) async {
    if (AppConfig.useMockBackend) return;

    try {
      // Keep conversation metadata real instead of overwriting every thread with
      // a hardcoded "Campus Community" label.
      final Map<String, dynamic> upsertData = {
        'id': conversationId,
        'other_user_name': conversation?.participantName ?? 'Conversation',
        'last_message': message.text,
        'last_message_time': message.timestamp.toIso8601String(),
        'campus_id': conversation?.campusId,
      };

      // Try to create/update the conversation record first.
      await _supabase.from('chat_conversations').upsert(upsertData);

      try {
        // Advanced insert with all features
        await _supabase.from('chat_messages').insert({
          'conversation_id': conversationId,
          'sender_id': message.senderId,
          'sender_name': message.senderName,
          'text': message.text,
          'timestamp': message.timestamp.toIso8601String(),
          'is_read': message.isRead,
          'reactions': message.reactions,
          'audio_url': message.audioUrl,
          'audio_duration': message.audioDuration,
          'shared_card_type': message.sharedCardType.name,
          'shared_data': message.sharedData,
          'reply_to_id': message.replyToId,
          'reply_to_text': message.replyToText,
          'reply_to_name': message.replyToName,
        });
        // If we reach here, it succeeded! Do NOT run the fallback.
        return; 
      } catch (insertError) {
        // Fallback for missing columns/schema mismatches
        AppLogger.info(
          'Advanced insert failed, falling back to minimal: $insertError',
        );
        // Only retry if it was likely a column mismatch error (code 42703 or PGRST204)
        await _supabase.from('chat_messages').insert({
          'conversation_id': conversationId,
          'sender_id': message.senderId,
          'sender_name': message.senderName,
          'text': message.text,
          'timestamp': message.timestamp.toIso8601String(),
        });
      }
    } catch (e) {
      AppLogger.error('Definitive message failure: $e');
      throw Exception(e.toString());
    }
  }

  /// Get actual unique member count for a conversation
  Future<int> getMemberCount(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('sender_id')
          .eq('conversation_id', conversationId);

      final uniqueSenders = (response as List)
          .map((m) => m['sender_id'])
          .toSet();
      return uniqueSenders.length;
    } catch (e) {
      return 1; // Fallback to 1 (the current user)
    }
  }

  /// Archive a conversation — marks it as archived so it no longer appears in the list
  Future<void> archiveConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .update({'is_archived': true})
          .eq('id', conversationId);
    } catch (e) {
      AppLogger.error(
        'Failed to archive conversation, column might be missing: $e',
      );
    }
  }

  /// Unarchive a conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .update({'is_archived': false})
          .eq('id', conversationId);
    } catch (e) {
      AppLogger.error('Failed to unarchive conversation: $e');
    }
  }

  /// Update read status
  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      // Quiet fail
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (AppConfig.useMockBackend) return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', user.id);
    } catch (e) {
      AppLogger.error('Delete message failed: $e');
      rethrow;
    }
  }

  /// Toggle reaction on a message
  Future<void> toggleReaction(String messageId, String emoji) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (messageId.isEmpty || messageId.startsWith('local-')) {
      AppLogger.info('toggleReaction skipped: not a persisted message id');
      return;
    }

    try {
      final response = await _supabase
          .from('chat_messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      var reactions = parseReactionsJson(response['reactions']);
      final uid = user.id;
      final users = List<String>.from(reactions[emoji] ?? []);

      if (users.contains(uid)) {
        users.remove(uid);
      } else {
        users.add(uid);
      }

      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }

      await _supabase
          .from('chat_messages')
          .update({'reactions': reactionsToJsonb(reactions)})
          .eq('id', messageId);
    } catch (e, st) {
      AppLogger.error('Reaction error: $e');
      AppLogger.error('$st');
    }
  }

  /// Upload voice message to storage
  Future<String?> uploadVoiceMessage(List<int> bytes) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = 'chat_audio/$fileName';

    try {
      await _supabase.storage.from('community_assets').uploadBinary(path, Uint8List.fromList(bytes));
      return _supabase.storage.from('community_assets').getPublicUrl(path);
    } catch (e) {
      AppLogger.error('Voice upload error: $e');
      return null;
    }
  }

  /// Upload image to storage
  Future<String?> uploadImage(Uint8List bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'chat_images/$fileName';

    try {
      await _supabase.storage.from('community_assets').uploadBinary(path, bytes);
      return _supabase.storage.from('community_assets').getPublicUrl(path);
    } catch (e) {
      AppLogger.error('Image upload error: $e');
      return null;
    }
  }
  /// Watch messages for a community (community_messages table)
  Stream<List<Map<String, dynamic>>> watchCommunityMessages(String communityId) {
    return _supabase
        .from('community_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) {
              final m = Map<String, dynamic>.from(e);
              // Ensure consistent keys with DMs
              m['sender_name'] ??= 'User';
              // content is already there, created_at is already there
              return m;
            }).toList());
  }

  /// Send a message to a campus community
  Future<void> sendCommunityMessage({
    required String communityId,
    required String content,
    String? replyToId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();

    final senderName = profile?['full_name'] ??
        user.userMetadata?['display_name'] ??
        user.email?.split('@').first ??
        'User';

    await _supabase.from('community_messages').insert({
      'community_id': communityId,
      'sender_id': user.id,
      'sender_name': senderName,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

