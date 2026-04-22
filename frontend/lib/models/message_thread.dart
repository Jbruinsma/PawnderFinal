class MessageThread {
  final String id;
  final String? participantId;
  final String participantName;
  final String title;
  final String subtitle;
  final int unreadCount;
  final String lastUpdatedLabel;
  final List<ThreadMessage> messages;

  const MessageThread({
    required this.id,
    this.participantId,
    required this.participantName,
    required this.title,
    required this.subtitle,
    required this.unreadCount,
    required this.lastUpdatedLabel,
    required this.messages,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    final participantId = json['participant_id'].toString();
    final lastSentAt = DateTime.parse(json['last_sent_at'].toString());

    return MessageThread(
      id: participantId,
      participantId: participantId,
      participantName:
          json['participant_name']?.toString() ?? 'Community member',
      title: json['last_message']?.toString() ?? 'Message thread',
      subtitle: 'Community conversation',
      unreadCount: json['unread_count'] as int? ?? 0,
      lastUpdatedLabel: _formatTimestamp(lastSentAt),
      messages: const [],
    );
  }
}

class ThreadMessage {
  final String? id;
  final String text;
  final bool isMine;
  final String timestamp;
  final DateTime? sentAt;

  const ThreadMessage({
    this.id,
    required this.text,
    required this.isMine,
    required this.timestamp,
    this.sentAt,
  });

  factory ThreadMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final sentAt = DateTime.parse(json['sent_at'].toString());

    return ThreadMessage(
      id: json['id']?.toString(),
      text: json['content']?.toString() ?? '',
      isMine: json['sender_id'].toString() == currentUserId,
      timestamp: _formatTimestamp(sentAt),
      sentAt: sentAt,
    );
  }
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
