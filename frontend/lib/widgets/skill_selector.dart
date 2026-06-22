// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class SkillSelector extends StatefulWidget {
  const SkillSelector({
    super.key,
    required this.habilidades,
    required this.selectedIds,
    required this.onChanged,
    this.title = 'Habilidades',
    this.searchController,
    this.searchHint = 'Buscar habilidades',
    this.showSearch = true,
    this.showSelected = true,
    this.showAreaFilter = true,
    this.maxListHeight = 320,
  });

  final List<dynamic> habilidades;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final String title;
  final TextEditingController? searchController;
  final String searchHint;
  final bool showSearch;
  final bool showSelected;
  final bool showAreaFilter;
  final double maxListHeight;

  @override
  State<SkillSelector> createState() => _SkillSelectorState();
}

class _SkillSelectorState extends State<SkillSelector> {
  late final TextEditingController _internalSearchController;
  final _listScrollController = ScrollController();
  TextEditingController get _searchController =>
      widget.searchController ?? _internalSearchController;
  String? _areaFiltro;

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
    'OUTRAS': 'Outras',
  };

  static const _areaOrder = [
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
    'OUTRAS',
  ];

  @override
  void initState() {
    super.initState();
    _internalSearchController = TextEditingController();
    _searchController.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant SkillSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController =
        oldWidget.searchController ?? _internalSearchController;
    final newController = widget.searchController ?? _internalSearchController;
    if (oldController != newController) {
      oldController.removeListener(_refresh);
      newController.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_refresh);
    _listScrollController.dispose();
    _internalSearchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHabilidades;

    if (widget.habilidades.isEmpty) {
      return const Text(
        'Nenhuma habilidade cadastrada.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_border, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.showSearch) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: widget.searchHint,
              hintText: 'Digite para buscar...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.showAreaFilter) ...[
          _buildAreaFilter(),
          const SizedBox(height: 16),
        ],
        if (widget.showSelected && widget.selectedIds.isNotEmpty) ...[
          _buildSelectedSection(),
          const SizedBox(height: 18),
        ],
        if (filtered.isEmpty)
          const Text(
            'Nenhuma habilidade encontrada.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          )
        else
          SizedBox(
            height: widget.maxListHeight,
            child: Scrollbar(
              controller: _listScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _listScrollController,
                padding: EdgeInsets.zero,
                children: _buildGroups(filtered),
              ),
            ),
          ),
      ],
    );
  }

  List<dynamic> get _filteredHabilidades {
    final query = _normalizar(_searchController.text);

    return widget.habilidades.where((habilidade) {
      final nome = habilidade['nome']?.toString() ?? '';
      final area = habilidade['area']?.toString() ?? '';
      final label = _areaLabels[area] ?? area;
      final areaMatches = _areaFiltro == null || area == _areaFiltro;
      final queryMatches =
          query.isEmpty ||
          _normalizar(nome).contains(query) ||
          _normalizar(label).contains(query);

      return areaMatches && queryMatches;
    }).toList();
  }

  String _normalizar(String value) {
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

  int? _idOf(dynamic habilidade) {
    final id = habilidade['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  Widget _buildAreaFilter() {
    final areasPresentes = widget.habilidades
        .map((habilidade) => habilidade['area']?.toString())
        .where((area) => area != null && _areaLabels.containsKey(area))
        .cast<String>()
        .toSet();
    final areasOrdenadas = _areaOrder
        .where((area) => areasPresentes.contains(area))
        .toList();

    if (areasOrdenadas.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String?>(
      initialValue: _areaFiltro,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Área',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas as áreas'),
        ),
        ...areasOrdenadas.map(
          (area) => DropdownMenuItem<String?>(
            value: area,
            child: Text(_areaLabels[area] ?? area),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() => _areaFiltro = value);
      },
    );
  }

  Widget _buildSelectedSection() {
    final selected = widget.habilidades.where((habilidade) {
      final id = _idOf(habilidade);
      return id != null && widget.selectedIds.contains(id);
    }).toList();

    if (selected.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecionadas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selected.map((habilidade) {
            final id = _idOf(habilidade);
            return InputChip(
              label: Text(habilidade['nome'] ?? 'Sem nome'),
              selected: true,
              selectedColor: const Color(0xFFEDE9FE),
              deleteIconColor: const Color(0xFF7C3AED),
              onDeleted: id != null
                  ? () {
                      final updated = Set<int>.from(widget.selectedIds)
                        ..remove(id);
                      widget.onChanged(updated);
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildGroups(List<dynamic> habilidadesFiltradas) {
    final grouped = <String, List<dynamic>>{};

    for (final habilidade in habilidadesFiltradas) {
      final area = habilidade['area']?.toString();
      final key = _areaLabels.containsKey(area) ? area! : 'OUTRAS';
      grouped.putIfAbsent(key, () => []).add(habilidade);
    }

    return _areaOrder.where((area) => grouped[area]?.isNotEmpty ?? false).map((
      area,
    ) {
      final items = grouped[area]!;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _areaLabels[area]!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: items.map(_buildChip).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildChip(dynamic habilidade) {
    final id = _idOf(habilidade);
    final nome = habilidade['nome'] ?? 'Sem nome';

    if (id == null) {
      return const SizedBox.shrink();
    }

    final selected = widget.selectedIds.contains(id);

    return FilterChip(
      label: Text(
        nome,
        style: TextStyle(
          color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF7C3AED).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? const Color(0xFF7C3AED).withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      onSelected: (value) {
        final updated = Set<int>.from(widget.selectedIds);

        if (value) {
          updated.add(id);
        } else {
          updated.remove(id);
        }

        widget.onChanged(updated);
      },
    );
  }
}
