import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'company_dashboard_page.dart';
import 'moderator_dashboard_page.dart';
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
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    final perfilNormalizado = perfil?.toLowerCase();

    if (!['aluno', 'empresa', 'admin'].contains(perfilNormalizado)) {
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('user_nome');
      await prefs.remove('user_email');
      await prefs.remove('user_perfil');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    setState(() {
      _perfil = perfilNormalizado;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_perfil == 'empresa') {
      return const CompanyDashboardPage();
    }

    if (_perfil == 'admin') {
      return const ModeratorDashboardPage();
    }

    return const StudentJobsPage();
  }
}
