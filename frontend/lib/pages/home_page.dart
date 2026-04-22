import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_nome');
    await prefs.remove('user_email');
    await prefs.remove('user_perfil');

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<bool> _hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasToken = snapshot.data ?? false;

        if (!hasToken) {
          return const LoginPage();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nexa'),
            actions: [
              IconButton(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: const Center(
            child: Text('Você está logado'),
          ),
        );
      },
    );
  }
}