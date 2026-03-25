import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

Widget buildSearch({
  required ValueChanged<String> onChanged,
  TextEditingController? controller,
}) {
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
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.bodyText),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorColor: AppColors.seaBlue,
                    style: const TextStyle(
                      color: AppColors.bodyText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search for pets...',
                      hintStyle: TextStyle(
                        color: AppColors.bodyText,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
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
