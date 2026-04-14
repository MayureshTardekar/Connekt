import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';
import '../lost_found/lost_found_tab.dart';
import '../study_groups/study_groups_tab.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Student';
    return user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        user.email?.split('@').first ??
        'Student';
  }



  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _staggeredFade(int index) {
    final start = (index * 0.1).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = (index * 0.1).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Greeting
              FadeTransition(
                opacity: _staggeredFade(0),
                child: SlideTransition(
                  position: _staggeredSlide(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _getUserName(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const SizedBox(height: 28),

              // Quick actions
              FadeTransition(
                opacity: _staggeredFade(2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              FadeTransition(
                opacity: _staggeredFade(3),
                child: SlideTransition(
                  position: _staggeredSlide(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Notes',
                          'Share & discover',
                          Icons.auto_stories_rounded,
                          const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          onTap: () => context
                              .findAncestorStateOfType<MainScreenState>()
                              ?.navigateToTab(1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Events',
                          'What\'s happening',
                          Icons.celebration_rounded,
                          const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          onTap: () => context
                              .findAncestorStateOfType<MainScreenState>()
                              ?.navigateToTab(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _staggeredFade(4),
                child: SlideTransition(
                  position: _staggeredSlide(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Lost & Found',
                          'Report & recover',
                          Icons.manage_search_rounded,
                          const [Color(0xFF0D9488), Color(0xFF0F766E)],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LostFoundTab(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Chat',
                          'Stay connected',
                          Icons.forum_rounded,
                          const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                          onTap: () => context
                              .findAncestorStateOfType<MainScreenState>()
                              ?.navigateToTab(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _staggeredFade(5),
                child: SlideTransition(
                  position: _staggeredSlide(5),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'World Chat',
                          'Campus-wide talk',
                          Icons.public_rounded,
                          const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                          onTap: () => context
                              .findAncestorStateOfType<MainScreenState>()
                              ?.navigateToTab(4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFeatureCard(
                          context,
                          'Study Groups',
                          'Learn together',
                          Icons.groups_3_rounded,
                          const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudyGroupsTab(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradient, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
