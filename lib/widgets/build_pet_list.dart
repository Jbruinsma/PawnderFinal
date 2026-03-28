import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

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

  final visiblePets = selectedCategory == 'all'
    ? byCategory
    : byCategory.where((pet) {
      final name = (pet['name'] ?? '').toLowerCase();
      final meta = (pet['name'] ?? '').toLowerCase();
      return name.contains(query) || meta.contains(query);
    }).toList();
  
  if (visiblePets.isEmpty) {
    return const Center(
      child: Text(
        'No pets found',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.bodyText,
        ),
      ),
    );
  }

  return ListView.separated(
    itemCount: visiblePets.length,
    separatorBuilder: (context, index) => const SizedBox(height: 14),
    itemBuilder: (context, index) {
      final pet = visiblePets[index];
      final heroTag = 'pet-${pet['name'] ?? index.toString()}';

      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onPetTap(pet),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.seaBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/animals.jpg',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(height: 160, child: ImageFallback());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['name']!,
                            style: const TextStyle(
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pet['meta']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.pets_rounded,
                      size: 30,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}