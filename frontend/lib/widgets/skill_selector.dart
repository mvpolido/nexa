// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class SkillSelector extends StatelessWidget {
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
  });

  final List<dynamic> habilidades;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final String title;
  final TextEditingController? searchController;
  final String searchHint;
  final bool showSearch;
  final bool showSelected;

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
  Widget build(BuildContext context) {
    final filtered = _filteredHabilidades;

    if (habilidades.isEmpty) {
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
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (showSearch) ...[
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: searchHint,
              hintText: 'Digite para buscar...',
              prefixIcon: const Icon(Icons.search),
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
        if (showSelected && selectedIds.isNotEmpty) ...[
          _buildSelectedSection(),
          const SizedBox(height: 18),
        ],
        if (filtered.isEmpty)
          const Text(
            'Nenhuma habilidade encontrada.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          )
        else
          ..._buildGroups(filtered),
      ],
    );
  }

  List<dynamic> get _filteredHabilidades {
    final query = _normalizar(searchController?.text ?? '');
    if (query.isEmpty) return habilidades;

    return habilidades.where((habilidade) {
      final nome = habilidade['nome']?.toString() ?? '';
      final area = habilidade['area']?.toString() ?? '';
      final label = _areaLabels[area] ?? area;
      return _normalizar(nome).contains(query) ||
          _normalizar(label).contains(query);
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

  Widget _buildSelectedSection() {
    final selected = habilidades.where((habilidade) {
      final id = habilidade['id'];
      return id is int && selectedIds.contains(id);
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
            final id = habilidade['id'];
            return InputChip(
              label: Text(habilidade['nome'] ?? 'Sem nome'),
              selected: true,
              selectedColor: const Color(0xFFEDE9FE),
              deleteIconColor: const Color(0xFF7C3AED),
              onDeleted: id is int
                  ? () {
                      final updated = Set<int>.from(selectedIds)..remove(id);
                      onChanged(updated);
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
    final id = habilidade['id'];
    final nome = habilidade['nome'] ?? 'Sem nome';

    if (id is! int) {
      return const SizedBox.shrink();
    }

    final selected = selectedIds.contains(id);

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
        final updated = Set<int>.from(selectedIds);

        if (value) {
          updated.add(id);
        } else {
          updated.remove(id);
        }

        onChanged(updated);
      },
    );
  }
}
