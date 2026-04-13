import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'post_ghost_screen.dart';
import 'comments_screen.dart';

import '../../core/providers/campus_provider.dart';
import '../../core/models/ghost_post.dart';
import 'package:intl/intl.dart';

class GhostTab extends ConsumerStatefulWidget {
  const GhostTab({super.key});

  @override
  ConsumerState<GhostTab> createState() => _GhostTabState();
}

class _GhostTabState extends ConsumerState<GhostTab> {
  int _selectedMood = 0;
  final List<String> _moods = [
    'All',
    'Stressed',
    'Happy',
    'Confused',
    'Venting',
    'Motivated',
  ];
  final List<IconData> _moodIcons = [
    Icons.grid_view_rounded,
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
    Icons.psychology_rounded,
    Icons.whatshot_rounded,
    Icons.rocket_launch_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.anonPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.ghostGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.visibility_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GhostZone',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Anonymous & safe',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34D399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '42 online',
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF581C87),
                          Color(0xFF7C3AED),
                          Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.masks_rounded,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Whisper your truths.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No names. Just souls.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mood chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _moods.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedMood == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppTheme.ghostGradient
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _moodIcons[index],
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _moods[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Posts
                Expanded(
                  child: ref.watch(ghostPostsProvider).when(
                    data: (posts) {
                      final filteredPosts = _selectedMood == 0
                          ? posts
                          : posts
                              .where(
                                  (p) => p.mood.toUpperCase() == _moods[_selectedMood].toUpperCase())
                              .toList();

                      if (filteredPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ghost_fixed, color: Colors.white24, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No secrets here... yet.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredPosts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filteredPosts.length) {
                            return const SizedBox(height: 100);
                          }

                          final post = filteredPosts[index];
                          final timeAgo = _getTimeAgo(post.createdAt);
                          
                          // Map mood to icon and color
                          final moodIndex = _moods.indexWhere((m) => m.toUpperCase() == post.mood.toUpperCase());
                          final color = moodIndex != -1 ? _getMoodColor(moodIndex) : AppTheme.anonPurple;
                          final icon = moodIndex != -1 ? _moodIcons[moodIndex] : Icons.bubble_chart_rounded;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildGhostPost(
                              context,
                              post.mood.toUpperCase(),
                              color,
                              icon,
                              timeAgo,
                              post.text,
                              post.likes,
                              post.commentsCount,
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.anonPurple),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Error: $err', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAB
          Positioned(
            bottom: 28,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostGhostScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.ghostGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d').format(dateTime);
  }

  Color _getMoodColor(int index) {
    const colors = [
      AppTheme.anonPurple,
      Color(0xFFF43F5E), // Stressed
      Color(0xFF10B981), // Happy
      Color(0xFFF59E0B), // Confused
      Color(0xFF8B5CF6), // Venting
      Color(0xFF3B82F6), // Motivated
    ];
    if (index < 0 || index >= colors.length) return AppTheme.anonPurple;
    return colors[index];
  }

  Widget _buildGhostPost(
    BuildContext context,
    String tag,
    Color tagColor,
    IconData tagIcon,
    String time,
    String content,
    int likes,
    int comments, {
    bool isEphemeral = false,
    bool isSensitive = false,
    List<Map<String, dynamic>>? pollOptions,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommentsScreen(
              postContent: content,
              mood: tag,
              moodColor: tagColor,
              likes: likes,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tagIcon, size: 13, color: tagColor),
                          const SizedBox(width: 5),
                          Text(
                            tag,
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEphemeral) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '24H',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isSensitive)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sensitive Content Hidden',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Show',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),

            if (pollOptions != null) ...[
              const SizedBox(height: 16),
              ...pollOptions.map(
                (opt) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    children: [
                      Container(
                        height: 36,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: opt['percent'] / 100,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${opt['percent']}%',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '243 votes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],

            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Upvote',
                  child: GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Icon(
                      Icons.keyboard_double_arrow_up_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$likes',
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Downvote',
                  child: GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Icon(
                      Icons.keyboard_double_arrow_down_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Semantics(
                  button: true,
                  label: '$comments Comments',
                  child: GestureDetector(
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 17,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$comments',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Share post',
                  child: GestureDetector(
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Icon(
                      Icons.share_rounded,
                      size: 17,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
