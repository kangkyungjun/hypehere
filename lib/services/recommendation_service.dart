import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/recommendation.dart';

/// 추천종목 조회 서비스 (Phase C).
///
/// Django(`AUTH_API_BASE_URL`) + Token 인증을 사용한다 — 투자 프로필 서비스와 동일.
/// 엔드포인트: GET {base}/recommendations/?date=YYYY-MM-DD
class RecommendationService {
  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';
  static const _storage = FlutterSecureStorage();
  static const _timeout = Duration(seconds: 15);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// 본인 추천종목 조회. date 미지정 시 서버가 최신 날짜를 반환.
  /// 비로그인이거나 데이터 없으면 빈 결과(또는 null)를 반환 — graceful.
  Future<RecommendationResult?> getRecommendations({DateTime? date}) async {
    final token = await _getToken();
    if (token == null) return null;

    var url = '$_baseUrl/recommendations/';
    if (date != null) {
      final d = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      url = '$url?date=$d';
    }

    final http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'Recommendations GET');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'Recommendations GET timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return RecommendationResult.fromJson(data as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      return null;
    } else if (response.statusCode == 404) {
      return const RecommendationResult(date: null, style: null, items: []);
    } else {
      debugPrint('[RecommendationService] GET failed: ${response.statusCode}');
      return null;
    }
  }
}
