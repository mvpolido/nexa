import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'senha': _passwordController.text,
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', data['token']);
        await prefs.setString('user_id', data['user']['id'].toString());
        await prefs.setString('user_nome', data['user']['nome_exibicao']);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('user_perfil', data['user']['perfil']);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'Erro ao fazer login';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão com o servidor';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7C3AED); // Roxo Nexa

    // Estilo padrão para os inputs externos (InputDecoration)
    final inputDecorationTemplate = InputDecorationTheme(
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
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo do Nexa centralizada
                  Image.asset(
                    'assets/images/logonexa.png',
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.flutter_dash, size: 64, color: primaryColor);
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Título Principal
                  const Text(
                    'Entrar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtítulo
                  const Text(
                    'Acesse sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Label E-mail
                  const Text(
                    'E-mail',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: const Icon(Icons.mail_outline, size: 22),
                      filled: inputDecorationTemplate.filled,
                      fillColor: inputDecorationTemplate.fillColor,
                      contentPadding: inputDecorationTemplate.contentPadding,
                      border: inputDecorationTemplate.border,
                      enabledBorder: inputDecorationTemplate.enabledBorder,
                      focusedBorder: inputDecorationTemplate.focusedBorder,
                      errorBorder: inputDecorationTemplate.errorBorder,
                      focusedErrorBorder: inputDecorationTemplate.focusedErrorBorder,
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Informe o e-mail';
                      if (!email.contains('@')) return 'Informe um e-mail válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Label Senha
                  const Text(
                    'Senha',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, size: 22),
                      filled: inputDecorationTemplate.filled,
                      fillColor: inputDecorationTemplate.fillColor,
                      contentPadding: inputDecorationTemplate.contentPadding,
                      border: inputDecorationTemplate.border,
                      enabledBorder: inputDecorationTemplate.enabledBorder,
                      focusedBorder: inputDecorationTemplate.focusedBorder,
                      errorBorder: inputDecorationTemplate.errorBorder,
                      focusedErrorBorder: inputDecorationTemplate.focusedErrorBorder,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 22,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Informe a senha';
                      if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                      return null;
                    },
                  ),
                  
                  // Link Esqueci minha senha
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bloco de Feedback de Erro
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botão Entrar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer Cadastre-se
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Não tem conta? ',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontFamily: 'Inter'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/register');
                        },
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}