import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<User?> signInEmail(String email, String password) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    if (res.hasError) throw Exception(res.error?.message);
    return res.user;
  }

  Future<User?> signUpEmail(String email, String password) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (res.hasError) throw Exception(res.error?.message);
    return res.user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
