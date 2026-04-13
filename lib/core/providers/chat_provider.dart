import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

// Provides a singleton instance of our Mock Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// A StreamProvider that listens to the list of chat conversations
final chatConversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchConversations();
});

// A StreamProvider that listens to specific messages by passing a conversationId
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchMessages(conversationId);
});
