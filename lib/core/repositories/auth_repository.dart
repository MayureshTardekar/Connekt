import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Email & Password Sign In
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Email & Password Sign Up
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Social Sign In (Google / Discord)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    return await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : 'io.supabase.connekt://login-callback',
    );
  }

  // Update Ghost Alias (with 7-day cooldown)
  Future<Map<String, dynamic>> updateGhostAlias(String newAlias) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final lastUpdateStr = user.userMetadata?['ghost_alias_updated_at'];
    if (lastUpdateStr != null) {
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final daysSince = DateTime.now().difference(lastUpdate).inDays;
      if (daysSince < 7) {
        return {
          'success': false,
          'message': 'You can change your alias in ${7 - daysSince} days.',
        };
      }
    }

    await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          'ghost_alias': newAlias,
          'ghost_alias_updated_at': DateTime.now().toIso8601String(),
        },
      ),
    );

    return {'success': true, 'message': 'Alias updated successfully!'};
  }

  // Upload Profile Photo
  Future<String?> uploadProfilePhoto(Uint8List bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'avatars/$fileName';

    try {
      // Upload to 'avatars' bucket
      await _supabase.storage.from('avatars').uploadBinary(path, bytes);

      // Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // Update user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'avatar_url': imageUrl},
        ),
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  String? get currentGhostAlias => _supabase.auth.currentUser?.userMetadata?['ghost_alias'];

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
