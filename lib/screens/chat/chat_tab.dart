import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/chat_conversation.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';

import '../ghost/ghost_tab.dart';
import '../../core/widgets/premium_background.dart';

class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({super.key});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Social Hub',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_tabController.index == 1)
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.createCommunity),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.07),
                            ),
                            color: theme.colorScheme.surfaceContainer,
                          ),
                          child: Icon(Icons.add_rounded, color: theme.colorScheme.primary, size: 24),
                        ),
                      ),
                  ],
                ),
              ),

              // Custom Segmented Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: isDark ? 0.5 : 1.0),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Announcements'),
                      Tab(text: 'Communities'),
                      Tab(text: 'Ghost Chat'),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _AnnouncementsView(),
                    _CommunitiesView(),
                    GhostTab(isTab: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementsView extends ConsumerStatefulWidget {
  const _AnnouncementsView();

  @override
  ConsumerState<_AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends ConsumerState<_AnnouncementsView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conversationsAsync = ref.watch(chatConversationsProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: _GlassSearchBar(
            controller: _searchController,
            hint: 'Search announcements',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: conversationsAsync.when(
            loading: () => const AppLoadingState(message: 'Loading announcements...'),
            error: (error, _) => AppErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(chatConversationsProvider),
            ),
            data: (conversations) {
              final visible = conversations
                  .where((chat) => chat.isOfficial)
                  .where((chat) => chat.participantName.toLowerCase().contains(query))
                  .toList();

              if (visible.isEmpty) {
                return AppEmptyState(
                  icon: Icons.campaign_rounded,
                  title: query.isEmpty ? 'No Announcements' : 'No matching notices',
                  subtitle: query.isEmpty 
                    ? 'Official updates from your college will appear here.'
                    : 'Try another keyword.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(chatConversationsProvider),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _AnnouncementTile(conversation: visible[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CommunitiesView extends ConsumerStatefulWidget {
  const _CommunitiesView();

  @override
  ConsumerState<_CommunitiesView> createState() => _CommunitiesViewState();
}

class _CommunitiesViewState extends ConsumerState<_CommunitiesView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final communitiesAsync = ref.watch(communitiesProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: _GlassSearchBar(
            controller: _searchController,
            hint: 'Search communities',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: communitiesAsync.when(
            loading: () => const AppLoadingState(message: 'Loading communities...'),
            error: (error, _) => AppErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(communitiesProvider),
            ),
            data: (communities) {
              final visible = communities
                  .where((c) => (c['name'] as String? ?? '').toLowerCase().contains(query))
                  .toList();

              if (visible.isEmpty) {
                return AppEmptyState(
                  icon: Icons.groups_rounded,
                  title: query.isEmpty ? 'No Communities' : 'No matching groups',
                  subtitle: query.isEmpty 
                    ? 'Student-led clubs and campus groups will appear here.'
                    : 'Try another keyword.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(communitiesProvider),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _CommunityListTile(community: visible[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _GlassSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final ChatConversation conversation;

  const _AnnouncementTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.chatDetail, extra: conversation),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    conversation.isOfficial ? Icons.campaign_rounded : Icons.groups_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              conversation.participantName,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (conversation.isOfficial)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Official',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                 borderRadius: BorderRadius.circular(10),
                                 border: Border.all(
                                   color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                 ),
                               ),
                               child: Text(
                                 'Community',
                                 style: TextStyle(
                                   color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                   fontSize: 9,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ),
                          const Spacer(),
                           Text(
                             _formatTime(conversation.lastMessageTime),
                             style: TextStyle(
                               color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                               fontSize: 10,
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 4),
                       Text(
                         conversation.lastMessage.isEmpty ? 'Tap to view announcement' : conversation.lastMessage,
                         style: TextStyle(
                           color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                           fontSize: 12,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return DateFormat('MMM d').format(value);
  }
}

class _CommunityListTile extends StatelessWidget {
  final Map<String, dynamic> community;

  const _CommunityListTile({required this.community});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = community['name'] as String? ?? 'Unknown';
    final desc = community['description'] as String? ?? '';
    final isPrivate = community['is_private'] as bool? ?? false;
    final id = community['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(AppRoutes.communityChat.replaceAll(':id', id));
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    isPrivate ? Icons.lock_rounded : Icons.groups_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPrivate)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Private',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
