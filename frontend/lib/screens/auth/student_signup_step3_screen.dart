import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/temp_registration.dart';
import '../../services/address_service.dart';

class StudentSignupStep3Screen extends StatefulWidget {
  const StudentSignupStep3Screen({super.key});

  @override
  State<StudentSignupStep3Screen> createState() => _StudentSignupStep3ScreenState();
}

class _StudentSignupStep3ScreenState extends State<StudentSignupStep3Screen> {
  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();
  final _curriculoController = TextEditingController();
  
  // Controllers para exibir dados do endereço
  late final TextEditingController _logradouroController = TextEditingController();
  late final TextEditingController _bairroController = TextEditingController();
  late final TextEditingController _cidadeController = TextEditingController();

  bool _loadingCep = false;
  bool _loadingFinish = false;

  String _logradouro = '';
  String _bairro = '';
  String _cidade = '';
  String _estado = '';
  
  // Coordenadas para o mapa
  double? _latitude;
  double? _longitude;
  
  // Controller para o mapa
  late final MapController _mapController = MapController();

  @override
  void dispose() {
    _cepController.dispose();
    _numeroController.dispose();
    _curriculoController.dispose();
    _logradouroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.trim();
    if (cep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, digite um CEP')));
      return;
    }

    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP deve ter 8 dígitos')));
      return;
    }

    setState(() {
      _loadingCep = true;
    });

    try {
      print('🔍 Buscando CEP: $cep (limpo: $cleanCep)');
      final data = await AddressService.fetchCep(cep);
      print('✅ CEP encontrado: ${data.logradouro}, ${data.bairro}, ${data.cidade}/${data.estado}');
      
      // Buscar coordenadas do endereço
      print('🗺️ Buscando coordenadas...');
      final coords = await AddressService.geocodeAddress(
        logradouro: data.logradouro,
        numero: _numeroController.text.isEmpty ? '0' : _numeroController.text,
        bairro: data.bairro,
        cidade: data.cidade,
        estado: data.estado,
        cep: data.cep,
      );
      print('📍 Coordenadas obtidas: ${coords.latitude}, ${coords.longitude}');
      
      setState(() {
        _cepController.text = data.cep;
        _logradouro = data.logradouro;
        _bairro = data.bairro;
        _cidade = data.cidade;
        _estado = data.estado;
        _latitude = coords.latitude;
        _longitude = coords.longitude;
        
        _logradouroController.text = data.logradouro;
        _bairroController.text = data.bairro;
        _cidadeController.text = '${data.cidade}/${data.estado}';
        
        print('🎨 UI atualizada: logradouro=$_logradouro, lat=$_latitude, lng=$_longitude');
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CEP encontrado com sucesso!')));
    } catch (e) {
      print('❌ Erro ao buscar CEP: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no CEP: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingCep = false;
        });
      }
    }
  }

  Future<void> _finalizarCadastro() async {
    final reg = TempRegistration();
    final cep = _cepController.text.trim();
    final numero = _numeroController.text.trim();
    final curriculo = _curriculoController.text.trim();

    if (reg.nomeExibicao.isEmpty || reg.email.isEmpty || reg.password.isEmpty || reg.cpf.isEmpty || reg.course.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados do cadastro incompletos. Volte e preencha novamente.')));
      return;
    }

    if (_logradouro.isEmpty || _cidade.isEmpty || _estado.isEmpty || cep.isEmpty || numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Busque o CEP e informe o número')));
      return;
    }

    setState(() {
      _loadingFinish = true;
    });

    try {
      final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
      final enderecoCompleto = '$_logradouro, $numero - $_bairro, $_cidade/$_estado, $cepLimpo';

      final registerResp = await http.post(
        Uri.parse('http://localhost:3000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome_exibicao': reg.nomeExibicao,
          'email': reg.email,
          'password': reg.password,
          'perfil': 'aluno',
          'cpf': reg.cpf,
          'curso': reg.course,
          'instituicao': reg.institution,
          'url_curriculo': curriculo.isEmpty ? null : curriculo,
          'skills': reg.skills,
          'endereco': enderecoCompleto,
          'logradouro': _logradouro,
          'cep': cepLimpo,
          'numero': numero,
          'bairro': _bairro,
          'cidade': _cidade,
          'estado': _estado,
          'latitude': _latitude,
          'longitude': _longitude,
        }),
      );

      if (registerResp.statusCode != 201) {
        print('❌ Erro no registro: Status ${registerResp.statusCode}');
        print('📦 Resposta: ${registerResp.body}');
        
        if (registerResp.statusCode == 409) {
          throw Exception('Email já cadastrado. Tente fazer login ou usar outro email.');
        }
        throw Exception('Falha no registro: ${registerResp.body}');
      }
      
      print('✅ Usuário registrado com sucesso');
      print('📦 Resposta do registro: ${registerResp.body}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro concluído com sucesso! Faça login para continuar.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao finalizar cadastro: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingFinish = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = TempRegistration();

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
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              Text('Cadastro de ${reg.nomeExibicao}', style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 24),

              const Text('CEP', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Ex: 87015000'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: _loadingCep ? null : _buscarCep,
                      child: _loadingCep
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_logradouro.isNotEmpty) ...[
                TextField(
                  controller: _logradouroController,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Logradouro'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bairroController,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cidadeController,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Cidade/UF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Número', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _numeroController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Ex: 123'),
                ),
                const SizedBox(height: 16),

                // Mapa interativo
                const Text('Localização no mapa', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude!, _longitude!),
                      initialZoom: 17.0,
                      onTap: (tapPosition, point) {
                        print('📍 Novo ponto clicado: ${point.latitude}, ${point.longitude}');
                        setState(() {
                          _latitude = point.latitude;
                          _longitude = point.longitude;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.nexa.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF7C3AED),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Coordenadas: $_latitude, $_longitude\nClique ou arraste para ajustar',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text('Currículo (URL ou caminho)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _curriculoController,
                decoration: const InputDecoration(hintText: 'Cole a URL do currículo, se houver'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loadingFinish ? null : _finalizarCadastro,
                child: _loadingFinish
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Finalizar Cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
