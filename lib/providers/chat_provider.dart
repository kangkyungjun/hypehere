import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chat_api_client.dart';
import '../services/chat_local_store.dart';

/// AI 멀티턴 채팅 상태 관리.
///
/// 전송 흐름(기존 포트폴리오 자문과 동일한 enqueue + 백오프 폴링):
///   1) 사용자 메시지를 낙관적으로 화면에 추가
///   2) 서버로 전송(POST) — 서버가 user턴 저장 + CHAT 큐 적재(history 동봉)
///   3) 대화 이력을 백오프 폴링하여 assistant 응답 도착을 감지 → 서버 이력으로 동기화
/// conversation_id는 앱에서 생성(즉시 스레드), 서버가 그대로 정본(SoT) 저장.
///
/// **로컬 캐시 정책 (2026-06-27 추가):**
/// - 서버=SoT 유지. 로컬은 빠른 표시/오프라인 캐시 용도(`ChatLocalStore`).
/// - 폴링 응답이 오면 즉시 sqflite에 영속화 → 앱 재실행 후에도 보임.
/// - 사용자가 한 대화를 폰에서 숨기면 hidden=1 (서버엔 보존). 머지 시 자동 필터.
/// - 한도 초과 시 가장 오래된 대화부터 자동 삭제 → `kLocalLimit` 키.
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatApiClient? api, ChatLocalStore? store})
      : _api = api ?? ChatApiClient(),
        _store = store ?? ChatLocalStore.instance;
  final ChatApiClient _api;
  final ChatLocalStore _store;

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

  // ── 로컬 캐시 한도 (SharedPreferences) ──
  /// 로컬에 보관할 최대 대화 수. 0 = 무제한.
  /// 기본 500건 ≈ 3MB(평균). 100/500/1000/0 중 사용자 선택 가능(설정 화면).
  static const int defaultLocalLimit = 500;
  static const _kLocalLimit = 'chat_local_limit';
  int _localLimit = defaultLocalLimit;
  int get localLimit => _localLimit;

  /// 새 대화 시작 (id 생성, 메시지 초기화).
  void startNew() {
    _conversationId = _generateId();
    _messages = [];
    _error = null;
    notifyListeners();
  }

  /// 기존 대화 로드 — 로컬 캐시 즉시 표시 후 서버 최신화로 덮어쓴다.
  Future<void> loadConversation(String id) async {
    _conversationId = id;
    _error = null;
    // 1) 로컬 즉시(빠른 진입감)
    try {
      final cached = await _store.messagesOf(id);
      if (cached.isNotEmpty) {
        _messages = cached;
        notifyListeners();
      }
    } catch (_) {/* 캐시 실패 무시 */}
    // 2) 서버 최신화
    try {
      final fresh = await _api.getMessages(id);
      _messages = fresh;
      // 서버 응답으로 로컬 갱신(SoT)
      if (fresh.isNotEmpty) {
        await _store.replaceConversation(id, fresh,
            maxConversations: _localLimit);
      }
    } catch (e) {
      // 서버 실패해도 로컬 캐시는 유지
      if (_messages.isEmpty) _error = e.toString();
    }
    notifyListeners();
  }

  /// 대화 목록 로드 — 로컬을 우선 보여주고 서버와 머지.
  ///
  /// 머지 규칙:
  ///  - 서버 목록을 기준으로 표시(서버=SoT).
  ///  - 단, 로컬에 hidden=1로 마킹된 대화 id는 제외("폰에서 안 보기").
  ///  - 서버에 없고 로컬에만 있는(아직 답변 폴링 전인 신규 대화 등)도 같이 표시.
  Future<void> loadConversations() async {
    _loadingConversations = true;
    notifyListeners();

    // 1) 로컬 캐시 즉시 표시
    try {
      _conversations = await _store.listConversations();
      notifyListeners();
    } catch (_) {/* ignore */}

    // 2) 서버 fetch + hidden id 조회는 각각 독립적으로 보호.
    //    로컬/네트워크 중 한쪽이 실패해도 다른 쪽 결과를 살린다.
    List<Conversation> server = const [];
    try {
      server = await _api.getConversations();
    } catch (_) {/* 서버 실패 시 로컬 캐시만 표시 */}
    Set<String> hidden = <String>{};
    try {
      hidden = await _store.hiddenConversationIds();
    } catch (_) {/* 캐시 미구성 환경(테스트 등)도 진행 */}

    if (server.isNotEmpty || hidden.isNotEmpty) {
      final localById = {for (final c in _conversations) c.id: c};
      final merged = <Conversation>[];
      final seen = <String>{};
      for (final c in server) {
        if (hidden.contains(c.id)) continue;
        merged.add(c);
        seen.add(c.id);
      }
      for (final c in localById.values) {
        if (seen.contains(c.id)) continue;
        if (hidden.contains(c.id)) continue;
        merged.add(c);
      }
      merged.sort((a, b) {
        final ax = a.updatedAt?.millisecondsSinceEpoch ?? 0;
        final bx = b.updatedAt?.millisecondsSinceEpoch ?? 0;
        return bx.compareTo(ax);
      });
      _conversations = merged;
    }

    _loadingConversations = false;
    notifyListeners();
  }

  /// 메시지 전송 + 응답 폴링.
  /// [category] : 추천 칩에서 호출할 때 전달(맥미니 컨텍스트 주입용). 자유입력은 null.
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
          // 로컬 캐시 영속화(앱 재실행 후에도 보임).
          // 실패는 조용히 무시(채팅 흐름 차단 금지).
          unawaitedPersist(convId, server);
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

  /// 화면 비차단 영속화. 실패는 디버그 로그만.
  void unawaitedPersist(String convId, List<ChatMessage> server) {
    _store
        .replaceConversation(convId, server, maxConversations: _localLimit)
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('chat cache persist failed: $e');
      }
    });
  }

  // ── 로컬 캐시 제어 (UI에서 호출) ──

  /// 한 대화를 폰에서 숨김(서버 보존). 다음 머지에서도 다시 안 나타남.
  Future<void> hideConversationLocally(String id) async {
    await _store.deleteConversationLocal(id);
    _conversations =
        _conversations.where((c) => c.id != id).toList(growable: false);
    if (_conversationId == id) {
      _conversationId = null;
      _messages = [];
    }
    notifyListeners();
  }

  /// 여러 대화 일괄 숨김.
  Future<void> hideConversationsLocally(Iterable<String> ids) async {
    final set = ids.toSet();
    for (final id in set) {
      await _store.deleteConversationLocal(id);
    }
    _conversations =
        _conversations.where((c) => !set.contains(c.id)).toList(growable: false);
    if (_conversationId != null && set.contains(_conversationId)) {
      _conversationId = null;
      _messages = [];
    }
    notifyListeners();
  }

  /// 로컬 캐시 전체 삭제(서버는 손대지 않음).
  Future<void> clearAllLocal() async {
    await _store.clearAll();
    _conversations = const [];
    notifyListeners();
  }

  /// 로컬 캐시 사용량 통계(설정 화면 표시용).
  /// 반환 `(visibleConversations, approxBytes)`.
  Future<({int conversations, int bytes})> localUsage() async {
    final c = await _store.visibleConversationCount();
    final b = await _store.approxStorageBytes();
    return (conversations: c, bytes: b);
  }

  /// 한도 변경 → 즉시 영속화 + (작아진 경우) FIFO 적용은 다음 저장 시 일어남.
  Future<void> setLocalLimit(int limit) async {
    _localLimit = limit < 0 ? 0 : limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLocalLimit, _localLimit);
    notifyListeners();
  }

  /// 한 대화의 메시지(공유/내보내기용) — 로컬 캐시 직접 조회.
  Future<List<ChatMessage>> messagesForExport(String id) =>
      _store.messagesOf(id);

  // ── 무료 쿼터 ──

  /// 쿼터 로드. 누적 차감 방식 — 자정 리셋 없음.
  /// 신규 설치(키 없음) → 0 → 무료 10/10으로 시작.
  /// 기존 사용자 → 마지막 저장값에서 이어감(상한 10 적용).
  Future<void> loadQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_kQuotaUsed) ?? 0;
    _quotaUsed = used.clamp(0, freeLimit);
    // 로컬 캐시 한도도 함께 로드
    _localLimit = prefs.getInt(_kLocalLimit) ?? defaultLocalLimit;
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
