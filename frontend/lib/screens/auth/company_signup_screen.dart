import 'package:flutter/material.dart';

class CompanySignupScreen extends StatefulWidget {
  const CompanySignupScreen({super.key});

  @override
  State<CompanySignupScreen> createState() => _CompanySignupScreenState();
}

class _CompanySignupScreenState extends State<CompanySignupScreen> {
  bool _obscurePassword = true;

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
            Text('Cadastro de Empresa', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Preencha os dados da sua empresa', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Razão Social', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'TechCorp Ltda')),
              const SizedBox(height: 20),

              const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Apenas números')),
              const SizedBox(height: 20),

              const Text('Endereço da Sede', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const TextField(decoration: InputDecoration(hintText: 'Centro, Campo Mourão - PR')),
              const SizedBox(height: 20),

              const Text('Crie uma Senha', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Simula conclusão voltando à tela inicial
                },
                child: const Text('Criar Conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}