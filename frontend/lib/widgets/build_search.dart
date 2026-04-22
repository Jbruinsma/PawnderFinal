import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

Widget buildSearch({
  required ValueChanged<String> onChanged,
  TextEditingController? controller,
}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.inputSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      cursorColor: theme.colorScheme.onSurface,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for pets...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, width: 1.4),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              size: 19,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    },
  );
}
