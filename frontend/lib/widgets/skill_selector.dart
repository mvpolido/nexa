// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class SkillSelector extends StatelessWidget {
  const SkillSelector({
    super.key,
    required this.habilidades,
    required this.selectedIds,
    required this.onChanged,
    this.title = 'Habilidades',
  });

  final List<dynamic> habilidades;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final String title;

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
        ..._buildGroups(),
      ],
    );
  }

  List<Widget> _buildGroups() {
    final grouped = <String, List<dynamic>>{};

    for (final habilidade in habilidades) {
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
