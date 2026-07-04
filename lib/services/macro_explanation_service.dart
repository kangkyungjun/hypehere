import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'auth_service.dart';

/// 거시 지표(VIX 등) AI 변동성 설명 서비스.
///
/// 흐름:
///  1) [request] — 서버에 캐시 hit 우선 요청. hit이면 즉시 done. miss면 request_id 받고 pending.
///  2) miss인 경우 [poll]로 ~10초 백오프 폴링 — assistant ingest 도착하면 done 또는 error.
///
/// 로컬 캐시(SharedPreferences)는 같은 시간 버킷 내 재진입 시 서버 호출 없이 즉시 반환.
class MacroExplanationService {
  MacroExplanationService({http.Client? httpClient, AuthService? authService})
      : _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService();

  final http.Client _httpClient;
  final AuthService _authService;

  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  static bool _tzInitialized = false;
  static void _ensureTzInit() {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    _tzInitialized = true;
  }

  /// ET(미국 동부) 자정 기준의 일 버킷 — 서버 정책과 일치.
  /// VIX 등 미국 시장 지표는 ET 거래일 단위로 캐싱.
  static String _todayBucketKeyEt({DateTime? now}) {
    _ensureTzInit();
    final et = tz.getLocation('America/New_York');
    final etNow = tz.TZDateTime.from(now ?? DateTime.now(), et);
    final ymd =
        '${etNow.year.toString().padLeft(4, '0')}-${etNow.month.toString().padLeft(2, '0')}-${etNow.day.toString().padLeft(2, '0')}';
    return ymd;
  }

  static String _cacheKey(String code, String lang, {DateTime? now}) {
    final ymd = _todayBucketKeyEt(now: now);
    return 'macro_ai_${code.toUpperCase()}_${lang}_${ymd}_et';
  }

  /// 로컬 캐시 hit이면 즉시 결과 반환, 아니면 null.
  Future<MacroExplanation?> readLocalCache(String code, String lang) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(code, lang));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return MacroExplanation.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalCache(
    String code,
    String lang,
    MacroExplanation e,
  ) async {
    if (e.isError || e.content == null || e.content!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(code, lang),
      jsonEncode(e.toJson()),
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      if (token != null) 'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }

  /// 서버에 설명 요청. force=true면 캐시 무시.
  /// [recentValues] = [{date: 'YYYY-MM-DD', value: 18.5}, ...] 오름차순.
  Future<MacroExplanation> request({
    required String indicatorCode,
    required String lang,
    required List<Map<String, Object>> recentValues,
    bool force = false,
  }) async {
    final code = indicatorCode.toUpperCase();
    final uri = Uri.parse('$_baseUrl/api/v1/macro/$code/explain');
    final body = jsonEncode({
      'lang': lang,
      'recent_values': recentValues,
      'force': force,
    });
    final res = await _httpClient
        .post(uri, headers: await _authHeaders(), body: body)
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw MacroExplanationException(
        'request failed: ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final e = MacroExplanation.fromJson(j);
    if (e.status == 'done' && !e.isError) {
      await _writeLocalCache(code, lang, e);
    }
    return e;
  }

  /// 큐 결과 폴링. 백오프 1s→2s→3s→4s→… 최대 [maxWait] 동안.
  /// pending 동안은 계속 폴링, done/error 시 반환. 시간 초과 시 마지막 응답 반환.
  Future<MacroExplanation> poll(
    int requestId, {
    Duration maxWait = const Duration(seconds: 30),
  }) async {
    final start = DateTime.now();
    int waitMs = 1000;
    MacroExplanation? last;
    while (DateTime.now().difference(start) < maxWait) {
      final uri = Uri.parse(
          '$_baseUrl/api/v1/macro/explain-status/$requestId');
      final res = await _httpClient
          .get(uri, headers: await _authHeaders())
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw MacroExplanationException(
          'poll failed: ${res.statusCode}',
          statusCode: res.statusCode,
        );
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      last = MacroExplanation.fromJson(j);
      if (last.status == 'done' || last.status == 'error') {
        if (last.status == 'done' && !last.isError && last.content != null) {
          await _writeLocalCache(
              last.indicatorCode, last.lang, last);
        }
        return last;
      }
      await Future<void>.delayed(Duration(milliseconds: waitMs));
      if (waitMs < 4000) waitMs += 1000;
    }
    return last ??
        MacroExplanation(
          status: 'error',
          indicatorCode: '',
          lang: '',
          isError: true,
        );
  }

  void dispose() => _httpClient.close();
}

class MacroExplanation {
  final String status; // 'done' | 'pending' | 'error'
  final String indicatorCode;
  final String lang;
  final String? content;
  final bool isError;
  final int? requestId;
  final bool cached;
  final String? updatedAt;

  const MacroExplanation({
    required this.status,
    required this.indicatorCode,
    required this.lang,
    this.content,
    this.isError = false,
    this.requestId,
    this.cached = false,
    this.updatedAt,
  });

  factory MacroExplanation.fromJson(Map<String, dynamic> j) => MacroExplanation(
        status: j['status'] as String? ?? 'pending',
        indicatorCode: j['indicator_code'] as String? ?? '',
        lang: j['lang'] as String? ?? 'en',
        content: j['content'] as String?,
        isError: j['is_error'] == true,
        requestId: (j['request_id'] as num?)?.toInt(),
        cached: j['cached'] == true,
        updatedAt: j['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'indicator_code': indicatorCode,
        'lang': lang,
        if (content != null) 'content': content,
        'is_error': isError,
        if (requestId != null) 'request_id': requestId,
        'cached': cached,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class MacroExplanationException implements Exception {
  final String message;
  final int? statusCode;
  MacroExplanationException(this.message, {this.statusCode});
  @override
  String toString() => 'MacroExplanationException($statusCode): $message';
}
