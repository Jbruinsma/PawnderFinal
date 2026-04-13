import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class MissingPostDetailsScreen extends StatelessWidget {
  final Map<String, String> post;

  const MissingPostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] ?? 'Pet Owner';
    final firstName = author.trim().isEmpty ? 'Owner' : author.split(' ').first;
    final tags = (post['tags'] ?? '')
        .split('|')
        .where((tag) => tag.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    post['image'] ?? 'assets/images/animals.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ImageFallback(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x12000000), Color(0x12000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.seaBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title'] ?? 'Help me find my pet',
                              style: const TextStyle(
                                fontSize: 34,
                                height: 0.96,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Posted ${post['posted'] ?? 'March 10th, 2026'}',
                              style: const TextStyle(
                                color: Color(0xFFE2F5F8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by $author',
                              style: const TextStyle(
                                color: Color(0xFFE2F5F8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          post['description'] ??
                              'Our pet has gone missing. If you see them, please contact us right away.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F6FA),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      color: AppColors.seaBlue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageThreadScreen(
                            thread: MessageThread(
                              id: 'post-${post['id'] ?? firstName}',
                              participantName: author,
                              title: post['title'] ?? 'Pet post conversation',
                              subtitle: 'Community contact thread',
                              unreadCount: 0,
                              lastUpdatedLabel: 'Just now',
                              messages: [
                                ThreadMessage(
                                  text:
                                      'Hi! I saw your post and wanted to reach out about ${post['title'] ?? 'your pet'}.',
                                  isMine: true,
                                  timestamp: 'Just now',
                                ),
                                ThreadMessage(
                                  text:
                                      'Thank you so much for messaging. Let me know what details you need.',
                                  isMine: false,
                                  timestamp: 'Just now',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        'Contact $firstName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
