import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../theme/avatar_helper.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  // Mock Data for pending requests
  final List<Map<String, String>> _pendingRequests = [
    {'name': 'Vikram Singh', 'mutual': '3 mutual friends', 'time': '2h ago'},
    {'name': 'Riya Mehta', 'mutual': '1 mutual friend', 'time': '5h ago'},
  ];

  @override
  Widget build(BuildContext context) {
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
      body: _pendingRequests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final req = _pendingRequests[index];
                return _buildRequestCard(req['name']!, req['mutual']!, req['time']!, index);
              },
            ),
    );
  }

  Widget _buildRequestCard(String name, String mutual, String time, int index) {
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
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarWidget(name, radius: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(mutual, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Handle Decline
                          setState(() {
                            _pendingRequests.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined')));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Decline', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Handle Accept
                          setState(() {
                            _pendingRequests.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You and $name are now friends!')));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                            ]
                          ),
                          alignment: Alignment.center,
                          child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.people_alt_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text("No pending requests", style: AppTypography.heading3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text("You're all caught up! Search for friends above.", style: TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
  }
}
