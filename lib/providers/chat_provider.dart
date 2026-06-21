import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chat_api_client.dart';

/// AI 멀티턴 채팅 상태 관리.
///
/// 전송 흐름(기존 포트폴리오 자문과 동일한 enqueue + 백오프 폴링):
///   1) 사용자 메시지를 낙관적으로 화면에 추가
///   2) 서버로 전송(POST) — 서버가 user턴 저장 + CHAT 큐 적재(history 동봉)
///   3) 대화 이력을 백오프 폴링하여 assistant 응답 도착을 감지 → 서버 이력으로 동기화
/// conversation_id는 앱에서 생성(즉시 스레드), 서버가 그대로 정본(SoT) 저장.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatApiClient? api}) : _api = api ?? ChatApiClient();
  final ChatApiClient _api;

  String? _conversationId;
  List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _error;
  List<Conversation> _conversations = [];
  bool _loadingConversations = false;

  String? get conversationId => _conversationId;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isEmpty => _messages.isEmpty;
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get loadingConversations => _loadingConversations;

  // ── 누적 무료 쿼터 (광고 게이트, B) ──
  /// 무료 메시지 절대 한도(10). 자정 리셋 없음 — 누적 차감.
  /// 광고 시청 시 사용 카운터를 +5만큼 되돌려 다시 무료처럼 동작(상한 10 유지).
  /// 표시 형식은 항상 `{남은수}/10`.
  static const int freeLimit = 10;

  /// 누적 사용한 메시지 수(광고 시청 시 감소). 항상 0..freeLimit 범위.
  int _quotaUsed = 0;
  static const _kQuotaUsed = 'chat_quota_used';

  int get quotaUsed => _quotaUsed;
  int get quotaRemaining => (freeLimit - _quotaUsed).clamp(0, freeLimit);
  bool get quotaExhausted => quotaRemaining <= 0;

  /// 새 대화 시작 (id 생성, 메시지 초기화).
  void startNew() {
    _conversationId = _generateId();
    _messages = [];
    _error = null;
    notifyListeners();
  }

  /// 기존 대화 로드 (과거조회).
  Future<void> loadConversation(String id) async {
    _conversationId = id;
    _error = null;
    notifyListeners();
    try {
      _messages = await _api.getMessages(id);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// 대화 목록 로드 (이전 대화 조회). 실패는 조용히 무시(서버 미배포 등).
  Future<void> loadConversations() async {
    _loadingConversations = true;
    notifyListeners();
    try {
      _conversations = await _api.getConversations();
    } catch (_) {
      // 목록 조회 실패는 채팅 흐름을 막지 않도록 무시
    }
    _loadingConversations = false;
    notifyListeners();
  }

  /// 메시지 전송 + 응답 폴링.
  /// [category] : 추천 칩 탭에서 호출할 때 전달(맥미니 컨텍스트 주입용). 자유입력은 null.
  Future<void> sendMessage(
    String text, {
    String lang = 'en',
    String? category,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;
    _conversationId ??= _generateId();
    final convId = _conversationId!;

    _error = null;
    _isSending = true;
    // 낙관적 user 말풍선
    _messages = [..._messages, ChatMessage(role: 'user', content: trimmed)];
    final baselineAssistant = _messages.where((m) => m.isAssistant).length;
    notifyListeners();

    try {
      await _api.sendMessage(
        conversationId: convId,
        message: trimmed,
        lang: lang,
        category: category,
      );

      // 백오프 폴링 (~50s) — assistant 턴이 늘면 서버 이력으로 동기화
      const delays = [2, 3, 4, 5, 5, 5, 6, 6, 7, 7];
      for (final d in delays) {
        await Future.delayed(Duration(seconds: d));
        final server = await _api.getMessages(convId);
        final assistantCount = server.where((m) => m.isAssistant).length;
        if (assistantCount > baselineAssistant) {
          _messages = server; // 서버가 정본
          _isSending = false;
          // 마지막 assistant 턴이 에러 플래그면 사용자에게 안내(UI는 isError 메시지 자체로 표시).
          final last = server.lastWhere(
            (m) => m.isAssistant,
            orElse: () =>
                const ChatMessage(role: 'assistant', content: ''),
          );
          if (last.isError) {
            _error = 'assistant_failed';
          }
          notifyListeners();
          return;
        }
      }
      _error = 'timeout'; // 응답 지연 — UI에서 안내
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 쿼터 로드. 누적 차감 방식 — 자정 리셋 없음.
  /// 신규 설치(키 없음) → 0 → 무료 10/10으로 시작.
  /// 기존 사용자 → 마지막 저장값에서 이어감(상한 10 적용).
  Future<void> loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_kQuotaUsed) ?? 0;
    _quotaUsed = used.clamp(0, freeLimit);
    notifyListeners();
  }

  /// 무료 메시지 1개 소비.
  Future<void> consumeQuota() async {
    _quotaUsed = (_quotaUsed + 1).clamp(0, freeLimit);
    notifyListeners();
    await _persistQuota();
  }

  /// 보상형 광고 시청 보상으로 사용 카운터 되돌림(절대 한도 10 유지).
  /// 광고 1회 → 메시지 [n]개 충전(기본 +5). bonus 슬롯 없이 used를 감소시킴.
  Future<void> grantQuotaBonus([int n = 5]) async {
    _quotaUsed = (_quotaUsed - n).clamp(0, freeLimit);
    notifyListeners();
    await _persistQuota();
  }

  Future<void> _persistQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kQuotaUsed, _quotaUsed);
  }

  String _generateId() {
    final r = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rnd =
        List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
    return 'c_$ts$rnd';
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
