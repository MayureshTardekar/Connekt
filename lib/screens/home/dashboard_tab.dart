import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import '../main_screen.dart';
import '../lost_found/lost_found_tab.dart';
import '../study_groups/study_groups_tab.dart';
import '../ai/ai_chat_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/ai_provider.dart';

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

  String _getUserInitials() {
    final name = _getUserName();
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeTransition(
                opacity: _staggeredFade(0),
                child: SlideTransition(
                  position: _staggeredSlide(0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: avatarWidget(_getUserInitials(), radius: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                            Text(
                              _getUserName(),
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 19),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Badge(
                          smallSize: 8,
                          backgroundColor: AppTheme.coral,
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: AppTheme.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Hero banner
              FadeTransition(
                opacity: _staggeredFade(1),
                child: SlideTransition(
                  position: _staggeredSlide(1),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E1B4B),
                          Color(0xFF312E81),
                          Color(0xFF4338CA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.hub_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.emerald,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Campus Active',
                                    style: TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Campus Hub',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Everything at Central University,\nright at your fingertips.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildStatPill(
                                  '${ref.watch(dashboardStatsProvider).noteCount}',
                                  'Notes',
                                  const Color(0xFF818CF8),
                                ),
                                const SizedBox(width: 10),
                                _buildStatPill(
                                  '${ref.watch(dashboardStatsProvider).ghostPostCount}',
                                  'Secrets',
                                  const Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 10),
                                _buildStatPill(
                                  '${ref.watch(dashboardStatsProvider).unreadMessagesCount}',
                                  'Messages',
                                  const Color(0xFF34D399),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    const Text(
                      'See all',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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
                          'GhostZone',
                          'Anonymous space',
                          Icons.masks_rounded,
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

              // AI Assistant Card
              FadeTransition(
                opacity: _staggeredFade(6),
                child: SlideTransition(
                  position: _staggeredSlide(6),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AIChatScreen()),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.cyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.cyanAccent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Connekt AI Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ref.watch(campusSummaryProvider).when(
                                          data: (summary) => Text(
                                            summary,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          loading: () => const Text(
                                            'Analyzing campus activity...',
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                            ),
                                          ),
                                          error: (_, __) => const Text(
                                            'Summarize campus activity or ask anything.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              FadeTransition(
                opacity: _staggeredFade(7),
                child: Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),

              FadeTransition(
                opacity: _staggeredFade(7),
                child: SlideTransition(
                  position: _staggeredSlide(7),
                  child: Column(
                    children: [
                      /* ## [MOCK DATA]
                      _buildActivityCard(
                        context,
                        name: 'Jordan Davies',
                        action: 'shared "Vector Calculus Week 4"',
                        time: '2m ago',
                        icon: Icons.description_rounded,
                        iconColor: AppTheme.primary,
                        iconBg: const Color(0xFFEEF2FF),
                      ),
                      const SizedBox(height: 12),
                      _buildActivityCard(
                        context,
                        name: 'Aisha Lindholm',
                        action: 'posted a new campus event',
                        time: '15m ago',
                        icon: Icons.event_rounded,
                        iconColor: AppTheme.amber,
                        iconBg: const Color(0xFFFEF3C7),
                      ),
                      const SizedBox(height: 12),
                      _buildActivityCard(
                        context,
                        name: 'Marcus Wright',
                        action: 'reported a lost MacBook charger',
                        time: '1h ago',
                        icon: Icons.search_rounded,
                        iconColor: AppTheme.teal,
                        iconBg: const Color(0xFFCCFBF1),
                      ),
                      */
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Widget _buildActivityCard(
    BuildContext context, {
    required String name,
    required String action,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          avatarWidget(name, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' $action',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ],
      ),
    );
  }
}
