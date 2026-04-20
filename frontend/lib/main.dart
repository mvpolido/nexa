import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';



void main() {
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}