import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../widgets/skill_selector.dart';

class StudentJobsPage extends StatefulWidget {
  const StudentJobsPage({super.key});

  @override
  State<StudentJobsPage> createState() => _StudentJobsPageState();
}

class _StudentJobsPageState extends State<StudentJobsPage> {
  bool isLoading = true;
  bool isSavingSkills = false;

  String? token;
  String? nome;

  List<dynamic> vagas = [];
  List<dynamic> habilidadesDisponiveis = [];

  Set<int> minhasHabilidadesIds = {};
  Map<int, String> statusCandidaturasPorVaga = {};

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
      carregarHabilidades(),
      carregarMeuPerfil(),
      carregarVagas(),
      carregarMinhasCandidaturas(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> carregarHabilidades() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/habilidades'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          habilidadesDisponiveis = data;
        }
      }
    } catch (_) {}
  }

  Future<void> carregarMeuPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final relacoes = data['alunoHabilidades'];

        if (relacoes is List) {
          minhasHabilidadesIds = relacoes
              .map((relacao) => relacao['habilidade_id'])
              .where((id) => id is int)
              .map<int>((id) => id as int)
              .toSet();
        }
      }
    } catch (_) {}
  }

  Future<void> carregarVagas() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vagas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          vagas = data.where((vaga) {
            return vaga['ativo'] == 1 || vaga['ativo'] == true;
          }).toList();
        }
      }
    } catch (_) {}
  }

  Future<void> carregarMinhasCandidaturas() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/candidaturas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          statusCandidaturasPorVaga = {};

          for (final candidatura in data) {
            final vagaId = candidatura['vaga_id'];
            final status = candidatura['status'];

            if (vagaId is int && status != null) {
              statusCandidaturasPorVaga[vagaId] = status.toString();
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> salvarMinhasHabilidades(Set<int> habilidadeIds) async {
    setState(() {
      isSavingSkills = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/habilidades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'habilidadeIds': habilidadeIds.toList(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          minhasHabilidadesIds = habilidadeIds;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habilidades atualizadas com sucesso.'),
          ),
        );
      } else {
        String mensagem = 'Erro ao salvar habilidades.';

        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingSkills = false;
        });
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
          statusCandidaturasPorVaga[vagaId] = 'PENDENTE';
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

    return usuario['nome_exibicao'] ??
        usuario['nome'] ??
        'Empresa não informada';
  }

  String labelStatusCandidatura(String status) {
    switch (status) {
      case 'PENDENTE':
        return 'Em análise';
      case 'ACEITA':
        return 'Aceita';
      case 'REJEITADA':
        return 'Rejeitada';
      default:
        return status;
    }
  }

  IconData iconeStatusCandidatura(String status) {
    switch (status) {
      case 'PENDENTE':
        return Icons.hourglass_empty;
      case 'ACEITA':
        return Icons.check_circle_outline;
      case 'REJEITADA':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color? corStatusCandidatura(String status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange.shade100;
      case 'ACEITA':
        return Colors.green.shade100;
      case 'REJEITADA':
        return Colors.red.shade100;
      default:
        return null;
    }
  }

  List<dynamic> habilidadesDaVaga(dynamic vaga) {
    final relacoes = vaga['vagaHabilidades'];

    if (relacoes is List) {
      return relacoes
          .map((relacao) => relacao['habilidade'])
          .where((habilidade) => habilidade != null)
          .toList();
    }

    final legado = vaga['habilidades'];

    if (legado is List) {
      return legado
          .map((nome) => {
                'id': null,
                'nome': nome.toString(),
              })
          .toList();
    }

    return [];
  }

  Widget chipsHabilidades(List<dynamic> habilidades) {
    if (habilidades.isEmpty) {
      return const Text(
        'Nenhuma habilidade informada.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: habilidades.map((habilidade) {
        final id = habilidade['id'];
        final alunoPossui = id is int && minhasHabilidadesIds.contains(id);

        return Chip(
          avatar: Icon(
            alunoPossui ? Icons.check_circle_outline : Icons.label_outline,
            size: 18,
          ),
          label: Text(habilidade['nome'] ?? 'Sem nome'),
        );
      }).toList(),
    );
  }

  Widget cardMinhasHabilidades() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isSavingSkills
            ? const Center(child: CircularProgressIndicator())
            : SkillSelector(
                title: 'Minhas habilidades',
                habilidades: habilidadesDisponiveis,
                selectedIds: minhasHabilidadesIds,
                onChanged: (updated) async {
                  await salvarMinhasHabilidades(updated);
                },
              ),
      ),
    );
  }

  Widget cardVaga(dynamic vaga) {
    final int? vagaId = vaga['id'];
    final String? statusCandidatura =
        vagaId != null ? statusCandidaturasPorVaga[vagaId] : null;

    final bool jaCandidatou = statusCandidatura != null;
    final habilidades = habilidadesDaVaga(vaga);

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
              runSpacing: 8,
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
            const SizedBox(height: 12),
            const Text(
              'Habilidades exigidas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            chipsHabilidades(habilidades),
            if ((vaga['requisitos'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Observações adicionais',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(vaga['requisitos']),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: jaCandidatou
                  ? Chip(
                      avatar: Icon(
                        iconeStatusCandidatura(statusCandidatura),
                        size: 18,
                      ),
                      label: Text(
                        'Status: ${labelStatusCandidatura(statusCandidatura)}',
                      ),
                      backgroundColor: corStatusCandidatura(statusCandidatura),
                    )
                  : ElevatedButton.icon(
                      onPressed: vagaId == null
                          ? null
                          : () => confirmarCandidatura(vaga),
                      icon: const Icon(Icons.send),
                      label: const Text('Candidatar-se'),
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

    return RefreshIndicator(
      onRefresh: carregarDados,
      child: ListView(
        children: [
          cardMinhasHabilidades(),
          if (vagas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Nenhuma vaga disponível no momento.'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: vagas.map((vaga) => cardVaga(vaga)).toList(),
              ),
            ),
        ],
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
