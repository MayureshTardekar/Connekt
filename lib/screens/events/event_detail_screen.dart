import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/campus_event.dart';
import '../../core/providers/campus_provider.dart';
import '../../theme/app_theme.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});

  final CampusEvent event;

  List<Color> get _gradientColors {
    switch (event.category.toLowerCase()) {
      case 'workshop':
        return const [Color(0xFF2563EB), Color(0xFF1D4ED8)];
      case 'fest':
        return const [Color(0xFFF43F5E), Color(0xFFE11D48)];
      case 'sports':
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case 'seminar':
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case 'social':
        return const [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
      default:
        return const [Color(0xFF0EA5E9), Color(0xFF0284C7)];
    }
  }

  IconData get _icon {
    switch (event.category.toLowerCase()) {
      case 'workshop':
        return Icons.build_rounded;
      case 'fest':
        return Icons.celebration_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'seminar':
        return Icons.school_rounded;
      case 'social':
        return Icons.groups_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String get _timeLabel =>
      DateFormat('EEEE, dd MMM yyyy • h:mm a').format(event.dateTime);

  Future<void> _deleteEvent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This action cannot be undone. All attendees will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(campusRepositoryProvider).deleteEvent(event.id);
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = _gradientColors.first;
    final isDark = theme.brightness == Brightness.dark;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isOrganizer = event.organizerId == userId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: accent,
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
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isOrganizer)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => _deleteEvent(context, ref),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradientColors,
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
                        _icon,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Center(child: Icon(_icon, size: 80, color: Colors.white)),
                  ],
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _EventInfoCard(
                    color: theme.colorScheme.surface,
                    showShadow: !isDark,
                    child: Column(
                      children: [
                        _EventMetaRow(
                          icon: Icons.calendar_month_rounded,
                          label: 'When',
                          value: _timeLabel,
                          accent: accent,
                        ),
                        const SizedBox(height: 16),
                        _EventMetaRow(
                          icon: Icons.location_on_rounded,
                          label: 'Where',
                          value: event.location,
                          accent: accent,
                        ),
                        const SizedBox(height: 16),
                        _EventMetaRow(
                          icon: Icons.campaign_rounded,
                          label: 'Organizer',
                          value: event.organizer,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EventInfoCard(
                    color: theme.colorScheme.surface,
                    showShadow: !isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this event',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          event.description.isNotEmpty
                              ? event.description
                              : 'No description was provided for this event.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EventInfoCard(
                    color: theme.colorScheme.surface,
                    showShadow: !isDark,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.group_rounded, color: accent),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.attendees > 0
                                    ? '${event.attendees} confirmed'
                                    : 'No confirmed attendees yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final summary = [
                          event.title,
                          _timeLabel,
                          event.location,
                          if (event.description.isNotEmpty) event.description,
                        ].join('\n');
                        await Clipboard.setData(ClipboardData(text: summary));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event details copied.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Event Details'),
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

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({
    required this.child,
    required this.color,
    required this.showShadow,
  });

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
      child: child,
    );
  }
}

class _EventMetaRow extends StatelessWidget {
  const _EventMetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
