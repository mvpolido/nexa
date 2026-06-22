// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  bool isLoadingVerificacao = true;
  bool isUploadingVerificacao = false;
  String? token;

  Map<String, dynamic>? empresaData;
  Map<String, dynamic>? verificacaoData;
  PlatformFile? documentoVerificacao;
  String? documentoVerificacaoErro;
  final TextEditingController _nomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token == null || token!.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/empresas/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          empresaData = data;
          _nomeController.text =
              data['usuario']?['nome_exibicao'] ??
              data['usuario']?['nome'] ??
              '';
        });
        await carregarVerificacao();
      } else {
        mostrarErro('Erro ao carregar perfil da empresa.');
      }
    } catch (_) {
      mostrarErro('Erro de ligação ao servidor.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> carregarVerificacao() async {
    if (token == null || token!.isEmpty) return;

    if (mounted) {
      setState(() {
        isLoadingVerificacao = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/empresas/me/verificacao'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          verificacaoData = jsonDecode(response.body);
        });
      } else {
        String mensagem = 'Erro ao carregar status de verificação.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }
        mostrarErro(mensagem);
      }
    } catch (_) {
      mostrarErro('Erro ao consultar verificação da empresa.');
    } finally {
      if (mounted) setState(() => isLoadingVerificacao = false);
    }
  }

  Future<void> selecionarDocumentoVerificacao() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final isPdf = file.extension?.toLowerCase() == 'pdf';
    final hasBytes = file.bytes != null;
    final isWithinLimit = file.size <= 5 * 1024 * 1024;

    setState(() {
      if (!isPdf || !hasBytes) {
        documentoVerificacao = null;
        documentoVerificacaoErro = 'Selecione um arquivo PDF válido.';
      } else if (!isWithinLimit) {
        documentoVerificacao = null;
        documentoVerificacaoErro = 'O documento deve ter no máximo 5 MB.';
      } else {
        documentoVerificacao = file;
        documentoVerificacaoErro = null;
      }
    });
  }

  Future<void> enviarDocumentoVerificacao({bool substituindo = false}) async {
    final file = documentoVerificacao;
    if (file == null || file.bytes == null) {
      setState(() {
        documentoVerificacaoErro = 'Selecione um PDF antes de enviar.';
      });
      return;
    }

    if (substituindo) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Substituir documento'),
          content: const Text(
            'Deseja substituir o documento enviado anteriormente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
    }

    setState(() => isUploadingVerificacao = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/empresas/me/solicitar-verificacao'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'documento',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento enviado para análise.')),
        );
        setState(() {
          documentoVerificacao = null;
          documentoVerificacaoErro = null;
        });
        await carregarVerificacao();
      } else {
        String mensagem = 'Erro ao enviar documento.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }
        mostrarErro(mensagem);
      }
    } catch (_) {
      mostrarErro('Erro de conexão ao enviar documento.');
    } finally {
      if (mounted) setState(() => isUploadingVerificacao = false);
    }
  }

  Future<void> guardarPerfil() async {
    setState(() => isSaving = true);
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/empresas/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nome_exibicao': _nomeController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final empresaAtualizada = data['empresa'] ?? data;
        final nomeAtualizado = empresaAtualizada['usuario']?['nome_exibicao']
            ?.toString();

        setState(() {
          isEditing = false;
          empresaData = empresaAtualizada;
          if (nomeAtualizado != null && nomeAtualizado.isNotEmpty) {
            _nomeController.text = nomeAtualizado;
          }
        });
        final prefs = await SharedPreferences.getInstance();
        if (nomeAtualizado != null && nomeAtualizado.isNotEmpty) {
          await prefs.setString('user_nome', nomeAtualizado);
        }
        await carregarPerfil();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Razão Social atualizada!')),
          );
        }
      } else {
        String mensagem = 'Erro ao guardar as alterações.';
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          mensagem = data['message'] ?? mensagem;
        }
        mostrarErro(mensagem);
      }
    } catch (_) {
      mostrarErro('Erro de ligação ao servidor.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> logout() async {
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
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  String formatarCNPJ(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  String _statusVerificacaoLabel(String? status) {
    switch (status) {
      case 'pendente':
        return 'Em análise';
      case 'aprovada':
        return 'Verificada';
      case 'rejeitada':
        return 'Solicitação rejeitada';
      case 'nao_solicitada':
      default:
        return 'Não solicitada';
    }
  }

  IconData _statusVerificacaoIcon(String? status) {
    switch (status) {
      case 'pendente':
        return Icons.schedule;
      case 'aprovada':
        return Icons.verified;
      case 'rejeitada':
        return Icons.error_outline;
      default:
        return Icons.verified_user_outlined;
    }
  }

  Color _statusVerificacaoColor(String? status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'aprovada':
        return Colors.blue;
      case 'rejeitada':
        return Colors.red;
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Widget _verifiedIcon({double size = 22}) {
    return Tooltip(
      message: 'Empresa verificada',
      child: Icon(Icons.verified, color: Colors.blue, size: size),
    );
  }

  Widget _buildEstatistica(String titulo, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: const Color(0xFF7C3AED), size: 28),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildComentarioReal(Map<String, dynamic> av) {
    final nome =
        av['alunoUsuario']?['nome_exibicao'] ??
        av['alunoUsuario']?['nome'] ??
        'Aluno';
    final data = DateTime.parse(av['criado_em']).toLocal();
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    final nota = (av['nota'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      nome[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        dataFormatada,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < nota ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            av['comentario'] ?? '',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    final bool isVerificada =
        empresaData?['verificada'] == true || empresaData?['verificada'] == 1;
    final double avaliacaoMedia = (empresaData?['avaliacao_media'] ?? 0.0)
        .toDouble();
    final int totalAvaliacoes = empresaData?['total_avaliacoes'] ?? 0;
    final List<dynamic> avaliacoes = empresaData?['avaliacoes'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Perfil da Empresa',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
              tooltip: 'Editar Perfil',
              onPressed: () => setState(() => isEditing = true),
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              tooltip: 'Cancelar',
              onPressed: () => setState(() {
                isEditing = false;
                _nomeController.text =
                    empresaData?['usuario']?['nome_exibicao'] ??
                    empresaData?['usuario']?['nome'] ??
                    '';
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 50,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      if (isVerificada)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Tooltip(
                            message: 'Empresa verificada',
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isEditing) ...[
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _nomeController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Razão Social (Editável)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSaving ? null : guardarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar Razão Social',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _nomeController.text.isNotEmpty
                              ? _nomeController.text
                              : 'Nome da Empresa',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (isVerificada) ...[
                          const SizedBox(width: 8),
                          _verifiedIcon(),
                        ],
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    isVerificada
                        ? 'Empresa Verificada'
                        : 'A aguardar verificação',
                    style: TextStyle(
                      color: isVerificada ? Colors.blue : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEstatistica(
                        'Avaliação',
                        avaliacaoMedia.toStringAsFixed(1),
                        Icons.star,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _buildEstatistica(
                        'Comentários',
                        totalAvaliacoes.toString(),
                        Icons.chat_bubble_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _buildSecaoVerificacaoEmpresa(isVerificada),

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados da Empresa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.badge, color: Color(0xFF7C3AED)),
                    title: const Text('CNPJ'),
                    subtitle: Text(
                      empresaData?['cnpj'] != null
                          ? formatarCNPJ(empresaData!['cnpj'])
                          : 'Não informado',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email, color: Color(0xFF7C3AED)),
                    title: const Text('Email de Contato'),
                    subtitle: Text(
                      empresaData?['usuario']?['email'] ?? 'Não informado',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.description,
                      color: Color(0xFF7C3AED),
                    ),
                    title: const Text('Descrição'),
                    subtitle: Text(
                      empresaData?['descricao'] ?? 'Sem descrição detalhada.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Avaliações',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            avaliacaoMedia.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (avaliacoes.isEmpty)
                    const Text(
                      'Esta empresa ainda não possui avaliações.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    ...avaliacoes.map((av) => _buildComentarioReal(av)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sair da conta',
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
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoVerificacaoEmpresa(bool isVerificada) {
    final status =
        verificacaoData?['status_verificacao']?.toString() ??
        (isVerificada ? 'aprovada' : 'nao_solicitada');
    final documentoEnviado = verificacaoData?['documento_enviado'] == true;
    final nomeDocumento = verificacaoData?['documento_nome_original'];
    final motivo = verificacaoData?['motivo_rejeicao'];
    final color = _statusVerificacaoColor(status);
    final podeEnviar = status == 'nao_solicitada' || status == 'rejeitada';
    final podeSubstituir = status == 'pendente';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verificação da empresa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (isLoadingVerificacao)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_statusVerificacaoIcon(status), color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusVerificacaoLabel(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (status == 'nao_solicitada')
                        const Text(
                          'Envie um documento em PDF que comprove a existência da empresa para análise do moderador.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        )
                      else if (status == 'pendente') ...[
                        const Text(
                          'Solicitação em análise. Nossa equipe avaliará o documento enviado.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        if (nomeDocumento != null)
                          Text(
                            'Documento: $nomeDocumento',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                      ] else if (status == 'aprovada')
                        const Text(
                          'Empresa verificada. Novos envios não são necessários.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        )
                      else if (status == 'rejeitada') ...[
                        if (motivo != null)
                          Text(
                            'Motivo: $motivo',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        const Text(
                          'Você pode enviar outro PDF para uma nova análise.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if ((podeEnviar || podeSubstituir) && !isVerificada) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: isUploadingVerificacao
                    ? null
                    : selecionarDocumentoVerificacao,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Selecionar PDF'),
              ),
              if (documentoVerificacao != null) ...[
                const SizedBox(height: 8),
                Text(
                  documentoVerificacao!.name,
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
              ],
              if (documentoVerificacaoErro != null) ...[
                const SizedBox(height: 8),
                Text(
                  documentoVerificacaoErro!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isUploadingVerificacao || documentoVerificacao == null
                      ? null
                      : () => enviarDocumentoVerificacao(
                          substituindo: podeSubstituir && documentoEnviado,
                        ),
                  icon: isUploadingVerificacao
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    podeSubstituir
                        ? 'Enviar substituição'
                        : 'Enviar para análise',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
