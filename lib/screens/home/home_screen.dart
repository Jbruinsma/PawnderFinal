import 'package:flutter/material.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_header.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/build_search.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _pets = const [
    {
      'name': 'Pearline',
      'meta': 'Siamese, 4 months old',
      'category': '🐱',
    },
    {
      'name': 'Scooba',
      'meta': 'Dalmatian, 2 years old',
      'category': '🐶',
    },
    {
      'name': 'Juniper',
      'meta': 'Calico, 1 year old',
      'category': '🐱',
    },
    {
      'name': 'Pico',
      'meta': 'Canary, 8 months old',
      'category': '🐤',
    },
    {
      'name': 'Nibbles',
      'meta': 'Hamster, 1 year old',
      'category': '🐹',
    },
    {
      'name': 'Bubbles',
      'meta': 'Goldfish, 6 months old',
      'category': '🐟',
    },
    {
      'name': 'Milo',
      'meta': 'Golden Retriever, 1 year old',
      'category': '🐶',
    },
    {
      'name': 'Daisy',
      'meta': 'Beagle, 3 years old',
      'category': '🐶',
    },
    {
      'name': 'Bruno',
      'meta': 'French Bulldog, 2 years old',
      'category': '🐶',
    },
    {
      'name': 'Luna',
      'meta': 'Ragdoll, 10 months old',
      'category': '🐱',
    },
    {
      'name': 'Shadow',
      'meta': 'Bombay, 2 years old',
      'category': '🐱',
    },
    {
      'name': 'Coco',
      'meta': 'Persian, 5 years old',
      'category': '🐱',
    },
    {
      'name': 'Kiwi',
      'meta': 'Parakeet, 1 year old',
      'category': '🐤',
    },
    {
      'name': 'Sunny',
      'meta': 'Cockatiel, 2 years old',
      'category': '🐤',
    },
    {
      'name': 'Pepper',
      'meta': 'Lovebird, 11 months old',
      'category': '🐤',
    },
    {
      'name': 'Mocha',
      'meta': 'Guinea Pig, 9 months old',
      'category': '🐹',
    },
    {
      'name': 'Pip',
      'meta': 'Dwarf Hamster, 7 months old',
      'category': '🐹',
    },
    {
      'name': 'Nori',
      'meta': 'Chinchilla, 2 years old',
      'category': '🐹',
    },
    {
      'name': 'Coral',
      'meta': 'Betta, 1 year old',
      'category': '🐟',
    },
    {
      'name': 'Neptune',
      'meta': 'Angelfish, 3 years old',
      'category': '🐟',
    },
    {
      'name': 'Skipper',
      'meta': 'Clownfish, 2 years old',
      'category': '🐟',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 14),
              buildSearch(),
              const SizedBox(height: 18),
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.seaBlue,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              buildCategoryRow(
                selectedCategory: _selectedCategory,
                onCategoryTap: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: buildPetList(
                  pets: _pets,
                  selectedCategory: _selectedCategory,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(
        selectedNavIndex: _selectedNavIndex,
        onNavTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
    );
  }

}
  

  






