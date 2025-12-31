import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authCallbackUrlHostname: 'login-callback',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
