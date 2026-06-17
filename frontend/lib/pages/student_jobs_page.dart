import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';
import '../widgets/skill_selector.dart';
import 'chat_page.dart';
import 'chat_list_page.dart';
import '../widgets/sininho_notificacao.dart';

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
  int? meuUsuarioId;

  List<dynamic> vagas = [];
  List<dynamic> habilidadesDisponiveis = [];

  Set<int> minhasHabilidadesIds = {};
  Map<int, String> statusCandidaturasPorVaga = {};
  Map<int, int> idCandidaturasPorVaga = {};
  bool alunoTemCurriculoPerfil = false;

  double _raioBusca = 10.0;
  String _modalidadeFiltro = 'TODAS';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
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

    setState(() => isLoading = true);

    await Future.wait([
      carregarHabilidades(),
      carregarMeuPerfil(),
      carregarVagas(),
      carregarMinhasCandidaturas(),
    ]);

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> carregarHabilidades() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/habilidades'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) habilidadesDisponiveis = data;
      }
    } catch (_) {}
  }

  Future<void> carregarMeuPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        alunoTemCurriculoPerfil = (data['url_curriculo'] ?? '')
            .toString()
            .isNotEmpty;
        final relacoes = data['alunoHabilidades'];
        if (relacoes is List) {
          minhasHabilidadesIds = relacoes
              .map((relacao) => relacao['habilidade_id'])
              .whereType<int>()
              .toSet();
        }
      }
    } catch (_) {}
  }

  Future<void> carregarVagas() async {
    try {
      final queryParams = <String, String>{
        'distanciaKm': _raioBusca.round().toString(),
      };

      if (_modalidadeFiltro != 'TODAS') {
        queryParams['modalidade'] = _modalidadeFiltro;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/vagas',
        ).replace(queryParameters: queryParams),
        headers: {'Authorization': 'Bearer $token'},
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
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          statusCandidaturasPorVaga = {};
          idCandidaturasPorVaga = {};

          for (final candidatura in data) {
            final vagaId = candidatura['vaga_id'];
            final status = candidatura['status'];
            final candidaturaId = candidatura['id'];

            if (vagaId is int && status != null) {
              statusCandidaturasPorVaga[vagaId] = status.toString();
              if (candidaturaId is int) {
                idCandidaturasPorVaga[vagaId] = candidaturaId;
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> salvarMinhasHabilidades(Set<int> habilidadeIds) async {
    setState(() => isSavingSkills = true);
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/habilidades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'habilidadeIds': habilidadeIds.toList()}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => minhasHabilidadesIds = habilidadeIds);
        await carregarVagas();
        if (mounted) setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habilidades atualizadas com sucesso.')),
        );
      } else {
        String mensagem = 'Erro ao salvar habilidades.';
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
    } finally {
      if (mounted) setState(() => isSavingSkills = false);
    }
  }

  Future<void> confirmarCandidatura(dynamic vaga) async {
    PlatformFile? arquivoSelecionado;
    bool usarCurriculoPerfil = alunoTemCurriculoPerfil;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 8,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              title: const Text(
                'Detalhes da Vaga',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 500,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaga['titulo'] ?? 'Sem título',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nomeEmpresa(vaga),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            vaga['modalidade'] ?? 'Presencial',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Descrição',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vaga['descricao'] ?? 'Sem descrição detalhada.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if ((vaga['requisitos'] ?? '').toString().isNotEmpty) ...[
                        const Text(
                          'Requisitos Adicionais',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vaga['requisitos'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Text(
                        'Habilidades Exigidas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 12),
                      chipsHabilidades(habilidadesDaVaga(vaga)),
                      const SizedBox(height: 24),

                      const Divider(),
                      const SizedBox(height: 16),

                      const Text(
                        'Currículo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        alunoTemCurriculoPerfil
                            ? 'Use o currículo salvo no perfil ou envie outro PDF para esta vaga.'
                            : 'Envie um PDF para anexar à candidatura.',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (alunoTemCurriculoPerfil) ...[
                        RadioListTile<bool>(
                          value: true,
                          groupValue: usarCurriculoPerfil,
                          onChanged: (value) {
                            setDialogState(() {
                              usarCurriculoPerfil = true;
                              arquivoSelecionado = null;
                            });
                          },
                          title: const Text('Usar currículo do meu perfil'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: usarCurriculoPerfil,
                          onChanged: (value) {
                            setDialogState(() {
                              usarCurriculoPerfil = false;
                            });
                          },
                          title: const Text(
                            'Enviar outro currículo para esta vaga',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],

                      if (!usarCurriculoPerfil && arquivoSelecionado == null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'],
                                  withData: true,
                                );
                            if (result != null &&
                                result.files.first.bytes != null) {
                              setDialogState(
                                () => arquivoSelecionado = result.files.first,
                              );
                              setState(
                                () => arquivoSelecionado = result.files.first,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF7C3AED),
                          ),
                          label: const Text(
                            'Anexar Currículo (PDF)',
                            style: TextStyle(color: Color(0xFF7C3AED)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        )
                      else if (!usarCurriculoPerfil)
                        Card(
                          color: Colors.purple.shade50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.purple.shade100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    arquivoSelecionado!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setDialogState(
                                      () => arquivoSelecionado = null,
                                    );
                                    setState(() => arquivoSelecionado = null);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Confirmar Candidatura',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar == true) {
      await candidatar(
        vaga['id'],
        arquivoSelecionado,
        usarCurriculoPerfil: usarCurriculoPerfil,
      );
    }
  }

  Future<void> candidatar(
    int vagaId,
    PlatformFile? arquivo, {
    bool usarCurriculoPerfil = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/vagas/$vagaId/candidatar');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['useCurriculoPerfil'] = usarCurriculoPerfil.toString();

      if (!usarCurriculoPerfil && arquivo != null && arquivo.bytes != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'curriculo',
          arquivo.bytes!,
          filename: arquivo.name,
          contentType: MediaType('application', 'pdf'),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      String? mensagemApi;
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          mensagemApi = data['mensagem'] ?? data['message'];
        } catch (_) {}
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemApi ?? 'Candidatura enviada com sucesso.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemApi ?? 'Erro ao processar candidatura.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro de conexão com o servidor.')),
      );
    }
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

  Color corStatusCandidatura(String status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange.shade600;
      case 'ACEITA':
        return Colors.green.shade600;
      case 'REJEITADA':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color corFundoStatusCandidatura(String status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange.shade50;
      case 'ACEITA':
        return Colors.green.shade50;
      case 'REJEITADA':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  double? matchPercent(dynamic item) {
    final value = item['match_percent'] ?? item['pontuacao_compatibilidade'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double? distanciaKm(dynamic item) {
    final value = item['distancia_km'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String labelDistancia(dynamic vaga) {
    final distancia = distanciaKm(vaga);
    final modalidade = vaga['modalidade']?.toString();

    if (distancia != null) {
      return '${distancia.toStringAsFixed(1)} km';
    }

    if (modalidade == 'REMOTO') {
      return 'Remoto';
    }

    return 'Distância não disponível';
  }

  List<dynamic> habilidadesDaVaga(dynamic vaga) {
    final relacoes = vaga['vagaHabilidades'];
    if (relacoes is List) {
      return relacoes
          .map((relacao) => relacao['habilidade'])
          .where((h) => h != null)
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

  Widget chipsHabilidades(List<dynamic> habilidades) {
    if (habilidades.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: habilidades.map((habilidade) {
        final id = habilidade['id'];
        final alunoPossui = id is int && minhasHabilidadesIds.contains(id);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: alunoPossui
                ? const Color(0xFF7C3AED).withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alunoPossui
                  ? const Color(0xFF7C3AED).withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alunoPossui) ...[
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                habilidade['nome'] ?? 'Sem nome',
                style: TextStyle(
                  fontSize: 12,
                  color: alunoPossui
                      ? const Color(0xFF7C3AED)
                      : Colors.grey.shade700,
                  fontWeight: alunoPossui ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget cardMinhasHabilidades() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: isSavingSkills
          ? const Center(child: CircularProgressIndicator())
          : SkillSelector(
              title: 'Minhas Habilidades',
              habilidades: habilidadesDisponiveis,
              selectedIds: minhasHabilidadesIds,
              onChanged: (updated) async =>
                  await salvarMinhasHabilidades(updated),
            ),
    );
  }

  Widget cardVaga(dynamic vaga) {
    final int? vagaId = vaga['id'];
    final String? statusCandidatura = vagaId != null
        ? statusCandidaturasPorVaga[vagaId]
        : null;
    final bool jaCandidatou = statusCandidatura != null;
    final habilidades = habilidadesDaVaga(vaga);
    final match = matchPercent(vaga);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: jaCandidatou ? null : () => confirmarCandidatura(vaga),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaga['titulo'] ?? 'Sem título',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nomeEmpresa(vaga),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (match != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${match.round()}%',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vaga['modalidade'] ?? 'Presencial',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labelDistancia(vaga),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  vaga['descricao'] ?? 'Sem descrição detalhada.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),
                chipsHabilidades(habilidades),

                if (jaCandidatou) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: corFundoStatusCandidatura(statusCandidatura),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Candidatura ${labelStatusCandidatura(statusCandidatura)}',
                        style: TextStyle(
                          color: corStatusCandidatura(statusCandidatura),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  if (statusCandidatura == 'ACEITA' &&
                      meuUsuarioId != null &&
                      idCandidaturasPorVaga[vagaId] != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                candidaturaId: idCandidaturasPorVaga[vagaId]!,
                                vagaTitulo: vaga['titulo'] ?? 'Vaga',
                                token: token!,
                                meuUsuarioId: meuUsuarioId!,
                                isAluno: true, // 🛠️ CORREÇÃO APLICADA AQUI
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text(
                          'Abrir Chat com a Empresa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Toque para candidatar-se →',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          isLabelVisible: count > 0,
          backgroundColor: const Color(0xFF7C3AED),
          child: IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.black87,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListPage(
                    token: token!,
                    isAluno: true,
                  ), // 🛠️ CORREÇÃO APLICADA AQUI
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Row(
                    children: [
                      // 🔔 O SININHO ENTRA AQUI!
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const SininhoNotificacao(),
                      ),
                      // 💬 O Chat que já existia
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: buildChatBadge(),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          tooltip: 'Atualizar vagas',
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.black87,
                            size: 22,
                          ),
                          onPressed: isLoading ? null : carregarDados,
                        ),
                      ),
                      // 👤 O Perfil que já existia
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/student-profile'),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7C3AED),
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF7C3AED),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF7C3AED),
                      onRefresh: carregarDados,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  'Olá, ${nome?.split(' ')[0] ?? 'Aluno'} 👋',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Encontre sua próxima oportunidade',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        [
                                          {'value': 'TODAS', 'label': 'Todas'},
                                          {
                                            'value': 'REMOTO',
                                            'label': 'Remoto',
                                          },
                                          {
                                            'value': 'PRESENCIAL',
                                            'label': 'Presencial',
                                          },
                                          {
                                            'value': 'HIBRIDO',
                                            'label': 'Híbrido',
                                          },
                                        ].map((item) {
                                          final value = item['value']!;
                                          final selected =
                                              _modalidadeFiltro == value;

                                          return ChoiceChip(
                                            label: Text(item['label']!),
                                            selected: selected,
                                            onSelected: (_) async {
                                              setState(() {
                                                _modalidadeFiltro = value;
                                                isLoading = true;
                                              });
                                              await carregarVagas();
                                              if (!mounted) return;
                                              setState(() {
                                                isLoading = false;
                                              });
                                            },
                                            selectedColor: const Color(
                                              0xFFEDE9FE,
                                            ),
                                            labelStyle: TextStyle(
                                              color: selected
                                                  ? const Color(0xFF7C3AED)
                                                  : const Color(0xFF374151),
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: 'Buscar vagas em um raio de ',
                                        style: const TextStyle(
                                          color: Color(0xFF374151),
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${_raioBusca.toInt()} km',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      '50 km',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFF7C3AED),
                                    inactiveTrackColor: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.2),
                                    thumbColor: Colors.white,
                                    overlayColor: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.1),
                                    trackHeight: 6.0,
                                  ),
                                  child: Slider(
                                    value: _raioBusca,
                                    min: 1,
                                    max: 50,
                                    onChanged: (value) {
                                      setState(() {
                                        _raioBusca = value;
                                      });
                                    },
                                    onChangeEnd: (_) async {
                                      await carregarVagas();
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          cardMinhasHabilidades(),
                          const SizedBox(height: 24),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Text(
                              '${vagas.length} vagas encontradas',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (vagas.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'Nenhuma vaga disponível no momento.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: vagas
                                  .map((vaga) => cardVaga(vaga))
                                  .toList(),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
