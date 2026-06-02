import 'dart:convert';
import 'dart:html' as importHTML;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/skill_selector.dart';
import '../config/api_config.dart';
import 'chat_page.dart'; 
import 'chat_list_page.dart'; 
import '../widgets/sininho_notificacao.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  bool isLoading = true;
  String? token;
  String? nome;
  int? meuUsuarioId; 

  int selectedMenuIndex = 0;

  List<dynamic> vagas = [];
  List<dynamic> habilidadesDisponiveis = [];

  @override
  void initState() {
    super.initState();
    carregarSessaoEVagas();
  }

  Future<void> carregarSessaoEVagas() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token');
    nome = prefs.getString('user_nome');
    
    final rawUserId = prefs.get('user_id');
    if (rawUserId is int) {
      meuUsuarioId = rawUserId;
    } else if (rawUserId is String) {
      meuUsuarioId = int.tryParse(rawUserId);
    }

    if (token == null || token!.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    await Future.wait([
        carregarHabilidades(),
        carregarVagas(),
    ]);
  }

  bool vagaArquivada(dynamic vaga) {
    return vaga['ativo'] == 0 || vaga['ativo'] == false;
  }

  List<dynamic> get vagasAtivas {
    return vagas.where((vaga) => !vagaArquivada(vaga)).toList();
  }

  List<dynamic> get vagasArquivadas {
    return vagas.where((vaga) => vagaArquivada(vaga)).toList();
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
    } catch (_) {
    }
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

        setState(() {
          vagas = data is List ? data : [];
          isLoading = false;
        });
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

    Set<int> habilidadeIdsSelecionadas =
    editando ? habilidadeIdsDaVaga(vaga) : <int>{};

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
                'habilidadeIds': habilidadeIdsSelecionadas.toList(),
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
                            const SizedBox(height: 16),
                            SkillSelector(
                            title: 'Habilidades exigidas pela vaga',
                            habilidades: habilidadesDisponiveis,
                            selectedIds: habilidadeIdsSelecionadas,
                            onChanged: (updated) {
                                setDialogState(() {
                                habilidadeIdsSelecionadas = updated;
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

  Future<void> confirmarArquivamento(dynamic vaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Arquivar vaga'),
          content: Text(
            'Deseja realmente arquivar a vaga "${vaga['titulo'] ?? 'Sem título'}"?\n\n'
            'Ela não aparecerá mais para alunos, mas as candidaturas serão preservadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await arquivarVaga(vaga['id']);
    }
  }

  Future<void> confirmarDesarquivamento(dynamic vaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Desarquivar vaga'),
          content: Text(
            'Deseja realmente desarquivar a vaga "${vaga['titulo'] ?? 'Sem título'}"?\n\n'
            'Ela voltará a aparecer para os alunos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desarquivar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await desarquivarVaga(vaga['id']);
    }
  }

  Future<void> arquivarVaga(int vagaId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId/arquivar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga arquivada com sucesso.')),
        );

        await carregarVagas();
      } else {
        String mensagem = 'Erro ao arquivar vaga.';

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
    }
  }

  Future<void> desarquivarVaga(int vagaId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId/desarquivar'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga desarquivada com sucesso.')),
        );

        await carregarVagas();
      } else {
        String mensagem = 'Erro ao desarquivar vaga.';

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

  String labelStatusCandidatura(String status) {
      switch (status) {
          case 'PENDENTE':
          return 'Pendente';
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

  double? matchPercent(dynamic item) {
      final value = item['match_percent'] ?? item['pontuacao_compatibilidade'];

      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);

      return null;
  }

  Widget chipMatch(double? match) {
      if (match == null) return const SizedBox.shrink();

      return Chip(
          avatar: const Icon(Icons.insights, size: 18),
          label: Text('${match.round()}% match'),
      );
  }

  Future<bool> atualizarStatusCandidatura({
      required int candidaturaId,
      required String novoStatus,
      }) async {
      try {
          final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/candidaturas/$candidaturaId/status'),
          headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
              'status': novoStatus,
          }),
          );

          if (!mounted) return false;

          if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
              content: Text('Status da candidatura atualizado com sucesso.'),
              ),
          );

          return true;
          }

          String mensagem = 'Erro ao atualizar status da candidatura.';

          if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
          }

          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
          );

          return false;
      } catch (_) {
          if (!mounted) return false;

          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão com o servidor.')),
          );

          return false;
      }
  }

  void abrirDialogCandidatos(dynamic vaga, List<dynamic> candidaturas) {
    final List<dynamic> candidaturasDialog = List<dynamic>.from(candidaturas);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Candidatos - ${vaga['titulo'] ?? 'Vaga'}'),
              content: SizedBox(
                width: 760,
                child: candidaturasDialog.isEmpty
                    ? const Text('Nenhum candidato encontrado para esta vaga.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: candidaturasDialog.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final candidatura = candidaturasDialog[index];
                          final aluno = candidatura['aluno'];
                          final usuario = aluno?['usuario'];

                          final candidaturaId = candidatura['id'];

                          final nomeAluno = usuario?['nome_exibicao'] ??
                              usuario?['nome'] ??
                              'Aluno sem nome';

                          final curso = aluno?['curso'] ?? 'Curso não informado';
                          final statusAtual =
                              candidatura['status']?.toString() ?? 'PENDENTE';
                          final match = matchPercent(candidatura);

                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(iconeStatusCandidatura(statusAtual)),
                            ),
                            title: Text(nomeAluno),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Curso: $curso'),
                                  
                                  if (candidatura['curriculo_path'] != null && candidatura['curriculo_path'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        final String? path = candidatura['curriculo_path']?.toString();
  
                                        if (path != null && path != 'null' && path.isNotEmpty) {
                                          final String urlCompleta = '${ApiConfig.baseUrl}/files/curriculos/$path';
                                          importHTML.window.open(urlCompleta, '_blank');
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Erro: Arquivo do currículo não encontrado para este candidato.')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 16),
                                      label: const Text(
                                        'Visualizar Currículo',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        avatar: Icon(
                                          iconeStatusCandidatura(statusAtual),
                                          size: 18,
                                        ),
                                        label: Text(labelStatusCandidatura(statusAtual)),
                                      ),
                                      chipMatch(match),
                                      
                                      if (statusAtual == 'ACEITA' && meuUsuarioId != null)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                          ),
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                  candidaturaId: candidaturaId,
                                                  vagaTitulo: vaga['titulo'] ?? 'Vaga',
                                                  token: token!,
                                                  meuUsuarioId: meuUsuarioId!,
                                                  isAluno: false, // 👈 EMPRESA ABRINDO O CHAT
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.chat, size: 16),
                                          label: const Text('Abrir Chat', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: SizedBox(
                              width: 170,
                              child: DropdownButtonFormField<String>(
                                value: ['PENDENTE', 'ACEITA', 'REJEITADA']
                                        .contains(statusAtual)
                                    ? statusAtual
                                    : 'PENDENTE',
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'PENDENTE',
                                    child: Text('Pendente'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ACEITA',
                                    child: Text('Aceita'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'REJEITADA',
                                    child: Text('Rejeitada'),
                                  ),
                                ],
                                onChanged: candidaturaId == null
                                    ? null
                                    : (novoStatus) async {
                                        if (novoStatus == null ||
                                            novoStatus == statusAtual) {
                                          return;
                                        }

                                        final sucesso =
                                            await atualizarStatusCandidatura(
                                          candidaturaId: candidaturaId,
                                          novoStatus: novoStatus,
                                        );

                                        if (!sucesso) return;

                                        setDialogState(() {
                                          candidaturasDialog[index]['status'] =
                                              novoStatus;
                                        });
                                      },
                              ),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
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

  Set<int> habilidadeIdsDaVaga(dynamic vaga) {
    return habilidadesDaVaga(vaga)
        .where((habilidade) => habilidade['id'] is int)
        .map<int>((habilidade) => habilidade['id'] as int)
        .toSet();
  }

  Widget chipsHabilidades(List<dynamic> habilidades) {
    if (habilidades.isEmpty) {
        return const Text(
        'Nenhuma habilidade selecionada.',
        style: TextStyle(fontStyle: FontStyle.italic),
        );
    }

    return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: habilidades.map((habilidade) {
        return Chip(
            avatar: const Icon(Icons.label_outline, size: 18),
            label: Text(habilidade['nome'] ?? 'Sem nome'),
        );
        }).toList(),
    );
  }

  Widget cardVaga(dynamic vaga) {
    final bool arquivada = vagaArquivada(vaga);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: arquivada ? 0.78 : 1,
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
                    label: Text(vaga['modalidade'] ?? '-'),
                    avatar: const Icon(Icons.work_outline, size: 18),
                  ),
                  Chip(
                    label: Text(arquivada ? 'Arquivada' : 'Ativa'),
                    avatar: Icon(
                      arquivada
                          ? Icons.archive_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 12),
                const Text(
                'Habilidades exigidas',
                style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                chipsHabilidades(habilidadesDaVaga(vaga)),

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
                    onPressed:
                        arquivada ? null : () => abrirFormularioVaga(vaga: vaga),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => verCandidatos(vaga),
                    icon: const Icon(Icons.people),
                    label: const Text('Ver candidatos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: arquivada
                        ? () => confirmarDesarquivamento(vaga)
                        : () => confirmarArquivamento(vaga),
                    icon: Icon(
                      arquivada
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    label: Text(arquivada ? 'Desarquivar' : 'Arquivar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget listaDeVagas(List<dynamic> lista, String mensagemVazia) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(mensagemVazia, textAlign: TextAlign.center),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: carregarVagas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          return cardVaga(lista[index]);
        },
      ),
    );
  }

  Widget conteudoSelecionado() {
    if (selectedMenuIndex == 0) {
      return listaDeVagas(
        vagasAtivas,
        'Sua empresa não possui vagas ativas no momento.',
      );
    }

    return listaDeVagas(
      vagasArquivadas,
      'Sua empresa não possui vagas arquivadas no momento.',
    );
  }

  Widget menuLateral() {
    return NavigationRail(
      selectedIndex: selectedMenuIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedMenuIndex = index;
        });
      },
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.work_outline),
          selectedIcon: const Icon(Icons.work),
          label: Text('Vagas ativas (${vagasAtivas.length})'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.archive_outlined),
          selectedIcon: const Icon(Icons.archive),
          label: Text('Arquivadas (${vagasArquivadas.length})'),
        ),
      ],
    );
  }

  String tituloTela() {
    if (selectedMenuIndex == 0) {
      return 'Vagas ativas';
    }

    return 'Vagas arquivadas';
  }

  String subtituloTela() {
    if (selectedMenuIndex == 0) {
      return 'Vagas visíveis para alunos e abertas para candidatura.';
    }

    return 'Vagas ocultas para alunos, com histórico de candidatos preservado.';
  }

  Future<int> buscarContagemChats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats/contagem'), 
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['total'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Widget buildChatBadge() {
    return FutureBuilder<int>(
      future: buscarContagemChats(), 
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Badge(
          label: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11)),
          isLabelVisible: count > 0,
          backgroundColor: const Color(0xFF7C3AED),
          child: IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            tooltip: 'Mensagens/Chats',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatListPage(token: token!, isAluno: false), // 👈 EMPRESA ABRINDO A LISTA
              ));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mostrandoArquivadas = selectedMenuIndex == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard da Empresa', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // 🔔  WIDGET DE SININHO 
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 4.0),
            child: SininhoNotificacao(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: buildChatBadge(),
          ),
          IconButton(
            onPressed: carregarVagas,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.black87),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/company-profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 12, left: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED), width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF7C3AED),
                child: Icon(Icons.business, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: mostrandoArquivadas
          ? null
          : FloatingActionButton.extended(
              onPressed: () => abrirFormularioVaga(),
              icon: const Icon(Icons.add),
              label: const Text('Nova vaga'),
            ),
      body: Row(
        children: [
          menuLateral(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${nome ?? 'empresa'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tituloTela(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtituloTela()),
                    ],
                  ),
                ),
                Expanded(child: conteudoSelecionado()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}