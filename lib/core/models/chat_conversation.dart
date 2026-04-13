class ChatConversation {
  final String id;
  final String participantName;
  final String participantId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isPinned;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
  });
}
