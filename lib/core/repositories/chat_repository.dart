import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ChatRepository {
  // Simulate network delay to make it feel like a real backend
  Future<List<ChatConversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      ChatConversation(
        id: '1',
        participantName: 'Rahul Sharma',
        participantId: 'p1',
        lastMessage: 'Are we still meeting for the project?',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isPinned: true,
      ),
      ChatConversation(
        id: '2',
        participantName: 'Priya Patel',
        participantId: 'p2',
        lastMessage: 'Thanks for the notes!',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      ChatConversation(
        id: '3',
        participantName: 'Dev team (MP)',
        participantId: 'p3',
        lastMessage: 'I will push the code tonight.',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 5,
      ),
    ];
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ChatMessage(
        id: 'm1',
        senderId: 'p1',
        senderName: 'Rahul Sharma',
        text: 'Hey, are you free?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isFromMe: false,
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'me',
        senderName: 'Me',
        text: 'Yes, just finishing up an assignment.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isFromMe: true,
        isRead: true,
      ),
      ChatMessage(
        id: 'm3',
        senderId: 'p1',
        senderName: 'Rahul Sharma',
        text: 'Are we still meeting for the project?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isFromMe: false,
      ),
      ChatMessage(
        id: 'm4',
        senderId: 'p1',
        senderName: 'Rahul Sharma',
        text: 'Hey check out these notes I made for OS.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isFromMe: false,
        sharedCardType: SharedCardType.note,
        sharedData: {
          'title': 'Operating Systems Ch-2',
          'author': 'Rahul Sharma',
          'type': 'PDF',
          'pages': 14,
        }
      ),
    ];
  }
}
