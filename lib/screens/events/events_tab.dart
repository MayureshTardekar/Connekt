import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'post_event_screen.dart';

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF59E0B),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Stack(
                  children: [
                    Positioned(right: -20, bottom: -20, child: Icon(Icons.celebration_rounded, size: 160, color: Colors.white.withValues(alpha: 0.08))),
                    Positioned(
                      left: 24, right: 24, bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Campus Events', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text('Don\'t miss out on what\'s happening.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
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
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final dates = ['12', '13', '14', '15', '16', '17', '18'];
                    final isSelected = _selectedDay == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]) : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : AppTheme.softShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(days[index], style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(dates[index], style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('Upcoming', style: Theme.of(context).textTheme.titleLarge))),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEventCard(context, title: 'Annual Hackathon 2026', description: '24-hour coding marathon. Build something amazing.', location: 'Main Auditorium', time: '09:00 AM - 08:00 PM', gradientColors: const [Color(0xFF7C3AED), Color(0xFF5B21B6)], icon: Icons.computer_rounded, attendees: 148, isLive: true),
                const SizedBox(height: 16),
                _buildEventCard(context, title: 'Career Fair & Networking', description: 'Meet top recruiters from leading tech companies.', location: 'Student Center', time: '11:00 AM - 03:00 PM', gradientColors: const [Color(0xFF0D9488), Color(0xFF0F766E)], icon: Icons.business_center_rounded, attendees: 89, isLive: false),
                const SizedBox(height: 16),
                _buildEventCard(context, title: 'Open Mic Night', description: 'Music, poetry, comedy — anything goes!', location: 'Campus Amphitheatre', time: '06:00 PM - 09:00 PM', gradientColors: const [Color(0xFFF43F5E), Color(0xFFE11D48)], icon: Icons.mic_rounded, attendees: 67, isLive: false),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostEventScreen())),
        backgroundColor: const Color(0xFFF59E0B), elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, {
    required String title, required String description, required String location,
    required String time, required List<Color> gradientColors, required IconData icon,
    required int attendees, required bool isLive,
  }) {
    final attendeeNames = ['Alex', 'Jordan', 'Aisha'];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: AppTheme.softShadow),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
            child: Stack(
              children: [
                Positioned(right: -20, bottom: -20, child: Icon(icon, size: 100, color: Colors.white.withValues(alpha: 0.1))),
                Center(child: Icon(icon, size: 44, color: Colors.white)),
                if (isLive)
                  Positioned(top: 12, right: 12, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppTheme.coral, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 6, color: Colors.white), SizedBox(width: 4), Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))]),
                  )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                const SizedBox(height: 14),
                Row(children: [_buildInfoChip(Icons.location_on_rounded, location), const SizedBox(width: 10), _buildInfoChip(Icons.access_time_rounded, time)]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 60, height: 24,
                      child: Stack(
                        children: List.generate(3, (i) => Positioned(left: i * 16.0, child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: avatarWidget(attendeeNames[i], radius: 11)))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$attendees attending', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors), borderRadius: BorderRadius.circular(10)),
                      child: const Text('RSVP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
