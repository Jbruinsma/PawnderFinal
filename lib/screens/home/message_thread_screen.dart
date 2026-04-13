import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class MessageThreadScreen extends StatelessWidget {
  final MessageThread thread;

  const MessageThreadScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/animals.jpg',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ImageFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.bodyText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFC8D8E0)),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bubbleWidth = constraints.maxWidth * 0.72;
                    return ListView.separated(
                      itemCount: thread.messages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = thread.messages[index];
                        return Align(
                          alignment: message.isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: bubbleWidth),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            decoration: BoxDecoration(
                              color: message.isMine
                                  ? const Color(0xFFDFF5F8)
                                  : AppColors.seaBlue,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft:
                                    Radius.circular(message.isMine ? 18 : 6),
                                bottomRight:
                                    Radius.circular(message.isMine ? 6 : 18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    color: message.isMine
                                        ? const Color(0xFF17333F)
                                        : Colors.white,
                                    fontSize: 15,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message.timestamp,
                                  style: TextStyle(
                                    color: message.isMine
                                        ? const Color(0xFF54717D)
                                        : const Color(0xFFD8F3F7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD2DEE6)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reply to thread',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9AA7B3),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.send_rounded, color: AppColors.seaBlue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(
        selectedNavIndex: 2,
        onNavTap: (index) {
          if (index == 2) {
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(initialNavIndex: index),
            ),
          );
        },
      ),
    );
  }
}
