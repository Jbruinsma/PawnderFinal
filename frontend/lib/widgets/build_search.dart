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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  cursorColor: AppColors.seaBlue,
                  style: const TextStyle(
                    color: Color(0xFF77818C),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search for pets...',
                    hintStyle: TextStyle(
                      color: Color(0xFFA5ADB7),
                      fontWeight: FontWeight.w500,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF444444), width: 1.4),
        ),
        child: const Icon(Icons.filter_alt_outlined, size: 19, color: Color(0xFF404040)),
      ),
    ],
  );
}
