import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend_request.dart';
import '../config/app_config.dart';
import '../mock/mock_datasource.dart';

class FriendRepository {
  SupabaseClient get _supabase => Supabase.instance.client;
  static const _table = 'friend_requests';

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// Stream of pending requests sent TO the current user.
  /// Uses Supabase Realtime postgres_changes for live updates.
  Stream<List<FriendRequest>> watchPendingRequests() {
    if (AppConfig.useMockBackend) {
      return Stream.value(MockDatasource.friendRequests);
    }
    if (_currentUserId.isEmpty) return Stream.value([]);

    // SupabaseStreamBuilder supports only one .eq() filter.
    // We filter by receiver_id via stream, then filter status client-side.
    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', _currentUserId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .map(FriendRequest.fromMap)
              .where((r) => r.status == 'pending')
              .toList(),
        );
  }

  /// Accept — optimistic: update status in DB, UI reacts via stream
  Future<void> acceptRequest(String requestId) async {
    if (AppConfig.useMockBackend) {
      MockDatasource.friendRequests.removeWhere((r) => r.id == requestId);
      return;
    }
    try {
      await _supabase
          .from(_table)
          .update({'status': 'accepted'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  /// Decline — optimistic: update status in DB, UI reacts via stream
  Future<void> declineRequest(String requestId) async {
    if (AppConfig.useMockBackend) {
      MockDatasource.friendRequests.removeWhere((r) => r.id == requestId);
      return;
    }
    try {
      await _supabase
          .from(_table)
          .update({'status': 'declined'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to decline request: $e');
    }
  }

  /// Send a friend request
  Future<void> sendRequest({
    required String receiverId,
    required String senderName,
  }) async {
    if (AppConfig.useMockBackend) return;
    if (_currentUserId.isEmpty) return;
    try {
      await _supabase.from(_table).insert({
        'sender_id': _currentUserId,
        'sender_name': senderName,
        'receiver_id': receiverId,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to send request: $e');
    }
  }
}
