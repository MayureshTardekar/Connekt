import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PostEventScreen extends StatelessWidget {
  const PostEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.softShadow),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post Event', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Column(
                children: [
                  Icon(Icons.celebration_rounded, size: 44, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Create Campus Event', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Share what\'s happening', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Event Title', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(decoration: const InputDecoration(hintText: 'e.g., Annual Hackathon 2026', prefixIcon: Icon(Icons.title_rounded, size: 20, color: AppTheme.textSecondary))),
            const SizedBox(height: 22),

            Text('Description', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What\'s the event about?',
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 22),

            Text('Date & Time', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Date', prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textSecondary)),
                    onTap: () => showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'Time', prefixIcon: Icon(Icons.access_time_rounded, size: 18, color: AppTheme.textSecondary)),
                    onTap: () => showTimePicker(context: context, initialTime: TimeOfDay.now()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            Text('Location', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(decoration: const InputDecoration(hintText: 'e.g., Main Auditorium', prefixIcon: Icon(Icons.location_on_rounded, size: 20, color: AppTheme.textSecondary))),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.event_available_rounded, size: 20),
                label: const Text('Post Event'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
