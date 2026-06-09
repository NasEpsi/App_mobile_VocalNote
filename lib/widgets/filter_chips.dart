import 'package:flutter/material.dart';

import '../models/note.dart';

/// Horizontal row of category filter chips: "Tous" + each [NoteCategory].
class FilterChips extends StatelessWidget {
  final NoteCategory? selected;
  final ValueChanged<NoteCategory?> onSelected;

  const FilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            context,
            label: 'Tous',
            isSelected: selected == null,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => onSelected(null),
          ),
          for (final category in NoteCategory.values)
            _chip(
              context,
              label: category.label,
              isSelected: selected == category,
              color: category.color,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE3E6EF),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF5A6072),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
