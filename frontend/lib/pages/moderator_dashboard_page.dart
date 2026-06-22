// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as import_html;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/admin_service.dart';

class ModeratorDashboardPage extends StatefulWidget {
  const ModeratorDashboardPage({super.key});

  @override
  State<ModeratorDashboardPage> createState() => _ModeratorDashboardPageState();
}

class _ModeratorDashboardPageState extends State<ModeratorDashboardPage> {
  final _service = AdminService();
  final _buscaUsuariosController = TextEditingController();
  final _buscaEmpresasController = TextEditingController();
  final _buscaVagasController = TextEditingController();
  final _buscaHabilidadesController = TextEditingController();
  final _buscaInstituicoesController = TextEditingController();
  final _buscaCursosController = TextEditingController();

  int _selectedIndex = 0;
  int? _meuUsuarioId;
  String? _nomeModerador;
  bool _loading = true;
  bool _actionLoading = false;
  String? _erro;

  Map<String, dynamic> _stats = {};
  List<dynamic> _usuarios = [];
  List<dynamic> _empresas = [];
  List<dynamic> _vagas = [];
  List<dynamic> _habilidades = [];
  List<dynamic> _instituicoes = [];
  List<dynamic> _cursos = [];

  String? _perfilFiltro;
  String? _empresaStatusFiltro;
  bool? _vagaAtivaFiltro;
  String? _areaFiltro;
  bool? _instituicaoAtivaFiltro;
  bool? _cursoAtivoFiltro;

  static const _purple = Color(0xFF7C3AED);
  static const _areas = [
    'TECNOLOGIA',
    'ENGENHARIA',
    'EXATAS',
    'SAUDE',
    'QUIMICA',
    'FISICA',
    'BIOLOGIA',
    'COMUNICACAO',
    'GESTAO',
    'DESIGN',
  ];

  static const _areaLabels = {
    'TECNOLOGIA': 'Tecnologia',
    'ENGENHARIA': 'Engenharia',
    'EXATAS': 'Exatas',
    'SAUDE': 'Saúde',
    'QUIMICA': 'Química',
    'FISICA': 'Física',
    'BIOLOGIA': 'Biologia',
    'COMUNICACAO': 'Comunicação',
    'GESTAO': 'Gestão',
    'DESIGN': 'Design',
  };

  @override
  void initState() {
    super.initState();
    _carregarSessao();
  }

  @override
  void dispose() {
    _buscaUsuariosController.dispose();
    _buscaEmpresasController.dispose();
    _buscaVagasController.dispose();
    _buscaHabilidadesController.dispose();
    _buscaInstituicoesController.dispose();
    _buscaCursosController.dispose();
    super.dispose();
  }

  Future<void> _carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.getString('user_id');
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    setState(() {
      _meuUsuarioId = int.tryParse(rawId ?? '');
      _nomeModerador = prefs.getString('user_nome') ?? 'Moderador';
    });

    await _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.dashboardStats(),
        _service.usuarios(
          busca: _buscaUsuariosController.text,
          perfil: _perfilFiltro,
        ),
        _service.empresas(
          busca: _buscaEmpresasController.text,
          statusVerificacao: _empresaStatusFiltro,
        ),
        _service.vagas(
          busca: _buscaVagasController.text,
          ativo: _vagaAtivaFiltro,
        ),
        _service.habilidades(
          busca: _buscaHabilidadesController.text,
          area: _areaFiltro,
        ),
        _service.instituicoes(
          busca: _buscaInstituicoesController.text,
          ativa: _instituicaoAtivaFiltro,
        ),
        _service.cursos(
          busca: _buscaCursosController.text,
          ativo: _cursoAtivoFiltro,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _usuarios = results[1] as List<dynamic>;
        _empresas = results[2] as List<dynamic>;
        _vagas = results[3] as List<dynamic>;
        _habilidades = results[4] as List<dynamic>;
        _instituicoes = results[5] as List<dynamic>;
        _cursos = results[6] as List<dynamic>;
      });
    } on AdminServiceException catch (e) {
      _handleError(e);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro de conexão com o servidor.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarAbaAtual() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }

    try {
      if (_selectedIndex == 0) {
        _stats = await _service.dashboardStats();
      } else if (_selectedIndex == 1) {
        _usuarios = await _service.usuarios(
          busca: _buscaUsuariosController.text,
          perfil: _perfilFiltro,
        );
      } else if (_selectedIndex == 2) {
        _empresas = await _service.empresas(
          busca: _buscaEmpresasController.text,
          statusVerificacao: _empresaStatusFiltro,
        );
      } else if (_selectedIndex == 3) {
        _vagas = await _service.vagas(
          busca: _buscaVagasController.text,
          ativo: _vagaAtivaFiltro,
        );
      } else if (_selectedIndex == 4) {
        _habilidades = await _service.habilidades(
          busca: _buscaHabilidadesController.text,
          area: _areaFiltro,
        );
      } else if (_selectedIndex == 5) {
        _instituicoes = await _service.instituicoes(
          busca: _buscaInstituicoesController.text,
          ativa: _instituicaoAtivaFiltro,
        );
      } else {
        _cursos = await _service.cursos(
          busca: _buscaCursosController.text,
          ativo: _cursoAtivoFiltro,
        );
      }

      if (!mounted) return;
      setState(() {});
    } on AdminServiceException catch (e) {
      _handleError(e);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro de conexão com o servidor.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleError(AdminServiceException e) {
    if (!mounted) return;
    if (e.statusCode == 401 || e.statusCode == 403) {
      _logout();
      return;
    }
    setState(() {
      _erro = e.message;
      _loading = false;
      _actionLoading = false;
    });
    _showSnack(e.message, error: true);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_nome');
    await prefs.remove('user_email');
    await prefs.remove('user_perfil');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _confirmar(String titulo, String mensagem) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _executarAcao(
    Future<void> Function() action,
    String sucesso,
  ) async {
    setState(() => _actionLoading = true);
    try {
      await action();
      _showSnack(sucesso);
      await _carregarAbaAtual();
      if (_selectedIndex != 0) {
        _stats = await _service.dashboardStats();
      }
    } on AdminServiceException catch (e) {
      _handleError(e);
    } catch (_) {
      _showSnack('Erro de conexão com o servidor.', error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _perfilLabel(String? perfil) {
    return switch (perfil) {
      'aluno' => 'Aluno',
      'empresa' => 'Empresa',
      'admin' => 'Moderador',
      _ => 'Desconhecido',
    };
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Sem data';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _maskCnpj(dynamic value) {
    final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (digits.length != 14) return value?.toString() ?? 'Não informado';
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  bool _isVagaAtiva(dynamic vaga) {
    final ativo = vaga['ativo'];
    return ativo == 1 || ativo == true;
  }

  bool _isEmpresaVerificada(dynamic empresa) {
    return empresa['verificada'] == true || empresa['verificada'] == 1;
  }

  String _statusVerificacao(dynamic empresa) {
    return empresa['status_verificacao']?.toString() ??
        (_isEmpresaVerificada(empresa) ? 'aprovada' : 'nao_solicitada');
  }

  String _statusVerificacaoLabel(String? status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'aprovada':
        return 'Aprovada';
      case 'rejeitada':
        return 'Rejeitada';
      case 'nao_solicitada':
      default:
        return 'Não solicitada';
    }
  }

  Color _statusVerificacaoColor(String? status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'aprovada':
        return Colors.blue;
      case 'rejeitada':
        return Colors.red;
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _verifiedBadge({double size = 18}) {
    return Tooltip(
      message: 'Empresa verificada',
      child: Icon(Icons.verified, color: Colors.blue, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text('Painel do Moderador'),
        actions: [
          if (_actionLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _carregarAbaAtual,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _buildSideNav(),
          Expanded(
            child: Column(
              children: [
                if (!isWide) _buildTopNav(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 240,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nomeModerador ?? 'Moderador',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Moderador', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final selected = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                selected: selected,
                selectedTileColor: const Color(0xFFEDE9FE),
                leading: Icon(item.icon, color: selected ? _purple : null),
                title: Text(item.label),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () => setState(() => _selectedIndex = index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _navItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _navItems[index];
          return ChoiceChip(
            label: Text(item.label),
            selected: _selectedIndex == index,
            avatar: Icon(item.icon, size: 18),
            onSelected: (_) => setState(() => _selectedIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }

    if (_erro != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Não foi possível carregar',
        message: _erro!,
        actionLabel: 'Tentar novamente',
        onAction: _carregarAbaAtual,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth > 48
            ? constraints.maxWidth - 48
            : constraints.maxWidth;

        return RefreshIndicator(
          onRefresh: _carregarAbaAtual,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: availableWidth,
                  maxWidth: 1180,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: switch (_selectedIndex) {
                    0 => _buildOverview(),
                    1 => _buildUsuarios(),
                    2 => _buildEmpresas(),
                    3 => _buildVagas(),
                    4 => _buildHabilidades(),
                    5 => _buildInstituicoes(),
                    _ => _buildCursos(),
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _habilidadesAreaDropdown({double? width}) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: _areaFiltro,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Área',
          suffixIcon: _areaFiltro == null
              ? null
              : IconButton(
                  tooltip: 'Limpar filtro',
                  onPressed: () {
                    setState(() => _areaFiltro = null);
                    _carregarAbaAtual();
                  },
                  icon: const Icon(Icons.clear),
                ),
        ),
        items: _areas
            .map(
              (area) => DropdownMenuItem<String>(
                value: area,
                child: Text(_areaLabels[area] ?? area),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _areaFiltro = value);
          _carregarAbaAtual();
        },
      ),
    );
  }

  Widget _buildOverview() {
    final cards = [
      _StatCard('Usuários', _stats['usuarios'], Icons.people_outline),
      _StatCard('Alunos', _stats['alunos'], Icons.school_outlined),
      _StatCard('Empresas', _stats['empresas'], Icons.business_outlined),
      _StatCard('Verificadas', _stats['empresasVerificadas'], Icons.verified),
      _StatCard(
        'Pendentes',
        _stats['empresasPendentes'],
        Icons.pending_actions,
      ),
      _StatCard('Vagas', _stats['vagas'], Icons.work_outline),
      _StatCard('Vagas ativas', _stats['vagasAtivas'], Icons.check_circle),
      _StatCard('Habilidades', _stats['habilidades'], Icons.star_border),
    ];

    if (_stats.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dashboard_outlined,
        title: 'Sem estatísticas',
        message: 'Ainda não há dados para exibir.',
        actionLabel: 'Atualizar',
        onAction: _carregarAbaAtual,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Visão geral', 'Acompanhe os principais números.'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 1000
                ? 4
                : width >= 640
                ? 2
                : 1;
            return GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) => _buildStatCard(cards[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Usuários',
          'Gerencie contas de alunos, empresas e moderadores.',
        ),
        _buildFilters([
          Expanded(
            child: _searchField(
              _buscaUsuariosController,
              'Buscar por nome ou email',
              _carregarAbaAtual,
            ),
          ),
          _dropdown<String>(
            value: _perfilFiltro,
            hint: 'Perfil',
            items: const {
              'aluno': 'Aluno',
              'empresa': 'Empresa',
              'admin': 'Moderador',
            },
            onChanged: (value) {
              setState(() => _perfilFiltro = value);
              _carregarAbaAtual();
            },
          ),
        ]),
        if (_usuarios.isEmpty)
          _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Nenhum usuário encontrado',
            message: 'Ajuste a busca ou os filtros.',
          )
        else
          ..._usuarios.map(_buildUsuarioCard),
      ],
    );
  }

  Widget _buildUsuarioCard(dynamic usuario) {
    final id = usuario['id'] is int
        ? usuario['id'] as int
        : int.tryParse('${usuario['id']}');
    final isSelf = id != null && id == _meuUsuarioId;

    return _card(
      child: ListTile(
        onTap: id == null ? null : () => _abrirDetalheUsuario(id),
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEDE9FE),
          child: Icon(Icons.person_outline, color: _purple),
        ),
        title: Text(usuario['nome_exibicao'] ?? 'Sem nome'),
        subtitle: Text(
          '${usuario['email'] ?? 'Sem email'}\n${_perfilLabel(usuario['perfil'])} - Criado em ${_formatDate(usuario['criado_em'])}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: isSelf
              ? 'Você não pode excluir sua própria conta'
              : 'Excluir',
          onPressed: isSelf || id == null
              ? null
              : () async {
                  final ok = await _confirmar(
                    'Excluir usuário',
                    'Tem certeza que deseja excluir este usuário?',
                  );
                  if (!ok) return;
                  await _executarAcao(
                    () => _service.excluirUsuario(id),
                    'Usuário removido com sucesso.',
                  );
                },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  Widget _buildEmpresas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Empresas',
          'Analise cadastros e status de verificação.',
        ),
        _buildFilters([
          Expanded(
            child: _searchField(
              _buscaEmpresasController,
              'Buscar empresa, email ou CNPJ',
              _carregarAbaAtual,
            ),
          ),
          _empresaStatusFilter(),
        ]),
        if (_empresas.isEmpty)
          _buildEmptyState(
            icon: Icons.business_outlined,
            title: 'Nenhuma empresa encontrada',
            message: 'Ajuste a busca ou os filtros.',
          )
        else
          ..._empresas.map(_buildEmpresaCard),
      ],
    );
  }

  Widget _buildEmpresaCard(dynamic empresa) {
    final verificada = _isEmpresaVerificada(empresa);
    final status = _statusVerificacao(empresa);
    final isPendente = status == 'pendente';
    final documentoEnviado = empresa['documento_enviado'] == true;
    final id = empresa['id'] is int
        ? empresa['id'] as int
        : int.tryParse('${empresa['id']}');

    return _card(
      child: InkWell(
        onTap: id == null ? null : () => _abrirDetalheEmpresa(id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: isPendente
                ? Border(
                    left: BorderSide(color: Colors.orange.shade600, width: 4),
                  )
                : null,
          ),
          padding: EdgeInsets.only(left: isPendente ? 12 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          empresa['nome_exibicao'] ??
                              empresa['usuario']?['nome_exibicao'] ??
                              'Empresa sem nome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (verificada) _verifiedBadge(),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(_statusVerificacaoLabel(status)),
                    backgroundColor: _statusVerificacaoColor(
                      status,
                    ).withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: _statusVerificacaoColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                empresa['email'] ?? empresa['usuario']?['email'] ?? 'Sem email',
              ),
              Text('CNPJ: ${_maskCnpj(empresa['cnpj'])}'),
              Text(
                'Vagas: ${empresa['quantidade_vagas'] ?? empresa['quantidadeVagas'] ?? 0}',
              ),
              if (empresa['verificacao_solicitada_em'] != null)
                Text(
                  'Solicitada em: ${_formatDate(empresa['verificacao_solicitada_em'])}',
                ),
              const SizedBox(height: 8),
              Text(
                empresa['descricao'] ?? 'Sem descrição.',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: id == null || !documentoEnviado
                        ? null
                        : () => _abrirDocumentoVerificacao(id),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Ver documento'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        id == null || !documentoEnviado || status == 'aprovada'
                        ? null
                        : () => _aprovarEmpresa(id),
                    icon: const Icon(Icons.verified),
                    label: const Text('Aprovar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: id == null || status == 'aprovada'
                        ? null
                        : () => _rejeitarEmpresa(id),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVagas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Vagas', 'Acompanhe e modere vagas publicadas.'),
        _buildFilters([
          Expanded(
            child: _searchField(
              _buscaVagasController,
              'Buscar por título ou empresa',
              _carregarAbaAtual,
            ),
          ),
          _dropdown<bool>(
            value: _vagaAtivaFiltro,
            hint: 'Status',
            items: const {true: 'Ativas', false: 'Arquivadas'},
            onChanged: (value) {
              setState(() => _vagaAtivaFiltro = value);
              _carregarAbaAtual();
            },
          ),
        ]),
        if (_vagas.isEmpty)
          _buildEmptyState(
            icon: Icons.work_outline,
            title: 'Nenhuma vaga encontrada',
            message: 'Ajuste a busca ou os filtros.',
          )
        else
          ..._vagas.map(_buildVagaCard),
      ],
    );
  }

  Widget _buildVagaCard(dynamic vaga) {
    final empresa = vaga['empresa'] ?? {};
    final usuario = empresa['usuario'] ?? {};
    final id = vaga['id'] is int
        ? vaga['id'] as int
        : int.tryParse('${vaga['id']}');
    final ativa = _isVagaAtiva(vaga);

    return _card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: ativa
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFF3F4F6),
          child: Icon(ativa ? Icons.work_outline : Icons.archive_outlined),
        ),
        title: Text(vaga['titulo'] ?? 'Vaga sem título'),
        subtitle: Text(
          '${usuario['nome_exibicao'] ?? 'Empresa não informada'}\n${vaga['modalidade'] ?? 'Modalidade não informada'} - ${ativa ? 'Ativa' : 'Arquivada'} - ${_formatDate(vaga['criado_em'])}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Excluir vaga',
          onPressed: id == null
              ? null
              : () async {
                  final ok = await _confirmar(
                    'Excluir vaga',
                    'Tem certeza que deseja excluir esta vaga?',
                  );
                  if (!ok) return;
                  await _executarAcao(
                    () => _service.excluirVaga(id),
                    'Vaga removida com sucesso.',
                  );
                },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  Widget _buildHabilidades() {
    final grouped = <String, List<dynamic>>{};
    for (final habilidade in _habilidades) {
      final area = habilidade['area']?.toString() ?? 'OUTRAS';
      grouped.putIfAbsent(area, () => []).add(habilidade);
    }

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final newButton = ElevatedButton.icon(
            onPressed: () => _abrirDialogHabilidade(),
            icon: const Icon(Icons.add),
            label: const Text('Nova habilidade'),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habilidades',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Crie e mantenha o catálogo usado por alunos e vagas.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              if (wide)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _searchField(
                          _buscaHabilidadesController,
                          'Buscar habilidade',
                          _carregarAbaAtual,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _habilidadesAreaDropdown(width: 220),
                      const SizedBox(width: 12),
                      newButton,
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _searchField(
                        _buscaHabilidadesController,
                        'Buscar habilidade',
                        _carregarAbaAtual,
                      ),
                      const SizedBox(height: 12),
                      _habilidadesAreaDropdown(width: double.infinity),
                      const SizedBox(height: 12),
                      newButton,
                    ],
                  ),
                ),
              if (_habilidades.isEmpty)
                _buildEmptyState(
                  icon: Icons.star_border,
                  title: 'Nenhuma habilidade encontrada',
                  message: 'Ajuste a busca ou cadastre uma nova habilidade.',
                )
              else
                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          _areaLabels[entry.key] ?? entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...entry.value.map(_buildHabilidadeCard),
                    ],
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHabilidadeCard(dynamic habilidade) {
    final id = habilidade['id'] is int
        ? habilidade['id'] as int
        : int.tryParse('${habilidade['id']}');

    return _card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE9FE),
          child: Icon(Icons.star_border, color: _purple),
        ),
        title: Text(habilidade['nome'] ?? 'Sem nome'),
        subtitle: Text(
          _areaLabels[habilidade['area']] ?? habilidade['area'] ?? 'Sem área',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: id == null
                  ? null
                  : () => _abrirDialogHabilidade(habilidade: habilidade),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: id == null
                  ? null
                  : () async {
                      final ok = await _confirmar(
                        'Excluir habilidade',
                        'Tem certeza que deseja excluir esta habilidade?',
                      );
                      if (!ok) return;
                      await _executarAcao(
                        () => _service.excluirHabilidade(id),
                        'Habilidade removida com sucesso.',
                      );
                    },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstituicoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Instituições',
          'Gerencie o catálogo usado no cadastro e perfil dos alunos.',
          action: ElevatedButton.icon(
            onPressed: () => _abrirDialogInstituicao(),
            icon: const Icon(Icons.add),
            label: const Text('Nova instituição'),
          ),
        ),
        _buildFilters([
          Expanded(
            child: _searchField(
              _buscaInstituicoesController,
              'Buscar instituição ou sigla',
              _carregarAbaAtual,
            ),
          ),
          _dropdown<bool>(
            value: _instituicaoAtivaFiltro,
            hint: 'Status',
            items: const {true: 'Ativas', false: 'Inativas'},
            onChanged: (value) {
              setState(() => _instituicaoAtivaFiltro = value);
              _carregarAbaAtual();
            },
          ),
        ]),
        if (_instituicoes.isEmpty)
          _buildEmptyState(
            icon: Icons.account_balance_outlined,
            title: 'Nenhuma instituição encontrada',
            message: 'Ajuste a busca ou cadastre uma nova instituição.',
          )
        else
          ..._instituicoes.map(_buildInstituicaoCard),
      ],
    );
  }

  Widget _buildInstituicaoCard(dynamic instituicao) {
    final id = instituicao['id'] is int
        ? instituicao['id'] as int
        : int.tryParse('${instituicao['id']}');
    final ativa = instituicao['ativa'] == true || instituicao['ativa'] == 1;

    return _card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: ativa
              ? const Color(0xFFEDE9FE)
              : const Color(0xFFF3F4F6),
          child: Icon(
            Icons.account_balance_outlined,
            color: ativa ? _purple : const Color(0xFF6B7280),
          ),
        ),
        title: Text(instituicao['nome'] ?? 'Sem nome'),
        subtitle: Text(
          '${instituicao['sigla'] ?? 'Sem sigla'} - ${ativa ? 'Ativa' : 'Inativa'}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: id == null
                  ? null
                  : () => _abrirDialogInstituicao(instituicao: instituicao),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: ativa ? 'Inativar' : 'Ativar',
              onPressed: id == null
                  ? null
                  : () => _executarAcao(
                      () => _service.atualizarInstituicao(id, ativa: !ativa),
                      ativa
                          ? 'Instituição inativada com sucesso.'
                          : 'Instituição ativada com sucesso.',
                    ),
              icon: Icon(ativa ? Icons.visibility_off : Icons.visibility),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: id == null
                  ? null
                  : () async {
                      final ok = await _confirmar(
                        'Excluir instituição',
                        'Se estiver em uso por alunos, ela será inativada.',
                      );
                      if (!ok) return;
                      await _executarAcao(
                        () => _service.excluirInstituicao(id),
                        'Instituição processada com sucesso.',
                      );
                    },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Cursos',
          'Gerencie o catálogo usado no cadastro e perfil dos alunos.',
          action: ElevatedButton.icon(
            onPressed: () => _abrirDialogCurso(),
            icon: const Icon(Icons.add),
            label: const Text('Novo curso'),
          ),
        ),
        _buildFilters([
          Expanded(
            child: _searchField(
              _buscaCursosController,
              'Buscar curso',
              _carregarAbaAtual,
            ),
          ),
          _dropdown<bool>(
            value: _cursoAtivoFiltro,
            hint: 'Status',
            items: const {true: 'Ativos', false: 'Inativos'},
            onChanged: (value) {
              setState(() => _cursoAtivoFiltro = value);
              _carregarAbaAtual();
            },
          ),
        ]),
        if (_cursos.isEmpty)
          _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'Nenhum curso encontrado',
            message: 'Ajuste a busca ou cadastre um novo curso.',
          )
        else
          ..._cursos.map(_buildCursoCard),
      ],
    );
  }

  Widget _buildCursoCard(dynamic curso) {
    final id = curso['id'] is int
        ? curso['id'] as int
        : int.tryParse('${curso['id']}');
    final ativo = curso['ativo'] == true || curso['ativo'] == 1;

    return _card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: ativo
              ? const Color(0xFFEDE9FE)
              : const Color(0xFFF3F4F6),
          child: Icon(
            Icons.school_outlined,
            color: ativo ? _purple : const Color(0xFF6B7280),
          ),
        ),
        title: Text(curso['nome'] ?? 'Sem nome'),
        subtitle: Text(ativo ? 'Ativo' : 'Inativo'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: id == null
                  ? null
                  : () => _abrirDialogCurso(curso: curso),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: ativo ? 'Inativar' : 'Ativar',
              onPressed: id == null
                  ? null
                  : () => _executarAcao(
                      () => _service.atualizarCurso(id, ativo: !ativo),
                      ativo
                          ? 'Curso inativado com sucesso.'
                          : 'Curso ativado com sucesso.',
                    ),
              icon: Icon(ativo ? Icons.visibility_off : Icons.visibility),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: id == null
                  ? null
                  : () async {
                      final ok = await _confirmar(
                        'Excluir curso',
                        'Se estiver em uso por alunos, ele será inativado.',
                      );
                      if (!ok) return;
                      await _executarAcao(
                        () => _service.excluirCurso(id),
                        'Curso processado com sucesso.',
                      );
                    },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDialogHabilidade({dynamic habilidade}) async {
    final editando = habilidade != null;
    final nomeController = TextEditingController(
      text: editando ? habilidade['nome'] ?? '' : '',
    );
    String area = editando ? habilidade['area'] ?? 'TECNOLOGIA' : 'TECNOLOGIA';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editando ? 'Editar habilidade' : 'Nova habilidade'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o nome.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: area,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Área'),
                  items: _areas
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(_areaLabels[item] ?? item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => area = value ?? area,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop();
                final id = editando
                    ? habilidade['id'] is int
                          ? habilidade['id'] as int
                          : int.tryParse('${habilidade['id']}')
                    : null;
                await _executarAcao(
                  () => editando && id != null
                      ? _service.atualizarHabilidade(
                          id,
                          nomeController.text.trim(),
                          area,
                        )
                      : _service.criarHabilidade(
                          nomeController.text.trim(),
                          area,
                        ),
                  editando
                      ? 'Habilidade atualizada com sucesso.'
                      : 'Habilidade criada com sucesso.',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
  }

  Future<void> _abrirDialogInstituicao({dynamic instituicao}) async {
    final editando = instituicao != null;
    final nomeController = TextEditingController(
      text: editando ? instituicao['nome'] ?? '' : '',
    );
    final siglaController = TextEditingController(
      text: editando ? instituicao['sigla'] ?? '' : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editando ? 'Editar instituição' : 'Nova instituição'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o nome.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: siglaController,
                  decoration: const InputDecoration(labelText: 'Sigla'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop();
                final id = editando
                    ? instituicao['id'] is int
                          ? instituicao['id'] as int
                          : int.tryParse('${instituicao['id']}')
                    : null;
                await _executarAcao(
                  () => editando && id != null
                      ? _service.atualizarInstituicao(
                          id,
                          nome: nomeController.text.trim(),
                          sigla: siglaController.text.trim(),
                        )
                      : _service.criarInstituicao(
                          nomeController.text.trim(),
                          siglaController.text.trim(),
                        ),
                  editando
                      ? 'Instituição atualizada com sucesso.'
                      : 'Instituição criada com sucesso.',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
    siglaController.dispose();
  }

  Future<void> _abrirDialogCurso({dynamic curso}) async {
    final editando = curso != null;
    final nomeController = TextEditingController(
      text: editando ? curso['nome'] ?? '' : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editando ? 'Editar curso' : 'Novo curso'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o nome.'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop();
                final id = editando
                    ? curso['id'] is int
                          ? curso['id'] as int
                          : int.tryParse('${curso['id']}')
                    : null;
                await _executarAcao(
                  () => editando && id != null
                      ? _service.atualizarCurso(
                          id,
                          nome: nomeController.text.trim(),
                        )
                      : _service.criarCurso(nomeController.text.trim()),
                  editando
                      ? 'Curso atualizado com sucesso.'
                      : 'Curso criado com sucesso.',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
  }

  Future<void> _abrirDetalheUsuario(int id) async {
    try {
      final detalhe = await _service.usuarioDetalhe(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detalhe['nome_exibicao'] ?? 'Detalhes do usuário'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Email', detalhe['email']),
                  _detailRow('Perfil', _perfilLabel(detalhe['perfil'])),
                  _detailRow('Criado em', _formatDate(detalhe['criado_em'])),
                  const Divider(height: 24),
                  if (detalhe['perfil'] == 'aluno') ...[
                    _detailRow('CPF', detalhe['cpf']),
                    _detailRow('Curso', detalhe['curso']),
                    _detailRow('Instituição', detalhe['instituicao']),
                    _detailRow('Ano de conclusão', detalhe['ano_conclusao']),
                    _detailRow('CEP', detalhe['cep']),
                    _detailRow('Endereço', detalhe['endereco']),
                    _detailRow('Número', detalhe['numero']),
                    _detailRow(
                      'Currículo',
                      detalhe['possui_curriculo'] == true
                          ? 'Anexado'
                          : 'Não anexado',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Habilidades',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _skillWrap(detalhe['habilidades']),
                  ] else if (detalhe['perfil'] == 'empresa') ...[
                    _detailRow('CNPJ', _maskCnpj(detalhe['cnpj'])),
                    _detailRow('Descrição', detalhe['descricao']),
                    _detailRow(
                      'Localização',
                      '${detalhe['latitude'] ?? 'sem latitude'} / ${detalhe['longitude'] ?? 'sem longitude'}',
                    ),
                    _detailRow(
                      'Verificada',
                      detalhe['verificada'] == true ? 'Sim' : 'Não',
                    ),
                    _detailRow(
                      'Quantidade de vagas',
                      detalhe['quantidade_vagas'],
                    ),
                  ] else
                    const Text('Conta de moderador.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } on AdminServiceException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Erro ao carregar detalhes do usuário.', error: true);
    }
  }

  Future<void> _abrirDocumentoVerificacao(int id) async {
    try {
      final bytes = await _service.documentoVerificacaoEmpresa(id);
      final blob = import_html.Blob([bytes], 'application/pdf');
      final url = import_html.Url.createObjectUrlFromBlob(blob);
      import_html.window.open(url, '_blank');
      Future.delayed(const Duration(seconds: 30), () {
        import_html.Url.revokeObjectUrl(url);
      });
    } on AdminServiceException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Erro ao abrir documento de verificação.', error: true);
    }
  }

  Future<void> _aprovarEmpresa(int id) async {
    final ok = await _confirmar(
      'Aprovar verificação',
      'Deseja aprovar a verificação desta empresa?',
    );
    if (!ok) return;

    await _executarAcao(
      () => _service.decidirVerificacaoEmpresa(id, 'aprovar'),
      'Empresa aprovada com sucesso.',
    );
  }

  Future<void> _rejeitarEmpresa(int id) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar verificação'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: motivoController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Informe o motivo da rejeição',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o motivo.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(motivoController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    motivoController.dispose();
    if (motivo == null) return;

    await _executarAcao(
      () => _service.decidirVerificacaoEmpresa(id, 'rejeitar', motivo: motivo),
      'Verificação rejeitada com sucesso.',
    );
  }

  Future<void> _abrirDetalheEmpresa(int id) async {
    try {
      final detalhe = await _service.empresaDetalhe(id);
      if (!mounted) return;
      final vagas = detalhe['vagas'] is List ? detalhe['vagas'] as List : [];
      final status = _statusVerificacao(detalhe);
      final documentoEnviado = detalhe['documento_enviado'] == true;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detalhe['nome_exibicao'] ?? 'Detalhes da empresa'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Email', detalhe['email']),
                  _detailRow('CNPJ', _maskCnpj(detalhe['cnpj'])),
                  _detailRow('Descrição', detalhe['descricao']),
                  _detailRow(
                    'Localização',
                    '${detalhe['latitude'] ?? 'sem latitude'} / ${detalhe['longitude'] ?? 'sem longitude'}',
                  ),
                  _detailRow(
                    'Verificada',
                    detalhe['verificada'] == true ? 'Sim' : 'Não',
                  ),
                  _detailRow(
                    'Situação da verificação',
                    _statusVerificacaoLabel(status),
                  ),
                  _detailRow('Documento', detalhe['documento_nome_original']),
                  _detailRow(
                    'Solicitada em',
                    _formatDate(detalhe['verificacao_solicitada_em']),
                  ),
                  _detailRow(
                    'Analisada em',
                    _formatDate(detalhe['verificacao_analisada_em']),
                  ),
                  _detailRow(
                    'Motivo da rejeição',
                    detalhe['verificacao_motivo_rejeicao'],
                  ),
                  _detailRow(
                    'Quantidade de vagas',
                    detalhe['quantidade_vagas'],
                  ),
                  _detailRow('Criada em', _formatDate(detalhe['criado_em'])),
                  _detailRow(
                    'Atualizada em',
                    _formatDate(detalhe['atualizado_em']),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Vagas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (vagas.isEmpty)
                    const Text('Nenhuma vaga cadastrada.')
                  else
                    ...vagas.map(
                      (vaga) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(vaga['titulo'] ?? 'Sem título'),
                        subtitle: Text(
                          '${vaga['modalidade'] ?? 'Sem modalidade'} - ${_isVagaAtiva(vaga) ? 'Ativa' : 'Arquivada'}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: documentoEnviado
                  ? () => _abrirDocumentoVerificacao(id)
                  : null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Ver documento'),
            ),
            TextButton.icon(
              onPressed: documentoEnviado && status != 'aprovada'
                  ? () {
                      Navigator.of(context).pop();
                      _aprovarEmpresa(id);
                    }
                  : null,
              icon: const Icon(Icons.verified),
              label: const Text('Aprovar'),
            ),
            TextButton.icon(
              onPressed: status != 'aprovada'
                  ? () {
                      Navigator.of(context).pop();
                      _rejeitarEmpresa(id);
                    }
                  : null,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Rejeitar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } on AdminServiceException catch (e) {
      _showSnack(e.message, error: true);
    } catch (_) {
      _showSnack('Erro ao carregar detalhes da empresa.', error: true);
    }
  }

  Widget _detailRow(String label, dynamic value) {
    final display = value == null || value.toString().trim().isEmpty
        ? 'Não informado'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: display),
          ],
        ),
      ),
    );
  }

  Widget _skillWrap(dynamic habilidades) {
    final items = habilidades is List ? habilidades : const [];
    if (items.isEmpty) return const Text('Nenhuma habilidade selecionada.');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (habilidade) => Chip(
              label: Text(habilidade['nome']?.toString() ?? 'Sem nome'),
              backgroundColor: const Color(0xFFEDE9FE),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildFilters(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              children: children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _unwrapExpanded(child),
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: child,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _unwrapExpanded(Widget child) {
    if (child is Expanded) {
      return SizedBox(width: double.infinity, child: child.child);
    }
    return child;
  }

  Widget _searchField(
    TextEditingController controller,
    String label,
    VoidCallback onSearch,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Buscar',
          onPressed: onSearch,
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
      onSubmitted: (_) => onSearch(),
    );
  }

  Widget _empresaStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: _empresaStatusFiltro == null,
          onSelected: (_) {
            setState(() => _empresaStatusFiltro = null);
            _carregarAbaAtual();
          },
        ),
        ChoiceChip(
          label: const Text('Pendentes'),
          selected: _empresaStatusFiltro == 'pendente',
          onSelected: (_) {
            setState(() => _empresaStatusFiltro = 'pendente');
            _carregarAbaAtual();
          },
        ),
        ChoiceChip(
          label: const Text('Aprovadas'),
          selected: _empresaStatusFiltro == 'aprovada',
          onSelected: (_) {
            setState(() => _empresaStatusFiltro = 'aprovada');
            _carregarAbaAtual();
          },
        ),
        ChoiceChip(
          label: const Text('Rejeitadas'),
          selected: _empresaStatusFiltro == 'rejeitada',
          onSelected: (_) {
            setState(() => _empresaStatusFiltro = 'rejeitada');
            _carregarAbaAtual();
          },
        ),
        ChoiceChip(
          label: const Text('Não solicitadas'),
          selected: _empresaStatusFiltro == 'nao_solicitada',
          onSelected: (_) {
            setState(() => _empresaStatusFiltro = 'nao_solicitada');
            _carregarAbaAtual();
          },
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Limpar filtro',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.clear),
                ),
        ),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStatCard(_StatCard card) {
    return _card(
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(card.icon, color: _purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.label,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                Text(
                  '${card.value ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_NavItem> get _navItems => const [
    _NavItem('Visão geral', Icons.dashboard_outlined),
    _NavItem('Usuários', Icons.people_outline),
    _NavItem('Empresas', Icons.business_outlined),
    _NavItem('Vagas', Icons.work_outline),
    _NavItem('Habilidades', Icons.star_border),
    _NavItem('Instituições', Icons.account_balance_outlined),
    _NavItem('Cursos', Icons.school_outlined),
  ];
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _StatCard {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final dynamic value;
  final IconData icon;
}
