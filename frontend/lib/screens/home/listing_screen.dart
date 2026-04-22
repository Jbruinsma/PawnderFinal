import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/services/api_service.dart';

class ListingScreen extends StatefulWidget {
  const ListingScreen({super.key});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  final List<String> _selectedTags = ['FoundPet', 'Queens'];
  XFile? _selectedImage;

  static const List<String> _availableTags = [
    'Rodent', 'FoundPet', 'Bird', 'LostPet', 'Cat', 'Brooklyn', 'Dog', 'Queens',
  ];

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

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meResponse = await ApiService.get('/auth/me');
      final authorId = meResponse.data['id']?.toString() ?? '';

      await ApiService.post('/community/posts', {
        'author_id': authorId,
        'community_id': 'cffd8c3f-40ee-47b7-84fc-b8bbe343887f',
        'post_type': _selectedTags.contains('LostPet') ? 'Lost Pet' : 'Sighting',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': {'latitude': 40.7128, 'longitude': -74.0060},
        'tags': _selectedTags,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickListingPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || image == null) return;
      setState(() => _selectedImage = image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your photo library right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 32, color: Color(0xFF27313C)),
              ),
              const SizedBox(height: 18),
              const Text(
                'CREATE LISTING',
                style: TextStyle(
                  fontSize: 42, height: 0.95, fontWeight: FontWeight.w900,
                  letterSpacing: -1.2, color: AppColors.seaBlue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Share a quick alert with your neighborhood.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.bodyText),
              ),
              const SizedBox(height: 28),
              _InputCard(
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF26313B)),
                ),
              ),
              const SizedBox(height: 18),
              _InputCard(
                minHeight: 148,
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 6, minLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add a description', border: InputBorder.none),
                  style: const TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xFF26313B)),
                ),
              ),
              const SizedBox(height: 26),
              const Center(
                child: Text(
                  'ADD TAGS',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.7, color: Color(0xFF111111)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, runSpacing: 10,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _toggleTag(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.seaBlue : const Color(0xFFF8FCFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? AppColors.seaBlue : const Color(0xFFB9D7DE)),
                        boxShadow: isSelected
                            ? const [BoxShadow(color: Color(0x22188393), blurRadius: 12, offset: Offset(0, 6))]
                            : null,
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF246979),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: _pickListingPhoto,
                      child: Container(
                        height: 210, width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FAFD),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFCFE3EA)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 72, color: AppColors.seaBlue),
                                  SizedBox(height: 12),
                                  Text('Add listing photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF24313E))),
                                  SizedBox(height: 6),
                                  Text('Tap to upload a clear pet photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.bodyText)),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                                  Positioned(
                                    right: 12, top: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: const Color(0xCCFFFFFF), borderRadius: BorderRadius.circular(999)),
                                      child: const Text('Change photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF24313E))),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.seaBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _isLoading ? null : _submitListing,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Post Listing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  final double minHeight;

  const _InputCard({required this.child, this.minHeight = 74});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}