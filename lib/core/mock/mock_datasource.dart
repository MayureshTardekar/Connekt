import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/friend_request.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/lost_item.dart';
import '../models/ghost_post.dart';

class MockDatasource {
  static final List<FriendRequest> friendRequests = [
    FriendRequest(
      id: 'req1',
      senderId: 'user_alice',
      senderName: 'Alice Smith',
      receiverId: 'me',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      mutualCount: 3,
    ),
    FriendRequest(
      id: 'req2',
      senderId: 'user_bob',
      senderName: 'Bob Jones',
      receiverId: 'me',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      mutualCount: 0,
    ),
  ];

  static final List<ChatConversation> chatConversations = [
    ChatConversation(
      id: 'conv1',
      participantId: 'user_alice',
      participantName: 'Alice Smith',
      lastMessage: 'Hey, are you going to the AI workshop later?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    ChatConversation(
      id: 'conv2',
      participantId: 'user_bob',
      participantName: 'Bob Jones',
      lastMessage: 'Thanks for sharing those notes!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
    ),
  ];

  static final Map<String, List<ChatMessage>> chatMessages = {
    'conv1': [
      ChatMessage(
        id: 'msg1',
        senderId: 'user_alice',
        senderName: 'Alice Smith',
        text: 'Hey, are you going to the AI workshop later?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isFromMe: false,
        isRead: false,
      ),
    ],
    'conv2': [
      ChatMessage(
        id: 'msg2',
        senderId: 'me',
        senderName: 'Me',
        text: 'Here are the physics notes you asked for.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isFromMe: true,
        isRead: true,
        sharedCardType: SharedCardType.note,
        sharedData: {
          'title': 'Quantum Physics 101',
          'pages': 12,
          'author': 'Dr. Quantum',
        },
      ),
      ChatMessage(
        id: 'msg3',
        senderId: 'user_bob',
        senderName: 'Bob Jones',
        text: 'Thanks for sharing those notes!',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isFromMe: false,
        isRead: true,
      ),
    ],
  };

  static final List<AcademicNote> notes = [];
  static final List<CampusEvent> events = [];
  static final List<LostItem> lostFound = [];
  static final List<GhostPost> ghostPosts = [];
}
