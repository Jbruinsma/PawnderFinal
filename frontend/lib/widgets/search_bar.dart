import 'dart:ui';

import 'package:flutter/material.dart';

class GlassmorphicSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final String hintText;
  final TextEditingController? controller;

  const GlassmorphicSearchBar({
    super.key,
    required this.onChanged,
    this.isLoading = false,
    this.hintText = 'Search...',
    this.controller,
  });

  @override
  State<GlassmorphicSearchBar> createState() => _GlassmorphicSearchBarState();
}

class _GlassmorphicSearchBarState extends State<GlassmorphicSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant GlassmorphicSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onChanged,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else if (hasText)
                      GestureDetector(
                        onTap: _clearSearch,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}