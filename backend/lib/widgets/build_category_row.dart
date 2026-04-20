import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

Widget buildCategoryRow({
  required String selectedCategory,
  required ValueChanged<String> onCategoryTap,
}) {
  final avatars = [
    {'id': 'dog', 'image': 'assets/images/animals.jpg'},
    {'id': 'cat', 'image': 'assets/images/animals.jpg'},
    {'id': 'bird', 'image': 'assets/images/animals.jpg'},
    {'id': 'small', 'image': 'assets/images/animals.jpg'},
    {'id': 'all', 'image': 'assets/images/animals.jpg'},
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: avatars.map((avatar) {
              final id = avatar['id']!;
              final isSelected = selectedCategory == id;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onCategoryTap(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.seaBlue : const Color(0x330E889C),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset(
                      avatar['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const ImageFallback(),
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
