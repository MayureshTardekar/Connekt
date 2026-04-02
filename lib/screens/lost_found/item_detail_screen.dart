import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import '../chat/chat_detail_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final String time;
  final String status;
  final Color statusColor;
  final String imageUrl;

  const ItemDetailScreen({super.key, required this.title, required this.description, required this.location, required this.time, required this.status, required this.statusColor, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: statusColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Center(
                  child: Icon(
                    status == 'Lost' ? Icons.search_off_rounded : Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
                  const SizedBox(height: 16),

                  // Description card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Description', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.6)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Location card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.location_on_rounded, color: AppTheme.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Location', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(location, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Posted by card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
                    child: Row(children: [
                      avatarWidget('Sarah Miller', radius: 24),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Posted by', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Sarah Miller', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetailScreen(userName: 'Sarah Miller', userInitial: 'SM', avatarColor: AppTheme.primary)));
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                      label: const Text('Contact via Chat'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (status == 'Lost')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('Mark as Found'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.emerald, side: const BorderSide(color: AppTheme.emerald, width: 2), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
