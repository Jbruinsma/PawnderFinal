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
        'reply_to_message_id': replyToMessageId,
      },
    );

    return ThreadMessage.fromJson(
      response.data ?? const {},
      currentUserId: currentUser.id,
    );
  }

  Future<void> deleteThread(String participantId) async {
    await _apiClient.delete<void>('/messages/threads/$participantId');
  }

  Future<ThreadMessage> unsendMessage(String messageId) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '/messages/$messageId',
    );

    return ThreadMessage.fromJson(
      response.data ?? const {},
      currentUserId: currentUser.id,
    );
  }

  Future<ThreadMessage> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/messages/$messageId/reaction',
      data: {'emoji': emoji},
    );

    return ThreadMessage.fromJson(
      response.data ?? const {},
      currentUserId: currentUser.id,
    );
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
