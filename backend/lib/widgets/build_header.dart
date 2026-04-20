import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

Widget buildHeader() {
  return Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFCCD6E0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Icons.cruelty_free_rounded,
          color: AppColors.ink,
          size: 32,
        ),
      ),
    ],
  );
}
