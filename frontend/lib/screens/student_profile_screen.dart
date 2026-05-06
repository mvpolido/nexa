import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../models/student_profile_model.dart';
import '../services/address_service.dart';
import '../services/student_api_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late Future<StudentProfile> _profileFuture;
  StudentProfile? _currentProfile;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _loadingCep = false;

  TextEditingController? _nameController;
  TextEditingController? _courseController;
  TextEditingController? _institutionController;
  TextEditingController? _resumeUrlController;
  TextEditingController? _cepController;
  TextEditingController? _numeroController;
  TextEditingController? _logradouroController;
  TextEditingController? _bairroController;
  TextEditingController? _cidadeUfController;

  String _logradouro = '';
  String _bairro = '';
  String _cidade = '';
  String _estado = '';

  double? _latitude;
  double? _longitude;
  
  late final MapController _mapController = MapController();
  File? _selectedImage;
  String? _fotoPerfil;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _fetchProfile();
  }

  Future<StudentProfile> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Token não encontrado. Faça login novamente.');
    }

    return StudentApiService.getStudentProfile(token);
  }

  void _startEditing(StudentProfile profile) {
    _currentProfile = profile;
    _nameController = TextEditingController(text: profile.nomeExibicao);
    _courseController = TextEditingController(text: profile.curso ?? '');
    _institutionController = TextEditingController(text: profile.instituicao ?? '');
    _resumeUrlController = TextEditingController(text: profile.urlCurriculo ?? '');
    _cepController = TextEditingController(text: profile.cep ?? '');
    _numeroController = TextEditingController(text: profile.numero ?? '');
    _logradouroController = TextEditingController(text: profile.logradouro ?? '');
    _bairroController = TextEditingController(text: profile.bairro ?? '');
    _cidadeUfController = TextEditingController(
      text: profile.cidade != null && profile.estado != null ? '${profile.cidade}/${profile.estado}' : '',
    );

    _logradouro = profile.logradouro ?? '';
    _bairro = profile.bairro ?? '';
    _cidade = profile.cidade ?? '';
    _estado = profile.estado ?? '';
    _latitude = profile.latitude;
    _longitude = profile.longitude;
    _fotoPerfil = profile.fotoPerfil;

    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _buscarCep() async {
    final cep = _cepController?.text.trim() ?? '';
    if (cep.isEmpty) return;

    setState(() {
      _loadingCep = true;
    });

    try {
      print('🔍 Buscando CEP: $cep');
      final data = await AddressService.fetchCep(cep);
      print('✅ CEP encontrado: ${data.logradouro}, ${data.bairro}, ${data.cidade}/${data.estado}');
      
      final coords = await AddressService.geocodeAddress(
        logradouro: data.logradouro,
        numero: _numeroController?.text.isEmpty ?? true ? '0' : _numeroController?.text ?? '0',
        bairro: data.bairro,
        cidade: data.cidade,
        estado: data.estado,
        cep: data.cep,
      );
      print('📍 Coordenadas obtidas: ${coords.latitude}, ${coords.longitude}');

      setState(() {
        _cepController?.text = data.cep;
        _logradouro = data.logradouro;
        _bairro = data.bairro;
        _cidade = data.cidade;
        _estado = data.estado;
        _latitude = coords.latitude;
        _longitude = coords.longitude;
        _logradouroController?.text = _logradouro;
        _bairroController?.text = _bairro;
        _cidadeUfController?.text = '$_cidade/$_estado';
      });
    } catch (e) {
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

  String _buildFullAddress() {
    final parts = <String>[];
    if (_logradouro.isNotEmpty) parts.add(_logradouro);
    if (_numeroController?.text.trim().isNotEmpty ?? false) parts.add(_numeroController!.text.trim());
    if (_bairro.isNotEmpty) parts.add(_bairro);
    if (_cidade.isNotEmpty && _estado.isNotEmpty) parts.add('$_cidade/$_estado');
    if (_cepController?.text.trim().isNotEmpty ?? false) parts.add(_cepController!.text.trim());
    return parts.join(', ');
  }

  Future<void> _saveProfile() async {
    final profile = _currentProfile;
    if (profile == null || _nameController == null) {
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token não encontrado');
      }

      String? fotoPerfil = _fotoPerfil;

      // Se selecionou uma nova imagem, converter para base64
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        fotoPerfil = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        print('📸 Foto convertida para base64');
      }

      final cepLimpo = _cepController?.text.trim().replaceAll(RegExp(r'[^0-9]'), '') ?? '';

      final updatedProfile = StudentProfile(
        id: profile.id,
        nomeExibicao: _nameController!.text.trim(),
        email: profile.email,
        cpf: profile.cpf,
        curso: _courseController!.text.trim().isEmpty ? null : _courseController!.text.trim(),
        instituicao: _institutionController!.text.trim().isEmpty ? null : _institutionController!.text.trim(),
        urlCurriculo: _resumeUrlController!.text.trim().isEmpty ? null : _resumeUrlController!.text.trim(),
        endereco: _buildFullAddress(),
        logradouro: _logradouro.isEmpty ? null : _logradouro,
        cep: cepLimpo.isEmpty ? null : cepLimpo,
        numero: _numeroController?.text.trim().isEmpty ?? true ? null : _numeroController!.text.trim(),
        bairro: _bairro.isEmpty ? null : _bairro,
        cidade: _cidade.isEmpty ? null : _cidade,
        estado: _estado.isEmpty ? null : _estado,
        fotoPerfil: fotoPerfil,
        latitude: _latitude,
        longitude: _longitude,
        criadoEm: profile.criadoEm,
        atualizadoEm: profile.atualizadoEm,
      );

      await StudentApiService.updateStudentProfile(token, updatedProfile);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _selectedImage = null;
      });

      _loadProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil atualizado com sucesso!'), backgroundColor: Color(0xFF7C3AED)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      print('❌ Erro ao atualizar perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token');

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _courseController?.dispose();
    _institutionController?.dispose();
    _resumeUrlController?.dispose();
    _cepController?.dispose();
    _numeroController?.dispose();
    _logradouroController?.dispose();
    _bairroController?.dispose();
    _cidadeUfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<StudentProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(_loadProfile),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado disponível'));
          }

          final profile = snapshot.data!;
          _currentProfile ??= profile;
          _fotoPerfil ??= profile.fotoPerfil;

          if (!_isEditing) {
            return _buildViewMode(profile);
          } else {
            return _buildEditMode(profile);
          }
        },
      ),
    );
  }

  Widget _buildProfileAvatar(StudentProfile profile, {bool isEditing = false}) {
    final imageProvider = _getImageProvider();

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
            image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
          ),
          child: imageProvider == null
              ? const Icon(Icons.person, size: 60, color: Color(0xFF7C3AED))
              : null,
        ),
        if (isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_fotoPerfil != null && _fotoPerfil!.isNotEmpty) {
      try {
        final base64String = _fotoPerfil!
            .replaceAll('data:image/jpeg;base64,', '')
            .replaceAll('data:image/png;base64,', '')
            .replaceAll('\n', '')
            .replaceAll('\r', '');

        if (base64String.isNotEmpty) {
          return MemoryImage(base64Decode(base64String));
        }
      } catch (e) {
        print('Erro ao decodificar imagem: $e');
      }
    }

    return null;
  }

  Widget _buildViewMode(StudentProfile profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cabeçalho com foto e informações básicas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              children: [
                _buildProfileAvatar(profile),
                const SizedBox(height: 16),
                Text(profile.nomeExibicao, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  profile.curso ?? 'Curso não informado',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _startEditing(profile),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Perfil'),
                ),
              ],
            ),
          ),
          // Informações em cards
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Seção: Informações Pessoais
                _buildSection(
                  'Informações Pessoais',
                  [
                    _buildInfoTile('📧 Email', profile.email),
                    _buildInfoTile('🆔 CPF', profile.cpf ?? 'Não informado'),
                  ],
                ),
                const SizedBox(height: 16),
                // Seção: Educação
                _buildSection(
                  'Educação',
                  [
                    _buildInfoTile('🎓 Curso', profile.curso ?? 'Não informado'),
                    _buildInfoTile('🏫 Instituição', profile.instituicao ?? 'Não informado'),
                    _buildInfoTile('📄 Currículo', profile.urlCurriculo ?? 'Não informado'),
                  ],
                ),
                const SizedBox(height: 16),
                // Seção: Localização
                if (profile.endereco != null && profile.endereco!.isNotEmpty)
                  _buildSection(
                    'Localização',
                    [
                      _buildInfoTile('📍 Endereço', profile.endereco ?? 'Não informado'),
                      _buildInfoTile('🏠 Logradouro', profile.logradouro ?? 'Não informado'),
                      _buildInfoTile('📮 CEP', profile.cep ?? 'Não informado'),
                      _buildInfoTile('🏙️ Cidade/UF', profile.cidade != null && profile.estado != null ? '${profile.cidade}/${profile.estado}' : 'Não informado'),
                      _buildInfoTile('🛣️ Bairro', profile.bairro ?? 'Não informado'),
                    ],
                  ),
                if (profile.latitude != null && profile.longitude != null) ...[
                  const SizedBox(height: 16),
                  // Mapa
                  _buildMapCard(profile),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(StudentProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar com opção de upload
          Center(
            child: Column(
              children: [
                _buildProfileAvatar(profile, isEditing: true),
                const SizedBox(height: 8),
                if (_selectedImage != null)
                  const Text('Foto selecionada ✓', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Formulário
          _buildTextField('Nome', _nameController),
          const SizedBox(height: 16),
          _buildSection(
            'Educação',
            [
              _buildTextField('Curso', _courseController),
              const SizedBox(height: 12),
              _buildTextField('Instituição', _institutionController),
              const SizedBox(height: 12),
              _buildTextField('Currículo (URL)', _resumeUrlController),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Localização',
            [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('CEP', _cepController, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton(
                        onPressed: _loadingCep ? null : _buscarCep,
                        child: _loadingCep
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Buscar'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Logradouro', _logradouroController, enabled: false),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Bairro', _bairroController, enabled: false)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Cidade/UF', _cidadeUfController, enabled: false)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Número', _numeroController),
            ],
          ),
          // Mapa interativo
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 16),
            _buildMapCard(profile, isEditing: true),
          ],
          const SizedBox(height: 24),
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200] ?? const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller,
      {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildMapCard(StudentProfile profile, {bool isEditing = false}) {
    final mapLatitude = _latitude ?? profile.latitude;
    final mapLongitude = _longitude ?? profile.longitude;

    if (mapLatitude == null || mapLongitude == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200] ?? const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'Localização ainda não disponível.',
          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Localização no Mapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 300,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(mapLatitude, mapLongitude),
              initialZoom: 17.0,
              onTap: isEditing
                  ? (tapPosition, point) {
                      print('📍 Novo ponto clicado: ${point.latitude}, ${point.longitude}');
                      setState(() {
                        _latitude = point.latitude;
                        _longitude = point.longitude;
                      });
                    }
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nexa.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(mapLatitude, mapLongitude),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordenadas: $mapLatitude, $mapLongitude',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
              ),
              if (isEditing)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Clique no mapa para ajustar a localização',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}