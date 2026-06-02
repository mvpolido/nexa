import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PublicCompanyProfilePage extends StatefulWidget {
  final int candidaturaId;
  final String token;

  const PublicCompanyProfilePage({super.key, required this.candidaturaId, required this.token});

  @override
  State<PublicCompanyProfilePage> createState() => _PublicCompanyProfilePageState();
}

class _PublicCompanyProfilePageState extends State<PublicCompanyProfilePage> {
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? empresaData;

  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/empresas/by-candidatura/${widget.candidaturaId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          empresaData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        mostrarErro('Erro ao carregar perfil da empresa.');
      }
    } catch (_) {
      mostrarErro('Erro de ligação ao servidor.');
    }
  }

  Future<void> enviarAvaliacao() async {
    if (_commentController.text.trim().isEmpty) {
      mostrarErro('Por favor, escreva um comentário.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/empresas/avaliar'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({
          'empresa_id': empresaData!['id'],
          'nota': _rating,
          'comentario': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação enviada com sucesso!')));
        _commentController.clear();
        await carregarPerfil(); // Recarrega para mostrar a nova média
      } else {
        mostrarErro('Erro ao enviar avaliação.');
      }
    } catch (_) {
      mostrarErro('Erro de ligação ao servidor.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));

    // 🛠️ PROTEÇÃO ADICIONADA: Impede o erro de ecrã branco se a API falhar
    if (empresaData == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
        body: const Center(child: Text('Perfil não encontrado.')),
      );
    }

    final bool canReview = empresaData?['can_review'] == true;
    final String nome = empresaData?['usuario']?['nome_exibicao'] ?? empresaData?['usuario']?['nome'] ?? 'Empresa';
    final double avaliacaoMedia = (empresaData?['avaliacao_media'] ?? 0.0).toDouble();
    final bool isVerificada = empresaData?['verificada'] == true || empresaData?['verificada'] == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(radius: 40, backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1), child: const Icon(Icons.business, size: 40, color: Color(0xFF7C3AED))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (isVerificada) ...[const SizedBox(width: 8), const Icon(Icons.verified, color: Colors.blue, size: 20)],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('$avaliacaoMedia Média de Avaliações', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
              child: Text(empresaData?['descricao'] ?? 'Sem descrição.', style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
            ),
            const SizedBox(height: 12),

            // 🛠️ ÁREA DE AVALIAÇÃO (SÓ APARECE SE FOR ALUNO)
            if (canReview)
              Container(
                width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avalie sua experiência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                          onPressed: () => setState(() => _rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Como foi o processo seletivo ou o trabalho?',
                        filled: true, fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : enviarAvaliacao,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar Avaliação', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}