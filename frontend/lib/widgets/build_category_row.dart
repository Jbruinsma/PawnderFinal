import 'package:flutter/material.dart';

Widget buildCategoryRow({
  required String selectedCategory,
  required ValueChanged<String> onCategoryTap,
}) {
  final avatars = [
    {'id': 'dog', 'label': 'Dogs', 'icon': Icons.pets_rounded},
    {'id': 'cat', 'label': 'Cats', 'icon': Icons.cruelty_free_rounded},
    {'id': 'bird', 'label': 'Birds', 'icon': Icons.flutter_dash_rounded},
    {'id': 'small', 'label': 'Small pets', 'icon': Icons.emoji_nature_rounded},
    {'id': 'all', 'label': 'All pets', 'icon': Icons.grid_view_rounded},
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final tileWidth = ((constraints.maxWidth - 16) / 2.2).clamp(132.0, 168.0);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < avatars.length; i++) ...[
              Builder(
                builder: (context) {
                  final avatar = avatars[i];
                  final id = avatar['id']! as String;
                  final label = avatar['label']! as String;
                  final icon = avatar['icon']! as IconData;
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
              if (i < avatars.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    },
  );
}
