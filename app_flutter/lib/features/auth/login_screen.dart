import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  void _signIn() async {
    setState(() => _loading = true);
    try {
      await _auth.signInEmail(_email.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signUp() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpEmail(_email.text.trim(), _password.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to confirm')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
          const SizedBox(height: 16),
          _loading ? const CircularProgressIndicator() : Row(children: [
            Expanded(child: ElevatedButton(onPressed: _signIn, child: const Text('Entrar'))),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: _signUp, child: const Text('Criar conta'))
          ])
        ]),
      ),
    );
  }
}
