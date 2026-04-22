import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/auth_service.dart';

class MessageService {
  MessageService({ApiClient? apiClient, AuthService? authService})
    : _apiClient = apiClient ?? ApiClient(),
      _authService = authService ?? AuthService();

  final ApiClient _apiClient;
  final AuthService _authService;

  Future<List<MessageThread>> getThreads() async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/v1/messages/threads',
    );

    return (response.data ?? const [])
        .map((json) => MessageThread.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ThreadMessage>> getMessages(String participantId) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/v1/messages/threads/$participantId',
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
  }) async {
    final currentUser = await _authService.getCurrentUser();
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/v1/messages',
      data: {'receiver_id': receiverId, 'content': content},
    );

    return ThreadMessage.fromJson(
      response.data ?? const {},
      currentUserId: currentUser.id,
    );
  }

  String messageForError(Object error) {
    return _apiClient.messageForError(error);
  }
}
