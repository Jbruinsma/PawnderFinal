import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:pawnder_app/services/profile_photo_service.dart';

class MessageService {
  MessageService({ApiClient? apiClient, AuthService? authService})
    : _apiClient = apiClient ?? ApiClient(),
      _authService = authService ?? AuthService(),
      _profilePhotoService = ProfilePhotoService();

  final ApiClient _apiClient;
  final AuthService _authService;
  final ProfilePhotoService _profilePhotoService;

  Future<List<MessageThread>> getThreads() async {
    final response = await _apiClient.get<List<dynamic>>('/messages/threads');

    final rawThreads = (response.data ?? const [])
        .map((json) => MessageThread.fromJson(json as Map<String, dynamic>))
        .toList();

    final enrichedThreads = <MessageThread>[];
    for (final thread in rawThreads) {
      final participantId = thread.participantId;
      final avatarPath = participantId == null
          ? null
          : await _profilePhotoService.getPhotoPath(participantId);
      enrichedThreads.add(
        MessageThread(
          id: thread.id,
          participantId: thread.participantId,
          participantName: thread.participantName,
          participantAvatarPath: avatarPath,
          title: thread.title,
          subtitle: thread.subtitle,
          unreadCount: thread.unreadCount,
          lastSenderId: thread.lastSenderId,
          lastUpdatedLabel: thread.lastUpdatedLabel,
          messages: thread.messages,
        ),
      );
    }
    return enrichedThreads;
  }

  Future<List<ThreadMessage>> getMessages(String participantId) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.get<List<dynamic>>(
      '/messages/threads/$participantId',
    );

    return (response.data ?? const [])
        .map(
          (json) => ThreadMessage.fromJson(
            json as Map<String, dynamic>,
            currentUserId: currentUser.id,
          ),
        )
        .toList();
  }

  Future<ThreadMessage> sendMessage({
    required String receiverId,
    required String content,
    String? replyToMessageId,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/messages',
      data: {
        'receiver_id': receiverId,
        'content': content,
      },
    );

    return ThreadMessage.fromJson(
      response.data ?? const {},
      currentUserId: currentUser.id,
    );
  }

  Future<void> deleteThread(String participantId) async {
    return;
  }

  Future<ThreadMessage> unsendMessage(ThreadMessage message) async {
    return message.copyWith(text: '', isUnsent: true, replyPreview: null);
  }

  Future<ThreadMessage> toggleReaction({
    required ThreadMessage message,
    required String emoji,
  }) async {
    final trimmed = emoji.trim();
    if (trimmed.isEmpty) {
      return message;
    }

    final reactions = [...message.reactions];
    final existingIndex = reactions.indexWhere((r) => r.emoji == trimmed);

    if (existingIndex == -1) {
      reactions.add(
        MessageReactionSummary(emoji: trimmed, count: 1, youReacted: true),
      );
    } else {
      final existing = reactions[existingIndex];
      if (existing.youReacted) {
        if (existing.count <= 1) {
          reactions.removeAt(existingIndex);
        } else {
          reactions[existingIndex] = MessageReactionSummary(
            emoji: trimmed,
            count: existing.count - 1,
            youReacted: false,
          );
        }
      } else {
        reactions[existingIndex] = MessageReactionSummary(
          emoji: trimmed,
          count: existing.count + 1,
          youReacted: true,
        );
      }
    }

    return message.copyWith(reactions: reactions);
  }

  String messageForError(Object error) {
    return _apiClient.messageForError(error);
  }

  MessageThread buildDirectThread({
    required String participantId,
    required String participantName,
    required String title,
    String subtitle = 'Direct message',
  }) {
    return MessageThread.direct(
      participantId: participantId,
      participantName: participantName,
      title: title,
      subtitle: subtitle,
    );
  }
}
