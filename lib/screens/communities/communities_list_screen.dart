import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/community_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunitiesListScreen extends ConsumerWidget {
  final bool isTab;
  const CommunitiesListScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(communitiesProvider);

    Widget content = communitiesAsync.when(
      data: (communities) {
        if (communities.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildCommunityCard(context, ref, community);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );

    if (isTab) return Container(color: Colors.black, child: content);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Campus Communities',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            onPressed: () => context.push('/communities/create'),
          ),
        ],
      ),
      body: communitiesAsync.when(
        data: (communities) {
          if (communities.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _buildCommunityCard(context, ref, community);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, WidgetRef ref, Map<String, dynamic> community) {
    final isPrivate = community['is_private'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
          backgroundImage: community['avatar_url'] != null ? NetworkImage(community['avatar_url']) : null,
          child: community['avatar_url'] == null ? const Icon(Icons.group, color: Colors.blueAccent) : null,
        ),
        title: Text(
          community['name'],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                isPrivate ? Icons.lock_outline : Icons.public,
                size: 14,
                color: Colors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                isPrivate ? 'Private Community' : 'Public Space',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: () async {
          final campusId = community['campus_id'] ?? '';
          
          // Show PIN Entry Dialog
          final pin = await _showPinDialog(context);
          if (pin == null) return;

          final isValid = await ref.read(communityRepositoryProvider).verifyCampusPin(campusId, pin);
          
          if (isValid) {
            ref.read(activeCommunityIdProvider.notifier).state = community['id'];
            if (context.mounted) context.push('/communities/chat/${community['id']}');
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid PIN. Contact your Campus Admin.'), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      ),
    );
  }

  Future<String?> _showPinDialog(BuildContext context) {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Campus Access PIN', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the secret PIN provided by your Campus Admin to unlock this ecosystem.', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '****',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3))),
              ),
              onChanged: (v) => pin = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pin),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'No Communities Yet',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create a space for your campus!',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/communities/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Create Community'),
          ),
        ],
      ),
    );
  }
}
