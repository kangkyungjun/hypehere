/// ContactoTalk API Client
///
/// Dio 기반 HTTP 클라이언트를 제공합니다.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:contactotalk_flutter/config/constants.dart';
import 'package:contactotalk_flutter/core/api/api_exceptions.dart';
import 'package:contactotalk_flutter/core/api/api_interceptors.dart';
import 'package:contactotalk_flutter/core/api/endpoint_manager.dart';

/// API 클라이언트 싱글톤 클래스
///
/// AWS Django 백엔드와 통신하기 위한 HTTP 클라이언트입니다.
class ApiClient {
  // 싱글톤 인스턴스
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  /// Dio 인스턴스
  late final Dio _dio;

  /// Secure Storage 인스턴스 (JWT 토큰 저장용)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// API 클라이언트 초기화 여부
  bool _initialized = false;

  /// API 클라이언트 초기화
  ///
  /// 앱 시작 시 한 번만 호출해야 합니다.
  /// EndpointManager가 자동으로 연결 가능한 서버를 찾습니다.
  Future<void> initialize() async {
    if (_initialized) return;

    // EndpointManager를 통해 최적의 엔드포인트 찾기
    final endpointManager = EndpointManager();
    final baseUrl = await endpointManager.getHttpEndpoint();

    print('🌐 ApiClient 초기화: $baseUrl');

    _dio = Dio(
      BaseOptions(
        // 자동 선택된 백엔드 URL (AWS 우선)
        baseUrl: baseUrl,

        // 타임아웃 설정
        connectTimeout: Duration(milliseconds: apiTimeoutMs),
        sendTimeout: Duration(milliseconds: apiTimeoutMs),
        receiveTimeout: Duration(milliseconds: apiTimeoutMs),

        // 기본 헤더
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        // 응답 타입
        responseType: ResponseType.json,
      ),
    );

    // 인터셉터 추가
    _dio.interceptors.addAll([
      // 1. 인증 인터셉터 (JWT 토큰 자동 추가)
      AuthInterceptor(
        secureStorage: _secureStorage,
        dio: _dio,
      ),

      // 2. 로깅 인터셉터 (디버그 모드)
      if (isDebugMode) LoggingInterceptor(),

      // 3. 재시도 인터셉터 (네트워크 오류 시 자동 재시도)
      RetryInterceptor(
        maxRetries: 3,
        retryDelay: const Duration(seconds: 1),
      ),
    ]);

    _initialized = true;
  }

  /// Dio 인스턴스 가져오기
  Dio get dio {
    if (!_initialized) {
      throw StateError('ApiClient가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _dio;
  }

  // ============================================================================
  // HTTP 메서드 래퍼 (예외 처리 포함)
  // ============================================================================

  /// GET 요청
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST 요청
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT 요청
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PATCH 요청
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE 요청
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================================
  // 파일 업로드/다운로드
  // ============================================================================

  /// 파일 업로드 (multipart/form-data)
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileFieldName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fileFieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 파일 다운로드
  Future<void> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================================
  // 예외 처리
  // ============================================================================

  /// DioException을 ApiException으로 변환
  ApiException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        // HTTP 상태 코드 기반 예외 생성
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          // 서버에서 보낸 에러 메시지 추출
          String? message;
          dynamic data;

          if (error.response?.data is Map<String, dynamic>) {
            final responseData = error.response?.data as Map<String, dynamic>;

            // Django REST Framework 에러 형식
            if (responseData.containsKey('detail')) {
              message = responseData['detail'] as String?;
            } else if (responseData.containsKey('message')) {
              message = responseData['message'] as String?;
            } else if (responseData.containsKey('error')) {
              message = responseData['error'] as String?;
            }

            data = responseData;
          }

          return createExceptionFromStatusCode(
            statusCode: statusCode,
            message: message,
            data: data,
            originalError: error,
          );
        }

        return UnknownException(originalError: error);

      case DioExceptionType.cancel:
        return const UnknownException(message: '요청이 취소되었습니다');

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      default:
        return UnknownException(originalError: error);
    }
  }

  // ============================================================================
  // 토큰 관리 (외부에서 사용)
  // ============================================================================

  /// 액세스 토큰 저장
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: accessTokenKey, value: token);
  }

  /// 리프레시 토큰 저장
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: refreshTokenKey, value: token);
  }

  /// 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: accessTokenKey);
  }

  /// 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: refreshTokenKey);
  }

  /// 모든 토큰 삭제 (로그아웃)
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: accessTokenKey);
    await _secureStorage.delete(key: refreshTokenKey);
  }

  /// 사용자 정보 저장
  Future<void> saveUserInfo(String userInfoJson) async {
    await _secureStorage.write(key: userInfoKey, value: userInfoJson);
  }

  /// 사용자 정보 가져오기
  Future<String?> getUserInfo() async {
    return await _secureStorage.read(key: userInfoKey);
  }

  /// 모든 저장된 데이터 삭제 (완전 로그아웃)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
