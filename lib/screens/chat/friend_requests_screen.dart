import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/friend_request.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/avatar_helper.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Friend Requests', style: AppTypography.heading3),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading friend requests...'),
        error: (err, _) => AppErrorState(
          message: 'Failed to load friend requests.\n$err',
          onRetry: () => ref.invalidate(friendRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(context, ref, req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) {
    final hoursAgo = DateTime.now().difference(request.createdAt).inHours;
    final timeLabel = hoursAgo <= 0 ? 'Just now' : '${hoursAgo}h ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarWidget(request.name, radius: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  request.mutualText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _declineRequest(context, ref, request),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _acceptRequest(context, ref, request),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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

  Future<void> _acceptRequest(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) async {
    await ref.read(chatRepositoryProvider).acceptFriendRequest(request.id);
    ref.invalidate(friendRequestsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You and ${request.name} are now friends!')),
    );
  }

  Future<void> _declineRequest(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) async {
    await ref.read(chatRepositoryProvider).declineFriendRequest(request.id);
    ref.invalidate(friendRequestsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request declined')),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.people_alt_rounded,
      title: 'No pending requests',
      subtitle: "You're all caught up! Search for friends above.",
    );
  }
}
