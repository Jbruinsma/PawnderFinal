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
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder, width: 1.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (icon != null)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.iconSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 17,
                color: AppColors.seaBlue,
              ),
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
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}