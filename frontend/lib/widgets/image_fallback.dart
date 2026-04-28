import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class ImageFallback extends StatelessWidget {
  const ImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 216,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [AppColors.darkElevated, AppColors.darkSurface]
              : const [Color(0xFFB4D8DE), Color(0xFFF2CCA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.pets, size: 88, color: theme.colorScheme.onSurface),
      ),
    );
  }
}
