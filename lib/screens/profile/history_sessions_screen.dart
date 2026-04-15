import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class HistorySessionsScreen extends StatelessWidget {
  const HistorySessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0A1E) : AppTheme.background,
      appBar: AppBar(
        title: const Text('Action History ⌚'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
                color: isDark ? Colors.white : AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSessionGroup(context, 'Today', [
            _SessionItem(
              title: 'AI Summary: Campus Activity',
              time: '10:30 AM',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            _SessionItem(
              title: 'Joined "M.Tech CSE" Study Group',
              time: '09:15 AM',
              icon: Icons.groups_rounded,
              color: const Color(0xFFF43F5E),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSessionGroup(context, 'Yesterday', [
            _SessionItem(
              title: 'Posted to GhostZone',
              time: '11:20 PM',
              icon: Icons.masks_rounded,
              color: const Color(0xFF7C3AED),
            ),
            _SessionItem(
              title: 'Chat with AI: Exam Prep',
              time: '04:05 PM',
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF3B82F6),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSessionGroup(context, 'Last Week', [
            _SessionItem(
              title: 'Reported Lost Item: Keys',
              time: 'Apr 12',
              icon: Icons.search_rounded,
              color: const Color(0xFF10B981),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSessionGroup(BuildContext context, String day, List<_SessionItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            day,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        ...items.map((item) => _buildItemTile(context, item)),
      ],
    );
  }

  Widget _buildItemTile(BuildContext context, _SessionItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class _SessionItem {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  _SessionItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}
