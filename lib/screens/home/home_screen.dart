import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/missing_post_details_screen.dart';
import 'package:pawnder_app/screens/home/pet_details_screen.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
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
  String _searchQuery = '';
  String _communitySearchQuery = '';

  final List<Map<String, String>> _pets = const [
    {'name': 'Pearline', 'meta': 'Siamese, 4 months old', 'category': '🐱'},
    {'name': 'Scooba', 'meta': 'Dalmatian, 2 years old', 'category': '🐶'},
    {'name': 'Juniper', 'meta': 'Calico, 1 year old', 'category': '🐱'},
    {'name': 'Pico', 'meta': 'Canary, 8 months old', 'category': '🐤'},
    {'name': 'Nibbles', 'meta': 'Hamster, 1 year old', 'category': '🐹'},
    {'name': 'Bubbles', 'meta': 'Goldfish, 6 months old', 'category': '🐟'},
    {'name': 'Milo', 'meta': 'Golden Retriever, 1 year old', 'category': '🐶'},
    {'name': 'Daisy', 'meta': 'Beagle, 3 years old', 'category': '🐶'},
    {'name': 'Bruno', 'meta': 'French Bulldog, 2 years old', 'category': '🐶'},
    {'name': 'Luna', 'meta': 'Ragdoll, 10 months old', 'category': '🐱'},
    {'name': 'Shadow', 'meta': 'Bombay, 2 years old', 'category': '🐱'},
    {'name': 'Coco', 'meta': 'Persian, 5 years old', 'category': '🐱'},
    {'name': 'Kiwi', 'meta': 'Parakeet, 1 year old', 'category': '🐤'},
    {'name': 'Sunny', 'meta': 'Cockatiel, 2 years old', 'category': '🐤'},
    {'name': 'Pepper', 'meta': 'Lovebird, 11 months old', 'category': '🐤'},
    {'name': 'Mocha', 'meta': 'Guinea Pig, 9 months old', 'category': '🐹'},
    {'name': 'Pip', 'meta': 'Dwarf Hamster, 7 months old', 'category': '🐹'},
    {'name': 'Nori', 'meta': 'Chinchilla, 2 years old', 'category': '🐹'},
    {'name': 'Coral', 'meta': 'Betta, 1 year old', 'category': '🐟'},
    {'name': 'Neptune', 'meta': 'Angelfish, 3 years old', 'category': '🐟'},
    {'name': 'Skipper', 'meta': 'Clownfish, 2 years old', 'category': '🐟'},
  ];

  final List<Map<String, String>> _communityPosts = const [
    {
      'id': 'missing-parrot-1',
      'section': 'recent',
      'title': 'Help me find my Parrot',
      'author': 'Sheila Carr',
      'location': 'Queens',
      'posted': 'March 10th, 2026 at 4:32 PM',
      'tags': 'Bird|LostPet|Queens',
      'image': 'assets/images/animals.jpg',
      'description':
          'My parrot has been missing for 2 hours, he was last seen in our backyard. We live in a suburban neighborhood in Queens, specifically in Elmhurst. If anyone in the area spots him, he usually responds to his name (Sony), or mimics tweets.',
    },
    {
      'id': 'missing-georgie-2',
      'section': 'recent',
      'title': 'Let\'s bring Georgie home',
      'author': 'Martha Ellis',
      'location': 'Brooklyn',
      'posted': 'March 9th, 2026 at 8:00 AM',
      'tags': 'Cat|LostPet|Brooklyn',
      'image': 'assets/images/animals.jpg',
      'description':
          'Georgie slipped out of our apartment this morning and we are doing everything we can to find him. Please message me if you have seen a white and brown cat near downtown Brooklyn.',
    },
    {
      'id': 'found-hedgehog-3',
      'section': 'found',
      'title': 'Who\'s hedgehog is this',
      'author': 'Manny Ortiz',
      'location': 'Manhattan',
      'posted': 'March 10th, 2026 at 3:10 PM',
      'tags': 'Manhattan|FoundPet|Hedgehog',
      'image': 'assets/images/animals.jpg',
      'description':
          'Found a friendly hedgehog near 96th street around noon. It looks domesticated and seems well cared for. Reach out with details if this pet belongs to you.',
    },
    {
      'id': 'found-cockatiel-4',
      'section': 'found',
      'title': 'Found this lil cockateel',
      'author': 'Noah Fields',
      'location': 'Queens',
      'posted': 'March 8th, 2026 at 4:00 PM',
      'tags': 'FoundPet|Bird|Queens',
      'image': 'assets/images/animals.jpg',
      'description':
          'I found this cockatiel perched on my window this afternoon. It is very tame and responds to whistles. Please contact me if you can identify unique markings.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SafeArea(
        child: switch (_selectedNavIndex) {
          1 => _buildCommunityView(context),
          2 => _buildPlaceholderView(
            title: 'Messages',
            subtitle: 'Direct messages are coming soon.',
            icon: Icons.chat_bubble_rounded,
          ),
          3 => _buildPlaceholderView(
            title: 'Profile',
            subtitle: 'Your profile page is coming soon.',
            icon: Icons.person_rounded,
          ),
          _ => _buildAdoptionView(context),
        },
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

  Widget _buildAdoptionView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),
          const SizedBox(height: 14),
          buildSearch(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
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
              searchQuery: _searchQuery,
              onPetTap: (pet) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: pet)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.asset(
                    'assets/images/animals.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Community Alerts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2A3440),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          buildSearch(
            onChanged: (value) {
              setState(() {
                _communitySearchQuery = value;
              });
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Stack(
              children: [
                buildCommunityPostsFeed(
                  posts: _communityPosts,
                  searchQuery: _communitySearchQuery,
                  onPostTap: (post) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MissingPostDetailsScreen(post: post),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 8,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF18212A),
                      elevation: 4,
                      shadowColor: const Color(0x22000000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListingScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Add listing here +',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 36, color: AppColors.seaBlue),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C3742),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
