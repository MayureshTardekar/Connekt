import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthRepository {
  /// Safely access supabase only if configured
  SupabaseClient get _supabase => Supabase.instance.client;

  // Get current user
  User? get currentUser {
    if (AppConfig.useMockBackend) return null; // Or return a mock user
    return _supabase.auth.currentUser;
  }

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges {
    if (AppConfig.useMockBackend) return const Stream.empty();
    return _supabase.auth.onAuthStateChange;
  }

  // Email & Password Sign In
  Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockBackend) {
      debugPrint('Mock Login: Success as Guest');
      return null; // Return successfully without calling Supabase
    }
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      throw Exception('Could not connect to server. Please try again.');
    }
  }

  // Email & Password Sign Up
  Future<dynamic> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockBackend) {
      debugPrint('Mock Signup: Success as $fullName');
      return null;
    }
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      
      if (response.user != null) {
        // Sync to public profiles table
        await _syncProfile(
          id: response.user!.id,
          fullName: fullName,
        );
      }
      
      return response;
    } on AuthException catch (e) {
      debugPrint('Registration error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign up error: $e');
      throw Exception('Sign up failed. Check your connection.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      return await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: AppConfig.oauthRedirectUrl,
      );
    } catch (e) {
      debugPrint('OAuth error ($provider): $e');
      return false;
    }
  }

  // Update Universal Alias/Display Name
  Future<Map<String, dynamic>> updateDisplayName(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      // Update local Auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': newName,
            'full_name': newName, // Sync for compatibility
          },
        ),
      );

      // Sync to public profiles table
      await _syncProfile(
        id: user.id,
        displayName: newName,
      );

      return {'success': true, 'message': 'Display name updated!'};
    } catch (e) {
      debugPrint('Update error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update Ghost Alias (with 7-day cooldown)
  Future<Map<String, dynamic>> updateGhostAlias(String newAlias) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      // 1. Check last update timestamp in metadata
      final lastUpdateStr = user.userMetadata?['ghost_alias_updated_at'];
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final diff = DateTime.now().difference(lastUpdate);
        if (diff.inDays < 7) {
          final remaining = 7 - diff.inDays;
          return {
            'success': false,
            'message': 'Cooldown active: Try again in $remaining days.'
          };
        }
      }

      // 2. Update Auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'ghost_alias': newAlias,
            'ghost_alias_updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      // 3. Sync to profiles table
      await _syncProfile(
        id: user.id,
        ghostAlias: newAlias,
      );

      return {'success': true, 'message': 'Ghost alias updated! 👻'};
    } catch (e) {
      debugPrint('Ghost update error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload Profile Photo
  Future<String?> uploadProfilePhoto(Uint8List bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = fileName;

    try {
      // Upload to 'avatars' bucket
      await _supabase.storage.from('avatars').uploadBinary(path, bytes);

      // Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // Update user metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      // Sync to public profiles table
      await _syncProfile(
        id: user.id,
        avatarUrl: imageUrl,
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  // Profile Synchronization with public table
  Future<void> _syncProfile({
    required String id,
    String? fullName,
    String? avatarUrl,
    String? ghostAlias,
    String? displayName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final updates = {
        'id': id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (ghostAlias != null) updates['ghost_alias'] = ghostAlias;
      if (displayName != null) updates['display_name'] = displayName;

      // Also grab missing fields from metadata if available to avoid overwriting with null
      if (user != null && user.id == id) {
        updates['full_name'] ??= user.userMetadata?['full_name'];
        updates['avatar_url'] ??= user.userMetadata?['avatar_url'];
        updates['ghost_alias'] ??= user.userMetadata?['ghost_alias'];
        updates['display_name'] ??= user.userMetadata?['display_name'];
      }

      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      debugPrint('Sync profile warning (table might not exist): $e');
    }
  }

  String? get currentGhostAlias =>
      _supabase.auth.currentUser?.userMetadata?['ghost_alias'];

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
