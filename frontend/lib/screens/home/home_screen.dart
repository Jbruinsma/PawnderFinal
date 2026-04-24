import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/chat_screen.dart';
import 'package:pawnder_app/screens/home/community_screen.dart';
import 'package:pawnder_app/screens/home/create_community_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/missing_post_details_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/pet_details_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/services/feed_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/build_search.dart';

const List<Map<String, String>> _staticPets = [];

const List<Map<String, String>> _fallbackPosts = [];

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
  final _feedService = FeedService();

  late int _selectedNavIndex;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  CurrentUser? _currentUser;
  String? _selectedCommunityName;
  List<Community> _nearbyCommunities = const [];
  bool _isLoadingCommunityPosts = false;
  bool _shouldShowFallbackCommunityPosts = true;
  bool _shouldShowFallbackPets = true;

  static const _defaultLatitude = 40.7128;
  static const _defaultLongitude = -74.0060;

  List<Map<String, String>> _communityPosts = [];
  List<Map<String, String>> _nearbyPets = [];

  List<Map<String, String>> get _visibleCommunityPosts =>
      _shouldShowFallbackCommunityPosts ? _fallbackPosts : _communityPosts;
  List<Map<String, String>> get _visiblePets =>
      _shouldShowFallbackPets ? _staticPets : _nearbyPets;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunityData();
    });
  }

  Future<void> _loadCommunityData() async {
    setState(() => _isLoadingCommunityPosts = true);

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (_) {
      _currentUser = null;
    }

    double lat = _defaultLatitude;
    double lon = _defaultLongitude;

    try {
      final currentLocation = await _locationService
          .requestAndSaveCurrentLocation();
      if (currentLocation != null) {
        lat = currentLocation.latitude;
        lon = currentLocation.longitude;
      }
    } catch (e) {
      debugPrint('Location request failed (using defaults): $e');
    }

    try {
      final feedData = await _feedService.getNewFeed(
        latitude: lat,
        longitude: lon,
      );

      final feedCommunities = feedData['communities'] as List<Community>;
      final posts = feedData['posts'] as List<CommunityPost>;
      List<Community> savedCommunities = const [];

      if (_currentUser != null) {
        try {
          savedCommunities = await _communityService.getMyNeighborhoods();
        } catch (e) {
          debugPrint('Saved communities request failed: $e');
        }
      }

      final communitiesById = <String, Community>{};
      for (final community in savedCommunities) {
        communitiesById[community.id] = community;
      }
      for (final community in feedCommunities) {
        communitiesById[community.id] = community;
      }

      _nearbyCommunities = communitiesById.values.toList();

      Community? selectedCommunity;
      if (_selectedCommunityName != null) {
        for (final community in _nearbyCommunities) {
          if (community.name == _selectedCommunityName) {
            selectedCommunity = community;
            break;
          }
        }
      }
      final defaultCommunity =
          selectedCommunity ??
          (_nearbyCommunities.isEmpty ? null : _nearbyCommunities.first);
      _selectedCommunityName = defaultCommunity?.name;

      if (mounted) {
        setState(() {
          _communityPosts = posts.map((post) => post.toFeedMap()).toList();
          _nearbyPets = posts.map((post) => post.toPetMap()).toList();
          _shouldShowFallbackCommunityPosts = _communityPosts.isEmpty;
          _shouldShowFallbackPets = _nearbyPets.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('API Feed request failed: $e');
      if (mounted) {
        setState(() {
          _shouldShowFallbackCommunityPosts = true;
          _shouldShowFallbackPets = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Showing saved sample posts while the backend loads.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCommunityPosts = false);
    }
  }

  Future<void> _handleCommunityTap(Community community) async {
    final selectedCommunityId = community.id;
    if (!mounted) return;

    if (_currentUser != null) {
      try {
        await _communityService.joinNeighborhood(
          communityId: selectedCommunityId,
        );
        if (mounted) {
          setState(() {
            _selectedCommunityName = community.name;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _selectedCommunityName = community.name);
      }
    } else if (mounted) {
      setState(() => _selectedCommunityName = community.name);
    }

    if (!mounted) return;

    List<Map<String, String>> communityPosts = [];
    try {
      final posts = await _postService.getCommunityPosts(
        communityId: selectedCommunityId,
        limit: 20,
      );
      communityPosts = posts.map((post) => post.toFeedMap()).toList();
    } catch (_) {
      communityPosts = [];
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostsScreen(
          title: community.name,
          posts: communityPosts,
          onPostTap: (post) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissingPostDetailsScreen(post: post),
            ),
          ),
          onAddListingTap: () async {
            if (_currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Log in before creating a listing.'),
                ),
              );
              return;
            }
            final didCreate = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ListingScreen(
                  authorId: _currentUser!.id,
                  communityId: selectedCommunityId,
                ),
              ),
            );
            if (didCreate == true && mounted) {
              Navigator.pop(context);
              await _handleCommunityTap(community);
            }
          },
        ),
      ),
    );
  }

  Future<void> _openCreateCommunityScreen() async {
    if (!mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log in before creating a community.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final createdCommunity = await Navigator.push<Community>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCommunityScreen(authorId: _currentUser!.id),
      ),
    );

    if (!mounted || createdCommunity == null) {
      return;
    }

    setState(() {
      _nearbyCommunities = [
        createdCommunity,
        ..._nearbyCommunities.where((c) => c.id != createdCommunity.id),
      ];
      _selectedCommunityName = createdCommunity.name;
    });

    await _loadCommunityData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppTheme.backgroundDecoration(context),
        child: SafeArea(
          child: switch (_selectedNavIndex) {
            1 => CommunityScreen(
              communities: _nearbyCommunities,
              selectedCommunityName: _selectedCommunityName,
              posts: _visibleCommunityPosts,
              isLoading: _isLoadingCommunityPosts,
              onRefresh: _loadCommunityData,
              onPostTap: (post) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissingPostDetailsScreen(post: post),
                ),
              ),
              onCreateCommunityTap: _openCreateCommunityScreen,
              onCommunityTap: _handleCommunityTap,
            ),
            2 => const ChatScreen(),
            3 => const ProfileScreen(),
            _ => _buildAdoptionView(context),
          },
        ),
      ),
      bottomNavigationBar: buildBottomNav(
        selectedNavIndex: _selectedNavIndex,
        onNavTap: (index) => setState(() => _selectedNavIndex = index),
      ),
    );
  }

  Widget _buildAdoptionView(BuildContext context) {
    final isResultsMode = _searchQuery.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark
        ? const Color(0xFFE5E4E2)
        : AppColors.seaBlue;
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          color: glassColor,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSearch(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              if (!isResultsMode)
                Text(
                  'Browse by pet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                  ),
                ),
              if (isResultsMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Showing results for "${_searchQuery.trim()}"',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: headerTextColor,
                    ),
                  ),
                ),
              if (!isResultsMode) const SizedBox(height: 12),
              if (!isResultsMode)
                buildCategoryRow(
                  selectedCategory: _selectedCategory,
                  onCategoryTap: (category) =>
                      setState(() => _selectedCategory = category),
                ),
              if (!isResultsMode) ...[
                const SizedBox(height: 22),
                Text(
                  'Ideas for you',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: buildPetList(
                  pets: _visiblePets,
                  selectedCategory: isResultsMode ? 'all' : _selectedCategory,
                  searchQuery: _searchQuery,
                  onPetTap: (pet) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetDetailsScreen(pet: pet),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
