import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/community_repository.dart';
import 'campus_provider.dart';

final communityRepositoryProvider = Provider((ref) => CommunityRepository());

// Stream all communities for the current campus
final communitiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final campusId = ref.watch(selectedCampusIdProvider);
  if (campusId == null) return Stream.value([]);
  
  return ref.watch(communityRepositoryProvider).watchCommunities(campusId);
});

// Current active community ID (for navigation/detail)
final activeCommunityIdProvider = StateProvider<String?>((ref) => null);

// Stream messages for the active community
final communityMessagesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final communityId = ref.watch(activeCommunityIdProvider);
  if (communityId == null) return Stream.value([]);

  return ref.watch(communityRepositoryProvider).watchMessages(communityId);
});

// Membership status for the active community
final communityMembershipStatusProvider = FutureProvider<String?>((ref) {
  final communityId = ref.watch(activeCommunityIdProvider);
  if (communityId == null) return null;

  return ref.watch(communityRepositoryProvider).getMembershipStatus(communityId);
});
