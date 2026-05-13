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

  @override
  Widget build(BuildContext context) {
    if (habilidades.isEmpty) {
      return const Text(
        'Nenhuma habilidade cadastrada.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: habilidades.map((habilidade) {
            final id = habilidade['id'];
            final nome = habilidade['nome'] ?? 'Sem nome';

            if (id is! int) {
              return const SizedBox.shrink();
            }

            final selected = selectedIds.contains(id);

            return FilterChip(
              label: Text(nome),
              selected: selected,
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
          }).toList(),
        ),
      ],
    );
  }
}
