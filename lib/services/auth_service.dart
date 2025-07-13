import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../utils/constants.dart';

class AuthService {
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: '$email@polres.cianjur.id',
      password: password,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: '$email@polres.cianjur.id',
      password: password,
    );
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static Future<void> updateUserProfile({
    required String userId,
    required String name,
  }) async {
    await supabase
        .from('users')
        .upsert({
          'id': userId,
          'name': name,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  static Future<app_user.User?> getUserProfile(String userId) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    return app_user.User.fromJson(response);
  }

  static app_user.User? getCurrentUser() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      return app_user.User(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] ?? '',
        createdAt: DateTime.parse(user.createdAt),
      );
    }
    return null;
  }
} 