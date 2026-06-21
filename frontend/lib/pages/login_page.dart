import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart'; // 👈 Nossa nova ponte com a API

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

  final Color primaryColor = const Color(0xFF7C3AED); // Roxo Nexa

  // Transformei o estilo dos inputs em um getter para poder reutilizá-lo no modal
  InputDecorationTheme get _inputDecorationTemplate {
    return InputDecorationTheme(
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
        borderSide: BorderSide(color: primaryColor, width: 2),
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
  }

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

        // Todos os usuários agora vão para a Home
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

  // --- MÁGICA DA RECUPERAÇÃO DE SENHA --- //
  Future<void> _showForgotPasswordDialog() async {
    int step = 1; // 1 = Pede E-mail | 2 = Pede Código e Nova Senha
    bool isDialogLoading = false;
    String? dialogError;

    final emailResetCtrl = TextEditingController(text: _emailController.text);
    final tokenCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    bool obscureNewPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                step == 1 ? 'Recuperar Senha' : 'Redefinir Senha',
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Color(0xFF1F2937)),
              ),
              content: SizedBox(
                width: 400, // Limita a largura do modal
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            dialogError!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontFamily: 'Inter'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (step == 1) ...[
                        const Text(
                          'Digite seu e-mail cadastrado. Enviaremos um código de 6 dígitos para você criar uma nova senha.',
                          style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter', fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailResetCtrl,
                          decoration: InputDecoration(
                            hintText: 'Seu e-mail',
                            prefixIcon: const Icon(Icons.mail_outline, size: 22),
                            filled: _inputDecorationTemplate.filled,
                            fillColor: _inputDecorationTemplate.fillColor,
                            contentPadding: _inputDecorationTemplate.contentPadding,
                            border: _inputDecorationTemplate.border,
                            enabledBorder: _inputDecorationTemplate.enabledBorder,
                            focusedBorder: _inputDecorationTemplate.focusedBorder,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Código enviado para ${emailResetCtrl.text.trim()}.',
                          style: const TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter', fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: tokenCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Código de 6 dígitos',
                            prefixIcon: const Icon(Icons.pin_outlined, size: 22),
                            filled: _inputDecorationTemplate.filled,
                            fillColor: _inputDecorationTemplate.fillColor,
                            contentPadding: _inputDecorationTemplate.contentPadding,
                            border: _inputDecorationTemplate.border,
                            enabledBorder: _inputDecorationTemplate.enabledBorder,
                            focusedBorder: _inputDecorationTemplate.focusedBorder,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPasswordCtrl,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            hintText: 'Nova senha',
                            prefixIcon: const Icon(Icons.lock_outline, size: 22),
                            filled: _inputDecorationTemplate.filled,
                            fillColor: _inputDecorationTemplate.fillColor,
                            contentPadding: _inputDecorationTemplate.contentPadding,
                            border: _inputDecorationTemplate.border,
                            enabledBorder: _inputDecorationTemplate.enabledBorder,
                            focusedBorder: _inputDecorationTemplate.focusedBorder,
                            suffixIcon: IconButton(
                              icon: Icon(obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 22),
                              onPressed: () {
                                setStateDialog(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                if (!isDialogLoading)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280), fontFamily: 'Inter')),
                  ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          setStateDialog(() {
                            isDialogLoading = true;
                            dialogError = null;
                          });

                          try {
                            if (step == 1) {
                              if (emailResetCtrl.text.trim().isEmpty) {
                                throw Exception("Preencha o e-mail");
                              }
                              // Chama a API para enviar o e-mail
                              await AuthService.forgotPassword(emailResetCtrl.text.trim());
                              setStateDialog(() {
                                step = 2; // Avança para o passo 2
                                isDialogLoading = false;
                              });
                            } else {
                              if (tokenCtrl.text.trim().isEmpty || newPasswordCtrl.text.isEmpty) {
                                throw Exception("Preencha todos os campos");
                              }
                              // Chama a API para trocar a senha
                              await AuthService.resetPassword(
                                emailResetCtrl.text.trim(),
                                tokenCtrl.text.trim(),
                                newPasswordCtrl.text,
                              );
                              
                              // Se der certo, fecha o modal e mostra mensagem de sucesso
                              if (!mounted) return;
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Senha atualizada com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() {
                              isDialogLoading = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isDialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text(step == 1 ? 'Enviar Código' : 'Redefinir Senha', style: const TextStyle(fontFamily: 'Inter')),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // -------------------------------------- //

  @override
  Widget build(BuildContext context) {
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
                      return Icon(Icons.flutter_dash, size: 64, color: primaryColor);
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
                      filled: _inputDecorationTemplate.filled,
                      fillColor: _inputDecorationTemplate.fillColor,
                      contentPadding: _inputDecorationTemplate.contentPadding,
                      border: _inputDecorationTemplate.border,
                      enabledBorder: _inputDecorationTemplate.enabledBorder,
                      focusedBorder: _inputDecorationTemplate.focusedBorder,
                      errorBorder: _inputDecorationTemplate.errorBorder,
                      focusedErrorBorder: _inputDecorationTemplate.focusedErrorBorder,
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
                      filled: _inputDecorationTemplate.filled,
                      fillColor: _inputDecorationTemplate.fillColor,
                      contentPadding: _inputDecorationTemplate.contentPadding,
                      border: _inputDecorationTemplate.border,
                      enabledBorder: _inputDecorationTemplate.enabledBorder,
                      focusedBorder: _inputDecorationTemplate.focusedBorder,
                      errorBorder: _inputDecorationTemplate.errorBorder,
                      focusedErrorBorder: _inputDecorationTemplate.focusedErrorBorder,
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
                      onPressed: _showForgotPasswordDialog, // 👈 BOTÃO CONECTADO AQUI!
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
                          Navigator.of(context).pushReplacementNamed('/welcome');
                        },
                        child: Text(
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