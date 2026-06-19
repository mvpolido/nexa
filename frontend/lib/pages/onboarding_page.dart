// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Vagas Perto de Você",
      "description": "Encontre oportunidades de estágio próximas da sua localização",
      "icon": Icons.location_on_outlined,
    },
    {
      "title": "Match de Habilidades",
      "description": "Conecte-se com vagas que combinam perfeitamente com seu perfil",
      "icon": Icons.auto_awesome,
    },
    {
      "title": "Chat Direto",
      "description": "Converse diretamente com as empresas e tire suas dúvidas",
      "icon": Icons.chat_bubble_outline,
    },
  ];

  void _goToNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    // Ao clicar em "Pular" ou "Começar", vai para a tela de escolha de perfil
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _onboardingData[index]["icon"],
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _onboardingData[index]["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]["description"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Rodapé com botões e indicador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botão Pular
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                    child: const Text(
                      "Pular",
                      style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                    ),
                  ),

                  // Indicador de Progresso Animado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryColor
                              : primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Botão Próximo / Começar
                  ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48), // 👈 AQUI ESTÁ A CORREÇÃO! Sobrescreve o infinito global.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? "Começar"
                          : "Próximo",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
