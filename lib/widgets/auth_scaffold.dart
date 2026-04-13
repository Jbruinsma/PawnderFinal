import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}