import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class AuthInput extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;

  const AuthInput({
    super.key,
    required this.hintText,
    this.icon,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 20, color: const Color(0xFF7E8A96)),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
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
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}