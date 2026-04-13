import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthInput extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final bool obscureText;

  const AuthInput({
    super.key,
    required this.hintText,
    this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF8B9097),
            ),
          if (icon != null) const SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: obscureText,
              style: AppTextStyles.field,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: AppTextStyles.field.copyWith(
                  color: const Color(0xFF8A95A1),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}