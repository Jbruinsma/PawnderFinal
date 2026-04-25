import 'dart:io';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imagePath;
  final double size;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserAvatar({
    super.key,
    required this.imagePath,
    this.size = 44,
    this.fallbackIcon = Icons.person_outline_rounded,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = imagePath?.trim();
    final hasImage = path != null && path.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: size * 0.46,
                  color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Icon(
                fallbackIcon,
                size: size * 0.46,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
