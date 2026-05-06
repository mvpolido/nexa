import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'student_signup_step2_screen.dart';
import '../../models/temp_registration.dart';
import '../../services/validators.dart';

class StudentSignupStep1Screen extends StatefulWidget {
  const StudentSignupStep1Screen({super.key});

  @override
  State<StudentSignupStep1Screen> createState() => _StudentSignupStep1ScreenState();
}

class _StudentSignupStep1ScreenState extends State<StudentSignupStep1Screen> {
  // Chave global para validar o formulário
  final _formKey = GlobalKey<FormState>(); 

  // Controllers para TODOS os campos agora
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _courseController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; 

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _courseController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
          // O Form que comanda tudo
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(hintText: 'Ex: Luciano Neves'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe seu nome completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'seu@email.com'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Por favor, informe o email';
                    }
                    if (!email.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('CPF', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Apenas números (11 dígitos)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe seu CPF';
                    }
                    if (!Validators.isValidCPF(value)) {
                      return 'CPF inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Instituição de Ensino', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(hintText: 'Ex: UTFPR, UEM, Integrado...'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe sua instituição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Seu Curso', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(hintText: 'Ex: Engenharia Civil, Ciência da Computação...'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe seu curso';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Crie uma Senha', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Senha', // MUDOU AQUI
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text('Confirme a Senha', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirmar Senha', // MUDOU AQUI
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme a senha';
                    }
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem. Tente novamente.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    // Valida todos os campos obrigatórios de uma vez
                    if (_formKey.currentState!.validate()) {
                      final reg = TempRegistration();
                      reg.nomeExibicao = _nomeController.text.trim();
                      reg.email = _emailController.text.trim();
                      reg.password = _passwordController.text;
                      reg.cpf = _cpfController.text.trim();
                      reg.institution = _institutionController.text.trim();
                      reg.course = _courseController.text.trim();
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => const StudentSignupStep2Screen()));
                    }
                  },
                  child: const Text('Próximo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}