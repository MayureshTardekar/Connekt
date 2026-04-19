import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/repositories/campus_repository.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/routing/app_routes.dart';
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
    return user?.userMetadata?['display_name'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Student';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final campusMembership = ref.watch(selectedCampusProvider);
    final role = campusMembership?['role'] ?? 'member';
    final isAdmin = role == 'admin' || role == 'owner';
    final campus = campusMembership?['campuses'];
    final bannerUrl = campus?['banner_url'];
    final campusId = campusMembership?['campus_id'] as String?;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // refresh logic if needed
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            _userName(),
                            style: theme.textTheme.displaySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (campus != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => context.push('/campus-select'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    campus['name'] ?? 'Select Campus',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // No Campus Selection Prompt
              if (campus == null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Campus Active',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join or select a campus to see notes, events, and community updates.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.push('/campus-select'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: theme.colorScheme.primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Select Campus',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Spotlight Carousel
                _SpotlightCarousel(bannerUrl: bannerUrl),

              if (isAdmin) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(
                        AppRoutes
                            .campusManagement, // We'll add this route or just use direct push
                        extra: {
                          'campusId': campusMembership?['campus_id'],
                          'campusName': campus?['name'] ?? 'Campus',
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Campus Management',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Manage members and banners',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Discovery Quick Actions — grelha 2×2 + expandir
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Discover',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _DiscoverQuickGrid(
                      theme: theme,
                      onNotes: () => context
                          .findAncestorStateOfType<MainScreenState>()
                          ?.navigateToTab(1),
                      onEvents: () => context
                          .findAncestorStateOfType<MainScreenState>()
                          ?.navigateToTab(2),
                      onChat: () => context
                          .findAncestorStateOfType<MainScreenState>()
                          ?.navigateToTab(3),
                      onLostFound: () => context.push(AppRoutes.lostFound),
                      onStudy: () => context.push(AppRoutes.studyGroups),
                      onAi: () => context.push(AppRoutes.aiChat),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Campus Feed (Insta-Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text('Campus Feed', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: CampusRepository().getRecentActivityStream(
                  campusId: campusId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final activities = snapshot.data ?? [];
                  if (activities.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 48,
                            color: theme.dividerColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nothing new yet. Be the first to post!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return _PostCard(activity: activities[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverQuickGrid extends StatefulWidget {
  const _DiscoverQuickGrid({
    required this.theme,
    required this.onNotes,
    required this.onEvents,
    required this.onChat,
    required this.onLostFound,
    required this.onStudy,
    required this.onAi,
  });

  final ThemeData theme;
  final VoidCallback? onNotes;
  final VoidCallback? onEvents;
  final VoidCallback? onChat;
  final VoidCallback? onLostFound;
  final VoidCallback? onStudy;
  final VoidCallback? onAi;

  @override
  State<_DiscoverQuickGrid> createState() => _DiscoverQuickGridState();
}

class _DiscoverQuickGridState extends State<_DiscoverQuickGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final specs = <_QuickGridSpec>[
      _QuickGridSpec(
        Icons.auto_stories_rounded,
        'Notes',
        Colors.blue,
        widget.onNotes,
      ),
      _QuickGridSpec(
        Icons.event_rounded,
        'Events',
        Colors.orange,
        widget.onEvents,
      ),
      _QuickGridSpec(Icons.forum_rounded, 'Chat', Colors.teal, widget.onChat),
      _QuickGridSpec(
        Icons.manage_search_rounded,
        'Lost & Found',
        Colors.deepPurple,
        widget.onLostFound,
      ),
      _QuickGridSpec(
        Icons.groups_rounded,
        'Study',
        Colors.pink,
        widget.onStudy,
      ),
      _QuickGridSpec(
        Icons.auto_awesome_rounded,
        'AI Chat',
        Colors.amber,
        widget.onAi,
      ),
    ];

    final visible = _expanded ? specs : specs.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1.22,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              padding: EdgeInsets.zero,
              children: visible
                  .map(
                    (s) => _DiscoverCompactTile(
                      theme: widget.theme,
                      icon: s.icon,
                      label: s.label,
                      color: s.color,
                      onTap: s.onTap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show Less' : 'Show More'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickGridSpec {
  const _QuickGridSpec(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
}

/// Compact Discover chip (~≤120px tall depending on grid); small icon + label.
class _DiscoverCompactTile extends StatelessWidget {
  const _DiscoverCompactTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: theme.shadowColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightCarousel extends StatefulWidget {
  final String? bannerUrl;
  const _SpotlightCarousel({this.bannerUrl});

  @override
  State<_SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<_SpotlightCarousel> {
  final PageController _controller = PageController(viewportFraction: 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Prepare slides: Priority to custom banner, then defaults
    final List<Map<String, String>> slides = [];
    if (widget.bannerUrl != null && widget.bannerUrl!.isNotEmpty) {
      slides.add({
        'image': widget.bannerUrl!,
        'title': 'Campus Spotlight',
        'subtitle': 'Official update from your campus admin.',
      });
    }

    if (slides.isEmpty) {
      slides.add({
        'image':
            'https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=1200', // Premium University theme
        'title': 'Welcome to Connekt',
        'subtitle': 'The premium social hub for your campus life.',
      });
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double value = 1.0;
                  if (_controller.position.hasContentDimensions) {
                    value = _controller.page! - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeInOut.transform(value) * 200,
                      width: MediaQuery.of(context).size.width,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(slide['image']!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.shadow.withValues(alpha: 0.45),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SPOTLIGHT',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide['title']!,
                          style: TextStyle(
                            color: theme.brightness == Brightness.light
                                ? theme.colorScheme.surface
                                : theme.colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          slide['subtitle']!,
                          style: TextStyle(
                            color: theme.brightness == Brightness.light
                                ? theme.colorScheme.surface.withValues(alpha: 0.92)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> activity;

  const _PostCard({required this.activity});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool? _isLiked;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final liked = await ref
        .read(campusRepositoryProvider)
        .hasLiked(
          widget.activity['id']?.toString() ?? '',
          widget.activity['type'] ?? 'note',
        );
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _handleLike() async {
    final activityId = widget.activity['id']?.toString() ?? '';
    final type = widget.activity['type'] ?? 'note';

    // Optimistic Update
    final previousState = _isLiked;
    setState(() {
      _isLiked = !(_isLiked ?? false);
    });

    try {
      await ref.read(campusRepositoryProvider).toggleLike(activityId, type);
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = previousState;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStr = TimeFormatter.format(widget.activity['created_at']);
    final liked = _isLiked ?? false;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    (widget.activity['title'] as String?)?[0] ?? 'C',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAuthorName(widget.activity),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.activity['type'] == 'note' ? 'Notes' : 'Event',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post Media
          AspectRatio(
            aspectRatio: 1.1,
            child: Container(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              child: Image.network(
                _getImageUrl(widget.activity),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    widget.activity['type'] == 'note'
                        ? Icons.description_outlined
                        : Icons.celebration_outlined,
                    size: 48,
                    color: theme.dividerColor,
                  ),
                ),
              ),
            ),
          ),

          // Post Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleLike,
                  icon: Icon(
                    liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: liked ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: '${_getAuthorName(widget.activity)} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '${widget.activity['title']}'),
                    ],
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.activity['subtitle'] ?? '',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAuthorName(Map<String, dynamic> activity) {
    return activity['author'] ?? 'Campus Member';
  }

  String _getImageUrl(Map<String, dynamic> activity) {
    if (activity['type'] == 'event' && activity['image_url'] != null) {
      return activity['image_url'];
    }
    if (activity['type'] == 'note') {
      return 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=800';
    }
    if (activity['type'] == 'lost_item') {
      return 'https://images.unsplash.com/photo-1540324155974-7523202daa3f?q=80&w=800';
    }
    return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800';
  }
}
