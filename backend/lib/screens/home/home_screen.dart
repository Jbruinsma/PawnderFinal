import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/chat_screen.dart';
import 'package:pawnder_app/screens/home/community_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/missing_post_details_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/pet_details_screen.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_header.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/build_search.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';
  final int initialNavIndex;

  const HomeScreen({super.key, this.initialNavIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedNavIndex;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  final List<Map<String, String>> _pets = const [
    {
      'name': 'Pearline',
      'meta': 'Siamese, 4 months old',
      'category': 'cat',
      'image': 'assets/images/animals.jpg',
    },
    {
      'name': 'Scooba',
      'meta': 'Dalmatian, 2 yrs old',
      'category': 'dog',
      'image': 'assets/images/animals.jpg',
    },
    {
      'name': 'Table',
      'meta': 'Calico, 1 month old',
      'category': 'cat',
      'image': 'assets/images/animals.jpg',
    },
    {
      'name': 'AppleJax',
      'meta': 'American Bobtail, 2 yrs old',
      'category': 'cat',
      'image': 'assets/images/animals.jpg',
    },
    {
      'name': 'Pico',
      'meta': 'Cockatiel, 8 months old',
      'category': 'bird',
      'image': 'assets/images/animals.jpg',
    },
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
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SafeArea(
        child: switch (_selectedNavIndex) {
          1 => CommunityScreen(
            posts: _communityPosts,
            onPostTap: (post) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissingPostDetailsScreen(post: post),
                ),
              );
            },
            onAddListingTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ListingScreen(),
                ),
              );
            },
            onCommunityTap: (community) {
              final filteredPosts = _communityPosts.where((post) {
                final tags = (post['tags'] ?? '').toLowerCase();
                final location = (post['location'] ?? '').toLowerCase();
                final title = (post['title'] ?? '').toLowerCase();
                final description = (post['description'] ?? '').toLowerCase();

                return switch (community.title) {
                  'Lost Critters' =>
                    (post['section'] ?? '') == 'recent' ||
                    tags.contains('lostpet') ||
                    title.contains('find') ||
                    description.contains('missing'),
                  'Bird Lovers' =>
                    tags.contains('bird') || title.contains('parrot'),
                  'Brooklyn' =>
                    tags.contains('brooklyn') || location.contains('brooklyn'),
                  _ => false,
                };
              }).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityPostsScreen(
                    title: community.title,
                    posts: filteredPosts,
                    onPostTap: (post) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MissingPostDetailsScreen(post: post),
                        ),
                      );
                    },
                    onAddListingTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          2 => const ChatScreen(),
          3 => const ProfileScreen(),
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
    final isResultsMode = _searchQuery.trim().isNotEmpty;

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
          const SizedBox(height: 16),
          if (!isResultsMode)
            const Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppColors.seaBlue,
                letterSpacing: -0.5,
              ),
            ),
          if (isResultsMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing results for "${_searchQuery.trim()}"',
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!isResultsMode) const SizedBox(height: 10),
          if (!isResultsMode)
            buildCategoryRow(
              selectedCategory: _selectedCategory,
              onCategoryTap: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          if (!isResultsMode) const SizedBox(height: 16),
          Expanded(
            child: buildPetList(
              pets: _pets,
              selectedCategory: isResultsMode ? 'all' : _selectedCategory,
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

}
