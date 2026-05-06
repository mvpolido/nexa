import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'student_signup_step3_screen.dart';

class StudentSignupStep2Screen extends StatefulWidget {
  const StudentSignupStep2Screen({super.key});

  @override
  State<StudentSignupStep2Screen> createState() => _StudentSignupStep2ScreenState();
}

class _StudentSignupStep2ScreenState extends State<StudentSignupStep2Screen> {
  // Lista gigante simulada com diversas áreas
  final List<String> _allKnowledge = [
    // Tecnologia
    'Flutter', 'Python', 'QA / Testes', 'SQL', 'React', 'Node.js',
    // Saúde
    'Farmacologia', 'Anatomia Humana', 'Nutrição Clínica', 'Fisiologia do Exercício', 'Primeiros Socorros',
    // Engenharia / Exatas
    'AutoCAD', 'Cálculo Estrutural', 'Resistência dos Materiais', 'Termodinâmica', 'Matemática Financeira',
    // Negócios / Geral
    'Gestão de Projetos', 'Marketing Digital', 'Excel Avançado', 'Inglês Fluente', 'Escrita Científica',
    'Educação Inclusiva', 'Direito Civil', 'Logística', 'Vendas B2B'
  ];

  final List<String> _selectedItems = [];
  String _searchQuery = "";

  void _addItem(String item) {
    if (!_selectedItems.contains(item)) {
      setState(() {
        _selectedItems.add(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtra a lista baseada no que o usuário digita
    final filteredList = _allKnowledge
        .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cadastro de Aluno', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Passo 2 de 3', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de Progresso
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Conhecimentos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Pesquise e selecione suas competências', style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 24),

              // "Dropdown" de Busca
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Ex: Farmacologia, AutoCAD, Excel...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              
              // Lista de resultados da busca (Aparece apenas quando digita)
              if (_searchQuery.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(filteredList[index]),
                        onTap: () {
                          _addItem(filteredList[index]);
                          setState(() => _searchQuery = ""); // Limpa busca
                          FocusScope.of(context).unfocus(); // Fecha teclado
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),
              const Text('Selecionados:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Área onde aparecem os conhecimentos selecionados
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _selectedItems.map((item) {
                      return Chip(
                        label: Text(item, style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFF7C3AED),
                        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                        onDeleted: () => setState(() => _selectedItems.remove(item)),
                      );
                    }).toList(),
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: _selectedItems.isEmpty ? null : () {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => const StudentSignupStep3Screen()));
                },
                child: const Text('Próximo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}