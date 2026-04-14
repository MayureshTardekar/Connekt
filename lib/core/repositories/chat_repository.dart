import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/friend_request.dart';
import '../config/app_config.dart';
import '../network/logger.dart';

class ChatRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all conversations
  Future<List<ChatConversation>> getConversations() async {
    AppLogger.info('Fetching conversations... [useMockBackend: ${AppConfig.useMockBackend}]');
    if (AppConfig.useMockBackend) {
      // Return empty or mock based on implementation
      return [];
    }
    
    final response = await _supabase
        .from('chat_conversations')
        .select()
        .eq('is_archived', false)
        .order('last_message_time', ascending: false);
        
    return response.map((json) => ChatConversation.fromJson(json)).toList();
  }

  // Real-time stream of conversations
  Stream<List<ChatConversation>> watchConversations() {
    if (AppConfig.useMockBackend) {
      return Stream.fromFuture(getConversations());
    }
    return _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .eq('is_archived', false)
        .order('last_message_time', ascending: false)
        .map((data) => data.map((json) => ChatConversation.fromJson(json)).toList());
  }

  // Fetch all messages for a specific conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    if (AppConfig.useMockBackend) {
      return [];
    }

    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true);
        
    return response.map((json) => ChatMessage.fromJson(json)).toList();
  }

  // Real-time stream of messages
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (AppConfig.useMockBackend) {
      return Stream.fromFuture(getMessages(conversationId));
    }
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true)
        .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
  }


  Future<List<FriendRequest>> getFriendRequests() async {
    if (AppConfig.useMockBackend) {
      return _mockFriendRequests();
    }

    final response = await _supabase
        .from('friend_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return response.map((json) => FriendRequest.fromJson(json)).toList();
  }

  Stream<List<FriendRequest>> watchFriendRequests() {
    if (AppConfig.useMockBackend) {
      return Stream.fromFuture(getFriendRequests());
    }

    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => FriendRequest.fromJson(json)).toList());
  }

  Future<void> acceptFriendRequest(String requestId) async {
    if (AppConfig.useMockBackend) return;
    await _supabase
        .from('friend_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  Future<void> declineFriendRequest(String requestId) async {
    if (AppConfig.useMockBackend) return;
    await _supabase
        .from('friend_requests')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }

  List<FriendRequest> _mockFriendRequests() {
    final now = DateTime.now();
    return [
      FriendRequest(
        id: 'fr_1',
        name: 'Vikram Singh',
        mutualText: '3 mutual friends',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      FriendRequest(
        id: 'fr_2',
        name: 'Riya Mehta',
        mutualText: '1 mutual friend',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }


  Future<void> archiveConversation(String conversationId) async {
    if (AppConfig.useMockBackend) return;
    await _supabase
        .from('chat_conversations')
        .update({'is_archived': true})
        .eq('id', conversationId);
  }

  Future<void> unarchiveConversation(String conversationId) async {
    if (AppConfig.useMockBackend) return;
    await _supabase
        .from('chat_conversations')
        .update({'is_archived': false})
        .eq('id', conversationId);
  }

  // Send a new message
  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    if (AppConfig.useMockBackend) return;

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
  }
}

