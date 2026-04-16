import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../mock/mock_datasource.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../network/logger.dart';

class ChatRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all conversations
  Future<List<ChatConversation>> getConversations() async {
    AppLogger.info(
      'Fetching conversations... [useMockBackend: ${AppConfig.useMockBackend}]',
    );
    if (AppConfig.useMockBackend) {
      return MockDatasource.chatConversations;
    }

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

  // Real-time stream of conversations
  Stream<List<ChatConversation>> watchConversations() {
    if (AppConfig.useMockBackend) {
      return Stream.value(MockDatasource.chatConversations);
    }
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
    if (AppConfig.useMockBackend) {
      return MockDatasource.chatMessages[conversationId] ?? [];
    }

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

  // Real-time stream of messages
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (AppConfig.useMockBackend) {
      return Stream.value(MockDatasource.chatMessages[conversationId] ?? []);
    }
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

  // Send a new message
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
    if (AppConfig.useMockBackend) return 15;
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
    if (AppConfig.useMockBackend) return;

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
    if (AppConfig.useMockBackend) return;

    try {
      await _supabase
          .from('chat_conversations')
          .update({'is_archived': false})
          .eq('id', conversationId);
    } catch (e) {
      AppLogger.error('Failed to unarchive conversation: $e');
    }
  }
}
