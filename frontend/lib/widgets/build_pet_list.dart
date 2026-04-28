import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

Widget buildPetList({
  required List<Map<String, String>> pets,
  required String selectedCategory,
  required String searchQuery,
  required ValueChanged<Map<String, String>> onPetTap,
}) {
  final byCategory = selectedCategory == 'all'
      ? pets
      : pets.where((pet) => pet['category'] == selectedCategory).toList();

  final query = searchQuery.trim().toLowerCase();

  final visiblePets = query.isEmpty
      ? byCategory
      : byCategory.where((pet) {
          final name = (pet['name'] ?? '').toLowerCase();
          final meta = (pet['meta'] ?? '').toLowerCase();
          return name.contains(query) || meta.contains(query);
        }).toList();

  if (visiblePets.isEmpty) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: Text(
            'No pets found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  return GridView.builder(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 24,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
    ),
    itemCount: visiblePets.length,
    itemBuilder: (context, index) {
      return _PetMarketCard(
        pet: visiblePets[index],
        index: index,
        onTap: () => onPetTap(visiblePets[index]),
      );
    },
  );
}

class _PetMarketCard extends StatelessWidget {
  final Map<String, String> pet;
  final int index;
  final VoidCallback onTap;

  const _PetMarketCard({
    required this.pet,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'pet-${pet['name'] ?? index.toString()}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : theme.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: -3,
                      top: -3,
                      right: -3,
                      bottom: -3,
                      child: Hero(
                        tag: heroTag,
                        child: PetImage(
                          image: pet['image'],
                          height: double.infinity,
                          width: double.infinity,
                          preserveSubject: true,
                          seed: pet['id'] ?? pet['name'] ?? index.toString(),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _RoundAction(icon: Icons.favorite_border_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pet['name'] ?? 'Pet listing',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pet['meta'] ?? 'Community listing',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  pet['location'] ?? 'Nearby',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;

  const _RoundAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
    );
  }
}
