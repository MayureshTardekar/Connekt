import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/lost_item.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/ai_prompts.dart';
import '../../theme/app_theme.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  final LostItem item;

  bool get _isLost => item.type.toLowerCase() == 'lost';

  bool get _hasImage =>
      item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;

  bool get _hasContact => item.contactInfo.trim().isNotEmpty;

  String get _statusLabel {
    if (item.isResolved) {
      return 'Resolved';
    }
    return _isLost ? 'Lost' : 'Found';
  }

  Color get _statusColor {
    if (item.isResolved) {
      return AppTheme.emerald;
    }
    return _isLost ? Colors.red : Colors.green;
  }

  String get _timeLabel => DateFormat('dd MMM, h:mm a').format(item.createdAt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _statusColor,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderArtwork(
                item: item,
                statusColor: _statusColor,
                isLost: _isLost,
                hasImage: _hasImage,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ) ??
                            const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Description',
                    child: Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    color: cardColor,
                    showShadow: !isDark,
                  ),
                  const SizedBox(height: 16),
                  if (_isLost)
                    GestureDetector(
                      onTap: () => context.push(
                        AppRoutes.aiChat,
                        extra: AIPrompts.lostItemTips(item.title),
                      ),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.teal,
                              AppTheme.teal.withValues(alpha: 0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.travel_explore_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need help finding this?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Get AI suggestions for places to check on campus.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  _InfoCard(
                    title: 'Location',
                    color: cardColor,
                    showShadow: !isDark,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.location,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Contact Info',
                    color: cardColor,
                    showShadow: !isDark,
                    child: Text(
                      _hasContact ? item.contactInfo : 'No contact info provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _hasContact
                            ? theme.colorScheme.onSurface
                            : AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasContact
                          ? () async {
                              await Clipboard.setData(
                                ClipboardData(text: item.contactInfo),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact info copied.'),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(
                        _hasContact
                            ? 'Copy Contact Info'
                            : 'No Contact Info Available',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            theme.disabledColor.withValues(alpha: 0.2),
                        disabledForegroundColor:
                            theme.disabledColor.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderArtwork extends StatelessWidget {
  const _HeaderArtwork({
    required this.item,
    required this.statusColor,
    required this.isLost,
    required this.hasImage,
  });

  final LostItem item;
  final Color statusColor;
  final bool isLost;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    if (hasImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _HeaderPlaceholder(
              statusColor: statusColor,
              isLost: isLost,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.42),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      );
    }

    return _HeaderPlaceholder(statusColor: statusColor, isLost: isLost);
  }
}

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder({
    required this.statusColor,
    required this.isLost,
  });

  final Color statusColor;
  final bool isLost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.9),
            statusColor.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isLost ? Icons.search_off_rounded : Icons.check_circle_rounded,
          size: 100,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    required this.color,
    required this.showShadow,
  });

  final String title;
  final Widget child;
  final Color color;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: showShadow ? AppTheme.softShadow : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
