import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/campus_event.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class EventsTab extends ConsumerStatefulWidget {
  const EventsTab({super.key});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  int _selectedDayIndex = 0;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(campusEventsProvider);

    return eventsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(campusEventsProvider),
          ),
        ),
      ),
      data: (events) {
        final categories = <String>{
          'All',
          ...events
              .map((event) => event.category.trim())
              .where((it) => it.isNotEmpty),
        }.toList();
        final effectiveCategory = categories.contains(_selectedCategory)
            ? _selectedCategory
            : 'All';
        final today = DateTime.now();
        final selectedDate = DateTime(
          today.year,
          today.month,
          today.day,
        ).add(Duration(days: _selectedDayIndex));

        final filteredEvents = events.where((event) {
          final eventDate = DateTime(
            event.dateTime.year,
            event.dateTime.month,
            event.dateTime.day,
          );
          final matchesDay = eventDate == selectedDate;
          final matchesCategory =
              effectiveCategory == 'All' || event.category == effectiveCategory;
          return matchesDay && matchesCategory;
        }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              // Event Content
              AnimationLimiter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
                  children: [
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Featured Events',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Discover Campus',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (context, index) {
                          final date = DateTime.now().add(Duration(days: index));
                          final isSelected = _selectedDayIndex == index;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDayIndex = index);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 74,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(date),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: 7,
                      ),
                    ),
                    if (categories.length > 1) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = effectiveCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              labelStyle: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: categories.length,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      '${filteredEvents.length} events',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    if (filteredEvents.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          'No events are scheduled for this selection.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    else
                      ...filteredEvents.map(_buildEventCard),
                  ],
                ),
              ),
              // Glassmorphic Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        bottom: 12,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Campus Events',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton.filled(
                            onPressed: () => context.push(AppRoutes.eventPost),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildEventCard(CampusEvent event) {
    final theme = Theme.of(context);
    final accent = _categoryColor(event.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.push(AppRoutes.eventDetail, extra: event),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('h:mm a').format(event.dateTime),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
              if (event.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  avatarWidget(event.organizer, radius: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.attendees > 0
                          ? '${event.attendees} confirmed'
                          : 'Hosted by ${event.organizer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.organizerId == ref.read(currentUserProvider)?.id)
                    IconButton(
                      onPressed: () => _deleteEvent(event.id),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.eventDetail, extra: event),
                      child: const Text('Open'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This will permanently remove the event.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(campusRepositoryProvider).deleteEvent(eventId);
        ref.invalidate(campusEventsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workshop':
        return const Color(0xFF2563EB);
      case 'fest':
        return const Color(0xFFE11D48);
      case 'sports':
        return const Color(0xFF059669);
      case 'seminar':
        return const Color(0xFFD97706);
      case 'social':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.primary;
    }
  }
}
