import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/vaga_detalhes_page.dart'; 
import 'screens/auth/auth_selection_screen.dart'; 
import 'pages/student_profile_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/company_profile_page.dart'; // novo Import

void main() {
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED), 
          primary: const Color(0xFF7C3AED),
        ),
        fontFamily: 'Inter', 
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      // AQUI FOI FEITA A ALTERAÇÃO:
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingPage(), 
        '/student-profile': (context) => const StudentProfilePage(),
        '/welcome': (context) => const AuthSelectionScreen(), 
        '/': (context) => const LoginPage(),                  
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/vaga-detalhes': (context) => const VagaDetalhesPage(),
        '/company-profile': (context) => const CompanyProfilePage(), // NOVA ROTA ADICIONADA
      },
    );
  }
}