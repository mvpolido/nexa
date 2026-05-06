import 'package:flutter/material.dart';

class StudentSignupStep3Screen extends StatefulWidget {
  const StudentSignupStep3Screen({super.key});

  @override
  State<StudentSignupStep3Screen> createState() => _StudentSignupStep3ScreenState();
}

class _StudentSignupStep3ScreenState extends State<StudentSignupStep3Screen> {
  bool _fileUploaded = false;

  void _simulateFileUpload() async {
    // Simula a abertura de pastas do sistema e o upload
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _fileUploaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Passo 3 de 3', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2)))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Localização e Currículo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'Rua, número - Campo Mourão - PR')),
              const SizedBox(height: 32),

              const Text('Currículo (PDF)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              
              InkWell(
                onTap: _simulateFileUpload,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _fileUploaded ? const Color(0xFFF3E8FF) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _fileUploaded ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _fileUploaded ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fileUploaded ? 'curriculo_filipe.pdf' : 'Upload de Currículo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fileUploaded ? const Color(0xFF7C3AED) : Colors.black,
                        ),
                      ),
                      if (!_fileUploaded)
                        const Text('Apenas PDF, máximo 5MB', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: _fileUploaded ? () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } : null,
                child: const Text('Finalizar Cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}