import 'package:flutter/material.dart';
import 'core/supabase/client.dart';
import 'features/dashboard/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // IMPORTANT: replace with your production values (do NOT hardcode service role key)
  await SupabaseClientWrapper.init(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
  runApp(const CashbackApp());
}

class CashbackApp extends StatelessWidget {
  const CashbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return MaterialApp(
      title: 'Cashback+',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.greenAccent,
        ),
      ),
      home: user == null ? const LoginScreen() : const HomeScreen(),
      routes: {'/login': (_) => const LoginScreen(), '/': (_) => const HomeScreen()},
    );
  }
}
