import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/campus_provider.dart';
import 'post_ghost_screen.dart';
import 'comments_screen.dart';

import '../../core/widgets/app_states.dart';
import '../../core/models/ghost_post.dart';

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
                color: AppColors.ghostPrimary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildMoodSelector(),
                Expanded(
                  child: ref.watch(ghostPostsProvider).when(
                        data: (posts) {
                          final filteredPosts =
                              _selectedMood == 0
                                  ? posts
                                  : posts
                                      .where(
                                        (p) =>
                                            p.mood == _moods[_selectedMood],
                                      )
                                      .toList();

                          if (filteredPosts.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.visibility_off_rounded,
                                    color: Colors.white24,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No anonymous whispers yet',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              return _buildGhostCard(filteredPosts[index]);
                            },
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.ghostPrimary,
                              ),
                            ),
                        error:
                            (err, stack) =>
                                AppErrorState(message: 'Failed to load data.\n$err'),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostGhostScreen()),
          );
        },
        backgroundColor: AppColors.ghostPrimary,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text(
          'Whisper Anonymously',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.ghostPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.theater_comedy_rounded,
                  color: AppColors.ghostPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghost Zone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '100% Anonymous Peer Support',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedMood == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.ghostPrimary
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.ghostPrimary
                          : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _moodIcons[index],
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _moods[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGhostCard(GhostPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentsScreen(
                postContent: post.text,
                mood: post.mood,
                moodColor: AppColors.ghostPrimary,
                likes: post.likes,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ghostPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.mood,
                      style: const TextStyle(
                        color: AppColors.ghostPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(post.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStat(Icons.favorite_rounded, '${post.likes}',
                      Colors.pinkAccent),
                  const SizedBox(width: 20),
                  _buildStat(Icons.chat_bubble_outline_rounded,
                      '${post.commentsCount}', Colors.blueAccent),
                  const Spacer(),
                  Icon(Icons.more_horiz_rounded, color: Colors.white24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.8)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }
}
