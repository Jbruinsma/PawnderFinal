import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/pet_image.dart';

class MessageThreadScreen extends StatefulWidget {
  final MessageThread thread;

  const MessageThreadScreen({super.key, required this.thread});

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final _messageService = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ThreadMessage> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messages = widget.thread.messages;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final participantId = widget.thread.participantId;
    if (participantId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await _messageService.getMessages(participantId);
      if (!mounted) {
        return;
      }

      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _messageService.messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final participantId = widget.thread.participantId;
    final content = _messageController.text.trim();

    if (participantId == null || content.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final message = await _messageService.sendMessage(
        receiverId: participantId,
        content: content,
      );

      if (!mounted) {
        return;
      }

      _messageController.clear();
      setState(() {
        _messages = [..._messages, message];
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _messageService.messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = widget.thread.participantId != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.cardColor,
                    child: ClipOval(
                      child: PetImage(
                        image: 'mock://thread/${widget.thread.id}',
                        width: 44,
                        height: 44,
                        seed: widget.thread.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.thread.participantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 14),
              if (_isLoading) const LinearProgressIndicator(minHeight: 3),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bubbleWidth = constraints.maxWidth * 0.72;

                    if (_messages.isEmpty && !_isLoading) {
                      return Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(
                          message: message,
                          maxWidth: bubbleWidth,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.fromLTRB(16, 3, 8, 3),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: canSend && !_isSending,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: canSend
                              ? 'Reply to thread'
                              : 'Open a real conversation to reply',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      onPressed: canSend && !_isSending ? _sendMessage : null,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      color: theme.colorScheme.onSurface,
                    ),
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

class _MessageBubble extends StatelessWidget {
  final ThreadMessage message;
  final double maxWidth;

  const _MessageBubble({required this.message, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mineBackground = isDark
        ? AppColors.darkElevated
        : const Color(0xFFE9EEF1);
    final mineText = isDark ? AppColors.darkText : const Color(0xFF17333F);
    final mineTime = isDark ? AppColors.darkMuted : const Color(0xFF54717D);
    final otherText = theme.colorScheme.onPrimary;

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: message.isMine ? mineBackground : theme.colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isMine ? 18 : 6),
            bottomRight: Radius.circular(message.isMine ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMine ? mineText : otherText,
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
                    ? mineTime
                    : otherText.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
