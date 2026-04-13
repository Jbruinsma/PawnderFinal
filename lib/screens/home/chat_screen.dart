import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/message_thread_screen.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/image_fallback.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<MessageThread> _threads = [
    MessageThread(
      id: 'jade-scooba',
      participantName: 'Jade Green',
      title: 'Scooba adoption check-in',
      subtitle: 'Interested in Scooba?',
      unreadCount: 2,
      lastUpdatedLabel: '2m ago',
      messages: [
        ThreadMessage(
          text: 'Heyy! Are you still interested in meeting Scooba this week?',
          isMine: false,
          timestamp: '11:42 AM',
        ),
        ThreadMessage(
          text: 'Yes, definitely. I can do Thursday after 6 if that still works.',
          isMine: true,
          timestamp: '11:45 AM',
        ),
        ThreadMessage(
          text: 'Perfect. I can bring Scooba to the park near 5th and Dean.',
          isMine: false,
          timestamp: '11:47 AM',
        ),
      ],
    ),
    MessageThread(
      id: 'martha-georgie',
      participantName: 'Martha Ellis',
      title: 'Georgie sighting update',
      subtitle: 'Possible lead in Brooklyn',
      unreadCount: 1,
      lastUpdatedLabel: '18m ago',
      messages: [
        ThreadMessage(
          text: 'Someone on Bergen said they may have seen Georgie near the deli.',
          isMine: false,
          timestamp: '10:22 AM',
        ),
        ThreadMessage(
          text: 'Thank you. I am heading over there now to check.',
          isMine: true,
          timestamp: '10:28 AM',
        ),
      ],
    ),
    MessageThread(
      id: 'noah-bird',
      participantName: 'Noah Fields',
      title: 'Bird pickup details',
      subtitle: 'Waiting on confirmation',
      unreadCount: 0,
      lastUpdatedLabel: '1h ago',
      messages: [
        ThreadMessage(
          text: 'If this is your cockatiel, send me a picture of the leg band.',
          isMine: false,
          timestamp: '9:05 AM',
        ),
        ThreadMessage(
          text: 'I just sent it over. Let me know if you need another angle.',
          isMine: true,
          timestamp: '9:08 AM',
        ),
      ],
    ),
    MessageThread(
      id: 'manny-hedgehog',
      participantName: 'Manny Ortiz',
      title: 'Hedgehog owner search',
      subtitle: 'Resolved thread',
      unreadCount: 0,
      lastUpdatedLabel: 'Yesterday',
      messages: [
        ThreadMessage(
          text: 'We found the owner. Thanks again for helping share the post.',
          isMine: false,
          timestamp: 'Yesterday',
        ),
        ThreadMessage(
          text: 'That is awesome news. Glad the little guy made it home.',
          isMine: true,
          timestamp: 'Yesterday',
        ),
      ],
    ),
  ];

  String _selectedThreadId = _threads.first.id;

  MessageThread get _selectedThread => _threads.firstWhere(
        (thread) => thread.id == _selectedThreadId,
        orElse: () => _threads.first,
      );

  void _openThread(MessageThread thread) {
    setState(() {
      _selectedThreadId = thread.id;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageThreadScreen(thread: thread),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedThread = _selectedThread;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/animals.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ImageFallback(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MESSAGES',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _threads.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final thread = _threads[index];
                final isSelected = thread.id == selectedThread.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _openThread(thread),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.seaBlue
                          : const Color(0xFFF4F8FB),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.seaBlue
                            : const Color(0xFFCAD7E0),
                      ),
                    ),
                    child: Text(
                      thread.participantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF294250),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _threads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final thread = _threads[index];
                final isSelected = thread.id == selectedThread.id;
                return _ThreadListTile(
                  thread: thread,
                  isSelected: isSelected,
                  onTap: () => _openThread(thread),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadListTile extends StatelessWidget {
  final MessageThread thread;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThreadListTile({
    required this.thread,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.seaBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.seaBlue
                : const Color(0xFFD4E0E7),
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22188393),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE9F2F8),
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF202A34),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        thread.lastUpdatedLabel,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFD8F3F7)
                              : const Color(0xFF66737E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF14212A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFE0F5F8)
                          : AppColors.bodyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (thread.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFFE0F6FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${thread.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.seaBlue,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected
                    ? const Color(0xFFD8F3F7)
                    : const Color(0xFF7C8A95),
              ),
          ],
        ),
      ),
    );
  }
}
