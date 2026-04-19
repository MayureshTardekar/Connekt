import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/chat_conversation.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

// Consolidated Views
import '../communities/communities_list_screen.dart';
import '../ghost/ghost_tab.dart';

class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({super.key});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: 0, // No standard toolbar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Social Hub', style: theme.textTheme.displaySmall),
                ),
                const SizedBox(height: 18),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.textTheme.bodySmall?.color,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Messages'),
                      Tab(text: 'Communities'),
                      Tab(text: 'Ghost Chat'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _MessagesView(),
            CommunitiesListScreen(isTab: true),
            GhostTab(isTab: true),
          ],
        ),
      ),
    );
  }
}

class _MessagesView extends ConsumerStatefulWidget {
  const _MessagesView();

  @override
  ConsumerState<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<_MessagesView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _archivedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(chatConversationsProvider);
    ref.invalidate(pendingRequestsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<bool> _confirmArchive(ChatConversation conversation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive conversation?'),
        content: Text(
          '${conversation.participantName} will be removed from your message list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _archiveConversation(ChatConversation conversation) async {
    setState(() => _archivedIds.add(conversation.id));
    try {
      await ref.read(chatRepositoryProvider).archiveConversation(conversation.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _archivedIds.remove(conversation.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not archive. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conversationsAsync = ref.watch(chatConversationsProvider);
    final pendingCount = ref.watch(pendingRequestsCountProvider);
    final selectedCampusId = ref.watch(selectedCampusIdProvider);
    final campus = ref.watch(selectedCampusProvider);
    final campusName = (campus?['campuses']?['name'] ?? campus?['campus_name'])?.toString();
    final query = _searchController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search conversations',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: conversationsAsync.when(
            loading: () => const AppLoadingState(message: 'Loading messages...'),
            error: (error, _) => AppErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(chatConversationsProvider),
            ),
            data: (conversations) {
              final hasCampusConversation = selectedCampusId != null &&
                  conversations.any((chat) => chat.id == selectedCampusId);
              final showCommunityShortcut = selectedCampusId != null &&
                  !hasCampusConversation &&
                  _matchesCommunityQuery(campusName, query);
              final visible = conversations
                  .where((chat) => !_archivedIds.contains(chat.id))
                  .where((chat) => _matchesConversation(chat, query))
                  .toList();
              final hasAnyContent = pendingCount > 0 || showCommunityShortcut || visible.isNotEmpty;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  children: [
                    if (pendingCount > 0) ...[
                      _FriendRequestBanner(count: pendingCount),
                      const SizedBox(height: 14),
                    ],
                    if (showCommunityShortcut) ...[
                      _CampusCommunityShortcut(
                        campusId: selectedCampusId,
                        campusName: campusName,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (!hasAnyContent)
                      SizedBox(
                        height: 380,
                        child: AppEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: query.isEmpty ? 'No conversations yet' : 'No matching conversations',
                          subtitle: query.isEmpty
                              ? 'When real chats exist, they will appear here.'
                              : 'Try a different name or message keyword.',
                        ),
                      )
                    else
                      ...visible.map(
                        (chat) => Dismissible(
                          key: ValueKey(chat.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmArchive(chat),
                          onDismissed: (_) => _archiveConversation(chat),
                          background: const _ArchiveBackground(),
                          child: _ConversationTile(conversation: chat),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesConversation(ChatConversation conversation, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return conversation.participantName.toLowerCase().contains(q) ||
        conversation.lastMessage.toLowerCase().contains(q);
  }

  bool _matchesCommunityQuery(String? campusName, String query) {
    if (query.isEmpty) return true;
    final rawName = campusName ?? 'Campus';
    final upperName = rawName.toUpperCase();
    final title = upperName.endsWith('S') || upperName.endsWith('S ') 
        ? "$rawName' Community"
        : "$rawName's Community";
    return title.toLowerCase().contains(query.toLowerCase());
  }
}

class _FriendRequestBanner extends StatelessWidget {
  const _FriendRequestBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(AppRoutes.chatFriendRequests),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Friend requests', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '$count pending ${count == 1 ? 'request' : 'requests'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusCommunityShortcut extends StatelessWidget {
  const _CampusCommunityShortcut({
    required this.campusId,
    required this.campusName,
  });

  final String campusId;
  final String? campusName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawName = campusName ?? 'Campus';
    final upperName = rawName.toUpperCase();
    final title = upperName.endsWith('S') || upperName.endsWith('S ') 
        ? "$rawName' Community"
        : "$rawName's Community";

    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.chatDetail,
          extra: ChatConversation(
            id: campusId,
            participantName: title,
            participantId: 'community',
            lastMessage: '',
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open the shared campus conversation.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasLastMessage = conversation.lastMessage.trim().isNotEmpty;
    final selectedCampusId = ref.watch(selectedCampusIdProvider);
    final campus = ref.watch(selectedCampusProvider);
    
    // Determine dynamic name for the tile
    String displayName = conversation.participantName;
    if (selectedCampusId != null && conversation.id == selectedCampusId) {
      final campusName = (campus?['campuses']?['name'] ?? campus?['campus_name'] ?? 'Campus').toString();
      final upperName = campusName.toUpperCase();
      displayName = upperName.endsWith('S') || upperName.endsWith('S ') 
          ? "$campusName' Community" 
          : "$campusName's Community";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.chatDetail, extra: conversation.copyWith(participantName: displayName)),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.dividerColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              avatarWidget(displayName, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: conversation.unreadCount > 0
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasLastMessage
                                ? conversation.lastMessage
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: hasLastMessage
                                  ? null
                                  : FontStyle.italic,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final now = DateTime.now();
    final date = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return DateFormat('h:mm a').format(value);
    if (value.year == now.year) return DateFormat('MMM d').format(value);
    return DateFormat('MMM d, yyyy').format(value);
  }
}

class _ArchiveBackground extends StatelessWidget {
  const _ArchiveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_rounded, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text(
            'Archive',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
