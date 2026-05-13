import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'company_dashboard_page.dart';
import 'login_page.dart';
import 'student_jobs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _perfil;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final perfil = prefs.getString('user_perfil');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      return;
    }

    setState(() {
      _perfil = perfil;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfil == 'empresa') {
      return CompanyDashboardPage();
    }

    return StudentJobsPage();
  }
}