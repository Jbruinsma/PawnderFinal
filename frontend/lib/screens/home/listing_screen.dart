import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pawnder_app/models/community.dart';
import 'package:pawnder_app/models/community_post.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/location_service.dart';
import 'package:pawnder_app/services/post_service.dart';
import 'package:pawnder_app/services/upload_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_header.dart';
import 'package:pawnder_app/widgets/image_picker_card.dart';
import 'package:pawnder_app/widgets/input_card.dart';

class ListingScreen extends StatefulWidget {
  final String? authorId;
  final String? communityId;
  final String? initialCommunityId;
  final List<Community> communities;

  const ListingScreen({
    super.key,
    this.authorId,
    this.communityId,
    this.initialCommunityId,
    this.communities = const [],
  });

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _postService = PostService();
  final _apiClient = ApiClient();
  final _locationService = LocationService();
  final _uploadService = UploadService();

  final List<String> _selectedTags = [];
  Uint8List? _imageBytes;
  String? _imageContentType;
  bool _isSubmitting = false;
  String? _selectedCommunityId;

  static const _defaultLatitude = 40.7128;
  static const _defaultLongitude = -74.0060;

  static const List<String> _availableTags = [
    'Rodent',
    'FoundPet',
    'Bird',
    'LostPet',
    'Cat',
    'Brooklyn',
    'Dog',
    'Queens',
  ];

  bool get _shouldShowCommunityPicker =>
      widget.communityId == null && widget.communities.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedCommunityId =
        widget.communityId ??
        widget.initialCommunityId ??
        (widget.communities.isNotEmpty ? widget.communities.first.id : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitListing() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showMessage('Title and description are required.');
      return;
    }

    if (_selectedTags.isEmpty) {
      _showMessage('Choose at least one tag.');
      return;
    }

    final authorId = widget.authorId;
    final communityId = widget.communityId ?? _selectedCommunityId;

    if (authorId == null || communityId == null) {
      _showMessage('Choose a community before posting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    PostLocation location = const PostLocation(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
    );
    try {
      final current = await _locationService.requestAndSaveCurrentLocation();
      if (current != null) {
        location = current;
      }
    } catch (_) {}

    String? imageUrl;
    final bytes = _imageBytes;
    final contentType = _imageContentType;
    if (bytes != null && contentType != null) {
      try {
        imageUrl = await _uploadService.uploadImage(
          bytes: bytes,
          contentType: contentType,
          purpose: UploadPurpose.post,
        );
      } catch (error) {
        if (!mounted) return;
        _showMessage(_apiClient.messageForError(error));
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    try {
      await _postService.createPost(
        CreatePostRequest(
          communityId: communityId,
          authorId: authorId,
          postType: _selectedTags.contains('LostPet') ? 'Lost Pet' : 'Sighting',
          title: title,
          description: description,
          location: location,
          tags: _selectedTags,
          imageUrl: imageUrl,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage('Listing posted.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(_apiClient.messageForError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppTheme.backgroundDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 32,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                const HomeHeader(
                  title: 'CREATE POST',
                  subtitle: 'Share a quick alert with your neighborhood',
                  icon: Icons.add_location_alt_outlined,
                ),
                const SizedBox(height: 28),
                if (_shouldShowCommunityPicker) ...[
                  InputCard(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCommunityId,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : theme.cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Post in community',
                        border: InputBorder.none,
                      ),
                      items: widget.communities
                          .map(
                            (community) => DropdownMenuItem<String>(
                              value: community.id,
                              child: Text(
                                community.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCommunityId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                InputCard(
                  child: TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                InputCard(
                  minHeight: 148,
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 6,
                    minLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add a description',
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Text(
                    'ADD TAGS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _toggleTag(tag),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                ImagePickerCard(
                  bytes: _imageBytes,
                  contentType: _imageContentType,
                  emptyTitle: 'Add post',
                  emptySubtitle: 'Tap to upload a clear pet photo',
                  onPicked: (bytes, contentType) {
                    setState(() {
                      _imageBytes = bytes;
                      _imageContentType = contentType;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitListing,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Upload Post',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}