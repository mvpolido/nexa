import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class StudentJobsPage extends StatefulWidget {
  const StudentJobsPage({super.key});

  @override
  State<StudentJobsPage> createState() => _StudentJobsPageState();
}

class _StudentJobsPageState extends State<StudentJobsPage> {
  bool isLoading = true;
  String? token;
  String? nome;

  List<dynamic> vagas = [];
  Set<int> vagasCandidatadas = {};

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token');
    nome = prefs.getString('user_nome');

    if (token == null || token!.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    setState(() {
      isLoading = true;
    });

    await Future.wait([
      carregarVagas(),
      carregarMinhasCandidaturas(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> carregarVagas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vagas'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        vagas = data;
      }
    }
  }

  Future<void> carregarMinhasCandidaturas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/alunos/me/candidaturas'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        vagasCandidatadas = data
            .where((candidatura) => candidatura['vaga_id'] != null)
            .map<int>((candidatura) => candidatura['vaga_id'] as int)
            .toSet();
      }
    }
  }

  Future<void> confirmarCandidatura(dynamic vaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar candidatura'),
          content: Text(
            'Deseja realmente se candidatar para a vaga "${vaga['titulo'] ?? 'Sem título'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await candidatar(vaga['id']);
    }
  }

  Future<void> candidatar(int vagaId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId/candidatar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      String mensagem = 'Erro ao enviar candidatura.';

      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        mensagem = data['message'] ?? mensagem;
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          vagasCandidatadas.add(vagaId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidatura enviada com sucesso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  String nomeEmpresa(dynamic vaga) {
    final empresa = vaga['empresa'];

    if (empresa == null) return 'Empresa não informada';

    final usuario = empresa['usuario'];

    if (usuario == null) return 'Empresa não informada';

    return usuario['nome_exibicao'] ?? usuario['nome'] ?? 'Empresa não informada';
  }

  Widget cardVaga(dynamic vaga) {
    final int? vagaId = vaga['id'];
    final bool jaCandidatou =
        vagaId != null && vagasCandidatadas.contains(vagaId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vaga['titulo'] ?? 'Sem título',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(vaga['descricao'] ?? 'Sem descrição.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(nomeEmpresa(vaga)),
                  avatar: const Icon(Icons.business, size: 18),
                ),
                Chip(
                  label: Text(vaga['modalidade'] ?? '-'),
                  avatar: const Icon(Icons.work_outline, size: 18),
                ),
              ],
            ),
            if ((vaga['requisitos'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Requisitos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(vaga['requisitos']),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: jaCandidatou || vagaId == null
                    ? null
                    : () => confirmarCandidatura(vaga),
                icon: Icon(
                  jaCandidatou ? Icons.check_circle : Icons.send,
                ),
                label: Text(
                  jaCandidatou ? 'Candidatura enviada' : 'Candidatar-se',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget conteudo() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vagas.isEmpty) {
      return const Center(
        child: Text('Nenhuma vaga disponível no momento.'),
      );
    }

    return RefreshIndicator(
      onRefresh: carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vagas.length,
        itemBuilder: (context, index) {
          return cardVaga(vagas[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vagas disponíveis'),
        actions: [
          IconButton(
            onPressed: carregarDados,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'Olá, ${nome ?? 'aluno'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: conteudo()),
        ],
      ),
    );
  }
}
