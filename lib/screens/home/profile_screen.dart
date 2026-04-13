import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/animals.jpg',
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ImageFallback(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'STEVEN XIMMER',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Account info',
                      style: TextStyle(
                        color: Color(0xFF27313A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 2, color: AppColors.seaBlue),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      'assets/images/animals.jpg',
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        height: 72,
                        child: ImageFallback(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 26),
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/images/animals.jpg',
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ImageFallback(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'STEVEN XIMMER',
              maxLines: 1,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _MenuTile(label: 'MY LISTINGS'),
          const SizedBox(height: 10),
          _MenuTile(label: 'BOOKMARKS'),
          const SizedBox(height: 10),
          _MenuTile(label: 'CONTACT\nINFORMATION'),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;

  const _MenuTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
          color: AppColors.seaBlue,
        ),
      ),
    );
  }
}
