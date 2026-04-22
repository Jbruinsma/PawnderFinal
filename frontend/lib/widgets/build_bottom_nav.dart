import 'package:flutter/material.dart';
import 'package:pawnder_app/models/nav_item.dart';
import 'package:pawnder_app/theme.dart';

Widget buildBottomNav({
  required int selectedNavIndex,
  required ValueChanged<int> onNavTap,
}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return _BottomNavContent(
        selectedNavIndex: selectedNavIndex,
        onNavTap: onNavTap,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedColor: theme.colorScheme.onSurface,
        unselectedColor: isDark
            ? AppColors.darkMuted
            : theme.colorScheme.onSurfaceVariant,
        borderColor: theme.dividerColor,
      );
    },
  );
}

class _BottomNavContent extends StatelessWidget {
  final int selectedNavIndex;
  final ValueChanged<int> onNavTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final Color borderColor;

  const _BottomNavContent({
    required this.selectedNavIndex,
    required this.onNavTap,
    required this.backgroundColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      NavItem(icon: Icons.home_rounded, label: 'Home'),
      NavItem(icon: Icons.priority_high_rounded, label: 'Alerts'),
      NavItem(icon: Icons.message_rounded, label: 'Messages'),
      NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 1, 4, 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = index == selectedNavIndex;
            final item = items[index];

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onNavTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Icon(
                    item.icon,
                    size: 26,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
