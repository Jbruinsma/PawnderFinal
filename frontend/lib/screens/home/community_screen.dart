import 'package:flutter/material.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_community_posts_feed.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';
import 'package:pawnder_app/services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  final List<Map<String, String>> posts;
  final ValueChanged<Map<String, String>> onPostTap;
  final VoidCallback onAddListingTap;
  final ValueChanged<CommunityDefinition> onCommunityTap;

  const CommunityScreen({
    super.key,
    required this.posts,
    required this.onPostTap,
    required this.onAddListingTap,
    required this.onCommunityTap,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';
  List<Map<String, String>> _neighborhoods = [];
  bool _loadingNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    _loadNeighborhoods();
  }

  Future<void> _loadNeighborhoods() async {
    setState(() => _loadingNeighborhoods = true);
    try {
      final results = await CommunityService.getNeighborhoods();
      if (mounted) setState(() => _neighborhoods = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingNeighborhoods = false);
    }
  }

  void _showAllNeighborhoods() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        if (_loadingNeighborhoods) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_neighborhoods.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No neighborhoods found')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _neighborhoods.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = _neighborhoods[i];
            return ListTile(
              title: Text(
                n['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(n['description'] ?? ''),
              leading: const CircleAvatar(
                backgroundColor: AppColors.seaBlue,
                child: Icon(Icons.location_on, color: Colors.white, size: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onCommunityTap(CommunityDefinition(
                  label: n['name'] ?? '',
                  title: n['name'] ?? '',
                ));
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/animals.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ImageFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'EXPLORE COMMUNITIES',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        letterSpacing: -0.5, color: AppColors.seaBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _communities.length; i++) ...[
                    Expanded(
                      child: _CommunityTile(
                        label: _communities[i].label,
                        onTap: () => widget.onCommunityTap(_communities[i]),
                      ),
                    ),
                    if (i < _communities.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showAllNeighborhoods,
                  child: const Text(
                    'Explore More\nCommunities',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.seaBlue,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SearchBar(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 14),
              Container(height: 2, color: AppColors.seaBlue),
              const SizedBox(height: 12),
              Expanded(
                child: buildCommunityPostsFeed(
                  posts: widget.posts,
                  searchQuery: _searchQuery,
                  onPostTap: widget.onPostTap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: widget.onAddListingTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1C1C1C),
                      elevation: 2,
                      shadowColor: const Color(0x22000000),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Add listing here +',
                      style: TextStyle(fontWeight: FontWeight.w800),
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

class _CommunityTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CommunityTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/animals.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ImageFallback(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13, height: 1.1,
              color: Color(0xFF1D232B), fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityDefinition {
  final String label;
  final String title;

  const CommunityDefinition({required this.label, required this.title});
}

const List<CommunityDefinition> _communities = [
  CommunityDefinition(label: 'Lost\nCritters', title: 'Lost Critters'),
  CommunityDefinition(label: 'Bird\nLovers', title: 'Bird Lovers'),
  CommunityDefinition(label: 'Brooklyn', title: 'Brooklyn'),
];

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search for communities...',
                hintStyle: TextStyle(
                  color: Color(0xFFB1B8C0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.search, color: AppColors.seaBlue, size: 20),
        ],
      ),
    );
  }
}