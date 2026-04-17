import 'package:supabase_flutter/supabase_flutter.dart';

class StudyGroupsRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  // Fetch all groups for the current campus
  Stream<List<Map<String, dynamic>>> getGroupsStream(String campusId) {
    return _supabase
        .from('study_groups')
        .stream(primaryKey: ['id'])
        .eq('campus_id', campusId)
        .order('created_at', ascending: false);
  }

  // Request to join a group
  Future<void> requestToJoin(String groupId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Check if already requested or member
    final existing = await _supabase
        .from('study_group_members')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Request already sent or already a member.');
    }

    await _supabase.from('study_group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'status': 'pending',
    });
  }

  // Approve a member (Owner only)
  Future<void> approveMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .update({'status': 'approved'})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Kick a member or Reject request
  Future<void> removeMember(String groupId, String userId) async {
    await _supabase
        .from('study_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Check membership status
  Future<String?> getMembershipStatus(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('study_group_members')
        .select('status')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return data?['status'];
  }
}
