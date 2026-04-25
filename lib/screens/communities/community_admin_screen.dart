import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/community_provider.dart';

class CommunityAdminScreen extends ConsumerWidget {
  final String communityId;
  const CommunityAdminScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Admin Controls', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('PENDING REQUESTS'),
            _buildRequestsList(ref),
            const SizedBox(height: 32),
            _buildSectionHeader('MANAGE MEMBERS'),
            _buildMembersList(ref),
            const SizedBox(height: 48),
            _buildDangerZone(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildRequestsList(WidgetRef ref) {
    final repo = ref.read(communityRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.supabase.from('community_requests').select('*, profiles(full_name, avatar_url)').eq('community_id', communityId).eq('status', 'pending'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyBox('No pending requests');
        }
        return Column(
          children: snapshot.data!.map((req) => _buildRequestTile(context, ref, req)).toList(),
        );
      },
    );
  }

  Widget _buildRequestTile(BuildContext context, WidgetRef ref, Map<String, dynamic> req) {
    final profile = req['profiles'] as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null),
          const SizedBox(width: 12),
          Expanded(child: Text(profile['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white))),
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.greenAccent), onPressed: () => ref.read(communityRepositoryProvider).handleRequest(req['id'], true)),
          IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => ref.read(communityRepositoryProvider).handleRequest(req['id'], false)),
        ],
      ),
    );
  }

  Widget _buildMembersList(WidgetRef ref) {
    final repo = ref.read(communityRepositoryProvider);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.supabase.from('community_members').select('*, profiles(full_name, avatar_url)').eq('community_id', communityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return Column(
          children: snapshot.data!.map((member) => _buildMemberTile(context, ref, member)).toList(),
        );
      },
    );
  }

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, Map<String, dynamic> member) {
    final profile = member['profiles'] as Map<String, dynamic>;
    final isMe = member['user_id'] == ref.read(communityRepositoryProvider).supabase.auth.currentUser?.id;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null),
      title: Text(profile['full_name'] ?? 'Member', style: const TextStyle(color: Colors.white)),
      trailing: isMe ? const Text('ADMIN', style: TextStyle(color: Colors.blueAccent, fontSize: 10)) : IconButton(
        icon: const Icon(Icons.person_remove_outlined, color: Colors.white24),
        onPressed: () => ref.read(communityRepositoryProvider).kickMember(communityId, member['user_id']),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danger Zone', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Deleting this community will erase all messages and cannot be undone.', style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // TODO: Implement delete
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Delete Community'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withAlpha(5), borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white24))),
    );
  }
}
