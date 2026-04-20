import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.powderBlue,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: child,
          ),
        ),
      ),
    );
  }
}
