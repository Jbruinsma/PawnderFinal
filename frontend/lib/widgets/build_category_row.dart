import 'package:flutter/material.dart';

IconData _getIconForCategory(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('dog')) return Icons.pets_rounded;
  if (lower.contains('cat')) return Icons.cruelty_free_rounded;
  if (lower.contains('bird')) return Icons.flutter_dash_rounded;
  if (lower.contains('small')) return Icons.emoji_nature_rounded;
  if (lower == 'all') return Icons.grid_view_rounded;
  return Icons.sell_rounded;
}

Widget buildCategoryRow({
  required String selectedCategory,
  required ValueChanged<String> onCategoryTap,
  required List<String> categories,
}) {
  final displayCategories = [
    'all',
    ...categories.where((c) => c.toLowerCase() != 'all'),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final tileWidth = ((constraints.maxWidth - 16) / 2.2).clamp(132.0, 168.0);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < displayCategories.length; i++) ...[
              Builder(
                builder: (context) {
                  final id = displayCategories[i];
                  final label = id == 'all' ? 'All pets' : id;
                  final icon = _getIconForCategory(id);
                  final isSelected = selectedCategory == id;

                  return SizedBox(
                    width: tileWidth,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(2),
                      onTap: () => onCategoryTap(id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : theme.cardColor,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.scaffoldBackgroundColor
                                      : theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              icon,
                              color: isSelected
                                  ? theme.scaffoldBackgroundColor
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (i < displayCategories.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    },
  );
}