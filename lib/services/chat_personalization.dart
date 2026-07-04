import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/chat_suggestions.dart';

/// AI 채팅 개인화 저장소.
///
/// 두 가지를 로컬(SharedPreferences)에 보관한다:
///  1) 접속 인사("대화를 걸어주는" 멘트) 마지막 노출 시각 → 2시간 쿨다운
///  2) 사용자가 누른 예시 질문의 **카테고리 관심도**(누적 카운트) + **탭 로그**
///     → 추천 질문을 관심사에 맞게 가중하고, 추후 서버 동기화로 맞춤 콘텐츠에 활용
///
/// 정적 헬퍼로 두어 Provider 등록 없이 어디서나 읽고 쓸 수 있다.
class ChatPersonalization {
  ChatPersonalization._();

  static const _kGreetLast = 'chat_greet_last_ms';
  static const _kGreetMode = 'chat_greet_cooldown_mode'; // off | 2h | daily
  static const _kInterest = 'chat_interest_v1'; // JSON {category: count}
  static const _kTapLog = 'chat_tap_log_v1'; // JSON [{id, cat, t}], 최근 300개
  static const _tapLogCap = 300;

  /// 접속 인사 쿨다운 — 기본값(2시간). 사용자 설정에서 끄기/2시간/하루1회 선택.
  static const Duration greetCooldown = Duration(hours: 2);

  /// 현재 쿨다운 모드 로드. 미설정 시 기본 [GreetCooldownMode.twoHours].
  static Future<GreetCooldownMode> loadGreetMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _modeFromWire(prefs.getString(_kGreetMode));
  }

  /// 쿨다운 모드 저장.
  static Future<void> saveGreetMode(GreetCooldownMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGreetMode, mode.wire);
  }

  /// 모드에 따라 인사 노출 여부 판단.
  ///   - off    → 항상 false (인사 없음)
  ///   - 2h     → 마지막 인사 후 2시간 경과
  ///   - daily  → 마지막 인사가 오늘(로컬 자정 기준)이 아니면 true
  static Future<bool> shouldGreet({DateTime? now}) async {
    final mode = await loadGreetMode();
    if (mode == GreetCooldownMode.off) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kGreetLast);
    if (lastMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final ref = now ?? DateTime.now();
    if (mode == GreetCooldownMode.daily) {
      // '오늘'(로컬 자정 기준) 첫 진입이면 통과.
      final sameDay = last.year == ref.year &&
          last.month == ref.month &&
          last.day == ref.day;
      return !sameDay;
    }
    return ref.difference(last) >= greetCooldown;
  }

  /// 인사를 노출했음을 기록(쿨다운 시작).
  static Future<void> markGreeted({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kGreetLast,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// 카테고리별 관심도 카운트.
  static Future<Map<String, int>> loadInterest() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kInterest);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// 예시 질문 탭 기록: 카테고리 관심도 +1, 탭 로그 적재(상한 유지).
  /// 반환값은 갱신된 관심도 맵(화면이 즉시 반영할 수 있게).
  static Future<Map<String, int>> recordTap(
    ChatSuggestion s, {
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) 관심도 카운트
    final interest = await loadInterest();
    interest[s.category] = (interest[s.category] ?? 0) + 1;
    await prefs.setString(_kInterest, jsonEncode(interest));

    // 2) 탭 로그(최근 N개만 유지) — 추후 서버 동기화/분석용 원천 데이터
    final log = _loadTapLogRaw(prefs);
    log.add({
      'id': s.id,
      'cat': s.category,
      't': (now ?? DateTime.now()).millisecondsSinceEpoch,
    });
    if (log.length > _tapLogCap) {
      log.removeRange(0, log.length - _tapLogCap);
    }
    await prefs.setString(_kTapLog, jsonEncode(log));

    return interest;
  }

  /// 저장된 탭 로그(원천 데이터). 서버 동기화 전 보관용.
  static Future<List<Map<String, dynamic>>> loadTapLog() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadTapLogRaw(prefs);
  }

  static List<Map<String, dynamic>> _loadTapLogRaw(SharedPreferences prefs) {
    final raw = prefs.getString(_kTapLog);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static GreetCooldownMode _modeFromWire(String? w) {
    switch (w) {
      case 'off':
        return GreetCooldownMode.off;
      case 'daily':
        return GreetCooldownMode.daily;
      case '2h':
      default:
        return GreetCooldownMode.twoHours;
    }
  }
}

/// AI 인사 쿨다운 모드.
enum GreetCooldownMode { off, twoHours, daily }

extension GreetCooldownModeX on GreetCooldownMode {
  String get wire {
    switch (this) {
      case GreetCooldownMode.off:
        return 'off';
      case GreetCooldownMode.twoHours:
        return '2h';
      case GreetCooldownMode.daily:
        return 'daily';
    }
  }
}
