import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.powderBlue,
      ),
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 26),
      child: child,
    );
  }
}