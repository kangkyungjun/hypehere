/// Endpoint Manager
///
/// AWS 우선 엔드포인트 관리 및 자동 fallback 시스템
library;

import 'package:dio/dio.dart';

/// 스마트 엔드포인트 매니저
///
/// 여러 URL을 우선순위에 따라 시도하고 성공한 엔드포인트를 캐싱합니다.
/// 우선순위: AWS (프로덕션) → localhost → 127.0.0.1
class EndpointManager {
  static final EndpointManager _instance = EndpointManager._internal();
  factory EndpointManager() => _instance;
  EndpointManager._internal();

  /// 캐싱된 HTTP 엔드포인트
  String? _cachedHttpEndpoint;

  /// 캐싱된 WebSocket 엔드포인트
  String? _cachedWsEndpoint;

  /// HTTP 엔드포인트 URL 목록 (우선순위 순서: AWS → localhost → 127.0.0.1)
  final List<String> _httpEndpoints = [
    'http://43.200.129.55:8000', // 1순위: AWS 프로덕션
    'http://localhost:8000',      // 2순위: 로컬 개발
    'http://127.0.0.1:8000',      // 3순위: 로컬 IP
  ];

  /// WebSocket 엔드포인트 URL 목록 (우선순위 순서: AWS → localhost → 127.0.0.1)
  final List<String> _wsEndpoints = [
    'ws://43.200.129.55:8001', // 1순위: AWS 프로덕션
    'ws://localhost:8001',      // 2순위: 로컬 개발
    'ws://127.0.0.1:8001',      // 3순위: 로컬 IP
  ];

  /// HTTP 엔드포인트 가져오기 (캐시된 값 또는 자동 탐색)
  Future<String> getHttpEndpoint() async {
    // 캐시된 엔드포인트가 있으면 반환
    if (_cachedHttpEndpoint != null) {
      return _cachedHttpEndpoint!;
    }

    // 각 URL을 순서대로 시도
    for (final endpoint in _httpEndpoints) {
      if (await _testHttpEndpoint(endpoint)) {
        _cachedHttpEndpoint = endpoint;
        print('✅ HTTP 엔드포인트 발견: $endpoint');
        return endpoint;
      }
    }

    // 모든 엔드포인트가 실패하면 기본값(AWS) 반환
    print('⚠️ 모든 HTTP 엔드포인트 실패, 기본값(AWS) 사용');
    _cachedHttpEndpoint = _httpEndpoints.first;
    return _cachedHttpEndpoint!;
  }

  /// WebSocket 엔드포인트 가져오기 (캐시된 값 반환)
  String getWsEndpoint() {
    // HTTP 엔드포인트와 매칭되는 WebSocket 엔드포인트 반환
    if (_cachedHttpEndpoint != null) {
      final index = _httpEndpoints.indexOf(_cachedHttpEndpoint!);
      if (index != -1) {
        return _wsEndpoints[index];
      }
    }

    // 기본값: AWS WebSocket
    return _wsEndpoints.first;
  }

  /// WebSocket 엔드포인트 목록 가져오기 (fallback용)
  List<String> getWsEndpoints() {
    return List.unmodifiable(_wsEndpoints);
  }

  /// HTTP 엔드포인트 연결 테스트
  Future<bool> _testHttpEndpoint(String endpoint) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));

      // /api/accounts/stats/ 엔드포인트로 간단한 GET 요청 (인증 불필요)
      final response = await dio.get('$endpoint/api/accounts/stats/');

      // 200번대 응답이면 성공
      return response.statusCode != null &&
             response.statusCode! >= 200 &&
             response.statusCode! < 300;
    } catch (e) {
      // 연결 실패
      return false;
    }
  }

  /// 캐시 초기화 (재연결 시도용)
  void resetCache() {
    _cachedHttpEndpoint = null;
    _cachedWsEndpoint = null;
    print('🔄 엔드포인트 캐시 초기화됨');
  }

  /// 현재 사용 중인 엔드포인트 정보
  Map<String, String?> getCurrentEndpoints() {
    return {
      'http': _cachedHttpEndpoint,
      'ws': getWsEndpoint(),
    };
  }
}
