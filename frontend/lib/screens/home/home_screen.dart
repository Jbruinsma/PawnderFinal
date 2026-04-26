import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/chat_screen.dart';
import 'package:pawnder_app/screens/home/community_screen.dart';
import 'package:pawnder_app/screens/home/create_community_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/unified_post_detail_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/services/feed_service.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/services/message_socket_service.dart';
import 'package:pawnder_app/services/search_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/community_card.dart';
import 'package:pawnder_app/widgets/search_bar.dart';
import 'package:pawnder_app/widgets/search_status.dart';

const List<Map<String, String>> _staticPets = [];
const List<String> _defaultCategories = ['Dogs', 'Cats', 'Birds'];

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
  final _messageService = MessageService();
  final _messageSocketService = MessageSocketService();
  final _searchService = SearchService();
  final _storage = const FlutterSecureStorage();

  late int _selectedNavIndex;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  CurrentUser? _currentUser;
  String? _selectedCommunityName;
  List<Community> _nearbyCommunities = const [];
  Set<String> _joinedCommunityIds = const {};
  bool _isLoadingCommunityPosts = false;
  bool _shouldShowFallbackPets = true;
  int _messageBadgeCount = 0;
  StreamSubscription? _messageSubscription;
  Future<PostLocation?>? _locationFuture;
  List<String> _feedCategories = _defaultCategories;

  Timer? _searchDebounce;
  CancelToken? _searchCancelToken;
  int _searchSeq = 0;
  bool _isSearching = false;
  String? _searchError;
  SearchAllResults _searchResults = SearchAllResults.empty;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  static const _defaultLatitude = 40.7128;
  static const _defaultLongitude = -74.0060;
  static const _coordThreshold = 0.005;

  List<Map<String, String>> _nearbyPets = [];
  List<CommunityPost> _recommendedPosts = const [];

  List<Map<String, String>> get _visiblePets =>
      _shouldShowFallbackPets ? _staticPets : _nearbyPets;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchCancelToken?.cancel('disposed');
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    _searchDebounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _searchCancelToken?.cancel('cleared');
      _searchCancelToken = null;
      setState(() {
        _isSearching = false;
        _searchError = null;
        _searchResults = SearchAllResults.empty;
      });
      return;
    }

    _searchDebounce = Timer(
      _searchDebounceDuration,
      () => _performSearch(trimmed),
    );
  }

  Future<void> _performSearch(String query) async {
    _searchCancelToken?.cancel('superseded');
    final token = CancelToken();
    _searchCancelToken = token;
    final seq = ++_searchSeq;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _searchService.searchAll(
        query: query,
        cancelToken: token,
      );

      if (!mounted || seq != _searchSeq) return;

      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        return;
      }
      if (!mounted || seq != _searchSeq) return;

      setState(() {
        _isSearching = false;
        _searchError = 'Couldn\'t search right now.';
      });
    }
  }

  void _retrySearch() {
    final trimmed = _searchQuery.trim();
    if (trimmed.isEmpty) return;
    _performSearch(trimmed);
  }

  Future<void> _connectMessageSocket() async {
    await _messageSocketService.connect();
    _messageSubscription ??= _messageSocketService.incomingEvents.listen((
      event,
    ) {
      final message = event.message;
      if (!mounted || message == null) {
        return;
      }
      if (event.type == 'message_created' &&
          !message.isMine &&
          _selectedNavIndex != 2) {
        setState(() => _messageBadgeCount += 1);
      }
    });
  }

  Future<void> _initializeHome() async {
    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (_) {
      _currentUser = null;
    }

    if (_selectedNavIndex == 0 && _currentUser != null) {
      final shouldPrompt = await _locationService
          .shouldPromptForFirstHomeLaunch(userId: _currentUser!.id);
      if (shouldPrompt) {
        _locationFuture = _requestLocationAsSoonAsPossible(
          userId: _currentUser!.id,
        );
      } else {
        _locationFuture = _locationService.requestAndSaveCurrentLocation();
      }
    }

    _loadCommunityData();
    _refreshMessageBadge();
    _connectMessageSocket();
  }

  Future<void> _refreshMessageBadge() async {
    try {
      final threads = await _messageService.getThreads();
      if (!mounted) {
        return;
      }
      setState(() {
        _messageBadgeCount = threads.fold<int>(
          0,
          (sum, thread) => sum + thread.unreadCount,
        );
      });
    } catch (_) {}
  }

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
      if (index == 2) {
        _messageBadgeCount = 0;
      }
    });

    if (index == 0 && _locationFuture == null) {
      final currentUser = _currentUser;
      if (currentUser != null) {
        _locationFuture = _requestLocationAsSoonAsPossible(
          userId: currentUser.id,
        );
      }
      _loadCommunityData();
    }

    if (index != 2) {
      _refreshMessageBadge();
    }
  }

  Future<PostLocation?> _requestLocationAsSoonAsPossible({
    required String userId,
  }) async {
    try {
      final location = await _locationService.requestAndSaveCurrentLocation();
      await _locationService.markHomeLocationPromptSeen(userId: userId);
      return location;
    } catch (_) {
      return null;
    }
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
      final cachedLatStr = await _storage.read(key: 'last_known_lat');
      final cachedLonStr = await _storage.read(key: 'last_known_lon');
      if (cachedLatStr != null && cachedLonStr != null) {
        lat = double.tryParse(cachedLatStr) ?? lat;
        lon = double.tryParse(cachedLonStr) ?? lon;
      }
    } catch (_) {}

    await _fetchFeedData(lat, lon, isSilentUpdate: false);

    if (_locationFuture != null) {
      _locationFuture!
          .then((actualLocation) async {
            if (actualLocation != null && mounted) {
              final latDiff = (actualLocation.latitude - lat).abs();
              final lonDiff = (actualLocation.longitude - lon).abs();

              await _storage.write(
                key: 'last_known_lat',
                value: actualLocation.latitude.toString(),
              );
              await _storage.write(
                key: 'last_known_lon',
                value: actualLocation.longitude.toString(),
              );

              if (latDiff > _coordThreshold || lonDiff > _coordThreshold) {
                await _fetchFeedData(
                  actualLocation.latitude,
                  actualLocation.longitude,
                  isSilentUpdate: true,
                );
              }
            }
          })
          .catchError((_) {});
    }
  }

  Future<void> _fetchFeedData(
    double lat,
    double lon, {
    required bool isSilentUpdate,
  }) async {
    if (_currentUser == null) {
      try {
        _currentUser = await _authService.getCurrentUser();
      } catch (_) {
        _currentUser = null;
      }
    }

    List<Community> nearbyCommunities = const [];
    List<Community> savedCommunities = const [];
    List<CommunityPost> posts = const [];
    List<String> tags = _defaultCategories;

    try {
      nearbyCommunities = await _communityService.getNeighborhoods(
        latitude: lat,
        longitude: lon,
      );
    } catch (_) {}

    if (_currentUser != null) {
      try {
        savedCommunities = await _communityService.getMyNeighborhoods();
      } catch (_) {}
    }

    try {
      final feedData = await _feedService.getNewFeed(
        latitude: lat,
        longitude: lon,
      );
      posts = feedData['posts'] as List<CommunityPost>;
      final apiTags = feedData['applicable_tags'] as List<String>;
      if (apiTags.isNotEmpty) {
        tags = apiTags;
      }
    } catch (_) {
      if (mounted && !isSilentUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Communities loaded. Showing sample posts while the backend feed catches up.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    Community? selectedCommunity;
    if (_selectedCommunityName != null) {
      for (final community in nearbyCommunities) {
        if (community.name == _selectedCommunityName) {
          selectedCommunity = community;
          break;
        }
      }
    }
    final defaultCommunity =
        selectedCommunity ??
        (nearbyCommunities.isEmpty ? null : nearbyCommunities.first);

    if (mounted) {
      setState(() {
        _nearbyCommunities = nearbyCommunities;
        _joinedCommunityIds = savedCommunities
            .map((community) => community.id)
            .toSet();
        _selectedCommunityName = defaultCommunity?.name;
        _recommendedPosts = posts;
        _nearbyPets = posts.map((post) => post.toPetMap()).toList();
        _shouldShowFallbackPets = _nearbyPets.isEmpty;
        _feedCategories = tags;
        if (!isSilentUpdate) {
          _isLoadingCommunityPosts = false;
        }
      });
    }
  }

  Future<void> _handleCommunityTap(Community community) async {
    final selectedCommunityId = community.id;
    if (!mounted) return;

    setState(() => _selectedCommunityName = community.name);

    final communityPosts = await _getCommunityFeedPosts(
      communityId: selectedCommunityId,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostsScreen(
          community: community,
          posts: communityPosts,
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
                  communities: _nearbyCommunities,
                  initialCommunityId: community.id,
                ),
              ),
            );

            if (didCreate != true || !mounted) {
              return;
            }

            Navigator.pop(context);
            await _handleCommunityTap(community);
          },
        ),
      ),
    );
  }

  Future<List<CommunityPost>> _getCommunityFeedPosts({
    required String communityId,
  }) async {
    try {
      return await _postService.getCommunityPosts(
        communityId: communityId,
        limit: 50,
      );
    } catch (_) {
      return [];
    }
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
      _joinedCommunityIds = {..._joinedCommunityIds, createdCommunity.id};
      _selectedCommunityName = createdCommunity.name;
    });

    await _loadCommunityData();
  }

  Future<void> _openCreatePostScreen() async {
    if (!mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log in before creating a post.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_nearbyCommunities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No communities are available yet. Create one first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? initialCommunityId;
    final selectedCommunityName = _selectedCommunityName;
    if (selectedCommunityName != null) {
      for (final community in _nearbyCommunities) {
        if (community.name == selectedCommunityName) {
          initialCommunityId = community.id;
          break;
        }
      }
    }

    final didCreate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListingScreen(
          authorId: _currentUser!.id,
          communities: _nearbyCommunities,
          initialCommunityId: initialCommunityId,
        ),
      ),
    );

    if (didCreate != true || !mounted) {
      return;
    }

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
              isLoading: _isLoadingCommunityPosts,
              onCreateCommunityTap: _openCreateCommunityScreen,
              onCreatePostTap: _openCreatePostScreen,
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
        messageBadgeCount: _messageBadgeCount,
        onNavTap: _handleNavTap,
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

    final filteredPosts = _selectedCategory == 'all'
        ? _recommendedPosts
        : _recommendedPosts.where((post) {
            return post.tags.any(
              (tag) => tag.toLowerCase() == _selectedCategory.toLowerCase(),
            );
          }).toList();

    final recommendedPostMaps = filteredPosts
        .map((post) => post.toFeedMap())
        .toList();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          color: glassColor,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: Text(
                    'P A W N D E R',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: headerTextColor,
                    ),
                  ),
                ),
              ),
              GlassmorphicSearchBar(
                onChanged: _onSearchChanged,
                isLoading: _isSearching,
                hintText: 'Search for...',
              ),
              const SizedBox(height: 16),
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
                )
              else ...[
                Text(
                  'Filter By Tags...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                buildCategoryRow(
                  categories: _feedCategories,
                  selectedCategory: _selectedCategory,
                  onCategoryTap: (category) =>
                      setState(() => _selectedCategory = category),
                ),
                const SizedBox(height: 22),
                Text(
                  recommendedPostMaps.isEmpty ? 'Ideas for you' : 'What\'s New',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: isResultsMode
                    ? _buildSearchResultsView(headerTextColor)
                    : (recommendedPostMaps.isNotEmpty
                          ? buildCommunityPostsFeed(
                              posts: recommendedPostMaps,
                              searchQuery: _searchQuery,
                              currentUserId: _currentUser?.id,
                              onPostTap: (postMap) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UnifiedPostDetailScreen(post: postMap),
                                  ),
                                );
                              },
                              onCommentTap: (postMap) async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UnifiedPostDetailScreen(post: postMap),
                                  ),
                                );
                              },
                            )
                          : buildPetList(
                              pets: _visiblePets,
                              selectedCategory: _selectedCategory,
                              searchQuery: _searchQuery,
                              onPetTap: (pet) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UnifiedPostDetailScreen(post: pet),
                                ),
                              ),
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(Color headerTextColor) {
    if (_isSearching && _searchResults.isEmpty) {
      return SearchStatus.loading();
    }

    if (_searchError != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: SearchStatus(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn\'t search right now',
          subtitle: 'Check your connection and try again.',
          onRetry: _retrySearch,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: SearchStatus(
          icon: Icons.search_off_rounded,
          title: 'No results for "${_searchQuery.trim()}"',
          subtitle: 'Try a different keyword, name, or location.',
        ),
      );
    }

    final theme = Theme.of(context);
    final communities = _searchResults.communities;
    final posts = _searchResults.posts;
    final postMaps = posts.map((post) => post.toFeedMap()).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 92),
      children: [
        if (communities.isNotEmpty) ...[
          _buildSectionHeader(
            label: 'Communities',
            count: communities.length,
            color: headerTextColor,
          ),
          const SizedBox(height: 12),
          ...communities.expand(
            (community) => [
              CommunityCard(
                community: community,
                isSelected: community.name == _selectedCommunityName,
                onTap: () => _handleCommunityTap(community),
              ),
              const SizedBox(height: 12),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (postMaps.isNotEmpty) ...[
          _buildSectionHeader(
            label: 'Posts',
            count: postMaps.length,
            color: headerTextColor,
          ),
          const SizedBox(height: 12),
          ...postMaps.expand((post) {
            final isAuthor =
                _currentUser != null && post['authorId'] == _currentUser!.id;
            return [
              _SearchPostCard(
                post: post,
                isAuthor: isAuthor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnifiedPostDetailScreen(post: post),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
            ];
          }),
        ],
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPostCard extends StatelessWidget {
  final Map<String, String> post;
  final bool isAuthor;
  final VoidCallback onTap;

  const _SearchPostCard({
    required this.post,
    required this.isAuthor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();
    final section = post['section'] ?? 'recent';
    final isFound = section == 'found';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isFound ? Icons.pets_rounded : Icons.location_searching_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isFound
                                  ? Colors.green.withValues(alpha: 0.18)
                                  : Colors.orange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isFound ? 'Found' : 'Lost',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isFound
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                          if (isAuthor) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      if ((post['description'] ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          post['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags
                              .take(3)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}