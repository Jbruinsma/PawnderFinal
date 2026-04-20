import 'package:flutter/material.dart';
import 'package:pawnder_app/models/nav_item.dart';
import 'package:pawnder_app/theme.dart';

Widget buildBottomNav({
  required int selectedNavIndex,
  required ValueChanged<int> onNavTap,
}) {
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
        color: AppColors.powderBlue,
        border: const Border(
          top: BorderSide(color: AppColors.seaBlue, width: 2),
        ),
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
                  color: isSelected ? AppColors.seaBlue : const Color(0xFF0A7082),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
