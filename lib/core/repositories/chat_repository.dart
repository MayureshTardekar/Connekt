import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../config/app_config.dart';
import '../network/logger.dart';
import '../mock/mock_datasource.dart';

class ChatRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all conversations
  Future<List<ChatConversation>> getConversations() async {
    AppLogger.info('Fetching conversations... [useMockBackend: ${AppConfig.useMockBackend}]');
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
      return [];
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
        .map((data) => data
            .where((json) => json['is_archived'] != true)
            .map((json) => ChatConversation.fromJson(json))
            .toList());
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
          
      return response.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to get messages: $e');
      return [];
    }
  }

  // Real-time stream of messages
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (AppConfig.useMockBackend) {
      return Stream.value(MockDatasource.chatMessages[conversationId] ?? []);
    }
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }

  // Send a new message
  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    if (AppConfig.useMockBackend) return;

    try {
      await _supabase.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': message.senderId,
        'sender_name': message.senderName,
        'text': message.text,
        'timestamp': message.timestamp.toIso8601String(),
        'is_read': message.isRead,
        'shared_card_type': message.sharedCardType.name,
        'shared_data': message.sharedData,
      });
      
      // Update the last message in the conversation for the list view
      await _supabase.from('chat_conversations').update({
        'last_message': message.text,
        'last_message_time': message.timestamp.toIso8601String(),
      }).eq('id', conversationId);
    } catch (e) {
      AppLogger.error('Failed to send message: $e');
      throw Exception('Failed to send message.');
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
      AppLogger.error('Failed to archive conversation, column might be missing: $e');
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

