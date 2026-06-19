// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

enum RegisterStep {
  selection,
  studentStep1,
  studentStep2,
  studentStep3,
  company,
}

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
  final _instituicaoFocusNode = FocusNode();
  final _cursoFocusNode = FocusNode();
  final List<String> _selectedSkills = [];
  String? _selectedInstituicao;
  String? _selectedCurso;
  bool _cpfInteragido = false;
  bool _cnpjInteragido = false;
  bool _studentStep1TentouAvancar = false;
  bool _studentStep3TentouFinalizar = false;
  bool _companyTentouFinalizar = false;
  String? _cepError;
  String? _curriculoError;

  // Dados de Geolocalização e Arquivo Real
  double? _latitude;
  double? _longitude;
  String? _curriculoFileName;
  PlatformFile? _curriculoFile;
  bool _isMapVisible = false;

  // Controladores Empresa
  final _cnpjController = TextEditingController();
  final _descricaoController = TextEditingController();

  final List<String> _suggestedSkills = [
    'Python',
    'JavaScript',
    'React',
    'Node.js',
    'Flutter',
    'Java',
    'C++',
    'SQL',
    'MongoDB',
    'Git',
    'Docker',
    'AWS',
  ];

  static const List<String> _cursosPermitidos = [
    'Administração',
    'Agronomia',
    'Análise e Desenvolvimento de Sistemas',
    'Arquitetura e Urbanismo',
    'Biomedicina',
    'Ciência da Computação',
    'Ciências Biológicas',
    'Ciências Contábeis',
    'Comunicação Social',
    'Design',
    'Design Gráfico',
    'Direito',
    'Economia',
    'Educação Física',
    'Enfermagem',
    'Engenharia Ambiental',
    'Engenharia Civil',
    'Engenharia da Computação',
    'Engenharia de Alimentos',
    'Engenharia de Controle e Automação',
    'Engenharia de Produção',
    'Engenharia de Software',
    'Engenharia Elétrica',
    'Engenharia Eletrônica',
    'Engenharia Mecânica',
    'Engenharia Química',
    'Farmácia',
    'Física',
    'Fisioterapia',
    'Gestão da Tecnologia da Informação',
    'Jornalismo',
    'Letras',
    'Logística',
    'Marketing',
    'Matemática',
    'Medicina Veterinária',
    'Nutrição',
    'Pedagogia',
    'Psicologia',
    'Publicidade e Propaganda',
    'Química',
    'Recursos Humanos',
    'Relações Internacionais',
    'Sistemas de Informação',
    'Técnico em Administração',
    'Técnico em Desenvolvimento de Sistemas',
    'Técnico em Edificações',
    'Técnico em Eletrotécnica',
    'Técnico em Informática',
    'Técnico em Mecânica',
    'Técnico em Química',
  ];

  static const List<String> _instituicoesPermitidas = [
    'UTFPR - Universidade Tecnológica Federal do Paraná',
    'IFPR - Instituto Federal do Paraná',
    'UFPR - Universidade Federal do Paraná',
    'UEM - Universidade Estadual de Maringá',
    'UEL - Universidade Estadual de Londrina',
    'UEPG - Universidade Estadual de Ponta Grossa',
    'UNESPAR - Universidade Estadual do Paraná',
    'UNICENTRO - Universidade Estadual do Centro-Oeste',
    'PUCPR - Pontifícia Universidade Católica do Paraná',
    'UniCesumar',
    'Uningá',
    'Unicesumar',
    'Unipar',
    'Universidade Positivo',
    'Universidade Tuiuti do Paraná',
    'FAG',
    'Univel',
    'Unioeste - Universidade Estadual do Oeste do Paraná',
    'Campo Real',
    'FAE Centro Universitário',
    'Estácio',
    'Anhanguera',
    'Unopar',
    'UniBrasil',
    'UniDomBosco',
    'SENAI',
    'SENAC',
    'Fatec',
    'ETEC',
    'IFSP - Instituto Federal de São Paulo',
    'USP - Universidade de São Paulo',
    'UNESP - Universidade Estadual Paulista',
    'UNICAMP - Universidade Estadual de Campinas',
    'UFSCar - Universidade Federal de São Carlos',
    'UFMG - Universidade Federal de Minas Gerais',
    'UFSC - Universidade Federal de Santa Catarina',
    'UFRGS - Universidade Federal do Rio Grande do Sul',
    'UFSM - Universidade Federal de Santa Maria',
  ];

  static const Map<String, String> _cursoAliases = {
    'eng eletronica': 'Engenharia Eletrônica',
    'engenharia eletronica': 'Engenharia Eletrônica',
    'ads': 'Análise e Desenvolvimento de Sistemas',
    'cc': 'Ciência da Computação',
    'sistemas': 'Sistemas de Informação',
    'eng software': 'Engenharia de Software',
  };

  static const Map<String, String> _instituicaoAliases = {
    'utfpr': 'UTFPR - Universidade Tecnológica Federal do Paraná',
    'universidade tecnologica federal do parana':
        'UTFPR - Universidade Tecnológica Federal do Paraná',
    'ifpr': 'IFPR - Instituto Federal do Paraná',
    'ufpr': 'UFPR - Universidade Federal do Paraná',
    'uem': 'UEM - Universidade Estadual de Maringá',
    'uel': 'UEL - Universidade Estadual de Londrina',
    'unespar': 'UNESPAR - Universidade Estadual do Paraná',
    'unicentro': 'UNICENTRO - Universidade Estadual do Centro-Oeste',
    'pucpr': 'PUCPR - Pontifícia Universidade Católica do Paraná',
    'faculdade tecnologica': 'Fatec',
    'fatec': 'Fatec',
    'federal do parana': 'UFPR - Universidade Federal do Paraná',
    'estadual de maringa': 'UEM - Universidade Estadual de Maringá',
  };

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
    _instituicaoFocusNode.dispose();
    _cursoFocusNode.dispose();
    _anoController.dispose();
    _cnpjController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  bool _validarCpf(String value) {
    final cpf = _onlyNumbers(value);
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    int calcularDigito(String base) {
      var soma = 0;
      for (var i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * (base.length + 1 - i);
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final digito1 = calcularDigito(cpf.substring(0, 9));
    final digito2 = calcularDigito(cpf.substring(0, 9) + digito1.toString());

    return cpf.endsWith('$digito1$digito2');
  }

  bool _validarCnpj(String value) {
    final cnpj = _onlyNumbers(value);
    if (cnpj.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;

    int calcularDigito(String base, List<int> pesos) {
      var soma = 0;
      for (var i = 0; i < base.length; i++) {
        soma += int.parse(base[i]) * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    final digito1 = calcularDigito(cnpj.substring(0, 12), pesos1);
    final digito2 = calcularDigito(
      cnpj.substring(0, 12) + digito1.toString(),
      pesos2,
    );

    return cnpj.endsWith('$digito1$digito2');
  }

  String _normalizarBusca(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _canonicalizar(
    String value,
    List<String> options,
    Map<String, String> aliases,
  ) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final normalized = _normalizarBusca(trimmed);
    for (final option in options) {
      final normalizedOption = _normalizarBusca(option);
      if (normalizedOption == normalized) return option;
      if (normalizedOption.contains(normalized) && normalized.length >= 4) {
        return option;
      }
    }

    return aliases[normalized];
  }

  String? _canonicalCurso(String value) {
    return _canonicalizar(value, _cursosPermitidos, _cursoAliases);
  }

  String? _canonicalInstituicao(String value) {
    return _canonicalizar(value, _instituicoesPermitidas, _instituicaoAliases);
  }

  String? get _cpfError {
    final cpf = _onlyNumbers(_cpfController.text);
    if (!_cpfInteragido && !_studentStep1TentouAvancar && cpf.length < 11) {
      return null;
    }
    if (cpf.isEmpty) return 'Campo obrigatório.';
    if (cpf.length != 11) return 'Informe os 11 dígitos do CPF.';
    if (!_validarCpf(cpf)) {
      return 'CPF inválido. Confira os números informados.';
    }
    return null;
  }

  String? get _cnpjError {
    final cnpj = _onlyNumbers(_cnpjController.text);
    if (!_cnpjInteragido && !_companyTentouFinalizar && cnpj.length < 14) {
      return null;
    }
    if (cnpj.isEmpty) return 'Campo obrigatório.';
    if (cnpj.length != 14) return 'Informe os 14 dígitos do CNPJ.';
    if (!_validarCnpj(cnpj)) {
      return 'CNPJ inválido. Confira os números informados.';
    }
    return null;
  }

  String? _requiredError(String value, bool touched) {
    if (!touched || value.trim().isNotEmpty) return null;
    return 'Campo obrigatório.';
  }

  String? _cursoError() {
    if (!_studentStep1TentouAvancar && _cursoController.text.trim().isEmpty) {
      return null;
    }

    if (_cursoController.text.trim().isEmpty) return 'Campo obrigatório.';
    if ((_selectedCurso ?? _canonicalCurso(_cursoController.text)) == null) {
      return 'Selecione um curso da lista.';
    }

    return null;
  }

  String? _instituicaoError() {
    if (!_studentStep1TentouAvancar &&
        _instituicaoController.text.trim().isEmpty) {
      return null;
    }

    if (_instituicaoController.text.trim().isEmpty) return 'Campo obrigatório.';
    if ((_selectedInstituicao ??
            _canonicalInstituicao(_instituicaoController.text)) ==
        null) {
      return 'Selecione uma instituição da lista.';
    }

    return null;
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // --- FUNÇÕES DE VALIDAÇÃO DE ESTADO DOS BOTÕES ---
  bool _isStudentStep1Valid() {
    return _nomeController.text.trim().isNotEmpty &&
        _validarCpf(_cpfController.text) &&
        (_selectedInstituicao ??
                _canonicalInstituicao(_instituicaoController.text)) !=
            null &&
        (_selectedCurso ?? _canonicalCurso(_cursoController.text)) != null &&
        _anoController.text.trim().isNotEmpty &&
        _emailController.text.contains('@') &&
        _senhaController.text.length >= 6 &&
        _confirmarSenhaController.text == _senhaController.text;
  }

  bool _isStudentStep3Valid() {
    return _onlyNumbers(_cepController.text).length == 8 &&
        _enderecoController.text.isNotEmpty &&
        _curriculoFile != null;
  }

  bool _isCompanyValid() {
    return _nomeController.text.trim().isNotEmpty &&
        _validarCnpj(_cnpjController.text) &&
        _onlyNumbers(_cepController.text).length == 8 &&
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

  void _voltar(RegisterStep previous) {
    setState(() {
      _currentStep = previous;
      _errorMessage = null;
      _isLoading = false;
    });
  }

  void _voltarParaEntrada() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  void _avancarStudentStep1() {
    setState(() {
      _cpfInteragido = true;
      _studentStep1TentouAvancar = true;
    });

    if (_isStudentStep1Valid()) {
      final cursoCanonico = _canonicalCurso(_cursoController.text);
      final instituicaoCanonica = _canonicalInstituicao(
        _instituicaoController.text,
      );

      if (cursoCanonico != null) {
        _selectedCurso = cursoCanonico;
        _cursoController.text = cursoCanonico;
      }
      if (instituicaoCanonica != null) {
        _selectedInstituicao = instituicaoCanonica;
        _instituicaoController.text = instituicaoCanonica;
      }
      _nextStep(RegisterStep.studentStep2);
    }
  }

  void _avancarStudentStep3() {
    setState(() {
      _studentStep3TentouFinalizar = true;
      _cepError = _cepErrorForCurrentValue();
      _curriculoError = _curriculoFile == null
          ? 'Envie um currículo em PDF.'
          : null;
    });

    if (_isStudentStep3Valid() && !_isLoading) {
      _submit();
    }
  }

  Future<void> _submitCompany() async {
    setState(() {
      _cnpjInteragido = true;
      _companyTentouFinalizar = true;
      _cepError = _cepErrorForCurrentValue();
    });

    if (!_isCompanyValid()) return;
    await _submit();
  }

  String? _cepErrorForCurrentValue() {
    final cepLimpo = _onlyNumbers(_cepController.text);

    if (cepLimpo.isEmpty) return 'Campo obrigatório.';
    if (cepLimpo.length != 8) return 'CEP inválido.';
    if (_enderecoController.text.trim().isEmpty) {
      return 'CEP inválido ou não encontrado.';
    }

    return null;
  }

  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = _onlyNumbers(cep);
    if (cepLimpo.length != 8) {
      setState(() {
        _cepError = cepLimpo.isEmpty ? null : 'CEP inválido.';
        _isMapVisible = false;
        _enderecoController.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _cepError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == null) {
          setState(() {
            _enderecoController.text =
                "${data['logradouro']}, ${data['bairro']} - ${data['localidade']}/${data['uf']}";
            _latitude = null;
            _longitude = null;
            _isMapVisible = false;
            _cepError = null;
          });
        } else {
          setState(() {
            _isMapVisible = false;
            _enderecoController.text = "";
            _cepError = 'CEP inválido ou não encontrado.';
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('CEP não encontrado.')));
        }
      }
    } catch (e) {
      setState(() {
        _cepError = 'Erro ao consultar CEP. Tente novamente.';
        _isMapVisible = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarCurriculo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final isPdf = file.extension?.toLowerCase() == 'pdf';
      final isWithinLimit = file.size <= 5 * 1024 * 1024;

      if (!isPdf || file.bytes == null) {
        setState(() {
          _curriculoFile = null;
          _curriculoFileName = null;
          _curriculoError = 'Envie um currículo em PDF.';
        });
        return;
      }

      if (!isWithinLimit) {
        setState(() {
          _curriculoFile = null;
          _curriculoFileName = null;
          _curriculoError = 'O currículo deve ter no máximo 5MB.';
        });
        return;
      }

      setState(() {
        _curriculoFile = file;
        _curriculoFileName = file.name;
        _curriculoError = null;
      });
    } catch (_) {
      setState(() {
        _curriculoError = 'Erro ao selecionar currículo.';
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _cpfInteragido = true;
      _cnpjInteragido = true;
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
      body['curso'] = _selectedCurso ?? _canonicalCurso(_cursoController.text);
      body['instituicao'] =
          _selectedInstituicao ??
          _canonicalInstituicao(_instituicaoController.text);
      body['ano_conclusao'] = int.tryParse(_anoController.text);
      body['skills'] = _selectedSkills;
    } else {
      body['cnpj'] = _onlyNumbers(_cnpjController.text);
      body['descricao'] = _descricaoController.text.trim();
    }

    try {
      final response = isAluno
          ? await _submitAlunoMultipart(body)
          : await http.post(
              Uri.parse('${ApiConfig.baseUrl}/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso! Faça login.'),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        final message = data['message'] ?? 'Erro ao cadastrar';
        if (isAluno &&
            message.toString().toLowerCase().contains('instituição')) {
          _currentStep = RegisterStep.studentStep1;
          _studentStep1TentouAvancar = true;
          _selectedInstituicao = null;
        }
        if (isAluno && message.toString().toLowerCase().contains('curso')) {
          _currentStep = RegisterStep.studentStep1;
          _studentStep1TentouAvancar = true;
          _selectedCurso = null;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = message;
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

  Future<http.Response> _submitAlunoMultipart(Map<String, dynamic> body) async {
    final file = _curriculoFile;
    if (file == null || file.bytes == null) {
      return http.Response(
        jsonEncode({'message': 'Envie um currículo em PDF.'}),
        400,
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
    );

    for (final entry in body.entries) {
      final value = entry.value;
      if (value == null) continue;
      request.fields[entry.key] = value is List
          ? jsonEncode(value)
          : value.toString();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'curriculo',
        file.bytes!,
        filename: file.name,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
      ),
    );
  }

  Widget _buildAutocompleteField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> options,
    required Map<String, String> aliases,
    required ValueChanged<String?> onCanonicalChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: focusNode,
          optionsBuilder: (textEditingValue) {
            final query = _normalizarBusca(textEditingValue.text);

            if (query.isEmpty) {
              return options;
            }

            final aliasMatches = aliases.entries
                .where((entry) => entry.key.contains(query))
                .map((entry) => entry.value);
            final optionMatches = options.where(
              (option) => _normalizarBusca(option).contains(query),
            );

            return {...optionMatches, ...aliasMatches};
          },
          onSelected: (selection) {
            controller.text = selection;
            onCanonicalChanged(selection);
            _refreshUI();
          },
          fieldViewBuilder:
              (
                context,
                textEditingController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: fieldFocusNode,
                  decoration: _buildInputDecoration(label, hint: hint).copyWith(
                    errorText: errorText,
                    suffixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    onCanonicalChanged(_canonicalizar(value, options, aliases));
                    _refreshUI();
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, iterableOptions) {
            final items = iterableOptions.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                    maxWidth: 452,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final option = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackButton(RegisterStep previous) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () => _voltar(previous),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Voltar'),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: index <= step - 1
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentStep1() {
    final isValid = _isStudentStep1Valid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(1),
        const SizedBox(height: 24),
        const Text(
          'Dados Pessoais e Acadêmicos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Informe seus dados básicos e credenciais',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nomeController,
          decoration:
              _buildInputDecoration(
                'Nome Completo',
                hint: 'João Silva Santos',
              ).copyWith(
                errorText: _requiredError(
                  _nomeController.text,
                  _studentStep1TentouAvancar,
                ),
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(
            'CPF',
            hint: 'Apenas números',
          ).copyWith(errorText: _cpfError),
          onChanged: (_) {
            if (_onlyNumbers(_cpfController.text).length >= 11) {
              _cpfInteragido = true;
            }
            _refreshUI();
          },
        ),
        const SizedBox(height: 16),
        _buildAutocompleteField(
          label: 'Instituição de Ensino',
          hint: 'Digite para pesquisar...',
          controller: _instituicaoController,
          focusNode: _instituicaoFocusNode,
          options: _instituicoesPermitidas,
          aliases: _instituicaoAliases,
          onCanonicalChanged: (value) {
            _selectedInstituicao = value;
          },
          errorText: _instituicaoError(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildAutocompleteField(
                label: 'Curso',
                hint: 'Digite para pesquisar...',
                controller: _cursoController,
                focusNode: _cursoFocusNode,
                options: _cursosPermitidos,
                aliases: _cursoAliases,
                onCanonicalChanged: (value) {
                  _selectedCurso = value;
                },
                errorText: _cursoError(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _anoController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Ano Conclusão', hint: '2026')
                    .copyWith(
                      errorText: _requiredError(
                        _anoController.text,
                        _studentStep1TentouAvancar,
                      ),
                    ),
              ),
            ),
          ],
        ),
        const Divider(height: 48),
        const Text(
          'Dados de Acesso',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration:
              _buildInputDecoration(
                'E-mail',
                hint: 'seuemail@provedor.com',
              ).copyWith(
                errorText:
                    _studentStep1TentouAvancar &&
                        !_emailController.text.contains('@')
                    ? (_emailController.text.trim().isEmpty
                          ? 'Campo obrigatório.'
                          : 'E-mail inválido.')
                    : null,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senhaController,
          obscureText: _obscurePassword,
          decoration: _buildInputDecoration('Senha').copyWith(
            errorText:
                _studentStep1TentouAvancar && _senhaController.text.length < 6
                ? (_senhaController.text.isEmpty
                      ? 'Campo obrigatório.'
                      : 'A senha deve ter pelo menos 6 caracteres.')
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: _obscureConfirmPassword,
          decoration: _buildInputDecoration('Confirmar Senha').copyWith(
            errorText:
                _studentStep1TentouAvancar &&
                    _confirmarSenhaController.text != _senhaController.text
                ? 'As senhas não conferem.'
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // BOTÃO DINÂMICO PASSO 1
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _avancarStudentStep1,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Próximo',
              style: TextStyle(
                color: isValid ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        const Text(
          'Suas Habilidades',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Selecione suas competências e conhecimentos',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: _buildInputDecoration(
            'Buscar habilidades',
            hint: 'Digite para buscar...',
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return ChoiceChip(
              label: Text(skill),
              selected: isSelected,
              selectedColor: const Color(0xFFEDE9FE),
              backgroundColor: const Color(0xFFF9FAFB),
              side: isSelected
                  ? const BorderSide(color: Color(0xFF8B5CF6))
                  : BorderSide.none,
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF6B7280),
              ),
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _selectedSkills.add(skill)
                      : _selectedSkills.remove(skill);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        _buildBackButton(RegisterStep.studentStep1),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _nextStep(RegisterStep.studentStep3),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Próximo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        const Text(
          'Localização e Currículo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Finalize preenchendo o CEP para carregar o mapa',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cepController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('CEP', hint: 'Apenas os 8 números')
              .copyWith(
                errorText: _studentStep3TentouFinalizar ? _cepError : _cepError,
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
          onChanged: (value) {
            setState(() {
              _studentStep3TentouFinalizar = false;
              _cepError = null;
            });
            if (_onlyNumbers(value).length == 8) _buscarCEP(value);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _enderecoController,
          decoration: _buildInputDecoration(
            'Endereço Completo (Validado pelo CEP)',
          ),
          readOnly: true,
        ),
        const SizedBox(height: 24),

        // MAPA SIMULADO COMPLETO (Renderiza visualmente sem API KEY)
        if (_isMapVisible) ...[
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(
                0xFFE0F2FE,
              ), // Tom azul claro simulando rios/bairros
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            ),
            child: Stack(
              children: [
                // Linhas simulando quadras urbanas da cidade
                Positioned.fill(child: CustomPaint(painter: GridMapPainter())),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lat: ${_latitude?.toStringAsFixed(4)} | Long: ${_longitude?.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                // Raio de proximidade útil para o algoritmo de match de vagas futuro
                Center(
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Currículo (PDF)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selecionarCurriculo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _curriculoFileName != null
                        ? Icons.check
                        : Icons.upload_file,
                    size: 32,
                    color: _curriculoFileName != null
                        ? Colors.green
                        : const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _curriculoFileName ??
                      'Clique para selecionar seu Currículo\nApenas PDF, máximo 5MB',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_curriculoError != null) ...[
          const SizedBox(height: 8),
          Text(
            _curriculoError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 32),
        if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        _buildBackButton(RegisterStep.studentStep2),
        const SizedBox(height: 12),

        // BOTÃO DINÂMICO PASSO FINAL
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _avancarStudentStep3,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Finalizar Cadastro',
                    style: TextStyle(
                      color: isValid ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyScreen() {
    final isValid = _isCompanyValid();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Razão Social',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nomeController,
          decoration:
              _buildInputDecoration(
                'Razão Social',
                hint: 'TechCorp Ltda',
              ).copyWith(
                errorText: _requiredError(
                  _nomeController.text,
                  _companyTentouFinalizar,
                ),
              ),
        ),
        const SizedBox(height: 16),
        const Text('CNPJ', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cnpjController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration(
            'CNPJ',
            hint: 'Apenas números',
          ).copyWith(errorText: _cnpjError),
          onChanged: (_) {
            if (_onlyNumbers(_cnpjController.text).length >= 14) {
              _cnpjInteragido = true;
            }
            _refreshUI();
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Descrição da Empresa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descricaoController,
          maxLines: 4,
          decoration: _buildInputDecoration('Descrição').copyWith(
            errorText: _requiredError(
              _descricaoController.text,
              _companyTentouFinalizar,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('CEP', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cepController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('CEP', hint: 'Apenas os 8 números')
              .copyWith(
                errorText: _companyTentouFinalizar ? _cepError : _cepError,
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
          onChanged: (value) {
            setState(() {
              _companyTentouFinalizar = false;
              _cepError = null;
            });
            if (_onlyNumbers(value).length == 8) _buscarCEP(value);
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Endereço da Sede',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _enderecoController,
          decoration:
              _buildInputDecoration(
                'Endereço',
                hint: 'Preenchido pelo CEP',
              ).copyWith(
                errorText: _requiredError(
                  _enderecoController.text,
                  _companyTentouFinalizar,
                ),
              ),
          readOnly: true,
        ),
        const Divider(height: 48),
        const Text(
          'Dados de Acesso',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: _buildInputDecoration('E-mail Corporativo').copyWith(
            errorText:
                _companyTentouFinalizar && !_emailController.text.contains('@')
                ? (_emailController.text.trim().isEmpty
                      ? 'Campo obrigatório.'
                      : 'E-mail inválido.')
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senhaController,
          obscureText: _obscurePassword,
          decoration: _buildInputDecoration('Senha').copyWith(
            errorText:
                _companyTentouFinalizar && _senhaController.text.length < 6
                ? (_senhaController.text.isEmpty
                      ? 'Campo obrigatório.'
                      : 'A senha deve ter pelo menos 6 caracteres.')
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: _obscureConfirmPassword,
          decoration: _buildInputDecoration('Confirmar Senha').copyWith(
            errorText:
                _companyTentouFinalizar &&
                    _confirmarSenhaController.text != _senhaController.text
                ? 'As senhas não conferem.'
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _voltarParaEntrada,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
          ),
        ),
        const SizedBox(height: 12),

        // BOTÃO DINÂMICO CADASTRO EMPRESA
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitCompany,
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Criar Conta',
                    style: TextStyle(
                      color: isValid ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
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
                  case RegisterStep.selection:
                    return const Center(child: CircularProgressIndicator());
                  case RegisterStep.studentStep1:
                    return _buildStudentStep1();
                  case RegisterStep.studentStep2:
                    return _buildStudentStep2();
                  case RegisterStep.studentStep3:
                    return _buildStudentStep3();
                  case RegisterStep.company:
                    return _buildCompanyScreen();
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
    final paint = Paint()
      ..color = const Color(0xFFF0FDF4)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
