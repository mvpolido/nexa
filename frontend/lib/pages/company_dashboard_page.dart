import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  bool isLoading = true;
  String? token;
  String? nome;
  int? userId;

  List<dynamic> vagas = [];

  @override
  void initState() {
    super.initState();
    carregarSessaoEVagas();
  }

  Future<void> carregarSessaoEVagas() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token');
    nome = prefs.getString('user_nome');
    userId = int.tryParse(prefs.getString('user_id') ?? '');

    if (token == null || token!.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    await carregarVagas();
  }

  Future<void> carregarVagas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vagas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            vagas = data.where((vaga) {
              if (userId == null) return true;

              final empresaId = vaga['empresa_id']?.toString();
              final usuarioId = vaga['empresa']?['usuario']?['id']?.toString();

              return empresaId == userId.toString() ||
                  usuarioId == userId.toString();
            }).toList();

            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar vagas.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

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

    Future<void> abrirFormularioVaga({dynamic vaga}) async {
    final bool editando = vaga != null;
    final scaffoldContext = context;

    final tituloController = TextEditingController(
        text: editando ? vaga['titulo'] ?? '' : '',
    );

    final descricaoController = TextEditingController(
        text: editando ? vaga['descricao'] ?? '' : '',
    );

    final requisitosController = TextEditingController(
        text: editando ? vaga['requisitos'] ?? '' : '',
    );

    String modalidade = editando ? vaga['modalidade'] ?? 'REMOTO' : 'REMOTO';

    if (modalidade == 'HÍBRIDO') {
        modalidade = 'HIBRIDO';
    }

    if (!['REMOTO', 'PRESENCIAL', 'HIBRIDO'].contains(modalidade)) {
        modalidade = 'REMOTO';
    }

    final formKey = GlobalKey<FormState>();

    await showDialog(
        context: context,
        builder: (dialogContext) {
        bool salvando = false;

        return StatefulBuilder(
            builder: (context, setDialogState) {
            Future<void> salvar() async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                setDialogState(() {
                salvando = true;
                });

                try {
                final body = jsonEncode({
                    'titulo': tituloController.text.trim(),
                    'descricao': descricaoController.text.trim(),
                    'requisitos': requisitosController.text.trim(),
                    'modalidade': modalidade,
                    'habilidades': [],
                });

                final response = editando
                    ? await http.put(
                        Uri.parse('${ApiConfig.baseUrl}/vagas/${vaga['id']}'),
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                        },
                        body: body,
                        )
                    : await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/vagas'),
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                        },
                        body: body,
                        );

                if (!mounted) return;

                if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                        content: Text(
                        editando
                            ? 'Vaga atualizada com sucesso.'
                            : 'Vaga criada com sucesso.',
                        ),
                    ),
                    );

                    await carregarVagas();
                } else {
                    String mensagem = 'Erro ao salvar vaga.';

                    if (response.body.isNotEmpty) {
                    final data = jsonDecode(response.body);
                    mensagem = data['message'] ?? mensagem;
                    }

                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(content: Text(mensagem)),
                    );

                    if (mounted) {
                    setDialogState(() {
                        salvando = false;
                    });
                    }
                }
                } catch (_) {
                if (!mounted) return;

                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                    content: Text('Erro de conexão com o servidor.'),
                    ),
                );

                if (mounted) {
                    setDialogState(() {
                    salvando = false;
                    });
                }
                }
            }

            return AlertDialog(
                title: Text(editando ? 'Editar vaga' : 'Nova vaga'),
                content: SizedBox(
                width: 520,
                child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        TextFormField(
                            controller: tituloController,
                            decoration: const InputDecoration(
                            labelText: 'Título',
                            border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                                return 'Informe o título.';
                            }

                            return null;
                            },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: descricaoController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                                return 'Informe a descrição.';
                            }

                            return null;
                            },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: requisitosController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                            labelText: 'Requisitos',
                            border: OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                            value: modalidade,
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

                            setDialogState(() {
                                modalidade = value;
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
                    onPressed: salvando
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                ),
                ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    child: salvando
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
        },
    );

    tituloController.dispose();
    descricaoController.dispose();
    requisitosController.dispose();
    }

  Future<void> confirmarRemocao(dynamic vaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover vaga'),
          content: Text(
            'Deseja realmente remover a vaga "${vaga['titulo'] ?? 'Sem título'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await removerVaga(vaga['id']);
    }
  }

  Future<void> removerVaga(int vagaId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga removida com sucesso.')),
        );

        await carregarVagas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover vaga.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
    }
  }

  Future<void> verCandidatos(dynamic vaga) async {
    final int? vagaId = vaga['id'];

    if (vagaId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId/candidaturas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidaturas = data is List ? data : [];

        abrirDialogCandidatos(vaga, candidaturas);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar candidatos.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
    }
  }

  void abrirDialogCandidatos(dynamic vaga, List<dynamic> candidaturas) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Candidatos - ${vaga['titulo'] ?? 'Vaga'}'),
          content: SizedBox(
            width: 620,
            child: candidaturas.isEmpty
                ? const Text('Nenhum candidato encontrado para esta vaga.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidaturas.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final candidatura = candidaturas[index];
                      final aluno = candidatura['aluno'];
                      final usuario = aluno?['usuario'];

                      final nomeAluno = usuario?['nome_exibicao'] ??
                          usuario?['nome'] ??
                          'Aluno sem nome';

                      final curso = aluno?['curso'] ?? 'Curso não informado';
                      final status = candidatura['status'] ?? '-';

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(nomeAluno),
                        subtitle: Text('Curso: $curso\nStatus: $status'),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget cardVaga(dynamic vaga) {
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
                  label: Text(vaga['modalidade'] ?? '-'),
                  avatar: const Icon(Icons.work_outline, size: 18),
                ),
                Chip(
                  label: Text(vaga['ativo'] == false ? 'Inativa' : 'Ativa'),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => abrirFormularioVaga(vaga: vaga),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => verCandidatos(vaga),
                  icon: const Icon(Icons.people),
                  label: const Text('Ver candidatos'),
                ),
                OutlinedButton.icon(
                  onPressed: () => confirmarRemocao(vaga),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ],
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
        child: Text('Sua empresa ainda não cadastrou nenhuma vaga.'),
      );
    }

    return RefreshIndicator(
      onRefresh: carregarVagas,
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
        title: const Text('Dashboard da Empresa'),
        actions: [
          IconButton(
            onPressed: carregarVagas,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormularioVaga(),
        icon: const Icon(Icons.add),
        label: const Text('Nova vaga'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'Olá, ${nome ?? 'empresa'} | Gestão de vagas e candidatos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: conteudo()),
        ],
      ),
    );
  }
}
