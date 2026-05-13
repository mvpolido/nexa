import 'package:flutter/material.dart';

class VagaDetalhesPage extends StatelessWidget {
  const VagaDetalhesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recupera os dados da vaga enviados pelo Navigator
    final vaga = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(vaga['titulo'] ?? 'Detalhes da Vaga')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vaga['titulo'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Empresa: ${vaga['empresa']?['nome_fantasia'] ?? 'Não informada'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(vaga['descricao'] ?? 'Sem descrição disponível.'),
            const SizedBox(height: 20),
            const Text('Requisitos:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(vaga['requisitos'] ?? 'Nenhum requisito listado.'),
          ],
        ),
      ),
    );
  }
}