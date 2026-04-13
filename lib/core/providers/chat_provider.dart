import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

// Provides a singleton instance of our Mock Repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// A FutureProvider that fetches the list of chat conversations
// This automatically provides us with UI states: Loading, Error, and Data!
final chatConversationsProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getConversations();
});

// A FutureProvider that fetches specific messages by passing a conversationId
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getMessages(conversationId);
});
