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
                color: Color(0xFF1F2937)
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: habilidades.map((habilidade) {
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
              showCheckmark: false, // Desliga o checkmark padrão feio
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF7C3AED).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? const Color(0xFF7C3AED).withOpacity(0.5) : Colors.transparent,
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
          }).toList(),
        ),
      ],
    );
  }
}
