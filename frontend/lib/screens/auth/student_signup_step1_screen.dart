import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'student_signup_step2_screen.dart';

class StudentSignupStep1Screen extends StatefulWidget {
  const StudentSignupStep1Screen({super.key});

  @override
  State<StudentSignupStep1Screen> createState() => _StudentSignupStep1ScreenState();
}

class _StudentSignupStep1ScreenState extends State<StudentSignupStep1Screen> {
  final _courseController = TextEditingController();
  final _institutionController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cadastro de Aluno', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Passo 1 de 3', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progresso
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Dados Pessoais e Acadêmicos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              const Text('Nome Completo', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'Ex: Luciano Neves')),
              const SizedBox(height: 20),

              const Text('CPF', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Apenas números')),
              const SizedBox(height: 20),

              // Campo de Instituição de Ensino restaurado!
              const Text('Instituição de Ensino', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _institutionController,
                decoration: const InputDecoration(hintText: 'Ex: UTFPR, UEM, Integrado...'),
              ),
              const SizedBox(height: 20),

              const Text('Seu Curso', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _courseController,
                decoration: const InputDecoration(hintText: 'Ex: Engenharia Civil, Ciência da Computação...'),
              ),
              const SizedBox(height: 20),

              const Text('Crie uma Senha', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => const StudentSignupStep2Screen()));
                },
                child: const Text('Próximo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}