import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/admin_dashboard.dart';
import 'auth_service.dart';

/// 어드민 대시보드 API (Master 전용 — 서버가 403으로 최종 게이트).
/// 모든 호출 Django Token 인증.
class AdminApiClient {
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  final http.Client _httpClient;
  final AuthService _authService;

  AdminApiClient({http.Client? httpClient, AuthService? authService})
    : _httpClient = httpClient ?? http.Client(),
      _authService = authService ?? AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        debugMessage: 'Admin requires login',
      );
    }
    return {'Authorization': 'Token $token'};
  }

  Future<http.Response> _get(String path, {Map<String, String>? params}) async {
    final headers = await _headers();
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: params?.isNotEmpty == true ? params : null);
    return _httpClient
        .get(uri, headers: headers)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Admin request timeout'),
        );
  }

  Future<AdminSummary> getSummary() async {
    final res = await _get('/api/v1/admin/dashboard/summary');
    if (res.statusCode == 200) {
      return AdminSummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        statusCode: res.statusCode,
      );
    }
    throw ApiException(ApiErrorCode.serverError, statusCode: res.statusCode);
  }

  Future<List<AdminUserPoint>> getUsersSeries({String range = '30d'}) async {
    final res = await _get(
      '/api/v1/admin/dashboard/users',
      params: {'range': range},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => AdminUserPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(
        ApiErrorCode.loginRequired,
        statusCode: res.statusCode,
      );
    }
    throw ApiException(ApiErrorCode.serverError, statusCode: res.statusCode);
  }

  void dispose() => _httpClient.close();
}
