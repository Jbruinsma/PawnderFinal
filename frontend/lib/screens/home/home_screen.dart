import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/chat_screen.dart';
import 'package:pawnder_app/screens/home/community_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/missing_post_details_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/pet_details_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
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
  final _authService = AuthService();
  final _communityService = CommunityService();
  final _locationService = LocationService();
  final _postService = PostService();

  late int _selectedNavIndex;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  CurrentUser? _currentUser;
  String? _defaultCommunityId;
  List<Community> _nearbyCommunities = const [];
  bool _isLoadingCommunityPosts = false;
  bool _shouldShowFallbackCommunityPosts = true;
  bool _shouldShowFallbackPets = true;

  static const _defaultLatitude = 40.7128;
  static const _defaultLongitude = -74.0060;

  final List<Map<String, String>> _pets = const [
    {
      'name': 'Pearline',
      'meta': 'Siamese, 4 months old',
      'category': 'cat',
      'image': 'mock://sample-pet/pearline',
    },
    {
      'name': 'Scooba',
      'meta': 'Dalmatian, 2 yrs old',
      'category': 'dog',
      'image': 'mock://sample-pet/scooba',
    },
    {
      'name': 'Table',
      'meta': 'Calico, 1 month old',
      'category': 'cat',
      'image': 'mock://sample-pet/table',
    },
    {
      'name': 'AppleJax',
      'meta': 'American Bobtail, 2 yrs old',
      'category': 'cat',
      'image': 'mock://sample-pet/applejax',
    },
    {
      'name': 'Pico',
      'meta': 'Cockatiel, 8 months old',
      'category': 'bird',
      'image': 'mock://sample-pet/pico',
    },
  ];

  static const List<Map<String, String>> _fallbackCommunityPosts = [
    {
      'id': 'missing-parrot-1',
      'section': 'recent',
      'title': 'Help me find my Parrot',
      'author': 'Sheila Carr',
      'location': 'Queens',
      'posted': 'March 10th, 2026 at 4:32 PM',
      'tags': 'Bird|LostPet|Queens',
      'image': 'mock://sample-post/parrot',
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
      'image': 'mock://sample-post/georgie',
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
      'image': 'mock://sample-post/hedgehog',
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
      'image': 'mock://sample-post/cockatiel',
      'description':
          'I found this cockatiel perched on my window this afternoon. It is very tame and responds to whistles. Please contact me if you can identify unique markings.',
    },
  ];

  List<Map<String, String>> _communityPosts = [];
  List<Map<String, String>> _nearbyPets = [];

  List<Map<String, String>> get _visibleCommunityPosts {
    return _shouldShowFallbackCommunityPosts
        ? _fallbackCommunityPosts
        : _communityPosts;
  }

  List<Map<String, String>> get _visiblePets {
    return _shouldShowFallbackPets ? _pets : _nearbyPets;
  }

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    _loadCommunityData();
  }

  Future<void> _loadCommunityData() async {
    setState(() {
      _isLoadingCommunityPosts = true;
    });

    CurrentUser? currentUser = _currentUser;
    Community? defaultCommunity;
    List<Community> neighborhoods = const [];
    List<CommunityPost> posts = const [];

    try {
      currentUser = await _authService.getCurrentUser();
    } catch (_) {
      currentUser = null;
    }

    try {
      final currentLocation = await _locationService
          .requestAndSaveCurrentLocation();
      final feedLatitude = currentLocation?.latitude ?? _defaultLatitude;
      final feedLongitude = currentLocation?.longitude ?? _defaultLongitude;

      neighborhoods = await _communityService.getNeighborhoods(
        latitude: feedLatitude,
        longitude: feedLongitude,
      );
      defaultCommunity = neighborhoods.isEmpty ? null : neighborhoods.first;
    } catch (_) {
      defaultCommunity = null;
      neighborhoods = const [];
    }

    try {
      posts = await _loadPostsFor(defaultCommunity);
    } catch (_) {
      posts = const [];
    }

    try {
      final communityPosts = posts.map((post) => post.toFeedMap()).toList();
      final nearbyPets = posts.map((post) => post.toPetMap()).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = currentUser;
        _defaultCommunityId = defaultCommunity?.id;
        _nearbyCommunities = neighborhoods;
        _communityPosts = communityPosts;
        _nearbyPets = nearbyPets;
        _shouldShowFallbackCommunityPosts = communityPosts.isEmpty;
        _shouldShowFallbackPets = nearbyPets.isEmpty;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = currentUser;
        _defaultCommunityId = defaultCommunity?.id;
        _nearbyCommunities = neighborhoods;
        _shouldShowFallbackCommunityPosts = true;
        _shouldShowFallbackPets = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing saved sample posts while the backend loads.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCommunityPosts = false;
        });
      }
    }
  }

  Future<CurrentUser?> _loadCurrentUserForListing() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final currentUser = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = currentUser;
        });
      }
      return currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadDefaultCommunityIdForListing() async {
    if (_defaultCommunityId != null) {
      return _defaultCommunityId;
    }

    try {
      final currentLocation = await _locationService
          .requestAndSaveCurrentLocation();
      final neighborhoods = await _communityService.getNeighborhoods(
        latitude: currentLocation?.latitude ?? _defaultLatitude,
        longitude: currentLocation?.longitude ?? _defaultLongitude,
      );
      final communityId = neighborhoods.isEmpty ? null : neighborhoods.first.id;

      if (mounted) {
        setState(() {
          _defaultCommunityId = communityId;
          _nearbyCommunities = neighborhoods;
        });
      }

      return communityId;
    } catch (_) {
      return null;
    }
  }

  String? _resolveCommunityIdForSelection(CommunityDefinition community) {
    if (_nearbyCommunities.isEmpty) {
      return _defaultCommunityId;
    }

    final target = community.title.toLowerCase();
    Community? matched;

    for (final item in _nearbyCommunities) {
      final name = item.name.toLowerCase();
      final description = item.description.toLowerCase();

      if (name.contains(target) || target.contains(name)) {
        matched = item;
        break;
      }

      if (target == 'brooklyn' && name.contains('brooklyn')) {
        matched = item;
        break;
      }

      if (target == 'bird lovers' && (name.contains('bird') || description.contains('bird'))) {
        matched = item;
        break;
      }

      if (target == 'lost critters' && (name.contains('lost') || description.contains('lost'))) {
        matched = item;
        break;
      }
    }

    return matched?.id ?? _defaultCommunityId ?? _nearbyCommunities.first.id;
  }

Future<void> _handleCommunityTap(CommunityDefinition community) async {
  final currentUser = await _loadCurrentUserForListing();
  final selectedCommunityId = _resolveCommunityIdForSelection(community);

  if (!mounted) return;

  // Join the community silently if logged in
  if (currentUser != null && selectedCommunityId != null) {
    try {
      await _communityService.joinNeighborhood(
        communityId: selectedCommunityId,
        currentUserId: currentUser.id,
      );
      if (mounted) {
        setState(() => _defaultCommunityId = selectedCommunityId);
      }
    } catch (_) {
      // Already a member or error — continue anyway
    }
  }

  if (!mounted) return;

  // Load posts fresh from the API for this specific community
  List<Map<String, String>> communityPosts = [];
  if (selectedCommunityId != null) {
    try {
      final posts = await _postService.getCommunityPosts(
        communityId: selectedCommunityId,
        limit: 20,
      );
      communityPosts = posts.map((post) => post.toFeedMap()).toList();
    } catch (_) {
      // Fall back to filtered local posts if API fails
      communityPosts = _visibleCommunityPosts.where((post) {
        final tags = (post['tags'] ?? '').toLowerCase();
        final title = (post['title'] ?? '').toLowerCase();
        final description = (post['description'] ?? '').toLowerCase();
        final communityTitle = community.title.toLowerCase();

        return switch (community.title) {
          'Lost Critters' =>
            tags.contains('lost') || tags.contains('lostpet') ||
            (post['section'] ?? '') == 'recent',
          'Bird Lovers' => tags.contains('bird'),
          'Brooklyn' => tags.contains('brooklyn'),
          _ => tags.contains(communityTitle) ||
             title.contains(communityTitle) ||
             description.contains(communityTitle),
        };
      }).toList();
    }
  }

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CommunityPostsScreen(
        title: community.title,
        posts: communityPosts,
        onPostTap: (post) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissingPostDetailsScreen(post: post),
            ),
          );
        },
        onAddListingTap: () async {
          // Pass the selected community ID so new posts go to the right place
          final user = await _loadCurrentUserForListing();
          if (!mounted) return;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log in before creating a listing.')),
            );
            return;
          }
          final didCreate = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ListingScreen(
                authorId: user.id,
                communityId: selectedCommunityId ?? _defaultCommunityId ?? '',
              ),
            ),
          );
          if (didCreate == true && mounted) {
            // Reload this community's posts and re-push the screen
            Navigator.pop(context);
            await _handleCommunityTap(community);
          }
        },
      ),
    ),
  );
}

  Future<List<CommunityPost>> _loadPostsFor(Community? community) async {
    final postsById = <String, CommunityPost>{};

    try {
      final posts = await _postService.getGeoFeed();
      for (final post in posts) {
        postsById[post.id] = post;
      }
    } catch (_) {
      // Fall back to the neighborhood endpoint below when location auth is not ready.
    }

    if (community == null) {
      return postsById.values.toList();
    }

    final communityPosts = await _postService.getCommunityPosts(
      communityId: community.id,
      limit: 20,
    );
    for (final post in communityPosts) {
      postsById[post.id] = post;
    }

    return postsById.values.toList();
  }

  Future<void> _openListingScreen() async {
    final currentUser = await _loadCurrentUserForListing();
    final communityId = await _loadDefaultCommunityIdForListing();

    if (!mounted) {
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log in before creating a listing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (communityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No neighborhood is available yet. Seed or load neighborhoods before posting.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final didCreatePost = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingScreen(authorId: currentUser.id, communityId: communityId),
      ),
    );

    if (didCreatePost == true) {
      await _loadCommunityData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: switch (_selectedNavIndex) {
          1 => CommunityScreen(
            posts: _visibleCommunityPosts,
            isLoading: _isLoadingCommunityPosts,
            onRefresh: _loadCommunityData,
            onPostTap: (post) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissingPostDetailsScreen(post: post),
                ),
              );
            },
            onAddListingTap: () {
              _openListingScreen();
            },
            onCommunityTap: _handleCommunityTap,
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
          buildSearch(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (!isResultsMode)
            Text(
              'Browse by pet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (isResultsMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing results for "${_searchQuery.trim()}"',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!isResultsMode) const SizedBox(height: 12),
          if (!isResultsMode)
            buildCategoryRow(
              selectedCategory: _selectedCategory,
              onCategoryTap: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          if (!isResultsMode) ...[
            const SizedBox(height: 22),
            Text(
              'Ideas for you',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: buildPetList(
              pets: _visiblePets,
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
