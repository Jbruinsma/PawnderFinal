import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';

class PetImage extends StatelessWidget {
  final String? image;
  final double height;
  final double? width;
  final BoxFit fit;
  final String seed;
  final bool preserveSubject;

  const PetImage({
    super.key,
    required this.image,
    required this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.seed = '',
    this.preserveSubject = false,
  });

  @override
  Widget build(BuildContext context) {
    final source = image?.trim() ?? '';
    final resolvedFit = preserveSubject ? BoxFit.cover : fit;
    final alignment = preserveSubject ? Alignment.center : Alignment.center;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget themedFrame(Widget child) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        color: isDark ? AppColors.darkBackground : AppColors.inputSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (isDark) ColoredBox(color: Colors.black.withValues(alpha: 0.34)),
          ],
        ),
      );
    }

    if (source.startsWith('mock://')) {
      return themedFrame(
        _MockAnimalPhoto(
          height: height,
          width: width,
          fit: resolvedFit,
          seed: source,
          alignment: alignment,
        ),
      );
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      Widget networkImage(BoxFit imageFit) {
        return Image.network(
          source,
          height: height,
          width: width,
          fit: imageFit,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => _PetPlaceholder(
            height: height,
            width: width,
            seed: seed.isEmpty ? source : seed,
          ),
        );
      }

      return themedFrame(networkImage(resolvedFit));
    }

    if (source.isNotEmpty && !source.startsWith('mock://')) {
      Widget assetImage(BoxFit imageFit) {
        return Image.asset(
          source,
          height: height,
          width: width,
          fit: imageFit,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => _PetPlaceholder(
            height: height,
            width: width,
            seed: seed.isEmpty ? source : seed,
          ),
        );
      }

      return themedFrame(assetImage(resolvedFit));
    }

    return _PetPlaceholder(height: height, width: width, seed: seed);
  }
}

class _MockAnimalPhoto extends StatelessWidget {
  final double height;
  final double? width;
  final BoxFit fit;
  final String seed;
  final Alignment alignment;

  const _MockAnimalPhoto({
    required this.height,
    required this.width,
    required this.fit,
    required this.seed,
    required this.alignment,
  });

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

  int get _index {
    final lowerSeed = seed.toLowerCase();
    for (final entry in _knownIndexes.entries) {
      if (lowerSeed.contains(entry.key)) {
        return entry.value;
      }
    }

    return lowerSeed.codeUnits.fold<int>(0, (sum, code) => sum + code) % 9;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPaths[_index],
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) =>
          _PetPlaceholder(height: height, width: width, seed: seed),
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  final double height;
  final double? width;
  final String seed;

  const _PetPlaceholder({
    required this.height,
    required this.width,
    required this.seed,
  });

  static const _palettes = [
    [Color(0xFFB4D8DE), Color(0xFFF2CCA2)],
    [Color(0xFFFFD1BA), Color(0xFF83C5BE)],
    [Color(0xFFCDEAC0), Color(0xFFFFC8DD)],
    [Color(0xFFA9DEF9), Color(0xFFE4C1F9)],
    [Color(0xFFFDFCDC), Color(0xFF90DBF4)],
  ];

  static const _icons = [
    Icons.pets_rounded,
    Icons.cruelty_free_rounded,
    Icons.flutter_dash_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final index =
        seed.codeUnits.fold<int>(0, (sum, code) => sum + code) %
        _palettes.length;

    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _palettes[index],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _icons[index],
          size: height.clamp(42, 88).toDouble(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
