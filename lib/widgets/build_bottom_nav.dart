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
    NavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
    NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.powderBlue,
        border: const Border(
          top: BorderSide(color: Color(0x80CAD4DF), width: 1),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0x66FFFFFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.easeOut,
                      width: isSelected ? 22 : 0,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.seaBlue,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Icon(
                      item.icon,
                      size: isSelected ? 26 : 23,
                      color: isSelected
                          ? const Color(0xFF24313E)
                          : const Color(0xFF8D99A6),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF24313E)
                            : const Color(0xFF8D99A6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
