import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerCard extends StatefulWidget {
  const ImagePickerCard({
    super.key,
    required this.bytes,
    required this.contentType,
    required this.onPicked,
    this.emptyTitle = 'Add photo',
    this.emptySubtitle = 'Tap to upload an image',
    this.previewHeight = 210,
    this.imageQuality = 88,
  });

  final Uint8List? bytes;
  final String? contentType;
  final void Function(Uint8List bytes, String contentType) onPicked;
  final String emptyTitle;
  final String emptySubtitle;
  final double previewHeight;
  final int imageQuality;

  @override
  State<ImagePickerCard> createState() => _ImagePickerCardState();
}

class _ImagePickerCardState extends State<ImagePickerCard> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pick() async {
    if (_isPicking) {
      return;
    }
    setState(() => _isPicking = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: widget.imageQuality,
      );
      if (!mounted || picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final contentType = _resolveContentType(picked);

      widget.onPicked(bytes, contentType);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open your photo library right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  String _resolveContentType(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.isNotEmpty) {
      return mime.toLowerCase();
    }

    final lowerName = file.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = widget.bytes != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: _pick,
          child: Container(
            height: widget.previewHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? _buildPreview(theme, isDark)
                : _buildEmpty(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 72,
          color: theme.colorScheme.onSurface,
        ),
        const SizedBox(height: 12),
        Text(
          widget.emptyTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.emptySubtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(widget.bytes!, fit: BoxFit.cover),
        Positioned(
          right: 12,
          top: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Change photo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF24313E),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isPicking)
          Container(
            color: Colors.black.withValues(alpha: 0.25),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      ],
    );
  }
}
