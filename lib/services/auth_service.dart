
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // নতুন অ্যাকাউন্ট তৈরি
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  // লগইন
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // লগআউট
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // বর্তমান ব্যবহারকারী
  User? get currentUser => _supabase.auth.currentUser;

  // লগইন অবস্থা
  bool get isLoggedIn => currentUser != null;
}
