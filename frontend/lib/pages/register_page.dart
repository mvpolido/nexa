import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cursoController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _perfil = 'aluno';
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _cursoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final body = <String, dynamic>{
      'nome_exibicao': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'senha': _senhaController.text,
      'perfil': _perfil,
    };

    if (_perfil == 'aluno') {
      body['cpf'] = _onlyNumbers(_cpfController.text);
      body['curso'] = _cursoController.text.trim();
    } else {
      body['cnpj'] = _onlyNumbers(_cnpjController.text);
      body['descricao'] = _descricaoController.text.trim();
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 201) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso')),
        );

        Navigator.of(context).pushReplacementNamed('/');
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'Erro ao cadastrar';
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

  Widget _buildAlunoFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF',
            hintText: 'Ex: 52998224725',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_perfil != 'aluno') return null;

            final cpf = _onlyNumbers(value ?? '');

            if (cpf.isEmpty) return 'Informe o CPF';
            if (cpf.length != 11) return 'O CPF deve ter 11 números';

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cursoController,
          decoration: const InputDecoration(
            labelText: 'Curso',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_perfil != 'aluno') return null;

            final curso = value?.trim() ?? '';

            if (curso.isEmpty) return 'Informe o curso';

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmpresaFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cnpjController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CNPJ',
            hintText: 'Ex: 11222333000181',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_perfil != 'empresa') return null;

            final cnpj = _onlyNumbers(value ?? '');

            if (cnpj.isEmpty) return 'Informe o CNPJ';
            if (cnpj.length != 14) return 'O CNPJ deve ter 14 números';

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descricaoController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Descrição da empresa',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_perfil != 'empresa') return null;

            final descricao = value?.trim() ?? '';

            if (descricao.isEmpty) return 'Informe a descrição da empresa';

            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Criar conta no Nexa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preencha os dados para se cadastrar',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final nome = value?.trim() ?? '';

                      if (nome.isEmpty) return 'Informe o nome';
                      if (nome.length < 3) {
                        return 'O nome deve ter pelo menos 3 caracteres';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) return 'Informe o email';
                      if (!email.contains('@')) return 'Informe um email válido';

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _perfil,
                    decoration: const InputDecoration(
                      labelText: 'Perfil',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'aluno',
                        child: Text('Aluno'),
                      ),
                      DropdownMenuItem(
                        value: 'empresa',
                        child: Text('Empresa'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _perfil = value;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_perfil == 'aluno') _buildAlunoFields(),
                  if (_perfil == 'empresa') _buildEmpresaFields(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final senha = value ?? '';

                      if (senha.isEmpty) return 'Informe a senha';
                      if (senha.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final confirmarSenha = value ?? '';

                      if (confirmarSenha.isEmpty) return 'Confirme a senha';

                      if (confirmarSenha != _senhaController.text) {
                        return 'As senhas não conferem';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cadastrar'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    child: const Text('Já tenho conta'),
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