import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 광고 로드 실패를 백엔드에 보고 → 서버가 owner/매니저에게 알림(FCM) + owner에게 이메일.
///
/// 스팸 방지: **앱 세션당 1회만** 보고한다 (광고 실패는 짧은 간격으로 반복 발생).
/// fire-and-forget: 보고 실패(엔드포인트 미배포/네트워크 등)는 조용히 무시한다.
class AdFailureReporter {
  AdFailureReporter._();

  static bool _reportedThisSession = false;

  /// 세션당 1회만 백엔드로 광고 실패를 보고한다.
  static Future<void> report(String error, {String adUnit = 'rewarded'}) async {
    if (_reportedThisSession) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    _reportedThisSession = true;

    try {
      final base = dotenv.env['AUTH_API_BASE_URL'] ??
          'http://43.201.45.60:8000/api/accounts';

      await http
          .post(
            Uri.parse('$base/ops/ad-failure/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'error': error,
              'platform': Platform.isAndroid ? 'android' : 'ios',
              'ad_unit': adUnit,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // 운영 알림용 fire-and-forget: 보고 실패는 무시
    }
  }
}
