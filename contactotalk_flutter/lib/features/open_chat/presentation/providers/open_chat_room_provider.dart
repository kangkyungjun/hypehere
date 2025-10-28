/// 오픈 채팅방 Provider
///
/// 개별 채팅방의 메시지 로드, WebSocket 연결, 메시지 전송 기능 제공
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:contactotalk_flutter/core/models/open_chat_room.dart';
import 'package:contactotalk_flutter/core/models/open_chat_message.dart';
import 'package:contactotalk_flutter/features/open_chat/presentation/providers/open_chat_state.dart';
import 'package:contactotalk_flutter/core/api/api_client.dart';
import 'package:contactotalk_flutter/core/providers/auth_provider.dart';
import 'package:contactotalk_flutter/core/api/endpoint_manager.dart';

/// 오픈 채팅방 StateNotifier
class OpenChatRoomNotifier extends StateNotifier<OpenChatRoomState> {
  final ApiClient _apiClient;
  final int roomId;
  final Ref ref;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  int _messagePage = 1;

  OpenChatRoomNotifier({
    required this.roomId,
    required ApiClient apiClient,
    required this.ref,
  })  : _apiClient = apiClient,
        super(const OpenChatRoomState.initial());

  /// 채팅방 및 메시지 로드
  Future<void> loadRoom() async {
    state = const OpenChatRoomState.loading();

    try {
      // 채팅방 정보 로드
      final roomResponse = await _apiClient.get('/api/chat/open-chat/$roomId/');
      final room = OpenChatRoom.fromJson(roomResponse.data as Map<String, dynamic>);

      // 메시지 목록 로드
      final messagesResponse = await _apiClient.get(
        '/api/chat/open-chat/$roomId/messages/',
        queryParameters: {'page': _messagePage},
      );

      final List<dynamic> messagesJson = messagesResponse.data['results'] as List;
      final messages = messagesJson
          .map((json) => OpenChatMessage.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // 최신 메시지가 아래로 가도록 역순 정렬

      final hasMore = messagesResponse.data['next'] != null;

      state = OpenChatRoomState.loaded(
        room: room,
        messages: messages,
        hasMore: hasMore,
      );

      // WebSocket 연결
      _connectWebSocket();
    } catch (e) {
      state = OpenChatRoomState.error(e.toString());
    }
  }

  /// 이전 메시지 로드 (페이징)
  Future<void> loadMoreMessages() async {
    state.maybeWhen(
      loaded: (room, messages, hasMore, isLoadingMore) async {
        if (!hasMore || isLoadingMore) return;

        state = OpenChatRoomState.loaded(
          room: room,
          messages: messages,
          hasMore: hasMore,
          isLoadingMore: true,
        );

        _messagePage++;

        try {
          final response = await _apiClient.get(
            '/api/chat/open-chat/$roomId/messages/',
            queryParameters: {'page': _messagePage},
          );

          final List<dynamic> messagesJson = response.data['results'] as List;
          final newMessages = messagesJson
              .map((json) => OpenChatMessage.fromJson(json as Map<String, dynamic>))
              .toList()
              .reversed
              .toList();

          final hasMorePages = response.data['next'] != null;

          state = OpenChatRoomState.loaded(
            room: room,
            messages: [...newMessages, ...messages],
            hasMore: hasMorePages,
            isLoadingMore: false,
          );
        } catch (e) {
          _messagePage--;
          state = OpenChatRoomState.loaded(
            room: room,
            messages: messages,
            hasMore: hasMore,
            isLoadingMore: false,
          );
        }
      },
      orElse: () {},
    );
  }

  /// WebSocket 연결 (AWS 우선, 자동 fallback)
  void _connectWebSocket() {
    final authState = ref.read(authProvider);
    String? token;

    if (authState.isAuthenticated && authState.accessToken != null) {
      token = authState.accessToken;
    }

    if (token == null) {
      return;
    }

    // EndpointManager에서 WebSocket URL 목록 가져오기
    final endpointManager = EndpointManager();
    final wsUrls = endpointManager.getWsEndpoints();

    // 우선순위에 따라 WebSocket 연결 시도
    _tryConnectWebSocket(wsUrls, 0, token);
  }

  /// WebSocket 연결을 순차적으로 시도
  void _tryConnectWebSocket(List<String> wsUrls, int index, String token) {
    if (index >= wsUrls.length) {
      print('❌ 모든 WebSocket 서버 연결 실패');
      return;
    }

    try {
      final wsUrl = Uri.parse('${wsUrls[index]}/ws/open-chat/$roomId/?token=$token');
      print('🔌 WebSocket 연결 시도 (${index + 1}/${wsUrls.length}): ${wsUrls[index]}');

      _channel = WebSocketChannel.connect(wsUrl);

      _channelSubscription = _channel!.stream.listen(
        (data) {
          print('✅ WebSocket 연결 성공: ${wsUrls[index]}');
          _handleWebSocketMessage(data as String);
        },
        onError: (error) {
          print('⚠️ WebSocket 오류 (${wsUrls[index]}): $error');
          // 다음 URL로 재시도
          _tryConnectWebSocket(wsUrls, index + 1, token);
        },
        onDone: () => _handleWebSocketDisconnect(),
      );
    } catch (e) {
      print('❌ WebSocket 연결 실패 (${wsUrls[index]}): $e');
      // 다음 URL로 재시도
      _tryConnectWebSocket(wsUrls, index + 1, token);
    }
  }

  /// WebSocket 메시지 처리
  void _handleWebSocketMessage(String data) {
    state.maybeWhen(
      loaded: (room, messages, hasMore, isLoadingMore) {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final messageType = json['type'] as String?;

          if (messageType == 'chat_message') {
            final messageData = json['message'] as Map<String, dynamic>;
            final newMessage = OpenChatMessage.fromJson(messageData);

            state = OpenChatRoomState.loaded(
              room: room,
              messages: [...messages, newMessage],
              hasMore: hasMore,
              isLoadingMore: false,
            );
          }
        } catch (e) {
          print('WebSocket 메시지 파싱 실패: $e');
        }
      },
      orElse: () {},
    );
  }

  /// WebSocket 에러 처리
  void _handleWebSocketError(dynamic error) {
    print('WebSocket 에러: $error');
    // 에러 발생 시 재연결 시도
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _connectWebSocket();
    });
  }

  /// WebSocket 연결 종료 처리
  void _handleWebSocketDisconnect() {
    print('WebSocket 연결 종료');
  }

  /// 메시지 전송
  Future<bool> sendMessage(String content) async {
    return state.maybeWhen(
      loaded: (room, messages, hasMore, isLoadingMore) async {
        try {
          // WebSocket으로 메시지 전송
          if (_channel != null) {
            _channel!.sink.add(jsonEncode({
              'type': 'chat_message',
              'message': content,
            }));
            return true;
          }

          // WebSocket이 연결되지 않았으면 REST API로 전송
          await _apiClient.post(
            '/api/chat/open-chat/$roomId/messages/',
            data: {'content': content},
          );

          // 메시지 목록 새로고침
          await loadRoom();

          return true;
        } catch (e) {
          return false;
        }
      },
      orElse: () => false,
    );
  }

  /// 채팅방 참여
  Future<bool> joinRoom() async {
    try {
      await _apiClient.post('/api/chat/open-chat/$roomId/join/');
      await loadRoom(); // 참여 후 채팅방 정보 새로고침
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 채팅방 나가기
  Future<bool> leaveRoom() async {
    try {
      await _apiClient.post('/api/chat/open-chat/$roomId/leave/');
      _disconnectWebSocket();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// WebSocket 연결 종료
  void _disconnectWebSocket() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    super.dispose();
  }
}

/// 오픈 채팅방 Provider 팩토리
final openChatRoomProvider = StateNotifierProvider.family<
    OpenChatRoomNotifier,
    OpenChatRoomState,
    int>((ref, roomId) {
  final apiClient = ref.watch(apiClientProvider);
  return OpenChatRoomNotifier(
    roomId: roomId,
    apiClient: apiClient,
    ref: ref,
  );
});
