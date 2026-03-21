import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

 Widget buildHeader() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: AppColors.seaBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Find your next best friend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C4856),
            ),
          ),
        ),
      ],
    );
  }
