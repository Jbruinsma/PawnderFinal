import 'dart:ui';
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
import 'package:pawnder_app/screens/home/missing_post_details_screen.dart';
import 'package:pawnder_app/screens/home/profile_screen.dart';
import 'package:pawnder_app/screens/home/unified_post_detail_screen.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/community_service.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/services/feed_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/build_category_row.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/build_pet_list.dart';
import 'package:pawnder_app/widgets/build_search.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/services/message_socket_service.dart';
import 'dart:async';

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
    super.dispose();
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

  Future<bool> _confirmJoinCommunity(Community community) async {
    final theme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Icon(Icons.groups_2_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Join community?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Text(
              'Would you like to join ${community.name} before opening it? You will start seeing its activity as one of your communities.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Join'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleCommunityTap(Community community) async {
    final selectedCommunityId = community.id;
    if (!mounted) return;

    if (_currentUser != null) {
      final isAlreadyJoined = _joinedCommunityIds.contains(selectedCommunityId);

      if (!isAlreadyJoined) {
        final shouldJoin = await _confirmJoinCommunity(community);
        if (!shouldJoin || !mounted) {
          return;
        }

        try {
          await _communityService.joinNeighborhood(
            communityId: selectedCommunityId,
          );
          if (mounted) {
            setState(() {
              _joinedCommunityIds = {
                ..._joinedCommunityIds,
                selectedCommunityId,
              };
            });
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not join this community right now.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        setState(() => _selectedCommunityName = community.name);
      }
    } else if (mounted) {
      setState(() => _selectedCommunityName = community.name);
    }

    if (!mounted) return;

    final communityPosts = await _getCommunityFeedPosts(
      communityId: selectedCommunityId,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostsScreen(
          title: community.name,
          posts: communityPosts,
          communityId: selectedCommunityId,
          onPostTap: (post) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissingPostDetailsScreen(post: post.toFeedMap()),
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
                  communityId: community.id,
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
              buildSearch(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              if (!isResultsMode)
                Text(
                  'Filter By Tags...',
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
              if (!isResultsMode) ...[
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
                child: recommendedPostMaps.isNotEmpty
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
                        selectedCategory: isResultsMode
                            ? 'all'
                            : _selectedCategory,
                        searchQuery: _searchQuery,
                        onPetTap: (pet) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UnifiedPostDetailScreen(post: pet),
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
