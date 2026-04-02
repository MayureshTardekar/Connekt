import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'post_ghost_screen.dart';
import 'comments_screen.dart';

class GhostTab extends StatefulWidget {
  const GhostTab({super.key});

  @override
  State<GhostTab> createState() => _GhostTabState();
}

class _GhostTabState extends State<GhostTab> {
  int _selectedMood = 0;
  final List<String> _moods = ['All', 'Stressed', 'Happy', 'Confused', 'Venting', 'Motivated'];
  final List<IconData> _moodIcons = [Icons.grid_view_rounded, Icons.sentiment_very_dissatisfied_rounded, Icons.sentiment_very_satisfied_rounded, Icons.psychology_rounded, Icons.whatshot_rounded, Icons.rocket_launch_rounded];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: Stack(
        children: [
          // Background decoration
          Positioned(top: -100, right: -60, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppTheme.anonPurple.withValues(alpha: 0.15), Colors.transparent])))),
          Positioned(bottom: -80, left: -40, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF7C3AED).withValues(alpha: 0.1), Colors.transparent])))),

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
                        child: const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GhostZone', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text('Anonymous & safe', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('42 online', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w600)),
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
                      gradient: const LinearGradient(colors: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Stack(
                      children: [
                        Positioned(right: -20, bottom: -20, child: Icon(Icons.masks_rounded, size: 100, color: Colors.white.withValues(alpha: 0.08))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Whisper your truths.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('No names. Just souls.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.ghostGradient : null,
                            color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_moodIcons[index], size: 16, color: isSelected ? Colors.white : Colors.white60),
                              const SizedBox(width: 6),
                              Text(_moods[index], style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.w600, fontSize: 12)),
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildGhostPost(context, 'VENTING', const Color(0xFFF43F5E), Icons.whatshot_rounded, '2m ago',
                        'Sometimes I feel like I\'m studying for a degree in stress management rather than Computer Science. Does anyone else feel like they\'re just pretending to know what\'s going on?',
                        128, 14),
                      const SizedBox(height: 14),
                      _buildGhostPost(context, 'HAPPY', const Color(0xFF10B981), Icons.sentiment_very_satisfied_rounded, '15m ago',
                        'Finally nailed that presentation today. The library cafe was actually quiet for once. Today is a win!',
                        45, 3),
                      const SizedBox(height: 14),
                      _buildGhostPost(context, 'CONFUSED', const Color(0xFFF59E0B), Icons.psychology_rounded, '1h ago',
                        'Is it normal to have a crush on your TA or am I just desperate for academic validation? Asking for a friend.',
                        89, 22),
                      const SizedBox(height: 14),
                      _buildGhostPost(context, 'MOTIVATED', const Color(0xFF3B82F6), Icons.rocket_launch_rounded, '3h ago',
                        'Just submitted my first ever open source PR and it got merged! Small step but it feels huge. Keep going everyone! 🚀',
                        215, 31),
                      const SizedBox(height: 100),
                    ],
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostGhostScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.ghostGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGhostPost(BuildContext context, String tag, Color tagColor, IconData tagIcon, String time, String content, int likes, int comments) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CommentsScreen(postContent: content, mood: tag, moodColor: tagColor, likes: likes),
        ));
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tagIcon, size: 13, color: tagColor),
                      const SizedBox(width: 5),
                      Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Text(time, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            Text(content, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.6, fontWeight: FontWeight.w400)),
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('$likes', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 24),
                Icon(Icons.chat_bubble_outline_rounded, size: 17, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('$comments', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.share_rounded, size: 17, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
