import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Student';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campus = ref.watch(selectedCampusProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              _greeting(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _userName(),
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Open the tools you actually use. Everything here is kept deliberately lean.',
              style: theme.textTheme.bodyMedium,
            ),
            if (campus?['campus_name'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        campus!['campus_name'].toString(),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Core tools',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardCard(
                  icon: Icons.auto_stories_rounded,
                  title: 'Notes',
                  subtitle: 'Upload and browse study material',
                  onTap: () => context
                      .findAncestorStateOfType<MainScreenState>()
                      ?.navigateToTab(1),
                ),
                _DashboardCard(
                  icon: Icons.event_rounded,
                  title: 'Events',
                  subtitle: 'See upcoming campus activity',
                  onTap: () => context
                      .findAncestorStateOfType<MainScreenState>()
                      ?.navigateToTab(2),
                ),
                _DashboardCard(
                  icon: Icons.forum_rounded,
                  title: 'Chat',
                  subtitle: 'Pick up conversations quickly',
                  onTap: () => context
                      .findAncestorStateOfType<MainScreenState>()
                      ?.navigateToTab(3),
                ),
                _DashboardCard(
                  icon: Icons.manage_search_rounded,
                  title: 'Lost & Found',
                  subtitle: 'Report and recover campus items',
                  onTap: () => context.push(AppRoutes.lostFound),
                ),
                _DashboardCard(
                  icon: Icons.groups_rounded,
                  title: 'Study Groups',
                  subtitle: 'Create or join focused sessions',
                  onTap: () => context.push(AppRoutes.studyGroups),
                ),
                _DashboardCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Assistant',
                  subtitle: 'Get quick answers and summaries',
                  onTap: () => context.push(AppRoutes.aiChat),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.dividerColor),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
