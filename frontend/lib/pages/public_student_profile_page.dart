import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PublicStudentProfilePage extends StatefulWidget {
  final int candidaturaId;
  final String token;

  const PublicStudentProfilePage({super.key, required this.candidaturaId, required this.token});

  @override
  State<PublicStudentProfilePage> createState() => _PublicStudentProfilePageState();
}

class _PublicStudentProfilePageState extends State<PublicStudentProfilePage> {
  bool isLoading = true;
  Map<String, dynamic>? alunoData;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats/${widget.candidaturaId}/perfil-aluno'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          alunoData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        mostrarErro('Erro ao carregar perfil do aluno.');
      }
    } catch (_) {
      mostrarErro('Erro de ligação ao servidor.');
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
    
    if (alunoData == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
        body: const Center(child: Text('Perfil não encontrado')),
      );
    }

    final nome = alunoData?['usuario']?['nome_exibicao'] ?? alunoData?['usuario']?['nome'] ?? 'Aluno';
    final curso = alunoData?['curso'] ?? 'Curso não informado';
    final email = alunoData?['usuario']?['email'] ?? 'Email não informado';
    final relacoes = alunoData?['alunoHabilidades'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: Text('Perfil do Candidato', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(radius: 40, backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1), child: const Icon(Icons.person, size: 40, color: Color(0xFF7C3AED))),
                  const SizedBox(height: 16),
                  Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(curso, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.email, color: Color(0xFF7C3AED)), title: const Text('Email'), subtitle: Text(email)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Habilidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (relacoes.isEmpty)
                    const Text('O aluno não registou habilidades.', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: relacoes.map((relacao) {
                        final hab = relacao['habilidade'];
                        if (hab == null) return const SizedBox.shrink();
                        return Chip(
                          label: Text(hab['nome'] ?? '', style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                          side: BorderSide.none,
                        );
                      }).toList(),
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