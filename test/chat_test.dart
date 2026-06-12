import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marketlens/exceptions/api_error_codes.dart';
import 'package:marketlens/exceptions/api_exception.dart';
import 'package:marketlens/services/auth_service.dart';
import 'package:marketlens/services/chat_api_client.dart';
import 'package:marketlens/providers/chat_provider.dart';

/// 토큰을 고정 반환하는 가짜 AuthService (secure storage 미접근).
class _FakeAuth extends AuthService {
  @override
  Future<String?> getAccessToken() async => 'test-token';
}

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: '');
  });

  ChatApiClient api202() => ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((r) async => http.Response('', 202)),
      );

  group('ChatApiClient', () {
    test('sendMessage — 올바른 body/헤더로 POST하고 202 수락', () async {
      late http.Request captured;
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response('', 202);
        }),
      );

      await api.sendMessage(conversationId: 'c1', message: '안녕', lang: 'ko');

      expect(captured.method, 'POST');
      expect(captured.url.path, contains('/api/v1/chat/messages'));
      expect(captured.headers['Authorization'], 'Token test-token');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['conversation_id'], 'c1');
      expect(body['message'], '안녕');
      expect(body['lang'], 'ko');
    });

    test('getMessages — {messages:[...]} 파싱', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => _json({
              'messages': [
                {'role': 'user', 'content': 'AAPL 어때?', 'turn_index': 1},
                {'role': 'assistant', 'content': '72점, 매수권고', 'turn_index': 2},
              ]
            })),
      );

      final msgs = await api.getMessages('c1');
      expect(msgs.length, 2);
      expect(msgs[0].isUser, true);
      expect(msgs[1].isAssistant, true);
      expect(msgs[1].content, '72점, 매수권고');
      expect(msgs[1].turnIndex, 2);
    });

    test('getMessages — bare 배열(top-level array) 응답도 파싱', () async {
      // 서버가 {messages:[...]} 대신 최상위 배열을 줘도 계약상 허용.
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => _json([
              {'role': 'user', 'content': 'hi'},
              {'role': 'assistant', 'content': 'hello'},
            ])),
      );
      final msgs = await api.getMessages('c1');
      expect(msgs.length, 2);
      expect(msgs.first.isUser, true);
      expect(msgs.last.isAssistant, true);
    });

    test('sendMessage — 404(브리지 미배포 현재 상태) → ApiException', () async {
      // 서버 배포 전 실제 라이브 상태: /api/v1/chat/* 가 404.
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => http.Response('', 404)),
      );
      expect(
        () => api.sendMessage(conversationId: 'c1', message: 'hi', lang: 'en'),
        throwsA(isA<ApiException>()),
      );
    });

    test('sendMessage — 401 → sessionExpired 코드', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => http.Response('', 401)),
      );
      await expectLater(
        () => api.sendMessage(conversationId: 'c1', message: 'hi', lang: 'en'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.sessionExpired)),
      );
    });

    test('getMessages — 401 → sessionExpired 코드', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => http.Response('', 401)),
      );
      await expectLater(
        () => api.getMessages('c1'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiErrorCode.sessionExpired)),
      );
    });
  });

  group('ChatProvider', () {
    test('sendMessage — 낙관적 user 추가 → 폴링 → assistant 응답 동기화', () async {
      int getCalls = 0;
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async {
          if (req.method == 'POST') return http.Response('', 202);
          getCalls++;
          // 폴링 GET: user + assistant (응답 준비됨)
          return _json({
            'messages': [
              {'role': 'user', 'content': '그럼 언제 팔아?'},
              {'role': 'assistant', 'content': '타깃가 도달 시 분할 매도를 권합니다'},
            ]
          });
        }),
      );
      final provider = ChatProvider(api: api);

      await provider.sendMessage('그럼 언제 팔아?', lang: 'ko');

      expect(provider.isSending, false);
      expect(provider.error, isNull);
      expect(provider.messages.length, 2);
      expect(provider.messages.last.isAssistant, true);
      expect(provider.messages.last.content, contains('분할 매도'));
      expect(getCalls, greaterThanOrEqualTo(1));
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('sendMessage — 전송 실패 시 error 노출 + 낙관적 user 유지', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async {
          if (req.method == 'POST') return http.Response('', 500);
          return _json({'messages': []});
        }),
      );
      final provider = ChatProvider(api: api);

      await provider.sendMessage('hi');

      expect(provider.isSending, false);
      expect(provider.error, isNotNull);
      expect(provider.messages.any((m) => m.isUser), true);
    });

    test('conversationId — 첫 전송 시 자동 생성', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async {
          if (req.method == 'POST') return http.Response('', 202);
          return _json({
            'messages': [
              {'role': 'user', 'content': 'hi'},
              {'role': 'assistant', 'content': 'hello'},
            ]
          });
        }),
      );
      final provider = ChatProvider(api: api);
      expect(provider.conversationId, isNull);

      await provider.sendMessage('hi');
      expect(provider.conversationId, isNotNull);
      expect(provider.conversationId!.startsWith('c_'), true);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('loadConversations — 목록 파싱', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => _json({
              'conversations': [
                {'conversation_id': 'c1', 'title': '애플 분석', 'last_message': '...'},
                {'conversation_id': 'c2', 'last_message': '테슬라?'},
              ]
            })),
      );
      final p = ChatProvider(api: api);
      await p.loadConversations();
      expect(p.conversations.length, 2);
      expect(p.conversations[0].id, 'c1');
      expect(p.conversations[0].title, '애플 분석');
      expect(p.loadingConversations, false);
    });

    test('loadConversations — 실패 시 조용히(목록 빈 채 에러 없음)', () async {
      final api = ChatApiClient(
        authService: _FakeAuth(),
        httpClient: MockClient((req) async => http.Response('', 500)),
      );
      final p = ChatProvider(api: api);
      await p.loadConversations();
      expect(p.conversations, isEmpty);
      expect(p.loadingConversations, false);
    });
  });

  group('ChatProvider 무료 쿼터(광고 게이트)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('초기 쿼터 = freeLimit, 소비 시 감소', () async {
      final p = ChatProvider(api: api202());
      await p.loadQuota();
      expect(p.quotaRemaining, ChatProvider.freeLimit);
      expect(p.quotaExhausted, false);
      await p.consumeQuota();
      expect(p.quotaRemaining, ChatProvider.freeLimit - 1);
    });

    test('소진 후 보상형 보너스(+5)로 리필', () async {
      final p = ChatProvider(api: api202());
      await p.loadQuota();
      for (var i = 0; i < ChatProvider.freeLimit; i++) {
        await p.consumeQuota();
      }
      expect(p.quotaExhausted, true);
      await p.grantQuotaBonus(5);
      expect(p.quotaExhausted, false);
      expect(p.quotaRemaining, 5);
    });

    test('영속화 — 새 인스턴스가 사용량 복원', () async {
      final p1 = ChatProvider(api: api202());
      await p1.loadQuota();
      await p1.consumeQuota();
      await p1.consumeQuota();

      final p2 = ChatProvider(api: api202());
      await p2.loadQuota();
      expect(p2.quotaUsed, 2);
    });
  });
}
