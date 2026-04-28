import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const NavItem({required this.icon, required this.label, this.badgeCount = 0});
}
