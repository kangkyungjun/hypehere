import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

/// 광고 로드 실패를 백엔드에 보고 → 서버가 owner/매니저에게 알림(FCM) + owner에게 이메일.
///
/// 스팸 방지: **adUnit별로 세션당 1회만** 보고한다 (광고 실패는 짧은 간격으로 반복 발생).
/// fire-and-forget: 보고 실패(엔드포인트 미배포/네트워크 등)는 조용히 무시한다.
///
/// 보고 페이로드(서버가 NO_FILL 등을 필터링할 수 있도록 코드 분리):
///   - error_code: 0=INTERNAL, 1=INVALID_REQUEST, 2=NETWORK, 3=NO_FILL, 8=APP_ID_MISSING ...
///   - error_domain: "com.google.android.gms.ads" 등
///   - error_message: SDK 메시지
///   - platform: android|ios
///   - ad_unit: rewarded|interstitial|app_open|banner
///   - app_version: 빌드 시 --dart-define=APP_VERSION=... 로 주입 (없으면 빈 문자열)
class AdFailureReporter {
  AdFailureReporter._();

  static const String _appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '');

  static final Set<String> _reportedAdUnitsThisSession = <String>{};

  /// adUnit별 세션당 1회만 백엔드로 광고 실패를 보고한다.
  static Future<void> reportLoadAdError(
    LoadAdError error, {
    required String adUnit,
  }) {
    return _send(
      code: error.code,
      domain: error.domain,
      message: error.message,
      adUnit: adUnit,
    );
  }

  /// 문자열 에러용 호환 진입점 (LoadAdError가 아닌 곳에서 사용).
  static Future<void> report(String error, {String adUnit = 'rewarded'}) {
    return _send(code: null, domain: '', message: error, adUnit: adUnit);
  }

  static Future<void> _send({
    required int? code,
    required String domain,
    required String message,
    required String adUnit,
  }) async {
    if (_reportedAdUnitsThisSession.contains(adUnit)) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    _reportedAdUnitsThisSession.add(adUnit);

    try {
      final base = dotenv.env['AUTH_API_BASE_URL'] ??
          'http://43.201.45.60:8000/api/accounts';

      await http
          .post(
            Uri.parse('$base/ops/ad-failure/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'error': message,
              'error_code': code,
              'error_domain': domain,
              'error_message': message,
              'platform': Platform.isAndroid ? 'android' : 'ios',
              'ad_unit': adUnit,
              'app_version': _appVersion,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // 운영 알림용 fire-and-forget: 보고 실패는 무시
    }
  }
}
