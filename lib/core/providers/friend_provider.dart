import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/friend_repository.dart';
import '../models/friend_request.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

final pendingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendRepositoryProvider).watchPendingRequests();
});

/// Exposes just the count for the banner badge
final pendingRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(pendingRequestsProvider).asData?.value.length ?? 0;
});
