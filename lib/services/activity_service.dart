import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// DAU/WAU 수집용 활동 핑.
///
/// 앱 포그라운드(시작/resume) 진입 시 `POST /api/v1/activity/ping` 1회.
/// - 로그인 상태에서만 전송(서버가 user_id로 집계, 익명은 대상 아님).
/// - `X-Platform` 헤더로 플랫폼 전달(서버 first-touch 집계).
/// - 클라 throttle(~30분)은 트래픽 절감용일 뿐, 정확성은 서버가 보장
///   (서버: PK(date,user_id) + ON CONFLICT DO NOTHING + 워커 seen-set).
/// - fire-and-forget: 실패해도 사용자 흐름에 영향 없음(다음 foreground 재시도).
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  static const Duration _throttle = Duration(minutes: 30);

  final AuthService _auth = AuthService();
  DateTime? _lastPingAt;
  bool _inFlight = false;

  /// 포그라운드 진입 시 호출. throttle·미로그인·중복요청은 조용히 스킵.
  Future<void> maybePing() async {
    if (_inFlight) return;
    final now = DateTime.now();
    if (_lastPingAt != null && now.difference(_lastPingAt!) < _throttle) {
      return;
    }

    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) return; // 비로그인 → 집계 대상 아님

    _inFlight = true;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/activity/ping'),
            headers: {'Authorization': 'Token $token', 'X-Platform': platform},
          )
          .timeout(const Duration(seconds: 8));
      // 성공(2xx)일 때만 throttle 시작 — 실패는 다음 foreground에서 재시도.
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _lastPingAt = now;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ActivityService] ping skipped: $e');
    } finally {
      _inFlight = false;
    }
  }
}
