import 'package:flutter/material.dart';
import 'package:pawnder_app/models/nav_item.dart';
import 'package:pawnder_app/theme.dart';

Widget buildBottomNav({
  required int selectedNavIndex,
  required ValueChanged<int> onNavTap,
  int messageBadgeCount = 0,
}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return _BottomNavContent(
        selectedNavIndex: selectedNavIndex,
        onNavTap: onNavTap,
        messageBadgeCount: messageBadgeCount,
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
  final int messageBadgeCount;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final Color borderColor;

  const _BottomNavContent({
    required this.selectedNavIndex,
    required this.onNavTap,
    required this.messageBadgeCount,
    required this.backgroundColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      NavItem(icon: Icons.home_rounded, label: 'Home'),
      NavItem(icon: Icons.groups_2_rounded, label: 'Alerts'),
      NavItem(
        icon: Icons.message_rounded,
        label: 'Messages',
        badgeCount: messageBadgeCount,
      ),
      NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
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
                    child: Center(
                      child: SizedBox(
                        width: 30,
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Icon(
                                item.icon,
                                size: 26,
                                color: isSelected
                                    ? selectedColor
                                    : unselectedColor,
                              ),
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -8,
                                top: -6,
                                child: _NavBadge(count: item.badgeCount),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  final int count;

  const _NavBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
