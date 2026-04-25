import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/screens/home/home_screen.dart';
import 'package:pawnder_app/services/message_service.dart';
import 'package:pawnder_app/services/message_socket_service.dart';
import 'package:pawnder_app/theme.dart';
import 'package:pawnder_app/widgets/build_bottom_nav.dart';
import 'package:pawnder_app/widgets/user_avatar.dart';

class MessageThreadScreen extends StatefulWidget {
  final MessageThread thread;

  const MessageThreadScreen({super.key, required this.thread});

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final _messageService = MessageService();
  final _messageSocketService = MessageSocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ThreadMessage> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isDeletingThread = false;
  String? _errorMessage;
  ThreadMessage? _replyingToMessage;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messages = widget.thread.messages;
    _loadMessages();
    _subscribeToLiveMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToLiveMessages() async {
    await _messageSocketService.connect();
    _messageSubscription = _messageSocketService.incomingEvents.listen((event) {
      final participantId = widget.thread.participantId;
      final message = event.message;
      if (!mounted || participantId == null || message == null) {
        return;
      }

      final isForThisThread =
          message.senderId == participantId ||
          message.receiverId == participantId;
      if (!isForThisThread) {
        return;
      }

      setState(() {
        _messages = _upsertMessage(_messages, message);
      });
      _scrollToBottom();
    });
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
        replyToMessageId: _replyingToMessage?.id,
      );

      if (!mounted) {
        return;
      }

      _messageController.clear();
      setState(() {
        _messages = _upsertMessage(_messages, message);
        _replyingToMessage = null;
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

  Future<void> _unsendMessage(ThreadMessage message) async {
    final messageId = message.id;
    if (messageId == null) {
      return;
    }

    try {
      final updated = await _messageService.unsendMessage(message);
      if (!mounted) {
        return;
      }

      setState(() {
        _messages = _upsertMessage(_messages, updated);
        if (_replyingToMessage?.id == updated.id) {
          _replyingToMessage = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageService.messageForError(error))),
      );
    }
  }

  Future<void> _toggleReaction(ThreadMessage message, String emoji) async {
    final messageId = message.id;
    if (messageId == null || emoji.trim().isEmpty) {
      return;
    }

    try {
      final updated = await _messageService.toggleReaction(
        message: message,
        emoji: emoji.trim(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _messages = _upsertMessage(_messages, updated);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageService.messageForError(error))),
      );
    }
  }

  Future<void> _confirmDeleteThread() async {
    final participantId = widget.thread.participantId;
    if (participantId == null || _isDeletingThread) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'This removes the conversation from your inbox on this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() => _isDeletingThread = true);
    try {
      await _messageService.deleteThread(participantId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageService.messageForError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingThread = false);
      }
    }
  }

  Future<void> _showMessageActions(ThreadMessage message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _startReply(message);
              },
            ),
            if (!message.isUnsent)
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: const Text('React'),
                onTap: () async {
                  Navigator.pop(context);
                  final emoji = await _showReactionPicker();
                  if (emoji != null && mounted) {
                    await _toggleReaction(message, emoji);
                  }
                },
              ),
            if (message.isMine && !message.isUnsent)
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: const Text('Unsend'),
                onTap: () {
                  Navigator.pop(context);
                  _unsendMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showReactionPicker() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReactionPickerSheet(),
    );
  }

  void _startReply(ThreadMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
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

  List<ThreadMessage> _upsertMessage(
    List<ThreadMessage> current,
    ThreadMessage incoming,
  ) {
    final messageId = incoming.id;
    if (messageId == null) {
      return [...current, incoming];
    }

    final index = current.indexWhere((item) => item.id == messageId);
    if (index == -1) {
      return [...current, incoming];
    }

    final updated = [...current];
    updated[index] = incoming;
    return updated;
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
                    child: UserAvatar(
                      imagePath: widget.thread.participantAvatarPath,
                      size: 44,
                      backgroundColor: theme.cardColor,
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
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !_isDeletingThread,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDeleteThread();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete chat'),
                      ),
                    ],
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
                    final bubbleWidth = constraints.maxWidth * 0.74;

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
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(
                          message: message,
                          maxWidth: bubbleWidth,
                          onReplyTap: () => _startReply(message),
                          onReactTap: message.isUnsent
                              ? null
                              : () async {
                                  final emoji = await _showReactionPicker();
                                  if (emoji != null) {
                                    await _toggleReaction(message, emoji);
                                  }
                                },
                          onLongPress: () => _showMessageActions(message),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_replyingToMessage != null) ...[
                _ReplyComposerBanner(
                  message: _replyingToMessage!,
                  onCancel: () => setState(() => _replyingToMessage = null),
                ),
                const SizedBox(height: 8),
              ],
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
                              ? (_replyingToMessage == null
                                    ? 'Reply to thread'
                                    : 'Send your reply')
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

class _ReplyComposerBanner extends StatelessWidget {
  final ThreadMessage message;
  final VoidCallback onCancel;

  const _ReplyComposerBanner({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isMine ? 'Replying to yourself' : 'Replying',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReactionPickerSheet extends StatefulWidget {
  const _ReactionPickerSheet();

  @override
  State<_ReactionPickerSheet> createState() => _ReactionPickerSheetState();
}

class _ReactionPickerSheetState extends State<_ReactionPickerSheet> {
  final _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleEmojis {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return _emojiCategories[_selectedCategoryIndex].emojis;
    }

    final normalized = query.toLowerCase();
    return _emojiCategories
        .expand((category) => category.emojis)
        .where((emoji) => emoji.contains(query) || emoji.contains(normalized))
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedCategory = _emojiCategories[_selectedCategoryIndex];

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.84,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'React with an emoji',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse all emojis or tap a quick reaction.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: _quickReactionEmojis
                            .map(
                              (emoji) => InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.pop(context, emoji),
                                child: Container(
                                  width: 74,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkBackground
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _emojiCategories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = _emojiCategories[index];
                          final isSelected = index == _selectedCategoryIndex;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                category.icon,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search all emojis',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedCategory.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _visibleEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _visibleEmojis[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, emoji),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiCategory {
  final String label;
  final IconData icon;
  final List<String> emojis;

  const _EmojiCategory({
    required this.label,
    required this.icon,
    required this.emojis,
  });
}

const List<String> _quickReactionEmojis = [
  '❤️',
  '👍',
  '👏',
  '🙏',
  '💪',
  '🔥',
  '😊',
  '😮',
];

const List<_EmojiCategory> _emojiCategories = [
  _EmojiCategory(
    label: 'Recent',
    icon: Icons.access_time_rounded,
    emojis: [
      '❤️',
      '👍',
      '😂',
      '😭',
      '🔥',
      '🙏',
      '🥺',
      '✨',
      '👏',
      '😊',
      '👀',
      '🐾',
      '😮',
      '😍',
      '💯',
      '🎉',
      '🤍',
      '😅',
      '🤣',
      '💔',
    ],
  ),
  _EmojiCategory(
    label: 'Smileys & Emotion',
    icon: Icons.sentiment_satisfied_alt_rounded,
    emojis: [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '☺️',
      '😚',
      '😙',
      '🥲',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🫠',
      '🤗',
      '🤭',
      '🫢',
      '🫣',
      '🤫',
      '🤔',
      '🫡',
      '🤐',
      '🤨',
      '😐',
      '😑',
      '😶',
      '🫥',
      '😏',
      '😒',
      '🙄',
      '😬',
      '🤥',
      '😌',
      '😔',
      '😪',
      '🤤',
      '😴',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '😎',
      '🥳',
      '😭',
      '😤',
      '😡',
      '🤬',
      '😱',
      '😳',
      '🥺',
    ],
  ),
  _EmojiCategory(
    label: 'Animals & Nature',
    icon: Icons.pets_rounded,
    emojis: [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐻‍❄️',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🐔',
      '🐧',
      '🐦',
      '🐤',
      '🦆',
      '🦅',
      '🦉',
      '🐺',
      '🐗',
      '🐴',
      '🦄',
      '🐝',
      '🪲',
      '🦋',
      '🐌',
      '🐞',
      '🐢',
      '🐍',
      '🦎',
      '🐙',
      '🦑',
      '🦞',
      '🦀',
      '🐠',
      '🐟',
      '🐬',
      '🐳',
      '🦭',
      '🌲',
      '🌳',
      '🌴',
      '🌵',
      '🌸',
      '🌼',
      '🌻',
      '🌞',
      '🌈',
      '⭐',
      '🔥',
      '🌊',
    ],
  ),
  _EmojiCategory(
    label: 'Hands & People',
    icon: Icons.waving_hand_rounded,
    emojis: [
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '🫱',
      '🫲',
      '🫳',
      '🫴',
      '👌',
      '🤌',
      '🤏',
      '✌️',
      '🤞',
      '🫰',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '🖕',
      '👇',
      '☝️',
      '👍',
      '👎',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '👏',
      '🙌',
      '🫶',
      '👐',
      '🤲',
      '🙏',
      '✍️',
      '💅',
      '🤳',
      '💪',
      '🦾',
      '🧠',
      '🫀',
      '👀',
      '🫂',
      '👤',
      '👥',
    ],
  ),
  _EmojiCategory(
    label: 'Activity',
    icon: Icons.local_fire_department_rounded,
    emojis: [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🥎',
      '🎾',
      '🏐',
      '🏉',
      '🥏',
      '🎱',
      '🏓',
      '🏸',
      '🥅',
      '🏒',
      '🏑',
      '🥍',
      '🏏',
      '🪃',
      '🥊',
      '🥋',
      '🎽',
      '🛹',
      '🛷',
      '⛸️',
      '🥌',
      '🎿',
      '⛷️',
      '🏂',
      '🪂',
      '🏋️',
      '🤼',
      '🤸',
      '⛹️',
      '🤺',
      '🤾',
      '🏌️',
      '🏇',
      '🧘',
      '🏄',
      '🏊',
      '🚣',
      '🧗',
      '🚴',
      '🚵',
      '🎯',
      '🎳',
      '🎮',
      '🎲',
      '🧩',
      '♟️',
      '🎭',
      '🎨',
      '🎬',
      '🎤',
      '🎧',
      '🎼',
      '🎹',
      '🥁',
      '🎷',
      '🎺',
      '🪗',
      '🎸',
      '🪕',
      '🎻',
      '🔥',
      '💥',
      '✨',
    ],
  ),
  _EmojiCategory(
    label: 'Travel & Places',
    icon: Icons.directions_car_filled_rounded,
    emojis: [
      '🚗',
      '🚕',
      '🚙',
      '🚌',
      '🚎',
      '🏎️',
      '🚓',
      '🚑',
      '🚒',
      '🚐',
      '🛻',
      '🚚',
      '🚛',
      '🚜',
      '🛵',
      '🏍️',
      '🚲',
      '🛴',
      '✈️',
      '🚀',
      '🛸',
      '⛵',
      '🚤',
      '🗽',
      '🌋',
      '⛰️',
      '🏠',
      '🏡',
      '🏢',
      '🏥',
      '🏫',
      '🏞️',
      '🌉',
      '🌆',
    ],
  ),
  _EmojiCategory(
    label: 'Objects & Symbols',
    icon: Icons.lightbulb_outline_rounded,
    emojis: [
      '⌚',
      '📱',
      '💻',
      '⌨️',
      '🖥️',
      '🖨️',
      '🖱️',
      '📷',
      '📸',
      '🎥',
      '📞',
      '☎️',
      '📺',
      '🔋',
      '🔌',
      '💡',
      '🔦',
      '🕯️',
      '🪫',
      '💸',
      '💰',
      '💎',
      '⚖️',
      '🔒',
      '🔑',
      '🛒',
      '🎁',
      '🎈',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💯',
      '✅',
      '❌',
      '⚠️',
      '❗',
      '❓',
      '💤',
      '✨',
      '🎉',
      '🔥',
      '⭐',
      '🌟',
    ],
  ),
  _EmojiCategory(
    label: 'Symbols',
    icon: Icons.tag_rounded,
    emojis: [
      '#️⃣',
      '*️⃣',
      '0️⃣',
      '1️⃣',
      '2️⃣',
      '3️⃣',
      '4️⃣',
      '5️⃣',
      '6️⃣',
      '7️⃣',
      '8️⃣',
      '9️⃣',
      '🔟',
      '➕',
      '➖',
      '➗',
      '🟰',
      '♾️',
      '‼️',
      '⁉️',
      '❓',
      '❔',
      '❕',
      '❗',
      '〰️',
      '💱',
      '💲',
      '⚕️',
      '♻️',
      '⚜️',
      '🔱',
      '📛',
      '🔰',
      '⭕',
      '✅',
      '☑️',
      '✔️',
      '❌',
      '❎',
      '➰',
      '➿',
      '〽️',
      '✳️',
      '✴️',
      '❇️',
      '©️',
      '®️',
      '™️',
      '🔴',
      '🟠',
      '🟡',
      '🟢',
      '🔵',
      '🟣',
      '⚫',
      '⚪',
      '🟤',
      '🔺',
      '🔻',
      '🔸',
      '🔹',
      '🔶',
      '🔷',
      '🔳',
      '🔲',
    ],
  ),
  _EmojiCategory(
    label: 'Flags',
    icon: Icons.outlined_flag_rounded,
    emojis: [
      '🏳️',
      '🏴',
      '🏁',
      '🚩',
      '🏳️‍🌈',
      '🏳️‍⚧️',
      '🇺🇸',
      '🇨🇦',
      '🇲🇽',
      '🇧🇷',
      '🇦🇷',
      '🇬🇧',
      '🇮🇪',
      '🇫🇷',
      '🇩🇪',
      '🇪🇸',
      '🇮🇹',
      '🇵🇹',
      '🇳🇱',
      '🇧🇪',
      '🇸🇪',
      '🇳🇴',
      '🇩🇰',
      '🇫🇮',
      '🇵🇱',
      '🇺🇦',
      '🇬🇷',
      '🇹🇷',
      '🇸🇦',
      '🇦🇪',
      '🇮🇳',
      '🇵🇰',
      '🇧🇩',
      '🇨🇳',
      '🇯🇵',
      '🇰🇷',
      '🇹🇭',
      '🇻🇳',
      '🇸🇬',
      '🇵🇭',
      '🇮🇩',
      '🇦🇺',
      '🇳🇿',
      '🇿🇦',
      '🇳🇬',
      '🇪🇬',
    ],
  ),
];

class _MessageBubble extends StatelessWidget {
  final ThreadMessage message;
  final double maxWidth;
  final VoidCallback onReplyTap;
  final VoidCallback? onReactTap;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.maxWidth,
    required this.onReplyTap,
    required this.onReactTap,
    required this.onLongPress,
  });

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
    final reactionText = message.isMine
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: message.isMine
                    ? mineBackground
                    : theme.colorScheme.primary,
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
                  if (message.replyPreview != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyPreview!.authorName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: message.isMine
                                  ? mineTime
                                  : otherText.withValues(alpha: 0.84),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.replyPreview!.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: message.isMine
                                  ? mineText.withValues(alpha: 0.88)
                                  : otherText.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMine ? mineText : otherText,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      fontStyle: message.isUnsent
                          ? FontStyle.italic
                          : FontStyle.normal,
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
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onReplyTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onReactTap != null)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onReactTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Icon(
                      Icons.add_reaction_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.reactions
                  .map(
                    (reaction) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reaction.youReacted
                            ? theme.colorScheme.primary.withValues(alpha: 0.14)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: reaction.youReacted
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        '${reaction.emoji} ${reaction.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: reactionText,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
