import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, String> pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final heroTag = 'pet-${pet['name'] ?? 'unknown'}';

    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
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
                    size: 27,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: Image.asset(
                  pet['image'] ?? 'assets/images/animals.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ImageFallback();
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.seaBlue,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pet['location'] ?? 'Washington Heights, New York',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              pet['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                fontSize: 42,
                                height: 0.95,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.pets_rounded,
                            size: 34,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Breed: ${pet['breed'] ?? 'Dalmatian'}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      Text(
                        'Age: ${pet['age'] ?? '2 years'}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      Text(
                        'Weight: ${pet['weight'] ?? '65 lbs'}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Main Contact',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(
                              'assets/images/animals.jpg',
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
                                  style: const TextStyle(
                                    color: AppColors.bodyText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _circleIcon(Icons.call_rounded),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessageThreadScreen(
                                  thread: MessageThread(
                                    id: 'pet-${pet['ownerName'] ?? 'owner'}',
                                    participantName:
                                        pet['ownerName'] ?? 'Jade Green',
                                    title:
                                        '${pet['name'] ?? 'Pet'} adoption chat',
                                    subtitle:
                                        pet['ownerMeta'] ?? 'Pet owner for 3 years',
                                    unreadCount: 0,
                                    lastUpdatedLabel: 'Just now',
                                    messages: [
                                      ThreadMessage(
                                        text:
                                            'Hi! I would love to learn more about ${pet['name'] ?? 'your pet'}.',
                                        isMine: true,
                                        timestamp: 'Just now',
                                      ),
                                      ThreadMessage(
                                        text:
                                            'Absolutely. I can answer any questions you have.',
                                        isMine: false,
                                        timestamp: 'Just now',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            child: _circleIcon(Icons.chat_bubble_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'About this Pet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet['about'] ??
                            'Friendly, playful, and loves long neighborhood walks.',
                        style: const TextStyle(
                          height: 1.45,
                          color: Color(0xFF2A2A2A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.seaBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text(
                            'Adopt this pet',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.seaBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
