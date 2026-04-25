import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/lost_item.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/avatar_helper.dart';

class LostFoundTab extends ConsumerStatefulWidget {
  const LostFoundTab({super.key});

  @override
  ConsumerState<LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends ConsumerState<LostFoundTab> {
  int _selectedFilter = 0;
  String _selectedCategory = 'Smart';
  final List<String> _filters = ['Lost', 'Found', 'My Reports'];
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Smart', 'icon': Icons.auto_awesome_rounded},
    {'name': 'Electronics', 'icon': Icons.smartphone_rounded},
    {'name': 'IDs', 'icon': Icons.badge_rounded},
    {'name': 'Keys', 'icon': Icons.key_rounded},
    {'name': 'Pets', 'icon': Icons.pets_rounded},
    {'name': 'Bags', 'icon': Icons.backpack_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lostItems = ref.watch(lostFoundProvider).value ?? [];
    final lostCount = lostItems.where((i) => i.type.toLowerCase() == 'lost' && !i.isResolved).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          gradient: RadialGradient(
            center: const Alignment(0.12, -1.0),
            radius: 1.2,
            colors: [
              const Color(0xFFC49A4C).withValues(alpha: 0.18),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42],
          ),
        ),
        child: Stack(
          children: [
            // Background secondary gradients
            Positioned(
              right: -100,
              top: 100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4C87C4).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(lostFoundProvider),
              color: const Color(0xFFC49A4C),
              backgroundColor: const Color(0xFF1A1A1A),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OBSIDIAN LUXE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3.2,
                                  color: const Color(0xFFC49A4C).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lost & Found',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          _buildNotificationBell(theme),
                        ],
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(child: _buildSearchBar(theme)),
                  SliverToBoxAdapter(child: _buildCategoryList()),
                  SliverToBoxAdapter(child: _buildFilterTabs(lostCount)),
                  
                  ref.watch(lostFoundProvider).when(
                    data: (items) {
                      final currentUserId = ref.read(currentUserProvider)?.id;
                      final filteredItems = items.where((item) {
                        // Filter by Status Tab
                        if (_selectedFilter == 0) return item.type.toLowerCase() == 'lost';
                        if (_selectedFilter == 1) return item.type.toLowerCase() == 'found';
                        if (_selectedFilter == 2) return item.postedBy == currentUserId;
                        return true;
                      }).where((item) {
                        // Filter by Category
                        if (_selectedCategory == 'Smart') return true;
                        // For now we match title/desc since we don't have category field
                        return item.title.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                               item.description.toLowerCase().contains(_selectedCategory.toLowerCase());
                      }).toList();

                      if (filteredItems.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.white24),
                                const SizedBox(height: 16),
                                Text('No items found', style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildModernItemCard(filteredItems[index], theme),
                            childCount: filteredItems.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFC49A4C))),
                    ),
                    error: (err, _) => SliverToBoxAdapter(child: AppErrorState(message: err.toString())),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () => context.push(AppRoutes.lostFoundPost),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC49A4C), Color(0xFFA07C3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC49A4C).withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.black, size: 24),
                SizedBox(width: 8),
                Text(
                  'Report Item',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFFC49A4C).withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Color(0xFFC49A4C), size: 22),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE55C5C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE55C5C).withValues(alpha: 0.8), blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF888888), size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search lost or found items...',
                style: TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC49A4C).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC49A4C).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Color(0xFFC49A4C), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Nearby',
                    style: TextStyle(
                      color: Color(0xFFC49A4C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFC49A4C), Color(0xFF8E6B2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF2A2A2A).withValues(alpha: 0.7),
                  border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFFC49A4C).withValues(alpha: 0.4), blurRadius: 12)]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'],
                      size: 14,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs(int lostCount) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.8) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : theme.dividerColor),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: List.generate(_filters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFC49A4C), Color(0xFF8E6B2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFFC49A4C).withValues(alpha: 0.4), blurRadius: 12)]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        index == 0 ? Icons.search_off_rounded : 
                        index == 1 ? Icons.inventory_2_outlined : Icons.person_outline_rounded,
                        size: 14,
                        color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.grey[600]),
                        ),
                      ),
                      if (index == 0 && lostCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$lostCount',
                            style: const TextStyle(fontSize: 10, color: Colors.black),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildModernItemCard(LostItem item, ThemeData theme) {
    final isLost = item.type.toLowerCase() == 'lost';
    final isMine = item.postedBy == ref.read(currentUserProvider)?.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with image and badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : _buildPlaceholderImage(theme),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Badges
              Positioned(
                left: 12,
                top: 12,
                child: Row(
                  children: [
                    _buildBadge(
                      isLost ? 'LOST' : 'FOUND',
                      isLost ? const Color(0xFFE55C5C) : const Color(0xFF5CE59C),
                    ),
                    const SizedBox(width: 8),
                    if (isMine) _buildBadge('MINE', const Color(0xFFC49A4C)),
                  ],
                ),
              ),
              // Title and Location overlay
              Positioned(
                left: 16,
                bottom: 12,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF888888), size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Content Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        avatarWidget('User', radius: 14),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reported by Student',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatDate(item.createdAt),
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.isResolved)
                      _buildResolvedTag()
                    else
                      const Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: Color(0xFF888888), size: 12),
                          SizedBox(width: 4),
                          Text('Active', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    if (isMine) ...[
                      if (!item.isResolved)
                        Expanded(
                          child: _buildButton(
                            'Resolve',
                            Icons.check_circle_rounded,
                            const Color(0xFF5CE59C),
                            () => _resolveItem(item.id),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.edit_outlined, Colors.white, () {}),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteItem(item.id)),
                    ] else ...[
                      Expanded(
                        child: _buildButton(
                          'Chat to Claim',
                          Icons.message_rounded,
                          const Color(0xFFC49A4C),
                          () => context.push(AppRoutes.lostFoundDetail, extra: item),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.share_outlined, Colors.white, () {}),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4C87C4).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4C87C4).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF4C87C4), size: 12),
          SizedBox(width: 4),
          Text('RESOLVED', style: TextStyle(color: Color(0xFF4C87C4), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Report?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently remove this lost/found report.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(campusRepositoryProvider).deleteLostFoundItem(itemId);
        ref.invalidate(lostFoundProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _resolveItem(String itemId) async {
    try {
      await ref.read(campusRepositoryProvider).resolveLostFoundItem(itemId, true);
      ref.invalidate(lostFoundProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as resolved!'),
            backgroundColor: Color(0xFF5CE59C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.image_outlined, color: Colors.white10, size: 48),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
