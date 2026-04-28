import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pawnder_app/models/message_thread.dart';
import 'package:pawnder_app/services/api_client.dart';
import 'package:pawnder_app/services/auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MessageSocketEvent {
  final String type;
  final ThreadMessage? message;

  MessageSocketEvent({required this.type, this.message});
}

class MessageSocketService {
  factory MessageSocketService({
    ApiClient? apiClient,
    AuthService? authService,
  }) {
    _instance ??= MessageSocketService._internal(
      apiClient: apiClient,
      authService: authService,
    );
    return _instance!;
  }

  MessageSocketService._internal({
    ApiClient? apiClient,
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  static MessageSocketService? _instance;

  final AuthService _authService;
  final StreamController<MessageSocketEvent> _incomingController =
      StreamController<MessageSocketEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  String? _currentUserId;
  bool _isConnecting = false;

  Stream<MessageSocketEvent> get incomingEvents => _incomingController.stream;

  Stream<ThreadMessage> get incomingMessages => incomingEvents
      .where((event) => event.message != null)
      .map((event) => event.message!);

  Future<void> connect() async {
    if (_channel != null || _isConnecting) {
      return;
    }

    _isConnecting = true;
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final currentUser = await _authService.getCurrentUser();
      _currentUserId = currentUser.id;

      final uri = _buildSocketUri(token);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _channelSubscription = channel.stream.listen(
        _handleSocketEvent,
        onDone: _resetChannel,
        onError: (_) => _resetChannel(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _resetChannel();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _resetChannel();
  }

  Uri _buildSocketUri(String token) {
    final apiUri = Uri.parse(ApiClient.baseUrl);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';

    var path = apiUri.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final wsPath = '$path/messaging/ws';

    return apiUri.replace(
      scheme: scheme,
      path: wsPath.startsWith('/') ? wsPath : '/$wsPath',
      queryParameters: {'token': token},
    );
  }

  void _handleSocketEvent(dynamic event) {
    if (_currentUserId == null) {
      return;
    }

    try {
      final Map<String, dynamic> json = switch (event) {
        String value => jsonDecode(value) as Map<String, dynamic>,
        Map value => value.cast<String, dynamic>(),
        _ => <String, dynamic>{},
      };

      if (json.isEmpty) {
        return;
      }

      if (json.containsKey('type') && json['message'] is Map<String, dynamic>) {
        _incomingController.add(
          MessageSocketEvent(
            type: json['type']?.toString() ?? 'message_updated',
            message: ThreadMessage.fromJson(
              json['message'] as Map<String, dynamic>,
              currentUserId: _currentUserId!,
            ),
          ),
        );
        return;
      }

      _incomingController.add(
        MessageSocketEvent(
          type: 'message_created',
          message: ThreadMessage.fromJson(json, currentUserId: _currentUserId!),
        ),
      );
    } catch (error) {
      debugPrint('WebSocket message parse failed: $error');
    }
  }

  void _resetChannel() {
    _channel = null;
    _channelSubscription = null;
  }
}