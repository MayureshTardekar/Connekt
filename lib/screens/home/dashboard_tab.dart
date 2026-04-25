import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/providers/auth_provider.dart';
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
    final raw = user?.userMetadata?['display_name'] ??
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@').first ??
        'Student';
    return raw.toString().trim().split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campusMembership = ref.watch(selectedCampusProvider);
    final isAdmin = ref.watch(isCampusCreatorProvider);
    final campus = campusMembership?['campuses'];
    final bannerUrl = campus?['banner_url'];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentActivityProvider);
                ref.invalidate(campusEventsProvider);
                ref.invalidate(academicNotesProvider);
                ref.invalidate(totalAppUsersProvider);
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
                    Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(
                            _userName(),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 30,
                              height: 1.05,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (campus != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              color: theme.colorScheme.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (campus['name'] as String? ?? 'Campus').toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      child: Row(
                        children: [
                          Text(
                            'Discover',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Campus Feed', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Post to campus feed',
                          onPressed: () => context.push(AppRoutes.campusFeed),
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.campusFeed),
                          child: const Text('View all', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _PostCard(activity: activities[index]);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              
              // Quick Stats Section
              _buildQuickStats(context, theme),
              const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.colorScheme.surface : theme.colorScheme.surface;
    
    // Dynamic fetching of stats
    final eventsCount = ref.watch(campusEventsProvider).value?.length ?? 0;
    final notesCount = ref.watch(academicNotesProvider).value?.length ?? 0;
    
    // Fetch actual members count
    final activeUsersCountRaw = ref.watch(totalAppUsersProvider).value ?? 0;
    final activeUsersStr = activeUsersCountRaw > 999 
        ? '${(activeUsersCountRaw / 1000).toStringAsFixed(1)}K' 
        : activeUsersCountRaw.toString();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Stats', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(theme, cardColor, Icons.people_outline_rounded, activeUsersStr, 'Active Users', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(theme, cardColor, Icons.calendar_today_rounded, eventsCount.toString(), 'Events', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(theme, cardColor, Icons.description_outlined, notesCount.toString(), 'Notes', Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, Color bgColor, IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14), // Reduced padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.light 
              ? theme.dividerColor.withValues(alpha: 0.8) 
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.brightness == Brightness.light 
                  ? const Color(0xFF111827) 
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.light 
                  ? const Color(0xFF6B7280) 
                  : Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
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
    final isDark = widget.theme.brightness == Brightness.dark;
    final cardColor = isDark ? widget.theme.colorScheme.surface : widget.theme.colorScheme.surface;

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.menu_book_rounded, 'label': 'Notes', 'color': const Color(0xFF3B82F6), 'onTap': widget.onNotes},
      {'icon': Icons.calendar_today_rounded, 'label': 'Events', 'color': const Color(0xFF10B981), 'onTap': widget.onEvents},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Chat', 'color': const Color(0xFFF59E0B), 'onTap': widget.onChat},
      {'icon': Icons.search_rounded, 'label': 'Lost', 'color': const Color(0xFF8B5CF6), 'onTap': widget.onLostFound},
      {'icon': Icons.people_outline_rounded, 'label': 'Clubs', 'color': const Color(0xFFEC4899), 'onTap': widget.onStudy},
      {'icon': Icons.auto_awesome_rounded, 'label': 'AI Chat', 'color': const Color(0xFFF59E0B), 'onTap': widget.onAi},
    ];

    final visibleItems = _expanded ? items : items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: visibleItems
              .map(
                (item) => _buildIcon(
                  cardColor,
                  item['icon'],
                  item['label'],
                  item['color'],
                  item['onTap'],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show Less ▲' : 'Show More ▼', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(Color bgColor, IconData icon, String label, Color iconColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.theme.brightness == Brightness.light 
                    ? widget.theme.dividerColor.withValues(alpha: 0.8) 
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: widget.theme.brightness == Brightness.light ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.theme.textTheme.labelSmall?.copyWith(color: widget.theme.textTheme.bodySmall?.color, fontSize: 11),
          ),
        ],
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
            'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=800', // Premium University theme
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(slide['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          slide['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
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
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.activity['likes_count'] ?? 0;
    _checkLikeStatus();
    _fetchLikesCount();
  }

  Future<void> _fetchLikesCount() async {
    final activityId = widget.activity['id']?.toString() ?? '';
    final type = widget.activity['type'] ?? 'note';
    final count = await ref.read(campusRepositoryProvider).getLikesCount(activityId, type);
    if (mounted) {
      setState(() => _likesCount = count);
    }
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
    final previousCount = _likesCount;
    
    setState(() {
      _isLiked = !(_isLiked ?? false);
      _likesCount += (_isLiked! ? 1 : -1);
    });

    try {
      await ref.read(campusRepositoryProvider).toggleLike(activityId, type);
      // Force refresh the activity feed to get the latest DB counts
      ref.invalidate(recentActivityProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = previousState;
          _likesCount = previousCount;
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
    final type = widget.activity['type'] as String;
    final status = widget.activity['status']?.toString();
    final isFound = status?.toLowerCase() == 'found';
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthor = widget.activity['author_id'] == user?.id;
    final isAdmin = ref.watch(isCampusCreatorProvider);

    // Show actual likes from DB, mock others as requested for UI display
    final likesCount = _likesCount;
    final commentsCount = 0;
    final sharesCount = 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
          ? theme.colorScheme.surface.withValues(alpha: 0.85) 
          : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : theme.colorScheme.primary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withValues(alpha: 0.2) 
              : theme.colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                if (isAuthor || isAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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

            const SizedBox(height: 16),
            // Content
            Text(
              widget.activity['title'] ?? widget.activity['caption'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            
            if (widget.activity['location'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(widget.activity['location'], style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            
            if (isFound)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('FOUND', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),

            const SizedBox(height: 16),
            // Actions Footer
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  _buildActionIcon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                    likesCount.toString(), 
                    liked ? Colors.redAccent : theme.colorScheme.onSurface.withValues(alpha: 0.5), 
                    onTap: _handleLike,
                    isActive: liked,
                  ),
                  const SizedBox(width: 24),
                  _buildActionIcon(Icons.chat_bubble_outline_rounded, commentsCount.toString(), theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 24),
                  _buildActionIcon(Icons.share_outlined, sharesCount.toString(), theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String count, Color color, {VoidCallback? onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              count, 
              style: TextStyle(
                color: color.withValues(alpha: 0.9), 
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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
          if (type == 'note') { await repo.deleteNote(activityId); }
          else if (type == 'event') { await repo.deleteEvent(activityId); }
          else if (type == 'lost_found') { await repo.deleteLostFoundItem(activityId); }
          else if (type == 'feed_post') { await repo.deleteFeedPost(activityId); }
          ref.invalidate(recentActivityProvider);
        } catch (e) {
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
        }
      }
    } else if (action == 'mark_found') {
      try {
        await ref.read(campusRepositoryProvider).markItemAsFound(activityId);
        ref.invalidate(recentActivityProvider);
      } catch (e) {
        if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
      }
    }
  }


  String _getAuthorName(Map<String, dynamic> activity) {
    return activity['author_name'] ?? activity['author'] ?? 'Campus Member';
  }
}
