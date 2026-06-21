import 'package:flutter/material.dart';

class VagaDetalhesPage extends StatelessWidget {
  const VagaDetalhesPage({super.key});

  List<String> cursosDaVaga(Map<String, dynamic> vaga) {
    final raw = vaga['cursos_destinados'] ?? vaga['cursosDestinados'];
    if (raw is! List) return [];
    return raw
        .map((curso) => curso.toString())
        .where((curso) => curso.trim().isNotEmpty)
        .toList();
  }

  int? inteiroOpcional(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String textoCursosDaVaga(Map<String, dynamic> vaga) {
    final cursos = cursosDaVaga(vaga);
    if (cursos.isEmpty) return 'Todos os cursos';
    return cursos.join(', ');
  }

  String textoConclusaoDaVaga(Map<String, dynamic> vaga) {
    final min = inteiroOpcional(
      vaga['ano_conclusao_min'] ?? vaga['anoConclusaoMin'],
    );
    final max = inteiroOpcional(
      vaga['ano_conclusao_max'] ?? vaga['anoConclusaoMax'],
    );

    if (min != null && max != null) return 'Conclusão entre $min e $max';
    if (max != null) return 'Conclusão até $max';
    if (min != null) return 'Conclusão a partir de $min';
    return 'Sem restrição de conclusão';
  }

  @override
  Widget build(BuildContext context) {
    // Recupera os dados da vaga enviados pelo Navigator
    final vaga =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(vaga['titulo'] ?? 'Detalhes da Vaga')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vaga['titulo'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Empresa: ${vaga['empresa']?['nome_fantasia'] ?? 'Não informada'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descrição:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(vaga['descricao'] ?? 'Sem descrição disponível.'),
            const SizedBox(height: 20),
            const Text(
              'Requisitos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(vaga['requisitos'] ?? 'Nenhum requisito listado.'),
            const SizedBox(height: 20),
            const Text(
              'Cursos destinados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(textoCursosDaVaga(vaga)),
            const SizedBox(height: 20),
            const Text(
              'Período de conclusão:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(textoConclusaoDaVaga(vaga)),
          ],
        ),
      ),
    );
  }
}
