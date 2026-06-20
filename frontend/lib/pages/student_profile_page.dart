// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as import_html;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../widgets/skill_selector.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingCurriculo = false;
  String? _token;

  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();

  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();

  final _instituicaoController = TextEditingController();
  final _cursoController = TextEditingController();
  final _anoController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _urlCurriculo;
  String? _cepOriginal;
  String? _enderecoOriginal;

  List<dynamic> _habilidadesDisponiveis = [];
  Set<int> _habilidadesSelecionadas = {};

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token == null || _token!.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    try {
      await _carregarHabilidadesDisponiveis();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Mapeamento à prova de falhas: procura os dados na raiz ou dentro do objeto 'usuario'/'aluno'
        final usuario = data['usuario'] ?? data;
        final aluno = data['aluno'] ?? data;

        setState(() {
          _nomeController.text =
              usuario['nome_exibicao'] ?? usuario['nome'] ?? '';
          _emailController.text = usuario['email'] ?? '';
          _cpfController.text =
              data['cpf'] ?? aluno['cpf'] ?? usuario['cpf'] ?? '';

          _cepController.text =
              data['cep'] ?? aluno['cep'] ?? usuario['cep'] ?? '';
          _enderecoController.text =
              data['endereco'] ??
              aluno['endereco'] ??
              usuario['endereco'] ??
              '';

          final lat =
              data['latitude'] ?? aluno['latitude'] ?? usuario['latitude'];
          final lng =
              data['longitude'] ?? aluno['longitude'] ?? usuario['longitude'];
          _latitude = lat != null ? double.tryParse(lat.toString()) : null;
          _longitude = lng != null ? double.tryParse(lng.toString()) : null;

          _instituicaoController.text =
              data['instituicao'] ?? aluno['instituicao'] ?? '';
          _cursoController.text = data['curso'] ?? aluno['curso'] ?? '';
          _anoController.text =
              data['ano_conclusao']?.toString() ??
              aluno['ano_conclusao']?.toString() ??
              '';

          _urlCurriculo = data['url_curriculo'] ?? aluno['url_curriculo'];
          _cepOriginal = _cepController.text;
          _enderecoOriginal = _enderecoController.text;

          final relacoes =
              data['alunoHabilidades'] ?? aluno['alunoHabilidades'];
          if (relacoes is List) {
            _habilidadesSelecionadas = relacoes
                .map((relacao) => relacao['habilidade_id'])
                .whereType<int>()
                .toSet();
          }

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _mostrarErro('Erro ao carregar dados do perfil.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro de conexão com o servidor.');
    }
  }

  String _onlyNumbers(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _carregarHabilidadesDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/habilidades'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _habilidadesDisponiveis = data;
        }
      }
    } catch (_) {}
  }

  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = _onlyNumbers(cep);
    if (cepLimpo.length != 8) return;

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _enderecoController.text =
                "${data['logradouro']}, ${data['bairro']} - ${data['localidade']}/${data['uf']}";
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _abrirCurriculo({bool download = false}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/curriculo'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode != 200) {
        _mostrarErro('Não foi possível abrir o currículo.');
        return;
      }

      final blob = import_html.Blob([response.bodyBytes], 'application/pdf');
      final url = import_html.Url.createObjectUrlFromBlob(blob);

      if (download) {
        final anchor = import_html.AnchorElement(href: url)
          ..download = _urlCurriculo?.split('/').last ?? 'curriculo.pdf';
        anchor.click();
      } else {
        import_html.window.open(url, '_blank');
      }

      Future.delayed(const Duration(seconds: 2), () {
        import_html.Url.revokeObjectUrl(url);
      });
    } catch (_) {
      _mostrarErro('Erro ao abrir currículo.');
    }
  }

  Future<void> _alterarCurriculo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final isPdf = file.extension?.toLowerCase() == 'pdf';

      if (!isPdf || file.bytes == null) {
        _mostrarErro('Envie um currículo em PDF.');
        return;
      }

      if (file.size > 5 * 1024 * 1024) {
        _mostrarErro('O currículo deve ter no máximo 5MB.');
        return;
      }

      setState(() => _isUploadingCurriculo = true);

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/curriculo'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'curriculo',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _urlCurriculo = data['url_curriculo']?.toString();
        });
        await _carregarPerfil();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currículo atualizado com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String mensagem = 'Erro ao atualizar currículo.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }
        _mostrarErro(mensagem);
      }
    } catch (_) {
      if (!mounted) return;
      _mostrarErro('Erro ao selecionar ou enviar currículo.');
    } finally {
      if (mounted) setState(() => _isUploadingCurriculo = false);
    }
  }

  Future<void> _salvarPerfil() async {
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final enderecoAlterado =
        _onlyNumbers(_cepController.text) != _onlyNumbers(_cepOriginal ?? '') ||
        _enderecoController.text.trim() != (_enderecoOriginal ?? '').trim();

    final payload = <String, dynamic>{
      'nome_exibicao': _nomeController.text.trim(),
      'cep': _onlyNumbers(_cepController.text),
      'endereco': _enderecoController.text,
      'instituicao': _instituicaoController.text,
      'curso': _cursoController.text,
      'ano_conclusao': int.tryParse(_anoController.text),
    };

    if (!enderecoAlterado && _hasValidCoordinates(_latitude, _longitude)) {
      payload['latitude'] = _latitude;
      payload['longitude'] = _longitude;
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alunoAtualizado = data['aluno'] ?? data;
        final usuarioAtualizado = alunoAtualizado['usuario'] ?? data['usuario'];
        final nomeAtualizado = usuarioAtualizado?['nome_exibicao']?.toString();

        if (nomeAtualizado != null && nomeAtualizado.isNotEmpty) {
          _nomeController.text = nomeAtualizado;
          await prefs.setString('user_nome', nomeAtualizado);
        }

        final habilidadesSalvas = await _salvarHabilidades();
        if (!mounted) return;

        if (!habilidadesSalvas) {
          setState(() => _isSaving = false);
          _mostrarErro('Perfil salvo, mas houve erro ao salvar habilidades.');
          return;
        }

        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        await _carregarPerfil();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String mensagem = 'Erro ao salvar alterações.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }
        setState(() => _isSaving = false);
        _mostrarErro(mensagem);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _mostrarErro('Erro de conexão com o servidor.');
    }
  }

  Future<bool> _salvarHabilidades() async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/alunos/me/habilidades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'habilidadeIds': _habilidadesSelecionadas.toList()}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sair', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_nome');
    await prefs.remove('user_perfil');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  // ---- WIDGETS DE UI ----

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isReadOnly = false,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                _isEditing && !isReadOnly
                    ? TextFormField(
                        controller: controller,
                        onChanged: onChanged,
                        keyboardType: keyboardType,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      )
                    : Text(
                        controller.text.isEmpty
                            ? 'Não informado'
                            : controller.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isReadOnly && _isEditing
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (!_isEditing)
                const Icon(Icons.edit, color: Color(0xFFD1D5DB), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  List<dynamic> get _habilidadesSelecionadasDetalhadas {
    return _habilidadesDisponiveis.where((habilidade) {
      final id = habilidade['id'];
      return id is int && _habilidadesSelecionadas.contains(id);
    }).toList();
  }

  bool _hasValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  Widget _buildEnderecoResumo() {
    final endereco = _enderecoController.text.trim();
    final cep = _cepController.text.trim();

    if (endereco.isEmpty && cep.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 32, top: 8),
        child: Text(
          'Localização ainda não definida',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 32, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (endereco.isNotEmpty)
                  Text(
                    endereco,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13,
                    ),
                  ),
                if (cep.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: endereco.isNotEmpty ? 4 : 0),
                    child: Text(
                      'CEP: $cep',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7C3AED),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: const Color(0xFF7C3AED),
              ),
              onPressed: () {
                if (_isEditing) {
                  _salvarPerfil();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho (Foto e Nome)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                      ? SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: _nomeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: UnderlineInputBorder(),
                            ),
                          ),
                        )
                      : Text(
                          _nomeController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    _cursoController.text.isEmpty
                        ? 'Curso não informado'
                        : _cursoController.text,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // DADOS PESSOAIS
                  _buildCard(
                    title: 'Dados Pessoais',
                    children: [
                      _buildField(
                        label: 'E-mail',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        isReadOnly: true,
                      ),
                      _buildField(
                        label: 'CPF',
                        icon: Icons.badge_outlined,
                        controller: _cpfController,
                        isReadOnly: true,
                      ),

                      if (_isEditing) ...[
                        _buildField(
                          label: 'Editar CEP',
                          icon: Icons.location_on_outlined,
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            if (val.length == 8 || val.length == 9) {
                              _buscarCEP(val);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32, bottom: 8),
                          child: Text(
                            'Endereço autocompletado:\n${_enderecoController.text}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildField(
                          label: 'Endereço Completo',
                          icon: Icons.location_on_outlined,
                          controller: _enderecoController,
                          isReadOnly: true,
                        ),
                      ],

                      _buildEnderecoResumo(),
                    ],
                  ),

                  // FORMAÇÃO ACADÊMICA
                  _buildCard(
                    title: 'Formação Acadêmica',
                    children: [
                      _buildField(
                        label: 'Instituição',
                        icon: Icons.account_balance_outlined,
                        controller: _instituicaoController,
                      ),
                      _buildField(
                        label: 'Curso',
                        icon: Icons.school_outlined,
                        controller: _cursoController,
                      ),
                      _buildField(
                        label: 'Previsão de Formatura',
                        icon: Icons.calendar_today_outlined,
                        controller: _anoController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  // HABILIDADES
                  _buildCard(
                    title: 'Habilidades',
                    children: [
                      if (_isEditing)
                        SkillSelector(
                          title: 'Minhas habilidades',
                          habilidades: _habilidadesDisponiveis,
                          selectedIds: _habilidadesSelecionadas,
                          onChanged: (updated) {
                            setState(() {
                              _habilidadesSelecionadas = updated;
                            });
                          },
                        )
                      else
                        _habilidadesSelecionadasDetalhadas.isEmpty
                            ? const Text(
                                'Nenhuma habilidade selecionada.',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _habilidadesSelecionadasDetalhadas
                                    .map(
                                      (hab) => Chip(
                                        label: Text(
                                          hab['nome'] ?? 'Sem nome',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor: const Color(
                                          0xFF7C3AED,
                                        ),
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                    ],
                  ),

                  // CURRÍCULO
                  _buildCard(
                    title: 'Currículo',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF7C3AED),
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Currículo Atual',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _urlCurriculo?.split('/').last ??
                                            'Nenhum currículo enviado',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 12,
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
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (_urlCurriculo != null &&
                                    _urlCurriculo!.isNotEmpty) ...[
                                  TextButton.icon(
                                    onPressed: _isUploadingCurriculo
                                        ? null
                                        : () => _abrirCurriculo(),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text('Abrir'),
                                  ),
                                  IconButton(
                                    onPressed: _isUploadingCurriculo
                                        ? null
                                        : () => _abrirCurriculo(download: true),
                                    icon: const Icon(Icons.download),
                                    tooltip: 'Baixar currículo',
                                  ),
                                ],
                                ElevatedButton.icon(
                                  onPressed: _isUploadingCurriculo
                                      ? null
                                      : _alterarCurriculo,
                                  icon: _isUploadingCurriculo
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file, size: 18),
                                  label: Text(
                                    _isUploadingCurriculo
                                        ? 'Enviando...'
                                        : (_urlCurriculo != null &&
                                                  _urlCurriculo!.isNotEmpty
                                              ? 'Alterar currículo'
                                              : 'Enviar currículo'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Sair da Conta',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0FDF4)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
