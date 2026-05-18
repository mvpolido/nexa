import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum RegisterStep { selection, studentStep1, studentStep2, studentStep3, company }

class RegisterPage extends StatefulWidget {
  final String? initialProfile; 
  
  const RegisterPage({super.key, this.initialProfile});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  RegisterStep _currentStep = RegisterStep.selection;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controladores Compartilhados
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  // Controladores de Endereço
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();

  // Controladores Aluno
  final _cpfController = TextEditingController();
  final _instituicaoController = TextEditingController(); 
  final _cursoController = TextEditingController();
  final _anoController = TextEditingController(); 
  final List<String> _selectedSkills = []; 
  
  // Dados de Geolocalização e Arquivo Real
  double? _latitude;
  double? _longitude;
  String? _curriculoFileName;
  bool _isMapVisible = false;

  // Controladores Empresa
  final _cnpjController = TextEditingController();
  final _descricaoController = TextEditingController();

  final List<String> _suggestedSkills = [
    'Python', 'JavaScript', 'React', 'Node.js', 'Flutter', 
    'Java', 'C++', 'SQL', 'MongoDB', 'Git', 'Docker', 'AWS'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile == 'aluno') {
      _currentStep = RegisterStep.studentStep1;
    } else if (widget.initialProfile == 'empresa') {
      _currentStep = RegisterStep.company;
    }

    // Ouvintes ativos para atualizar a cor dos botões em tempo real ao digitar
    _nomeController.addListener(_refreshUI);
    _emailController.addListener(_refreshUI);
    _senhaController.addListener(_refreshUI);
    _confirmarSenhaController.addListener(_refreshUI);
    _cepController.addListener(_refreshUI);
    _cpfController.addListener(_refreshUI);
    _instituicaoController.addListener(_refreshUI);
    _cursoController.addListener(_refreshUI);
    _anoController.addListener(_refreshUI);
    _cnpjController.addListener(_refreshUI);
    _descricaoController.addListener(_refreshUI);
  }

  void _refreshUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _cpfController.dispose();
    _instituicaoController.dispose();
    _cursoController.dispose();
    _anoController.dispose();
    _cnpjController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // --- FUNÇÕES DE VALIDAÇÃO DE ESTADO DOS BOTÕES ---
  bool _isStudentStep1Valid() {
    return _nomeController.text.trim().isNotEmpty &&
           _onlyNumbers(_cpfController.text).length == 11 &&
           _instituicaoController.text.trim().isNotEmpty &&
           _cursoController.text.trim().isNotEmpty &&
           _anoController.text.trim().isNotEmpty &&
           _emailController.text.contains('@') &&
           _senhaController.text.length >= 6 &&
           _confirmarSenhaController.text == _senhaController.text;
  }

  bool _isStudentStep3Valid() {
    return _onlyNumbers(_cepController.text).length == 8 &&
           _enderecoController.text.isNotEmpty &&
           _curriculoFileName != null;
  }

  bool _isCompanyValid() {
    return _nomeController.text.trim().isNotEmpty &&
           _onlyNumbers(_cnpjController.text).length == 14 &&
           _descricaoController.text.trim().isNotEmpty &&
           _enderecoController.text.trim().isNotEmpty &&
           _emailController.text.contains('@') &&
           _senhaController.text.length >= 6 &&
           _confirmarSenhaController.text == _senhaController.text;
  }

  void _nextStep(RegisterStep next) {
    setState(() {
      _currentStep = next;
      _errorMessage = null;
    });
  }

  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = _onlyNumbers(cep);
    if (cepLimpo.length != 8) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _enderecoController.text = "${data['logradouro']}, ${data['bairro']} - ${data['localidade']}/${data['uf']}";
            _latitude = -24.0439; 
            _longitude = -52.3791;
            _isMapVisible = true; 
          });
        } else {
          setState(() {
            _isMapVisible = false;
            _enderecoController.text = "";
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CEP não encontrado.')),
          );
        }
      }
    } catch (e) {
      // Falha de conexão
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setCustomCurriculo() {
    final textController = TextEditingController(text: _curriculoFileName ?? "meu_curriculo.pdf");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar arquivo de Currículo'),
        content: TextFormField(
          controller: textController,
          decoration: _buildInputDecoration('Nome do Arquivo PDF'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  _curriculoFileName = textController.text.trim().endsWith('.pdf') 
                      ? textController.text.trim() 
                      : '${textController.text.trim()}.pdf';
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final isAluno = _currentStep == RegisterStep.studentStep3;
    
    // CORRIGIDO: Retornando para as strings estritas em minúsculo ('aluno' / 'empresa')
    final perfilStr = isAluno ? 'aluno' : 'empresa';

    final body = <String, dynamic>{
      'nome_exibicao': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'senha': _senhaController.text, 
      'perfil': perfilStr,
      'cep': _onlyNumbers(_cepController.text),
      'endereco': _enderecoController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    };

    if (isAluno) {
      body['cpf'] = _onlyNumbers(_cpfController.text);
      body['curso'] = _cursoController.text.trim();
      body['instituicao'] = _instituicaoController.text.trim();
      body['ano_conclusao'] = int.tryParse(_anoController.text);
      body['skills'] = _selectedSkills;
      if (_curriculoFileName != null) {
        body['url_curriculo'] = "https://storage.nexa.com/uploads/$_curriculoFileName";
      }
    } else {
      body['cnpj'] = _onlyNumbers(_cnpjController.text);
      body['descricao'] = _descricaoController.text.trim();
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login.')),
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'Erro ao cadastrar';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro de conexão com o servidor';
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label, hintText: hint, filled: true, fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? 8 : 0), 
          height: 4, 
          decoration: BoxDecoration(
            color: index <= step - 1 ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB), 
            borderRadius: BorderRadius.circular(2)
          )
        )
      ))
    );
  }

  Widget _buildStudentStep1() {
    final isValid = _isStudentStep1Valid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(1),
        const SizedBox(height: 24),
        const Text('Dados Pessoais e Acadêmicos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('Informe seus dados básicos e credenciais', style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 24),
        TextFormField(controller: _nomeController, decoration: _buildInputDecoration('Nome Completo', hint: 'João Silva Santos')),
        const SizedBox(height: 16),
        TextFormField(controller: _cpfController, keyboardType: TextInputType.number, decoration: _buildInputDecoration('CPF', hint: 'Apenas números')),
        const SizedBox(height: 16),
        TextFormField(controller: _instituicaoController, decoration: _buildInputDecoration('Instituição de Ensino', hint: 'Universidade, Faculdade...')),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(flex: 2, child: TextFormField(controller: _cursoController, decoration: _buildInputDecoration('Curso', hint: 'Engenharia, Computação...'))),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: TextFormField(controller: _anoController, keyboardType: TextInputType.number, decoration: _buildInputDecoration('Ano Conclusão', hint: '2026'))),
          ],
        ),
        const Divider(height: 48),
        const Text('Dados de Acesso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 16),
        TextFormField(controller: _emailController, decoration: _buildInputDecoration('E-mail', hint: 'seuemail@provedor.com')),
        const SizedBox(height: 16),
        TextFormField(controller: _senhaController, obscureText: _obscurePassword, decoration: _buildInputDecoration('Senha').copyWith(suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
        const SizedBox(height: 16),
        TextFormField(controller: _confirmarSenhaController, obscureText: _obscureConfirmPassword, decoration: _buildInputDecoration('Confirmar Senha').copyWith(suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)))),
        const SizedBox(height: 32),
        
        // BOTÃO DINÂMICO PASSO 1
        SizedBox(
          height: 56, 
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: isValid ? () => _nextStep(RegisterStep.studentStep2) : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? const Color(0xFF7C3AED) : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Próximo', 
              style: TextStyle(
                color: isValid ? Colors.white : const Color(0xFF9CA3AF), 
                fontSize: 16, 
                fontWeight: FontWeight.bold
              )
            )
          )
        ),
      ],
    );
  }

  Widget _buildStudentStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(2),
        const SizedBox(height: 24),
        const Text('Suas Habilidades', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('Selecione suas competências e conhecimentos', style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 24),
        TextField(decoration: _buildInputDecoration('Buscar habilidades', hint: 'Digite para buscar...')),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _suggestedSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return ChoiceChip(
              label: Text(skill), selected: isSelected, selectedColor: const Color(0xFFEDE9FE), backgroundColor: const Color(0xFFF9FAFB),
              side: isSelected ? const BorderSide(color: Color(0xFF8B5CF6)) : BorderSide.none,
              labelStyle: TextStyle(color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280)),
              onSelected: (selected) {
                setState(() {
                  selected ? _selectedSkills.add(skill) : _selectedSkills.remove(skill);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 56, 
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: () => _nextStep(RegisterStep.studentStep3), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ), 
            child: const Text('Próximo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
          )
        ),
      ],
    );
  }

  Widget _buildStudentStep3() {
    final isValid = _isStudentStep3Valid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(3),
        const SizedBox(height: 24),
        const Text('Localização e Currículo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('Finalize preenchendo o CEP para carregar o mapa', style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cepController, keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('CEP', hint: 'Apenas os 8 números').copyWith(
            suffixIcon: _isLoading ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          onChanged: (value) {
            if (_onlyNumbers(value).length == 8) _buscarCEP(value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _enderecoController, decoration: _buildInputDecoration('Endereço Completo (Validado pelo CEP)'), readOnly: true),
        const SizedBox(height: 24),

        // MAPA SIMULADO COMPLETO (Renderiza visualmente sem API KEY)
        if (_isMapVisible) ...[
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE), // Tom azul claro simulando rios/bairros
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5)
            ),
            child: Stack(
              children: [
                // Linhas simulando quadras urbanas da cidade
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridMapPainter(),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                    child: Text('Lat: ${_latitude?.toStringAsFixed(4)} | Long: ${_longitude?.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
                // Raio de proximidade útil para o algoritmo de match de vagas futuro
                Center(
                  child: Container(
                    height: 70, width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7C3AED), width: 1)
                    ),
                  ),
                ),
                const Center(child: Icon(Icons.location_on, color: Colors.red, size: 38)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        const Text('Currículo (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _setCustomCurriculo,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle), child: Icon(_curriculoFileName != null ? Icons.check : Icons.upload_file, size: 32, color: _curriculoFileName != null ? Colors.green : const Color(0xFF8B5CF6))),
                const SizedBox(height: 16),
                Text(_curriculoFileName ?? 'Clique para selecionar seu Currículo\nApenas PDF, máximo 5MB', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) Center(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
        
        // BOTÃO DINÂMICO PASSO FINAL
        SizedBox(
          height: 56, 
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: isValid && !_isLoading ? _submit : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? const Color(0xFF7C3AED) : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text('Finalizar Cadastro', style: TextStyle(color: isValid ? Colors.white : const Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.bold))
          )
        ),
      ],
    );
  }

  Widget _buildCompanyScreen() {
    final isValid = _isCompanyValid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Razão Social', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(controller: _nomeController, decoration: _buildInputDecoration('Razão Social', hint: 'TechCorp Ltda')),
        const SizedBox(height: 16),
        const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(controller: _cnpjController, keyboardType: TextInputType.number, decoration: _buildInputDecoration('CNPJ', hint: 'Apenas números')),
        const SizedBox(height: 16),
        const Text('Descrição da Empresa', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(controller: _descricaoController, maxLines: 4, decoration: _buildInputDecoration('Descrição')),
        const SizedBox(height: 16),
        const Text('Endereço da Sede', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(controller: _enderecoController, decoration: _buildInputDecoration('Endereço', hint: 'Cidade, Estado')),
        const Divider(height: 48),
        const Text('Dados de Acesso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(controller: _emailController, decoration: _buildInputDecoration('E-mail Corporativo')),
        const SizedBox(height: 16),
        TextFormField(controller: _senhaController, obscureText: _obscurePassword, decoration: _buildInputDecoration('Senha').copyWith(suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
        const SizedBox(height: 16),
        TextFormField(controller: _confirmarSenhaController, obscureText: _obscureConfirmPassword, decoration: _buildInputDecoration('Confirmar Senha').copyWith(suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)))),
        const SizedBox(height: 32),
        if (_errorMessage != null) Center(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))),
        
        // BOTÃO DINÂMICO CADASTRO EMPRESA
        SizedBox(
          height: 56, 
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: isValid && !_isLoading ? _submit : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? const Color(0xFF7C3AED) : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text('Criar Conta', style: TextStyle(color: isValid ? Colors.white : const Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.bold))
          )
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: () {
                switch (_currentStep) {
                  case RegisterStep.selection: return const Center(child: CircularProgressIndicator());
                  case RegisterStep.studentStep1: return _buildStudentStep1();
                  case RegisterStep.studentStep2: return _buildStudentStep2();
                  case RegisterStep.studentStep3: return _buildStudentStep3();
                  case RegisterStep.company: return _buildCompanyScreen();
                }
              }(),
            ),
          ),
        ),
      ),
    );
  }
}

// Classe Utilitária para desenhar as ruas falsas do mockup do mapa
class GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF0FDF4)..strokeWidth = 3;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.7, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.6), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}