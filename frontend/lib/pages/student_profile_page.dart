import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _token;

  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  
  final _instituicaoController = TextEditingController();
  final _cursoController = TextEditingController();
  final _anoController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _urlCurriculo;
  
  List<String> _habilidades = [];
  final List<String> _habilidadesSugeridas = [
    'React', 'JavaScript', 'TypeScript', 'Git', 'Python', 'Node.js', 'Flutter', 'SQL', 'Java', 'C#'
  ];

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token == null || _token!.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/alunos/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Mapeamento à prova de falhas: procura os dados na raiz ou dentro do objeto 'usuario'/'aluno'
        final usuario = data['usuario'] ?? data;
        final aluno = data['aluno'] ?? data;

        setState(() {
          _nomeController.text = usuario['nome_exibicao'] ?? usuario['nome'] ?? '';
          _emailController.text = usuario['email'] ?? '';
          _cpfController.text = data['cpf'] ?? aluno['cpf'] ?? usuario['cpf'] ?? '';
          
          _cepController.text = data['cep'] ?? aluno['cep'] ?? usuario['cep'] ?? '';
          _enderecoController.text = data['endereco'] ?? aluno['endereco'] ?? usuario['endereco'] ?? '';
          
          final lat = data['latitude'] ?? aluno['latitude'] ?? usuario['latitude'];
          final lng = data['longitude'] ?? aluno['longitude'] ?? usuario['longitude'];
          _latitude = lat != null ? double.tryParse(lat.toString()) : null;
          _longitude = lng != null ? double.tryParse(lng.toString()) : null;

          _instituicaoController.text = data['instituicao'] ?? aluno['instituicao'] ?? '';
          _cursoController.text = data['curso'] ?? aluno['curso'] ?? '';
          _anoController.text = data['ano_conclusao']?.toString() ?? aluno['ano_conclusao']?.toString() ?? '';
          
          _urlCurriculo = data['url_curriculo'] ?? aluno['url_curriculo'];
          
          // Se não vier do banco, insere habilidades padrão de demonstração
          _habilidades = ['React', 'JavaScript', 'Git', 'Node.js']; 
          
          _isLoading = false;
        });
        
        // Se já tiver CEP mas não tiver coordenadas, tenta buscar o mapa
        if (_cepController.text.isNotEmpty && _latitude == null) {
          _buscarCEP(_cepController.text);
        }

      } else {
        setState(() => _isLoading = false);
        _mostrarErro('Erro ao carregar dados do perfil.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro de conexão com o servidor.');
    }
  }

  String _onlyNumbers(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = _onlyNumbers(cep);
    if (cepLimpo.length != 8) return;

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _enderecoController.text = "${data['logradouro']}, ${data['bairro']} - ${data['localidade']}/${data['uf']}";
            _latitude = -24.0439 + (int.parse(cepLimpo.substring(5)) / 100000); 
            _longitude = -52.3791 - (int.parse(cepLimpo.substring(5)) / 100000);
          });
        }
      }
    } catch (_) {}
  }

  void _atualizarCurriculoSimulado() {
    final textController = TextEditingController(text: _urlCurriculo?.split('/').last ?? "novo_curriculo.pdf");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar Currículo'),
        content: TextFormField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nome do Arquivo PDF', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  final nomeFinal = textController.text.trim().endsWith('.pdf') ? textController.text.trim() : '${textController.text.trim()}.pdf';
                  _urlCurriculo = "https://storage.nexa.com/uploads/$nomeFinal";
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

  Future<void> _salvarPerfil() async {
    setState(() => _isSaving = true);

    final payload = {
      'nome_exibicao': _nomeController.text,
      'cep': _onlyNumbers(_cepController.text),
      'endereco': _enderecoController.text,
      'latitude': _latitude,
      'longitude': _longitude,
      'instituicao': _instituicaoController.text,
      'curso': _cursoController.text,
      'ano_conclusao': int.tryParse(_anoController.text),
      'url_curriculo': _urlCurriculo,
      'skills': _habilidades,
    };

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/alunos/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token'
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isSaving = false);
        _mostrarErro('Erro ao salvar alterações.');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _mostrarErro('Erro de conexão com o servidor.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_nome');
    await prefs.remove('user_perfil');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  // ---- WIDGETS DE UI ----

  Widget _buildField({required String label, required IconData icon, required TextEditingController controller, bool isReadOnly = false, void Function(String)? onChanged, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                const SizedBox(height: 4),
                _isEditing && !isReadOnly
                    ? TextFormField(
                        controller: controller,
                        onChanged: onChanged,
                        keyboardType: keyboardType,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                      )
                    : Text(
                        controller.text.isEmpty ? 'Não informado' : controller.text,
                        style: TextStyle(
                          fontSize: 14, 
                          color: isReadOnly && _isEditing ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              if (!_isEditing) const Icon(Icons.edit, color: Color(0xFFD1D5DB), size: 18),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_latitude == null || _longitude == null) return const SizedBox.shrink();
    return Container(
      height: 140, width: double.infinity,
      margin: const EdgeInsets.only(left: 32, top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1)
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: GridMapPainter())),
          Positioned(
            bottom: 8, left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
              child: Text('Lat: ${_latitude!.toStringAsFixed(4)} | Long: ${_longitude!.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
            ),
          ),
          const Center(child: Icon(Icons.location_on, color: Colors.red, size: 32)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF9FAFB), body: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED))))
          else
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit, color: const Color(0xFF7C3AED)),
              onPressed: () {
                if (_isEditing) {
                  _salvarPerfil();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho (Foto e Nome)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7C3AED), width: 2)),
                    child: const Icon(Icons.person_outline, size: 40, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                      ? SizedBox(
                          width: 250,
                          child: TextFormField(
                            controller: _nomeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(isDense: true, border: UnderlineInputBorder()),
                          ),
                        )
                      : Text(_nomeController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(_cursoController.text.isEmpty ? 'Curso não informado' : _cursoController.text, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // DADOS PESSOAIS
                  _buildCard(
                    title: 'Dados Pessoais',
                    children: [
                      _buildField(label: 'E-mail', icon: Icons.email_outlined, controller: _emailController, isReadOnly: true),
                      _buildField(label: 'CPF', icon: Icons.badge_outlined, controller: _cpfController, isReadOnly: true),
                      
                      if (_isEditing) ...[
                        _buildField(
                          label: 'Editar CEP', 
                          icon: Icons.location_on_outlined, 
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            if (val.length == 8 || val.length == 9) _buscarCEP(val);
                          }
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32, bottom: 8),
                          child: Text('Endereço autocompletado:\n${_enderecoController.text}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                        ),
                      ] else ...[
                        _buildField(label: 'Endereço Completo', icon: Icons.location_on_outlined, controller: _enderecoController, isReadOnly: true),
                      ],
                      
                      _buildMap(),
                    ],
                  ),

                  // FORMAÇÃO ACADÊMICA
                  _buildCard(
                    title: 'Formação Acadêmica',
                    children: [
                      _buildField(label: 'Instituição', icon: Icons.account_balance_outlined, controller: _instituicaoController),
                      _buildField(label: 'Curso', icon: Icons.school_outlined, controller: _cursoController),
                      _buildField(label: 'Previsão de Formatura', icon: Icons.calendar_today_outlined, controller: _anoController, keyboardType: TextInputType.number),
                    ],
                  ),

                  // HABILIDADES
                  _buildCard(
                    title: 'Habilidades',
                    children: [
                      if (_isEditing)
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _habilidadesSugeridas.map((skill) {
                            final isSelected = _habilidades.contains(skill);
                            return ChoiceChip(
                              label: Text(skill),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _habilidades.add(skill) : _habilidades.remove(skill);
                                });
                              },
                              selectedColor: const Color(0xFFEDE9FE),
                              backgroundColor: const Color(0xFFF9FAFB),
                              side: isSelected ? const BorderSide(color: Color(0xFF7C3AED)) : BorderSide.none,
                            );
                          }).toList(),
                        )
                      else
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _habilidades.map((hab) => Chip(
                            label: Text(hab, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF7C3AED),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          )).toList(),
                        )
                    ],
                  ),

                  // CURRÍCULO
                  _buildCard(
                    title: 'Currículo',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: Color(0xFF7C3AED), size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Currículo Atual', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(_urlCurriculo?.split('/').last ?? 'Nenhum currículo enviado', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                                ],
                              ),
                            ),
                            if (_isEditing)
                              IconButton(
                                icon: const Icon(Icons.upload_file, color: Color(0xFF7C3AED)),
                                onPressed: _atualizarCurriculoSimulado,
                                tooltip: 'Substituir Currículo',
                              )
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF0FDF4)..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.8, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.5), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
