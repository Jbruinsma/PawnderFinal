import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/screens/home/chat_screen.dart';
import 'package:pawnder_app/screens/home/community_posts_screen.dart';
import 'package:pawnder_app/screens/home/community_screen.dart';
import 'package:pawnder_app/screens/home/create_community_screen.dart';
import 'package:pawnder_app/screens/home/listing_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/search_results.dart';
import 'package:pawnder_app/screens/home/unified_post_detail_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/feed_service.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/services/message_socket_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/location_lock_overlay.dart';
import 'package:pawnder_app/widgets/search_bar.dart';

const List<String> _defaultCategories = ['Dogs', 'Cats', 'Birds'];
const List<Map<String, String>> _staticPets = [];

class HomeScreen extends StatefulWidget {
  final int initialNavIndex;

  const HomeScreen({super.key, this.initialNavIndex = 0});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _communityService = CommunityService();
  final _feedService = FeedService();
  final _locationService = LocationService();
  final _messageService = MessageService();
  final _messageSocketService = MessageSocketService();
  final _postService = PostService();
  final _storage = const FlutterSecureStorage();

  static const _coordThreshold = 0.005;
  static const _defaultLatitude = 40.7128;
  static const _defaultLongitude = -74.0060;

  CurrentUser? _currentUser;
  List<String> _feedCategories = _defaultCategories;
  bool _isFetchingFeed = true;
  bool _isLoadingCommunityPosts = false;
  bool _isLocationBlocked = false;
  Set<String> _joinedCommunityIds = const {};
  Future<PostLocation?>? _locationFuture;
  int _messageBadgeCount = 0;
  StreamSubscription? _messageSubscription;
  List<Community> _nearbyCommunities = const [];
  List<Map<String, String>> _nearbyPets = [];

  List<CommunityPost> _lostPosts = const [];
  List<CommunityPost> _foundPosts = const [];
  List<CommunityPost> _miscPosts = const [];

  String _selectedCategory = 'all';
  String? _selectedCommunityName;
  late int _selectedNavIndex;
  bool _shouldShowFallbackPets = true;

  List<Map<String, String>> get _visiblePets =>
      _shouldShowFallbackPets ? _staticPets : _nearbyPets;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLocationBlocked) {
      _checkLocationStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedNavIndex = widget.initialNavIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  Future<void> _checkLocationStatus() async {
    final status = await _locationService.checkPermissionStatus();
    if (mounted) {
      setState(() {
        _isLocationBlocked = status == LocationPermission.denied ||
                             status == LocationPermission.deniedForever;
      });
    }
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

  Future<void> _fetchNeighborhoods(double lat, double lon) async {
    List<Community> nearbyCommunities = const [];
    List<Community> savedCommunities = const [];

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
        _joinedCommunityIds = savedCommunities
            .map((community) => community.id)
            .toSet();
        _nearbyCommunities = nearbyCommunities;
        _selectedCommunityName = defaultCommunity?.name;
        _isLoadingCommunityPosts = false;
      });
    }
  }

  Future<void> _fetchFeedData(
    double lat,
    double lon, {
    required bool isSilentUpdate,
  }) async {
    if (!isSilentUpdate && mounted) {
      setState(() => _isFetchingFeed = true);
    }

    _currentUser ??= await _authService.getCurrentUser();

    List<CommunityPost> lost = const [];
    List<CommunityPost> found = const [];
    List<CommunityPost> misc = const [];
    List<String> tags = _defaultCategories;

    try {
      final feedData = await _feedService.getNewFeed(
        latitude: lat,
        longitude: lon,
      );

      final postsMap = feedData['posts'] as Map<String, dynamic>? ?? const {};
      lost = (postsMap['lost'] as List?)?.cast<CommunityPost>() ?? const [];
      found = (postsMap['found'] as List?)?.cast<CommunityPost>() ?? const [];
      misc = (postsMap['misc'] as List?)?.cast<CommunityPost>() ?? const [];

      final apiTags = feedData['applicable_tags'] as List<String>;
      if (apiTags.isNotEmpty) {
        tags = apiTags;
      }
    } catch (_) {
      if (mounted && !isSilentUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Showing sample posts while the backend feed catches up.',
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _feedCategories = tags;
        _isFetchingFeed = false;
        _lostPosts = lost;
        _foundPosts = found;
        _miscPosts = misc;
        _nearbyPets = [...lost, ...found, ...misc].map((post) => post.toPetMap()).toList();
        _shouldShowFallbackPets = _nearbyPets.isEmpty;
        if (!isSilentUpdate) {
          _isLoadingCommunityPosts = false;
        }
      });
    }
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
          posts: communityPosts,
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    if (_isLocationBlocked) return;

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
    } else if (index == 1 && _nearbyCommunities.isEmpty) {
      _loadCommunityData();
    }

    if (index != 2) {
      _refreshMessageBadge();
    }
  }

  Future<void> _handlePostUpdate(Map<String, String>? updatedPost) async {
    if (updatedPost == null || !mounted) return;

    setState(() {
      final postId = updatedPost['id'];

      void updateInList(List<CommunityPost> list) {
        final recIndex = list.indexWhere((p) => p.id == postId);
        if (recIndex != -1) {
          list[recIndex] = list[recIndex].copyWith(
            title: updatedPost['title'],
            description: updatedPost['description'],
            postType: updatedPost['postType'],
            imageUrl: updatedPost['image'],
            tags: updatedPost['tags']?.split('|').where((t) => t.isNotEmpty).toList(),
            commentCount: int.tryParse(updatedPost['commentCount'] ?? '0') ?? 0,
            likeCount: int.tryParse(updatedPost['likeCount'] ?? '0') ?? 0,
            youLiked: updatedPost['youLiked'] == 'true',
            edited: updatedPost['edited'] == 'true',
          );
        }
      }

      updateInList(_lostPosts);
      updateInList(_foundPosts);
      updateInList(_miscPosts);

      _nearbyPets = [..._lostPosts, ..._foundPosts, ..._miscPosts]
          .map((post) => post.toPetMap())
          .toList();
    });
  }

  Future<void> _initializeHome() async {
    await _checkLocationStatus();

    if (_isLocationBlocked) {
      return;
    }

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

  Future<void> _loadCommunityData() async {
    setState(() {
      if (_selectedNavIndex == 0) _isFetchingFeed = true;
      if (_selectedNavIndex == 1) _isLoadingCommunityPosts = true;
    });

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

    if (_selectedNavIndex == 1) {
      await _fetchNeighborhoods(lat, lon);
    } else {
      await _fetchFeedData(lat, lon, isSilentUpdate: false);
    }

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
                if (_selectedNavIndex == 1) {
                  await _fetchNeighborhoods(actualLocation.latitude, actualLocation.longitude);
                } else {
                  await _fetchFeedData(
                    actualLocation.latitude,
                    actualLocation.longitude,
                    isSilentUpdate: true,
                  );
                }
              }
            }
          })
          .catchError((_) {});
    }
  }

  Future<void> _openCreateCommunityScreen() async {
    if (!mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Log in before creating a community.'),
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
      _joinedCommunityIds = {..._joinedCommunityIds, createdCommunity.id};
      _nearbyCommunities = [
        createdCommunity,
        ..._nearbyCommunities.where((c) => c.id != createdCommunity.id),
      ];
      _selectedCommunityName = createdCommunity.name;
    });

    await _loadCommunityData();
  }

  Future<void> _openCreatePostScreen() async {
    if (!mounted) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Log in before creating a post.'),
        ),
      );
      return;
    }

    if (_nearbyCommunities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No communities are available yet. Create one first.'),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          bottomNavigationBar: buildBottomNav(
            messageBadgeCount: _messageBadgeCount,
            onNavTap: _handleNavTap,
            selectedNavIndex: _selectedNavIndex,
          ),
          body: Container(
            decoration: AppTheme.backgroundDecoration(context),
            child: SafeArea(
              child: switch (_selectedNavIndex) {
                1 => CommunityScreen(
                  communities: _nearbyCommunities,
                  isLoading: _isLoadingCommunityPosts,
                  onCommunityTap: _handleCommunityTap,
                  onCreateCommunityTap: _openCreateCommunityScreen,
                  onCreatePostTap: _openCreatePostScreen,
                  onRefresh: _loadCommunityData,
                  selectedCommunityName: _selectedCommunityName,
                ),
                2 => const ChatScreen(),
                3 => const ProfileScreen(),
                _ => _buildAdoptionView(context),
              },
            ),
          ),
          extendBodyBehindAppBar: true,
        ),
        if (_isLocationBlocked)
          LocationLockOverlay(
            onOpenSettings: () async {
              await _locationService.openDeviceSettings();
            },
          ),
      ],
    );
  }

  Widget _buildAdoptionView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark
        ? const Color(0xFFE5E4E2)
        : AppColors.seaBlue;
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    List<CommunityPost> filterPosts(List<CommunityPost> posts) {
      if (_selectedCategory == 'all') return posts;
      return posts.where((post) {
        return post.tags.any(
          (tag) => tag.toLowerCase() == _selectedCategory.toLowerCase(),
        );
      }).toList();
    }

    final filteredLost = filterPosts(_lostPosts).map((p) => p.toFeedMap()).toList();
    final filteredFound = filterPosts(_foundPosts).map((p) => p.toFeedMap()).toList();
    final filteredMisc = filterPosts(_miscPosts).map((p) => p.toFeedMap()).toList();

    final hasAnyPosts = filteredLost.isNotEmpty || filteredFound.isNotEmpty || filteredMisc.isNotEmpty;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          color: glassColor,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Text(
                    'P A W N D E R',
                    style: TextStyle(
                      color: headerTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
              GlassmorphicSearchBar(
                hintText: 'Search for...',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsPage(
                        currentUserId: _currentUser?.id,
                      ),
                    ),
                  );
                  _loadCommunityData();
                },
                readOnly: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Filter By Tags...',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              buildCategoryRow(
                categories: _feedCategories,
                onCategoryTap: (category) =>
                    setState(() => _selectedCategory = category),
                selectedCategory: _selectedCategory,
              ),
              const SizedBox(height: 22),
              Text(
                !hasAnyPosts ? 'Ideas for you' : 'What\'s New',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  color: theme.colorScheme.primary,
                  onRefresh: _loadCommunityData,
                  child: _isFetchingFeed
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 3,
                          ),
                        )
                      : (!hasAnyPosts
                          ? buildPetList(
                              onPetTap: (pet) async {
                                final result = await Navigator.push<Map<String, String>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UnifiedPostDetailScreen(post: pet),
                                  ),
                                );
                                _handlePostUpdate(result);
                              },
                              pets: _visiblePets,
                              searchQuery: '',
                              selectedCategory: _selectedCategory,
                            )
                          : CustomScrollView(
                              slivers: [
                                if (filteredLost.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _HorizontalCarousel(
                                      title: 'Lost Pets',
                                      posts: filteredLost,
                                      tintColor: Colors.redAccent.withValues(alpha: 0.12),
                                      onPostTap: (postMap) async {
                                        final result = await Navigator.push<Map<String, String>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UnifiedPostDetailScreen(post: postMap),
                                          ),
                                        );
                                        _handlePostUpdate(result);
                                      },
                                    ),
                                  ),
                                if (filteredFound.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _HorizontalCarousel(
                                      title: 'Found Pets',
                                      posts: filteredFound,
                                      tintColor: Colors.green.withValues(alpha: 0.12),
                                      onPostTap: (postMap) async {
                                        final result = await Navigator.push<Map<String, String>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UnifiedPostDetailScreen(post: postMap),
                                          ),
                                        );
                                        _handlePostUpdate(result);
                                      },
                                    ),
                                  ),
                                if (filteredLost.isNotEmpty || filteredFound.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                                      child: Text(
                                        'Community Feed',
                                        style: TextStyle(
                                          color: headerTextColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (filteredMisc.isNotEmpty)
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: buildCommunityPostsFeed(
                                      currentUserId: _currentUser?.id,
                                      onCommentTap: (postMap) async {
                                        final result = await Navigator.push<Map<String, String>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UnifiedPostDetailScreen(post: postMap),
                                          ),
                                        );
                                        _handlePostUpdate(result);
                                      },
                                      onPostTap: (postMap) async {
                                        final result = await Navigator.push<Map<String, String>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UnifiedPostDetailScreen(post: postMap),
                                          ),
                                        );
                                        _handlePostUpdate(result);
                                      },
                                      posts: filteredMisc,
                                      searchQuery: '',
                                    ),
                                  ),
                              ],
                            )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalCarousel extends StatefulWidget {
  final String title;
  final List<Map<String, String>> posts;
  final Color tintColor;
  final ValueChanged<Map<String, String>> onPostTap;

  const _HorizontalCarousel({
    required this.title,
    required this.posts,
    required this.tintColor,
    required this.onPostTap,
  });

  @override
  State<_HorizontalCarousel> createState() => _HorizontalCarouselState();
}

class _HorizontalCarouselState extends State<_HorizontalCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark ? const Color(0xFFE5E4E2) : AppColors.seaBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: Text(
            widget.title,
            style: TextStyle(
              color: headerTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.04)).clamp(0.92, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _buildCard(widget.posts[index], theme, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, String> post, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => widget.onPostTap(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: widget.tintColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['title'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                post['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Posted ${post['posted'] ?? 'Recently'}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}