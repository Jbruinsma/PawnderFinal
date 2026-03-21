import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

Widget buildCategoryRow({
  required String selectedCategory,
  required ValueChanged<String> onCategoryTap,
}) {
  final avatars = ['🐶', '🐱', '🐤', '🐹', '🐟'];

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: avatars.map((emoji) {
              final isSelected = selectedCategory == emoji;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onCategoryTap(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.seaBlue : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.seaBlue, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 26,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
