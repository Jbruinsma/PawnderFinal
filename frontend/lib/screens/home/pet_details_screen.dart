import 'package:flutter/material.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

class PetDetailsScreen extends StatefulWidget {
  final Map<String, String> pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  static final MessageService _messageService = MessageService();

  Map<String, String> get pet => widget.pet;

  Future<void> _openConversation(BuildContext context) async {
    final participantId = pet['authorId'];
    if (participantId == null || participantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This listing does not have a valid message recipient.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final thread = _messageService.buildDirectThread(
      participantId: participantId,
      participantName: pet['ownerName'] ?? 'Pet owner',
      title: '${pet['name'] ?? 'Pet'} adoption chat',
      subtitle: pet['ownerMeta'] ?? 'Pet owner',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessageThreadScreen(thread: thread)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'pet-${pet['name'] ?? 'unknown'}';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = theme.brightness == Brightness.dark;
          final topInset = MediaQuery.paddingOf(context).top;
          final imageHeight = (constraints.maxHeight * 0.48)
              .clamp(390.0, 520.0)
              .ceilToDouble();
          final sheetOverlap = isDark ? 8.0 : 2.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: -topInset,
                right: 0,
                height: imageHeight + topInset + 2,
                child: ColoredBox(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.inputSurface,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: _DetailHeroImage(
                          image: pet['image'],
                          seed: pet['id'] ?? pet['name'] ?? '',
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.26),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.16),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                          child: Row(
                            children: [
                              _GlassIcon(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: imageHeight - sheetOverlap,
                right: 0,
                bottom: 0,
                child: _PetInfoSheet(
                  pet: pet,
                  scrollController: ScrollController(),
                  onMessageTap: () => _openConversation(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailHeroImage extends StatelessWidget {
  final String? image;
  final String seed;

  const _DetailHeroImage({required this.image, required this.seed});

  static const _assetPaths = [
    'assets/images/mock_animals/golden_retriever.png',
    'assets/images/mock_animals/tabby_cat.png',
    'assets/images/mock_animals/small_brown_dog.png',
    'assets/images/mock_animals/parrot.png',
    'assets/images/mock_animals/calico_cat.png',
    'assets/images/mock_animals/dalmatian.png',
    'assets/images/mock_animals/cockatiel.png',
    'assets/images/mock_animals/hedgehog.png',
    'assets/images/mock_animals/siamese_kitten.png',
  ];

  static const _knownIndexes = {
    'golden': 0,
    'retriever': 0,
    'tabby': 1,
    'brown-dog': 2,
    'small-brown': 2,
    'parrot': 3,
    'georgie': 4,
    'calico': 4,
    'cat': 1,
    'scooba': 5,
    'dalmatian': 5,
    'dog': 2,
    'cockatiel': 6,
    'bird': 6,
    'hedgehog': 7,
    'pearline': 8,
    'siamese': 8,
  };

  String get _source {
    final value = image?.trim() ?? '';
    if (!value.startsWith('mock://')) {
      return value;
    }

    final lowerSeed = value.toLowerCase();
    for (final entry in _knownIndexes.entries) {
      if (lowerSeed.contains(entry.key)) {
        return _assetPaths[entry.value];
      }
    }

    final index =
        lowerSeed.codeUnits.fold<int>(0, (sum, code) => sum + code) %
        _assetPaths.length;
    return _assetPaths[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final source = _source;

    Widget frame(Widget child) {
      return ColoredBox(
        color: isDark ? AppColors.darkBackground : AppColors.inputSurface,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: child),
              if (isDark)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return frame(
        Image.network(
          source,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
      );
    }

    if (source.isNotEmpty) {
      return frame(
        Image.asset(
          source,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
      );
    }

    return frame(const SizedBox.expand());
  }
}

class _PetInfoSheet extends StatelessWidget {
  final Map<String, String> pet;
  final ScrollController scrollController;
  final VoidCallback onMessageTap;

  const _PetInfoSheet({
    required this.pet,
    required this.scrollController,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = _statusLabelFor(pet);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              children: [
                _ContactRow(pet: pet),
                const SizedBox(height: 18),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  pet['name'] ?? 'Unnamed',
                  style: TextStyle(
                    fontSize: 31,
                    height: 1.13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(label: pet['breed'] ?? 'Dalmatian'),
                    _InfoPill(label: pet['age'] ?? '2 years'),
                    _InfoPill(label: pet['weight'] ?? '65 lbs'),
                  ],
                ),
                const SizedBox(height: 18),
                _LocationBar(
                  location: pet['location'] ?? 'Washington Heights, New York',
                ),
                const SizedBox(height: 18),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pet['about'] ??
                      'Friendly, playful, and loves long neighborhood walks.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkElevated
                          : theme.colorScheme.primary,
                      foregroundColor: isDark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: onMessageTap,
                    child: const Text(
                      'Message this owner',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabelFor(Map<String, String> pet) {
    final value = '${pet['meta'] ?? ''} ${pet['tags'] ?? ''}'.toLowerCase();
    if (value.contains('lost')) {
      return 'Missing pet';
    }
    if (value.contains('found') || value.contains('sighting')) {
      return 'Found nearby';
    }
    return 'Available nearby';
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final Map<String, String> pet;

  const _ContactRow({required this.pet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.cardColor,
          child: ClipOval(
            child: PetImage(
              image: 'mock://owner-${pet['ownerName']}',
              height: 40,
              width: 40,
              seed: pet['ownerName'] ?? pet['name'] ?? '',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet['ownerName'] ?? 'Jade Green',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                pet['ownerMeta'] ?? 'Pet owner for 3 years',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationBar extends StatelessWidget {
  final String location;

  const _LocationBar({required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.inputSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 15,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
      ),
    );
  }
}
