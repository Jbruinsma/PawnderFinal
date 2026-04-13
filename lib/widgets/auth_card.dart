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
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
      child: child,
    );
  }
}