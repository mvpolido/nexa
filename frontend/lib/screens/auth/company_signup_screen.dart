import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/address_service.dart';
import '../../services/validators.dart';

class CompanySignupScreen extends StatefulWidget {
  const CompanySignupScreen({super.key});

  @override
  State<CompanySignupScreen> createState() => _CompanySignupScreenState();
}

class _CompanySignupScreenState extends State<CompanySignupScreen> {
  final _razaoSocialController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeUfController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _loadingCep = false;

  String _logradouro = '';
  String _bairro = '';
  String _cidade = '';
  String _estado = '';

  @override
  void dispose() {
    _razaoSocialController.dispose();
    _cnpjController.dispose();
    _cepController.dispose();
    _numeroController.dispose();
    _descricaoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logradouroController.dispose();
    _bairroController.dispose();
    _cidadeUfController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.trim();
    if (cep.isEmpty) {
      _showSnackbar('Digite um CEP');
      return;
    }

    setState(() {
      _loadingCep = true;
    });

    try {
      final data = await AddressService.fetchCep(cep);
      setState(() {
        _cepController.text = data.cep;
        _logradouro = data.logradouro;
        _bairro = data.bairro;
        _cidade = data.cidade;
        _estado = data.estado;
        _logradouroController.text = _logradouro;
        _bairroController.text = _bairro;
        _cidadeUfController.text = '$_cidade/$_estado';
      });
    } catch (e) {
      _showSnackbar('Erro no CEP: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingCep = false;
        });
      }
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _registrarEmpresa() async {
    final razaoSocial = _razaoSocialController.text.trim();
    final cnpj = _cnpjController.text.trim();
    final cep = _cepController.text.trim();
    final numero = _numeroController.text.trim();
    final descricao = _descricaoController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (razaoSocial.isEmpty || cnpj.isEmpty || cep.isEmpty || numero.isEmpty || password.isEmpty) {
      _showSnackbar('Preencha todos os campos obrigatórios');
      return;
    }

    if (!Validators.isValidCNPJ(cnpj)) {
      _showSnackbar('CNPJ inválido');
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar('Senhas não correspondem');
      return;
    }

    if (_logradouro.isEmpty || _cidade.isEmpty || _estado.isEmpty) {
      _showSnackbar('Busque o CEP para preencher endereço');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final emailGerado = 'empresa_${cnpj.replaceAll(RegExp(r'\D'), '')}@nexa.local';

      // 1. Registrar usuário
      final registerResp = await http.post(
        Uri.parse('http://localhost:3000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_exibicao': razaoSocial,
          'email': emailGerado,
          'password': password,
          'perfil': 'empresa',
        }),
      );

      if (registerResp.statusCode != 201) {
        final msg = registerResp.body.isNotEmpty ? registerResp.body : 'Erro ${registerResp.statusCode}';
        _showSnackbar('Falha no cadastro: $msg');
        return;
      }

      // 2. Login automático
      final loginResp = await http.post(
        Uri.parse('http://localhost:3000/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailGerado,
          'password': password,
        }),
      );

      if (loginResp.statusCode == 200) {
        final token = jsonDecode(loginResp.body)['token'];
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('auth_token', token);
        } catch (_) {}

        // 3. Atualizar dados da empresa
        final putBody = {
          'cnpj': cnpj,
          'razao_social': razaoSocial,
          'nome_exibicao': razaoSocial,
          'email': emailGerado,
          'descricao': descricao.isEmpty ? null : descricao,
          'cep': cep,
          'numero': numero,
          'logradouro': _logradouro,
          'bairro': _bairro,
          'cidade': _cidade,
          'estado': _estado,
        };

        final putResp = await http.put(
          Uri.parse('http://localhost:3000/empresas/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(putBody),
        );

        if (putResp.statusCode == 200) {
          _showSnackbar('Empresa registrada com sucesso!');
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/company-profile', (route) => false);
        } else {
          _showSnackbar('Dados da empresa não salvos: ${putResp.statusCode}');
        }
      } else {
        _showSnackbar('Login automático falhou: ${loginResp.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Erro ao conectar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            Text('Cadastro de Empresa', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Preencha os dados da sua empresa', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Razão Social', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _razaoSocialController,
                decoration: const InputDecoration(hintText: 'TechCorp Ltda'),
              ),
              const SizedBox(height: 16),

              const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Apenas números (14 dígitos)'),
              ),
              const SizedBox(height: 16),

              const Text('CEP da Sede', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Ex: 87015000'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _loadingCep ? null : _buscarCep,
                      child: _loadingCep
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_logradouro.isNotEmpty) ...[
                TextField(
                  controller: _logradouroController,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Logradouro'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bairroController,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cidadeUfController,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Cidade/UF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              const Text('Número', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ex: 1500'),
              ),
              const SizedBox(height: 16),

              const Text('Descrição (Opcional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Descreva brevemente sua empresa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Senha', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Confirmar Senha', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registrarEmpresa,
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Criar Conta da Empresa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}