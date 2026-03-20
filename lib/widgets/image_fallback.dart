import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class ImageFallback extends StatelessWidget {
  const ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 216,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB4D8DE), Color(0xFFF2CCA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.pets,
          size: 88,
          color: AppColors.seaBlue,
        ),
      ),
    );
  }
}