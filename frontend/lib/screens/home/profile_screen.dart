import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawnder_app/models/current_user.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final ImagePicker _profileImagePicker = ImagePicker();
  CurrentUser? _currentUser;
  XFile? _selectedProfilePhoto;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _authService.messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final image = await _profileImagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (!mounted || image == null) {
        return;
      }

      setState(() {
        _selectedProfilePhoto = image;
      });
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
    }
  }

  void _removeProfilePhoto() {
    setState(() {
      _selectedProfilePhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _currentUser;
    final displayName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName
        : 'Account';
    final joinedLabel = user == null
        ? ''
        : 'Joined ${user.createdAt.month}/${user.createdAt.day}/${user.createdAt.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HomeHeader(
            title: 'Account Center',
            subtitle: 'Profile, listings, and contact details',
            icon: Icons.account_circle_outlined,
          ),
          const SizedBox(height: 18),
          Container(height: 2, color: theme.dividerColor),
          if (_isLoading) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _ProfileNotice(message: _errorMessage!, onRetry: _loadCurrentUser),
          ],
          const SizedBox(height: 16),
          _ThemeToggleTile(isDark: isDark),
          const SizedBox(height: 28),
          _ProfilePhotoButton(
            selectedPhoto: _selectedProfilePhoto,
            onPressed: _pickProfilePhoto,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickProfilePhoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text(
              _selectedProfilePhoto == null ? 'Choose photo' : 'Change photo',
            ),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkText
                  : theme.colorScheme.onSurface,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_selectedProfilePhoto != null)
            TextButton.icon(
              onPressed: _removeProfilePhoto,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Remove photo'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkMuted
                    : theme.colorScheme.onSurfaceVariant,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayName.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 6),
            Text(
              user.role,
              style: TextStyle(
                color: isDark ? AppColors.darkMuted : const Color(0xFF27313A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              joinedLabel,
              style: TextStyle(
                color: isDark ? AppColors.darkMuted : AppColors.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const _MenuTile(label: 'MY LISTINGS'),
          const SizedBox(height: 10),
          const _MenuTile(label: 'BOOKMARKS'),
          const SizedBox(height: 10),
          _MenuTile(label: user?.email ?? 'CONTACT\nINFORMATION'),
        ],
      ),
    );
  }
}

class _ProfileNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProfilePhotoButton extends StatelessWidget {
  final XFile? selectedPhoto;
  final VoidCallback onPressed;

  const _ProfilePhotoButton({
    required this.selectedPhoto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Choose profile photo',
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor, width: 2),
              ),
              child: ClipOval(
                child: selectedPhoto == null
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 44,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : Image.file(
                        File(selectedPhoto!.path),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: theme.colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;

  const _MenuTile({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;

  const _ThemeToggleTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark mode',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isDark ? 'Deep night theme enabled' : 'Soft daylight theme',
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.bodyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            activeThumbColor: theme.colorScheme.primary,
            onChanged: AppThemeController.setDarkMode,
          ),
        ],
      ),
    );
  }
}
