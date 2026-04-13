import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/friend_provider.dart';
import '../../core/models/friend_request.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/avatar_helper.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Friend Requests', style: AppTypography.heading3),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading requests...'),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(pendingRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_alt_rounded,
              title: 'No pending requests',
              subtitle: "You're all caught up! Search for friends to connect.",
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(pendingRequestsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

/// Isolated widget so actions don't cause full list rebuilds
class _RequestCard extends ConsumerStatefulWidget {
  final FriendRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isLoading = false;

  Future<void> _handleAction(bool accept) async {
    setState(() => _isLoading = true);
    final repo = ref.read(friendRepositoryProvider);
    try {
      if (accept) {
        await repo.acceptRequest(widget.request.id);
      } else {
        await repo.declineRequest(widget.request.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'You and ${widget.request.senderName} are now friends! 🎉'
                : 'Request declined.',
          ),
          backgroundColor: accept ? AppColors.success : AppColors.textHint,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
    // No setState needed — the stream automatically removes accepted/declined entries
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarWidget(req.senderName, radius: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.senderName,
                      style: AppTypography.bodyLarge
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatTime(req.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if (req.mutualCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${req.mutualCount} mutual friend${req.mutualCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Buttons — disabled while loading
                _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Decline',
                              color: AppColors.error,
                              background: AppColors.error.withValues(alpha: 0.1),
                              onTap: () => _handleAction(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Accept',
                              color: Colors.white,
                              background: AppColors.primary,
                              onTap: () => _handleAction(true),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
