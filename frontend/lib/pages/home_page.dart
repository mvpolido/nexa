import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String? _token;
  String? _perfil;
  String? _nome;

  List<dynamic> _vagas = [];

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _requisitosController = TextEditingController();
  String _modalidade = 'REMOTO';

  @override
  void initState() {
    super.initState();
    _loadSessionAndVagas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _requisitosController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionAndVagas() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final perfil = prefs.getString('user_perfil');
    final nome = prefs.getString('user_nome');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    setState(() {
      _token = token;
      _perfil = perfil;
      _nome = nome;
    });

    await _loadVagas();
  }

  Future<void> _loadVagas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/vagas'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (response.statusCode == 200) {
        setState(() {
          _vagas = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Erro ao carregar vagas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão com o servidor';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _createVaga() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/vagas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'titulo': _tituloController.text.trim(),
          'descricao': _descricaoController.text.trim(),
          'requisitos': _requisitosController.text.trim(),
          'modalidade': _modalidade,
          'habilidades': [],
        }),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 201) {
        _tituloController.clear();
        _descricaoController.clear();
        _requisitosController.clear();

        if (!mounted) return;

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso')),
        );

        await _loadVagas();
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Erro ao criar vaga';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão com o servidor';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _openCreateVagaDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova vaga'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Informe o título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descricaoController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Informe a descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _requisitosController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Requisitos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _modalidade,
                      decoration: const InputDecoration(
                        labelText: 'Modalidade',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'REMOTO',
                          child: Text('Remoto'),
                        ),
                        DropdownMenuItem(
                          value: 'PRESENCIAL',
                          child: Text('Presencial'),
                        ),
                        DropdownMenuItem(
                          value: 'HIBRIDO',
                          child: Text('Híbrido'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _modalidade = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : _createVaga,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVagaCard(dynamic vaga) {
    final empresa = vaga['empresa'];
    final usuarioEmpresa = empresa != null ? empresa['usuario'] : null;
    final nomeEmpresa = usuarioEmpresa != null
        ? usuarioEmpresa['nome_exibicao']
        : 'Empresa não informada';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          vaga['titulo'] ?? 'Sem título',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${vaga['descricao'] ?? ''}\n\n'
            'Empresa: $nomeEmpresa\n'
            'Modalidade: ${vaga['modalidade'] ?? '-'}\n'
            'Requisitos: ${vaga['requisitos'] ?? '-'}',
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_vagas.isEmpty) {
      return const Center(
        child: Text('Nenhuma vaga cadastrada ainda.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVagas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vagas.length,
        itemBuilder: (context, index) {
          return _buildVagaCard(_vagas[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = _perfil == 'empresa';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEmpresa ? 'Home Empresa' : 'Home Aluno'),
        actions: [
          IconButton(
            onPressed: _loadVagas,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: isEmpresa
          ? FloatingActionButton.extended(
              onPressed: _openCreateVagaDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nova vaga'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'Olá, ${_nome ?? 'usuário'} | Perfil: ${_perfil ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}