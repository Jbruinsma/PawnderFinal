class MessageThread {
  final String id;
  final String participantName;
  final String title;
  final String subtitle;
  final int unreadCount;
  final String lastUpdatedLabel;
  final List<ThreadMessage> messages;

  const MessageThread({
    required this.id,
    required this.participantName,
    required this.title,
    required this.subtitle,
    required this.unreadCount,
    required this.lastUpdatedLabel,
    required this.messages,
  });
}

class ThreadMessage {
  final String text;
  final bool isMine;
  final String timestamp;

  const ThreadMessage({
    required this.text,
    required this.isMine,
    required this.timestamp,
  });
}
