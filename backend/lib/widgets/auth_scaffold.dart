import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SizedBox.expand(child: child),
    );
  }
}