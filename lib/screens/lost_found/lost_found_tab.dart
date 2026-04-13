import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'post_lost_item_screen.dart';
import 'item_detail_screen.dart';

class LostFoundTab extends StatefulWidget {
  const LostFoundTab({super.key});

  @override
  State<LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends State<LostFoundTab> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Lost',
    'Found',
    'Electronics',
    'Documents',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.teal,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D9488),
                      Color(0xFF0F766E),
                      Color(0xFF115E59),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.manage_search_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lost & Found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Report and recover items on campus.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatBox(
                        '12',
                        'Lost',
                        AppTheme.coral,
                        const Color(0xFFFEE2E2),
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        '8',
                        'Found',
                        AppTheme.emerald,
                        const Color(0xFFD1FAE5),
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        '4',
                        'Pending',
                        AppTheme.primary,
                        const Color(0xFFEEF2FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search lost items...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0D9488),
                                        Color(0xFF0F766E),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Center(
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildItemCard(
                  context,
                  title: 'MacBook Pro Charger',
                  description: 'Left in Library Room 204, near window seats.',
                  location: 'Central Library',
                  time: '2h ago',
                  status: 'Lost',
                  statusColor: AppTheme.coral,
                  itemIcon: Icons.power_rounded,
                  poster: 'Sarah Miller',
                ),
                const SizedBox(height: 14),
                _buildItemCard(
                  context,
                  title: 'Student ID Card',
                  description: 'Found near cafeteria entrance. Blue lanyard.',
                  location: 'Student Cafeteria',
                  time: '5h ago',
                  status: 'Found',
                  statusColor: AppTheme.emerald,
                  itemIcon: Icons.badge_rounded,
                  poster: 'Jamie Chen',
                ),
                const SizedBox(height: 14),
                _buildItemCard(
                  context,
                  title: 'Black Umbrella',
                  description:
                      'Compact with wooden handle. Left in Lecture Hall B.',
                  location: 'Lecture Hall B',
                  time: 'Yesterday',
                  status: 'Lost',
                  statusColor: AppTheme.coral,
                  itemIcon: Icons.umbrella_rounded,
                  poster: 'Marcus Wright',
                ),
                const SizedBox(height: 14),
                _buildItemCard(
                  context,
                  title: 'Wireless Earbuds Case',
                  description:
                      'White AirPods case on bench outside Engineering.',
                  location: 'Engineering Block',
                  time: 'Yesterday',
                  status: 'Found',
                  statusColor: AppTheme.emerald,
                  itemIcon: Icons.headphones_rounded,
                  poster: 'Aisha Lindholm',
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostLostItemScreen()),
        ),
        backgroundColor: AppTheme.coral,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String count,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context, {
    required String title,
    required String description,
    required String location,
    required String time,
    required String status,
    required Color statusColor,
    required IconData itemIcon,
    required String poster,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              title: title,
              description: description,
              location: location,
              time: time,
              status: status,
              statusColor: statusColor,
              imageUrl: '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon placeholder instead of network image
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    statusColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  itemIcon,
                  size: 40,
                  color: statusColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        avatarWidget(poster, radius: 10),
                        const SizedBox(width: 6),
                        Text(
                          poster,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
