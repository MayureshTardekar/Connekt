import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/friend_request.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Friend requests'),
      ),
      body: requestsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading requests...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(pendingRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_alt_rounded,
              title: 'No pending requests',
              subtitle: 'New requests will appear here when someone connects.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingRequestsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _RequestCard(request: requests[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request});

  final FriendRequest request;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isLoading = false;

  Future<void> _handleAction(bool accept) async {
    setState(() => _isLoading = true);
    final repository = ref.read(friendRepositoryProvider);

    try {
      if (accept) {
        await repository.acceptRequest(widget.request.id);
      } else {
        await repository.declineRequest(widget.request.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'You and ${widget.request.senderName} are now friends.'
                : 'Request declined.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Please try again.')),
      );
    }
  }

  String _formatTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = widget.request;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarWidget(request.senderName, radius: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.senderName,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatTime(request.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (request.mutualCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${request.mutualCount} mutual ${request.mutualCount == 1 ? 'friend' : 'friends'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (_isLoading)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleAction(false),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAction(true),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
