import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

Widget buildSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCCD5DE), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.bodyText),
                SizedBox(width: 8),
                Text(
                  'Search for pets...',
                  style: TextStyle(
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCD5DE), width: 1),
          ),
          child: const Icon(Icons.tune_rounded, color: AppColors.seaBlue),
        ),
      ],
    );
  }
