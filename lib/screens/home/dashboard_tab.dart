import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/repositories/campus_repository.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/routing/app_routes.dart';
import '../main_screen.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final o = _scrollController.offset;
    if ((o - _scrollOffset).abs() > 0.5) {
      setState(() => _scrollOffset = o);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campusMembership = ref.watch(selectedCampusProvider);
    final isAdmin = ref.watch(isCampusCreatorProvider);
    final campus = campusMembership?['campuses'];
    final bannerUrl = campus?['banner_url'];
    final campusId = campusMembership?['campus_id'] as String?;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -30,
              top: 40 - _scrollOffset * 0.14,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.11),
                          theme.colorScheme.primary.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: 280 - _scrollOffset * 0.09,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.tertiary.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                // refresh logic if needed
              },
              child: ListView(
                controller: _scrollController,
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

              ref.watch(recentActivityProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(child: Text('Error loading feed: $error')),
                ),
                data: (activities) {
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
          ],
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
    final isDark = theme.brightness == Brightness.dark;
    final shadowA = Colors.black.withValues(alpha: isDark ? 0.28 : 0.07);
    final shadowB = Colors.black.withValues(alpha: isDark ? 0.16 : 0.04);
    final borderGlass = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.85);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: isDark ? 0.42 : 0.55),
                      theme.colorScheme.surface.withValues(alpha: isDark ? 0.28 : 0.42),
                    ],
                  ),
                  border: Border.all(
                    color: borderGlass,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowA,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: shadowB,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(icon, color: color, size: 21),
                      ),
                      const SizedBox(height: 3),
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
            ),
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
    final liked = await ref.read(campusRepositoryProvider).hasLiked(
          widget.activity['id']?.toString() ?? '',
          widget.activity['type'] ?? 'note',
        );
    if (mounted) {
      setState(() => _isLiked = liked);
    }
  }

  Future<void> _handleLike() async {
    final activityId = widget.activity['id']?.toString() ?? '';
    final type = widget.activity['type'] ?? 'note';
    final previousState = _isLiked;
    
    setState(() => _isLiked = !(_isLiked ?? false));

    try {
      await ref.read(campusRepositoryProvider).toggleLike(activityId, type);
    } catch (e) {
      if (mounted) setState(() => _isLiked = previousState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStr = TimeFormatter.format(widget.activity['created_at']);
    final liked = _isLiked ?? false;
    final type = widget.activity['type'] as String;
    final status = widget.activity['status']?.toString();
    final isFound = status?.toLowerCase() == 'found';
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthor = widget.activity['author_id'] == user?.id;
    final isAdmin = ref.watch(isCampusCreatorProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: widget.activity['author_avatar'] != null 
                    ? NetworkImage(widget.activity['author_avatar']) : null,
                  child: widget.activity['author_avatar'] == null 
                    ? Text(_getAuthorName(widget.activity)[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAuthorName(widget.activity),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getTypeLabel(type),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isAuthor || isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) => _handleMenuAction(val, context),
                    itemBuilder: (context) => [
                      if (type == 'lost_found' && !isFound && isAuthor)
                        const PopupMenuItem(value: 'mark_found', child: Text('Mark as Found')),
                      const PopupMenuItem(
                        value: 'delete', 
                        child: Text('Delete Post', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Media
          AspectRatio(
            aspectRatio: 1.1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _getImageUrl(widget.activity),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(_getTypeIcon(type), size: 48, color: theme.dividerColor),
                  ),
                ),
                if (isFound)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                        child: const Text('FOUND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              IconButton(
                onPressed: _handleLike,
                icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? Colors.red : null),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ),
            ],
          ),

          // Caption/Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(text: '${_getAuthorName(widget.activity)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: widget.activity['title'] ?? widget.activity['caption'] ?? ''),
                    ],
                  ),
                ),
                if (widget.activity['location'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(widget.activity['location'], style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'note': return 'Academic Note';
      case 'event': return 'Campus Event';
      case 'lost_found': return 'Lost & Found';
      case 'feed_post': return 'Campus Feed';
      default: return 'Update';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'note': return Icons.description_outlined;
      case 'event': return Icons.celebration_outlined;
      case 'lost_found': return Icons.manage_search_outlined;
      case 'feed_post': return Icons.auto_awesome_mosaic_outlined;
      default: return Icons.feed_outlined;
    }
  }

  void _handleMenuAction(String action, BuildContext context) async {
    final activityId = widget.activity['id']?.toString() ?? '';
    final type = widget.activity['type'] ?? '';

    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (confirm == true) {
        try {
          final repo = ref.read(campusRepositoryProvider);
          if (type == 'note') await repo.deleteNote(activityId);
          else if (type == 'event') await repo.deleteEvent(activityId);
          else if (type == 'lost_found') await repo.deleteLostFoundItem(activityId);
          else if (type == 'feed_post') await repo.deleteFeedPost(activityId);
          ref.invalidate(recentActivityProvider);
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else if (action == 'mark_found') {
      try {
        await ref.read(campusRepositoryProvider).markItemAsFound(activityId);
        ref.invalidate(recentActivityProvider);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getImageUrl(Map<String, dynamic> activity) {
    if (activity['image_url'] != null && activity['image_url'].toString().isNotEmpty) {
      return activity['image_url'];
    }
    final type = activity['type'] as String;
    if (type == 'note') return 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=800';
    if (type == 'lost_found') return 'https://images.unsplash.com/photo-1540324155974-7523202daa3f?q=80&w=800';
    if (type == 'event') return 'https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=800';
    return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800';
  }

  String _getAuthorName(Map<String, dynamic> activity) {
    return activity['author_name'] ?? activity['author'] ?? 'Campus Member';
  }
}
