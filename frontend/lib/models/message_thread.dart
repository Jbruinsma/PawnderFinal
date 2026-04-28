class MessageThread {
  final String id;
  final String? participantId;
  final String participantName;
  final String? participantAvatarPath;
  final String title;
  final String subtitle;
  final int unreadCount;
  final String? lastSenderId;
  final String lastUpdatedLabel;
  final List<ThreadMessage> messages;

  const MessageThread({
    required this.id,
    this.participantId,
    required this.participantName,
    this.participantAvatarPath,
    required this.title,
    required this.subtitle,
    required this.unreadCount,
    this.lastSenderId,
    required this.lastUpdatedLabel,
    required this.messages,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    final participantId = json['participant_id']?.toString();
    final lastSentAtValue = json['last_sent_at']?.toString();
    final lastSentAt = lastSentAtValue == null || lastSentAtValue.isEmpty
        ? null
        : DateTime.tryParse(lastSentAtValue);

    return MessageThread(
      id: json['id']?.toString() ?? participantId ?? '',
      participantId: participantId,
      participantName:
          json['participant_name']?.toString() ?? 'Community member',
      participantAvatarPath: json['participant_avatar_path']?.toString(),
      title: json['last_message']?.toString() ?? 'Message thread',
      subtitle: 'Community conversation',
      unreadCount: json['unread_count'] as int? ?? 0,
      lastSenderId: json['last_sender_id']?.toString(),
      lastUpdatedLabel: lastSentAt == null
          ? 'Just now'
          : _formatTimestamp(lastSentAt),
      messages: const [],
    );
  }

  factory MessageThread.direct({
    required String participantId,
    required String participantName,
    required String title,
    String subtitle = 'Direct message',
  }) {
    return MessageThread(
      id: participantId,
      participantId: participantId,
      participantName: participantName,
      participantAvatarPath: null,
      title: title,
      subtitle: subtitle,
      unreadCount: 0,
      lastSenderId: null,
      lastUpdatedLabel: 'Just now',
      messages: const [],
    );
  }
}

class ThreadMessage {
  final String? id;
  final String? senderId;
  final String? receiverId;
  final String text;
  final bool isMine;
  final String timestamp;
  final DateTime? sentAt;
  final bool isUnsent;
  final String? replyToMessageId;
  final MessageReplyPreview? replyPreview;
  final List<MessageReactionSummary> reactions;

  const ThreadMessage({
    this.id,
    this.senderId,
    this.receiverId,
    required this.text,
    required this.isMine,
    required this.timestamp,
    this.sentAt,
    this.isUnsent = false,
    this.replyToMessageId,
    this.replyPreview,
    this.reactions = const [],
  });

  factory ThreadMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final sentAtValue = json['sent_at']?.toString();
    final sentAt = sentAtValue == null || sentAtValue.isEmpty
        ? null
        : DateTime.tryParse(sentAtValue);

    return ThreadMessage(
      id: json['id']?.toString(),
      senderId: json['sender_id']?.toString(),
      receiverId: json['receiver_id']?.toString(),
      text: json['content']?.toString() ?? '',
      isMine: json['sender_id']?.toString() == currentUserId,
      timestamp: sentAt == null ? 'Just now' : _formatTimestamp(sentAt),
      sentAt: sentAt,
      isUnsent: json['is_unsent'] == true,
      replyToMessageId: json['reply_to_message_id']?.toString(),
      replyPreview: json['reply_preview'] is Map<String, dynamic>
          ? MessageReplyPreview.fromJson(
              json['reply_preview'] as Map<String, dynamic>,
            )
          : null,
      reactions: (json['reactions'] as List<dynamic>? ?? const [])
          .map(
            (reaction) => MessageReactionSummary.fromJson(
              reaction as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  ThreadMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    bool? isMine,
    String? timestamp,
    DateTime? sentAt,
    bool? isUnsent,
    String? replyToMessageId,
    MessageReplyPreview? replyPreview,
    List<MessageReactionSummary>? reactions,
  }) {
    return ThreadMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      isMine: isMine ?? this.isMine,
      timestamp: timestamp ?? this.timestamp,
      sentAt: sentAt ?? this.sentAt,
      isUnsent: isUnsent ?? this.isUnsent,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: replyPreview ?? this.replyPreview,
      reactions: reactions ?? this.reactions,
    );
  }
}

class MessageReplyPreview {
  final String id;
  final String authorName;
  final String content;
  final bool isUnsent;

  const MessageReplyPreview({
    required this.id,
    required this.authorName,
    required this.content,
    required this.isUnsent,
  });

  factory MessageReplyPreview.fromJson(Map<String, dynamic> json) {
    return MessageReplyPreview(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? 'Message',
      content: json['content']?.toString() ?? '',
      isUnsent: json['is_unsent'] == true,
    );
  }
}

class MessageReactionSummary {
  final String emoji;
  final int count;
  final bool youReacted;

  const MessageReactionSummary({
    required this.emoji,
    required this.count,
    required this.youReacted,
  });

  factory MessageReactionSummary.fromJson(Map<String, dynamic> json) {
    return MessageReactionSummary(
      emoji: json['emoji']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      youReacted: json['you_reacted'] == true,
    );
  }
}

class MessageSocketEvent {
  final String type;
  final ThreadMessage? message;

  const MessageSocketEvent({required this.type, this.message});
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
