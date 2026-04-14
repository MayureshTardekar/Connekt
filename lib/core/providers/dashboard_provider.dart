import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'campus_provider.dart';
import 'chat_provider.dart';

class DashboardStats {
  final int noteCount;
  final int ghostPostCount;
  final int unreadMessagesCount;
  final int eventCount;

  DashboardStats({
    required this.noteCount,
    required this.ghostPostCount,
    required this.unreadMessagesCount,
    required this.eventCount,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final notes = ref.watch(academicNotesProvider).value?.length ?? 0;
  final ghostPosts = ref.watch(ghostPostsProvider).value?.length ?? 0;
  final events = ref.watch(campusEventsProvider).value?.length ?? 0;
  final conversations = ref.watch(chatConversationsProvider).value ?? [];
  
  int unread = 0;
  for (var c in conversations) {
    unread += c.unreadCount;
  }

  return DashboardStats(
    noteCount: notes,
    ghostPostCount: ghostPosts,
    unreadMessagesCount: unread,
    eventCount: events,
  );
});
