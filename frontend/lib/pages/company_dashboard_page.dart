// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as import_html;
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
  Map<String, dynamic> resumoDashboard = {
    'vagasAtivas': 0,
    'vagasArquivadas': 0,
    'totalCandidatos': 0,
    'novasCandidaturas': 0,
  };

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
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    await Future.wait([
      carregarHabilidades(),
      carregarVagas(),
      carregarResumoDashboard(),
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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          habilidadesDisponiveis = data;
        }
      }
    } catch (_) {}
  }

  Future<void> carregarVagas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vagas'),
        headers: {'Authorization': 'Bearer $token'},
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

  Future<void> carregarResumoDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/empresas/me/dashboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            resumoDashboard = data;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> recarregarDashboard() async {
    await Future.wait([carregarVagas(), carregarResumoDashboard()]);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_nome');
    await prefs.remove('user_perfil');

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
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
    final cepController = TextEditingController(
      text: editando ? vaga['cep'] ?? '' : '',
    );
    final enderecoController = TextEditingController(
      text: editando ? vaga['endereco'] ?? '' : '',
    );
    final numeroController = TextEditingController(
      text: editando ? vaga['numero'] ?? '' : '',
    );
    final cidadeController = TextEditingController(
      text: editando ? vaga['cidade'] ?? '' : '',
    );
    final estadoController = TextEditingController(
      text: editando ? vaga['estado'] ?? '' : '',
    );

    String modalidade = editando ? vaga['modalidade'] ?? 'REMOTO' : 'REMOTO';

    if (modalidade == 'HÍBRIDO') {
      modalidade = 'HIBRIDO';
    }

    if (!['REMOTO', 'PRESENCIAL', 'HIBRIDO'].contains(modalidade)) {
      modalidade = 'REMOTO';
    }

    Set<int> habilidadeIdsSelecionadas = editando
        ? habilidadeIdsDaVaga(vaga)
        : <int>{};

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool salvando = false;
        bool buscandoCep = false;
        String? cepErro;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> buscarCep(String value) async {
              final cep = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (cep.length != 8) {
                setDialogState(() => cepErro = 'CEP inválido.');
                return;
              }

              setDialogState(() {
                buscandoCep = true;
                cepErro = null;
              });

              try {
                final response = await http.get(
                  Uri.parse('${ApiConfig.baseUrl}/enderecos/cep/$cep'),
                  headers: {'Authorization': 'Bearer $token'},
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  setDialogState(() {
                    enderecoController.text = data['logradouro'] ?? '';
                    cidadeController.text = data['cidade'] ?? '';
                    estadoController.text = data['estado'] ?? '';
                    cepErro = null;
                  });
                } else {
                  setDialogState(() => cepErro = 'CEP não encontrado.');
                }
              } catch (_) {
                setDialogState(() => cepErro = 'Erro ao consultar CEP.');
              } finally {
                setDialogState(() => buscandoCep = false);
              }
            }

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
                  'cep': cepController.text.trim(),
                  'endereco': enderecoController.text.trim(),
                  'numero': numeroController.text.trim(),
                  'cidade': cidadeController.text.trim(),
                  'estado': estadoController.text.trim(),
                  'latitude': vaga?['latitude'],
                  'longitude': vaga?['longitude'],
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
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  if (!scaffoldContext.mounted) return;
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        editando
                            ? 'Vaga atualizada com sucesso.'
                            : 'Vaga criada com sucesso.',
                      ),
                    ),
                  );

                  await recarregarDashboard();
                } else {
                  String mensagem = 'Erro ao salvar vaga.';

                  if (response.body.isNotEmpty) {
                    final data = jsonDecode(response.body);
                    mensagem = data['message'] ?? mensagem;
                  }

                  if (!scaffoldContext.mounted) return;
                  ScaffoldMessenger.of(
                    scaffoldContext,
                  ).showSnackBar(SnackBar(content: Text(mensagem)));

                  if (mounted) {
                    setDialogState(() {
                      salvando = false;
                    });
                  }
                }
              } catch (_) {
                if (!scaffoldContext.mounted) return;
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
                          initialValue: modalidade,
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cepController,
                          decoration:
                              const InputDecoration(
                                labelText: 'CEP',
                                border: OutlineInputBorder(),
                              ).copyWith(
                                errorText: cepErro,
                                suffixIcon: buscandoCep
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                          onChanged: (value) {
                            final cep = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cep.length == 8) {
                              buscarCep(value);
                            } else if (cepErro != null) {
                              setDialogState(() => cepErro = null);
                            }
                          },
                          validator: (value) {
                            if (modalidade == 'REMOTO') return null;
                            final cep = (value ?? '').replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            if (cep.length != 8) {
                              return 'Informe um CEP válido.';
                            }
                            if (cepErro != null) return cepErro;
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: enderecoController,
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (modalidade == 'REMOTO') return null;

                            if ((value ?? '').trim().isEmpty) {
                              return 'Informe o endereço para vagas presenciais ou híbridas.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: numeroController,
                          decoration: const InputDecoration(
                            labelText: 'Número',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: cidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (modalidade == 'REMOTO') return null;

                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Informe a cidade.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: estadoController,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (modalidade == 'REMOTO') return null;

                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Informe o estado.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
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
    cepController.dispose();
    enderecoController.dispose();
    numeroController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga arquivada com sucesso.')),
        );

        await recarregarDashboard();
      } else {
        String mensagem = 'Erro ao arquivar vaga.';

        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem)));
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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga desarquivada com sucesso.')),
        );

        await recarregarDashboard();
      } else {
        String mensagem = 'Erro ao desarquivar vaga.';

        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem)));
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
        headers: {'Authorization': 'Bearer $token'},
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
        body: jsonEncode({'status': novoStatus}),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));

      return false;
    } catch (_) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );

      return false;
    }
  }

  Future<void> abrirPdfAutenticado(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o currículo.')),
        );
        return;
      }

      final blob = import_html.Blob([response.bodyBytes], 'application/pdf');
      final url = import_html.Url.createObjectUrlFromBlob(blob);
      import_html.window.open(url, '_blank');
      Future.delayed(const Duration(seconds: 2), () {
        import_html.Url.revokeObjectUrl(url);
      });
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao abrir currículo.')));
    }
  }

  Future<void> abrirPerfilCandidato(int alunoId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/empresas/candidatos/$alunoId/perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar perfil do candidato.'),
          ),
        );
        return;
      }

      final perfil = jsonDecode(response.body);
      final habilidades = perfil['habilidades'] is List
          ? perfil['habilidades'] as List
          : [];
      final candidaturas = perfil['candidaturas'] is List
          ? perfil['candidaturas'] as List
          : [];

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(perfil['nome'] ?? 'Perfil do candidato'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Email: ${perfil['email'] ?? 'Não informado'}'),
                    Text('Curso: ${perfil['curso'] ?? 'Não informado'}'),
                    Text(
                      'Instituição: ${perfil['instituicao'] ?? 'Não informada'}',
                    ),
                    Text(
                      'Conclusão: ${perfil['ano_conclusao'] ?? 'Não informada'}',
                    ),
                    Text('Endereço: ${perfil['endereco'] ?? 'Não informado'}'),
                    const SizedBox(height: 12),
                    const Text(
                      'Habilidades',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    habilidades.isEmpty
                        ? const Text('Nenhuma habilidade cadastrada.')
                        : chipsHabilidades(habilidades),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (perfil['tem_curriculo'] == true)
                          TextButton.icon(
                            onPressed: () => abrirPdfAutenticado(
                              '/alunos/${perfil['id']}/curriculo',
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Abrir currículo do perfil'),
                          )
                        else
                          const Text('Currículo do perfil não anexado.'),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'Candidaturas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...candidaturas.map((candidatura) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(candidatura['vaga_titulo'] ?? 'Vaga'),
                        subtitle: Text(
                          'Status: ${candidatura['status'] ?? '-'}',
                        ),
                        trailing:
                            candidatura['tem_curriculo_candidatura'] == true
                            ? TextButton(
                                onPressed: () => abrirPdfAutenticado(
                                  '/candidaturas/${candidatura['id']}/curriculo',
                                ),
                                child: const Text('Currículo'),
                              )
                            : null,
                      );
                    }),
                  ],
                ),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
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
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 760,
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                child: SingleChildScrollView(
                  child: candidaturasDialog.isEmpty
                      ? const Text(
                          'Nenhum candidato encontrado para esta vaga.',
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(candidaturasDialog.length, (
                            index,
                          ) {
                            final candidatura = candidaturasDialog[index];
                            final aluno = candidatura['aluno'];
                            final usuario = aluno?['usuario'];
                            final candidaturaId = candidatura['id'];
                            final nomeAluno =
                                usuario?['nome_exibicao'] ??
                                usuario?['nome'] ??
                                'Aluno sem nome';
                            final curso =
                                aluno?['curso'] ?? 'Curso não informado';
                            final statusAtual =
                                candidatura['status']?.toString() ?? 'PENDENTE';
                            final statusDropdown =
                                [
                                  'PENDENTE',
                                  'ACEITA',
                                  'REJEITADA',
                                ].contains(statusAtual)
                                ? statusAtual
                                : 'PENDENTE';
                            final match = matchPercent(candidatura);
                            final curriculoPath = candidatura['curriculo_path']
                                ?.toString();
                            final temCurriculo =
                                curriculoPath != null &&
                                curriculoPath != 'null' &&
                                curriculoPath.isNotEmpty;

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        child: Icon(
                                          iconeStatusCandidatura(statusAtual),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nomeAluno,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Curso: $curso',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        avatar: Icon(
                                          iconeStatusCandidatura(statusAtual),
                                          size: 18,
                                        ),
                                        label: Text(
                                          labelStatusCandidatura(statusAtual),
                                        ),
                                      ),
                                      chipMatch(match),
                                      if (aluno?['id'] is int)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () =>
                                              abrirPerfilCandidato(aluno['id']),
                                          icon: const Icon(
                                            Icons.person_search,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Perfil completo',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      if (temCurriculo)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {
                                            abrirPdfAutenticado(
                                              '/candidaturas/$candidaturaId/curriculo',
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Visualizar Currículo',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      if (statusAtual == 'ACEITA' &&
                                          meuUsuarioId != null)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 0,
                                            ),
                                            minimumSize: const Size(0, 32),
                                          ),
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                  candidaturaId: candidaturaId,
                                                  vagaTitulo:
                                                      vaga['titulo'] ?? 'Vaga',
                                                  token: token!,
                                                  meuUsuarioId: meuUsuarioId!,
                                                  isAluno: false,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.chat,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Abrir Chat',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 260,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: statusDropdown,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Alterar status',
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
                                                    candidaturaId:
                                                        candidaturaId,
                                                    novoStatus: novoStatus,
                                                  );

                                              if (!sucesso) return;

                                              setDialogState(() {
                                                candidaturasDialog[index]['status'] =
                                                    novoStatus;
                                              });
                                              await carregarResumoDashboard();
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
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
          .map((nome) => {'id': null, 'nome': nome.toString()})
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

  // 🛠️ MÉTODOS VISUAIS E RESPONSIVOS (ISSUE #97)

  Widget chipsHabilidades(List<dynamic> habilidades) {
    if (habilidades.isEmpty) {
      return const Text(
        'Nenhuma habilidade selecionada.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: habilidades.map((habilidade) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withAlpha(20), // 0.08
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF7C3AED).withAlpha(51),
            ), // 0.2
          ),
          child: Text(
            habilidade['nome'] ?? 'Sem nome',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget cardVaga(dynamic vaga) {
    final bool arquivada = vagaArquivada(vaga);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Opacity(
          opacity: arquivada ? 0.6 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vaga['titulo'] ?? 'Sem título',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: arquivada
                          ? Colors.grey.shade100
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      arquivada ? 'Arquivada' : 'Ativa',
                      style: TextStyle(
                        color: arquivada
                            ? Colors.grey.shade600
                            : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vaga['modalidade'] ?? '-',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                vaga['descricao'] ?? 'Sem descrição.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.4,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),
              chipsHabilidades(habilidadesDaVaga(vaga)),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => verCandidatos(vaga),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: const Text(
                      'Ver Candidatos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: arquivada
                        ? null
                        : () => abrirFormularioVaga(vaga: vaga),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: arquivada
                        ? () => confirmarDesarquivamento(vaga)
                        : () => confirmarArquivamento(vaga),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: arquivada
                          ? Colors.green.shade600
                          : Colors.red.shade400,
                      side: BorderSide(
                        color: arquivada
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      arquivada
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 18,
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
          label: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          isLabelVisible: count > 0,
          backgroundColor: const Color(0xFF7C3AED),
          child: IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            tooltip: 'Mensagens/Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatListPage(token: token!, isAluno: false),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardMetrica(
    String titulo,
    String valor,
    IconData icone,
    Color corBase,
  ) {
    return Expanded(
      flex: 1,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
        ), // 👈 ERRO PRINCIPAL CORRIGIDO
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5), // 0.02
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: corBase.withAlpha(26), // 0.1
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: corBase, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoPrincipal() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    final listaExibicao = selectedMenuIndex == 0
        ? vagasAtivas
        : vagasArquivadas;

    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: recarregarDashboard,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // CABEÇALHO DO DASHBOARD
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nome ?? 'Sua Empresa',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // CARDS SUPERIORES
          if (selectedMenuIndex == 0) ...[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                Row(
                  children: [
                    _buildCardMetrica(
                      'Vagas Ativas',
                      '${resumoDashboard['vagasAtivas'] ?? vagasAtivas.length}',
                      Icons.work_outline,
                      const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 16),
                    _buildCardMetrica(
                      'Vagas Arquivadas',
                      '${resumoDashboard['vagasArquivadas'] ?? vagasArquivadas.length}',
                      Icons.archive_outlined,
                      Colors.orange,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildCardMetrica(
                      'Total de Candidatos',
                      '${resumoDashboard['totalCandidatos'] ?? 0}',
                      Icons.people_outline,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildCardMetrica(
                      'Novas Candidaturas',
                      '${resumoDashboard['novasCandidaturas'] ?? 0}',
                      Icons.fiber_new_outlined,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // LISTA DE VAGAS
          Text(
            selectedMenuIndex == 0 ? 'Vagas Ativas' : 'Vagas Arquivadas',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          if (listaExibicao.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  selectedMenuIndex == 0
                      ? 'Não possui vagas ativas no momento.'
                      : 'Não possui vagas arquivadas no momento.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ),
            )
          else
            ...listaExibicao.map((vaga) => cardVaga(vaga)),

          const SizedBox(
            height: 60,
          ), // Espaço pro botão flutuante não tapar o ultimo card
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🛠️ RESPONSIVIDADE: Verifica se a tela é pequena (Mobile)
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final bool mostrandoArquivadas = selectedMenuIndex == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Nexa',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C3AED),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(26), // 0.1
        actions: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: 4.0),
            child: SininhoNotificacao(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: buildChatBadge(),
          ),
          IconButton(
            onPressed: recarregarDashboard,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/company-profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED), width: 2),
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF7C3AED),
                child: Icon(Icons.business, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),

      // 🛠️ MENU INFERIOR APENAS PARA MOBILE
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: selectedMenuIndex,
              onTap: (index) => setState(() => selectedMenuIndex = index),
              selectedItemColor: const Color(0xFF7C3AED),
              unselectedItemColor: Colors.grey.shade500,
              backgroundColor: Colors.white,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'Vagas Ativas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.archive_outlined),
                  activeIcon: Icon(Icons.archive),
                  label: 'Arquivadas',
                ),
              ],
            )
          : null,

      floatingActionButton: mostrandoArquivadas
          ? null
          : FloatingActionButton.extended(
              onPressed: () => abrirFormularioVaga(),
              backgroundColor: const Color(0xFF7C3AED),
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nova vaga',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

      body: isMobile
          // Se for Mobile, ocupa a tela toda com o conteúdo
          ? _buildConteudoPrincipal()
          // Se for Desktop/Tablet, usa o menu lateral (NavigationRail)
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedMenuIndex,
                  onDestinationSelected: (index) =>
                      setState(() => selectedMenuIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(
                    color: Color(0xFF7C3AED),
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.work_outline),
                      selectedIcon: const Icon(Icons.work),
                      label: Text('Ativas (${vagasAtivas.length})'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.archive_outlined),
                      selectedIcon: const Icon(Icons.archive),
                      label: Text('Arquivadas (${vagasArquivadas.length})'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(child: _buildConteudoPrincipal()),
              ],
            ),
    );
  }
}
