import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

/// AI 멀티턴 채팅 API 클라이언트 (FastAPI:8001).
///
/// 합의 계약(SoT=서버, C-하이브리드 — 서버가 큐 적재 시 history 동봉):
///   POST /api/v1/chat/messages                     — 사용자 메시지 전송(enqueue)
///   GET  /api/v1/chat/conversations/{id}/messages  — 대화 이력(폴링/과거조회)
///   GET  /api/v1/chat/conversations                — 대화 목록
/// 모두 Django Token 인증. base는 PortfolioApiClient와 동일(API_BASE_URL).
class ChatApiClient {
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  final http.Client _httpClient;
  final AuthService _authService;

  ChatApiClient({http.Client? httpClient, AuthService? authService})
      : _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired,
          debugMessage: 'Chat requires login');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  /// 사용자 메시지 전송 — 서버가 user턴 저장(정본) + CHAT 큐 적재.
  /// [category] : 추천 칩에서 보낼 때만 지정(맥미니가 카테고리별 컨텍스트 주입에 사용).
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    required String lang,
    String? category,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/api/v1/chat/messages');
    final body = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message,
      'lang': lang,
    };
    if (category != null && category.isNotEmpty) {
      body['category'] = category;
    }
    final response = await _httpClient
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Chat send timeout'));
    // 200/201(동기 ack) 또는 202(큐 적재) 모두 수락
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 202) {
      if (response.statusCode == 401) {
        throw ApiException(ApiErrorCode.sessionExpired,
            statusCode: 401, debugMessage: 'chat send');
      }
      throw ApiException(ApiErrorCode.genericError,
          statusCode: response.statusCode, debugMessage: 'chat send');
    }
  }

  /// 대화 이력 조회 (폴링/과거조회). 시간순 메시지 리스트.
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '$_baseUrl/api/v1/chat/conversations/$conversationId/messages');
    final response = await _httpClient.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Chat history timeout'));
    if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.sessionExpired,
          statusCode: 401, debugMessage: 'chat history');
    }
    if (response.statusCode != 200) {
      throw ApiException(ApiErrorCode.genericError,
          statusCode: response.statusCode, debugMessage: 'chat history');
    }
    final body = jsonDecode(response.body);
    final list = (body is Map ? body['messages'] : body) as List? ?? const [];
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 대화 목록 조회.
  Future<List<Conversation>> getConversations() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/api/v1/chat/conversations');
    final response = await _httpClient.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Chat list timeout'));
    if (response.statusCode != 200) {
      throw ApiException(ApiErrorCode.genericError,
          statusCode: response.statusCode, debugMessage: 'chat list');
    }
    final body = jsonDecode(response.body);
    final list =
        (body is Map ? body['conversations'] : body) as List? ?? const [];
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _httpClient.close();
}
