import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/community_provider.dart';

class CommunitiesListScreen extends ConsumerStatefulWidget {
  const CommunitiesListScreen({super.key, this.isTab = false});

  final bool isTab;

  @override
  ConsumerState<CommunitiesListScreen> createState() =>
      _CommunitiesListScreenState();
}

class _CommunitiesListScreenState extends ConsumerState<CommunitiesListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _refreshNonce = 0;

  void _bumpRefresh() => setState(() => _refreshNonce++);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final communitiesAsync = ref.watch(communitiesProvider);

    Widget listFor(List<Map<String, dynamic>> communities) {
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isTab ? 16 : 120),
        itemCount: communities.length,
        itemBuilder: (context, index) {
          final community = communities[index];
          return _CommunityTile(
            key: ValueKey('${community['id']}_$_refreshNonce'),
            community: community,
            onMembershipChanged: _bumpRefresh,
          );
        },
      );
    }

    final content = communitiesAsync.when(
      data: (communities) {
        if (communities.isEmpty) {
          return _buildEmptyState(context, theme);
        }
        return listFor(communities);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );

    if (widget.isTab) {
      return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Campus Communities',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            onPressed: () => context.push('/communities/create'),
          ),
        ],
      ),
      body: communitiesAsync.when(
        data: (communities) {
          if (communities.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return listFor(communities);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final muted = theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.35);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: muted),
          const SizedBox(height: 24),
          Text(
            'No Communities Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a space for your campus!',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.push('/communities/create'),
            child: const Text('Create Community'),
          ),
        ],
      ),
    );
  }
}

class _CommunityTile extends ConsumerStatefulWidget {
  const _CommunityTile({
    super.key,
    required this.community,
    required this.onMembershipChanged,
  });

  final Map<String, dynamic> community;
  final VoidCallback onMembershipChanged;

  @override
  ConsumerState<_CommunityTile> createState() => _CommunityTileState();
}

class _CommunityTileState extends ConsumerState<_CommunityTile> {
  String? _status;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    final id = widget.community['id']?.toString();
    if (id == null) return;
    final s = await ref.read(communityRepositoryProvider).getMembershipStatus(id);
    if (mounted) {
      setState(() {
        _status = s;
        _loading = false;
      });
    }
  }

  Future<void> _openChat() async {
    final id = widget.community['id']?.toString();
    if (id == null) return;
    ref.read(activeCommunityIdProvider.notifier).state = id;
    if (context.mounted) context.push('/communities/chat/$id');
  }

  Future<void> _joinPublic() async {
    final id = widget.community['id']?.toString();
    if (id == null) return;
    setState(() => _acting = true);
    try {
      await ref.read(communityRepositoryProvider).joinCommunity(id, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You joined this community.')),
        );
      }
      widget.onMembershipChanged();
      await _loadStatus();
      if (mounted) await _openChat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _requestPrivate() async {
    final id = widget.community['id']?.toString();
    if (id == null) return;
    setState(() => _acting = true);
    try {
      await ref.read(communityRepositoryProvider).joinCommunity(id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Request sent. A community admin will be notified in the admin panel.',
            ),
          ),
        );
      }
      widget.onMembershipChanged();
      await _loadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final community = widget.community;
    final isPrivate = community['is_private'] == true;
    final border = theme.dividerColor.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  backgroundImage: community['avatar_url'] != null
                      ? NetworkImage(community['avatar_url'].toString())
                      : null,
                  child: community['avatar_url'] == null
                      ? Icon(Icons.group, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community['name']?.toString() ?? 'Community',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isPrivate ? Icons.lock_outline : Icons.public,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isPrivate ? 'Private — request to join' : 'Public — anyone can join',
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else
              _buildActions(theme, isPrivate),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, bool isPrivate) {
    if (_acting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_status == 'member') {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _openChat,
              child: const Text('Open chat'),
            ),
          ),
        ],
      );
    }

    if (_status == 'pending') {
      return Text(
        'Your join request is pending admin approval.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      );
    }

    if (isPrivate) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _requestPrivate,
              child: const Text('Request to Join'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _joinPublic,
            child: const Text('Join'),
          ),
        ),
      ],
    );
  }
}
