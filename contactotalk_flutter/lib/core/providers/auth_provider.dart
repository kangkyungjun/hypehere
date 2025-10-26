/// ContactoTalk 인증 Provider
///
/// Riverpod을 사용한 인증 상태 관리
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contactotalk_flutter/config/constants.dart';
import 'package:contactotalk_flutter/core/api/api_client.dart';
import 'package:contactotalk_flutter/core/api/api_exceptions.dart';
import 'package:contactotalk_flutter/core/models/user.dart';
import 'package:contactotalk_flutter/core/models/auth_state.dart';

/// AuthProvider의 StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState.initial()) {
    // 앱 시작 시 저장된 인증 정보 확인
    _checkSavedAuth();
  }

  /// 저장된 인증 정보 확인
  Future<void> _checkSavedAuth() async {
    state = const AuthState.loading();

    try {
      // Secure Storage에서 토큰 확인
      final accessToken = await _apiClient.getAccessToken();
      final refreshToken = await _apiClient.getRefreshToken();
      final userInfoJson = await _apiClient.getUserInfo();

      if (accessToken != null &&
          refreshToken != null &&
          userInfoJson != null) {
        // 저장된 사용자 정보 복원
        final userJson = jsonDecode(userInfoJson) as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        state = AuthState.authenticated(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// 로그인
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      // 로그인 API 호출
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': username,
          'password': password,
        },
      );

      // 토큰 및 사용자 정보 추출 (Django 백엔드는 tokens 객체 안에 토큰을 반환)
      final tokens = response['tokens'] as Map<String, dynamic>;
      final accessToken = tokens['access'] as String;
      final refreshToken = tokens['refresh'] as String;
      final userJson = response['user'] as Map<String, dynamic>;

      // User 객체 생성
      final user = User.fromJson(userJson);

      // 토큰 저장
      await _apiClient.saveAccessToken(accessToken);
      await _apiClient.saveRefreshToken(refreshToken);
      await _apiClient.saveUserInfo(jsonEncode(userJson));

      // 상태 업데이트
      state = AuthState.authenticated(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on ValidationException catch (e) {
      // 유효성 검증 오류 (400)
      String errorMessage = e.message;

      // Django REST Framework 에러 형식 처리
      if (e.errors != null && e.errors!.isNotEmpty) {
        final errors = e.errors!;

        if (errors.containsKey('non_field_errors')) {
          final nonFieldErrors = errors['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            errorMessage = nonFieldErrors.first.toString();
          }
        } else if (errors.containsKey('detail')) {
          errorMessage = errors['detail'].toString();
        } else {
          // 첫 번째 에러 메시지 사용
          errorMessage = errors.values.first.toString();
        }
      }

      state = AuthState.unauthenticated(errorMessage: errorMessage);
    } on UnauthorizedException catch (e) {
      // 인증 오류 (401)
      state = AuthState.unauthenticated(
        errorMessage: e.message,
      );
    } on ApiException catch (e) {
      // 기타 API 오류
      state = AuthState.unauthenticated(
        errorMessage: e.message,
      );
    } catch (e) {
      // 알 수 없는 오류
      state = AuthState.unauthenticated(
        errorMessage: '로그인 중 오류가 발생했습니다',
      );
    }
  }

  /// 회원가입
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String nickname,
    String? gender,
    String? countryCode,
  }) async {
    state = const AuthState.loading();

    try {
      // 회원가입 API 호출
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'nickname': nickname,
          if (gender != null) 'gender': gender,
          if (countryCode != null) 'country_code': countryCode,
        },
      );

      // 회원가입 후 자동 로그인
      // Django 백엔드가 회원가입 시 토큰을 반환하는 경우 (tokens 객체 안에 토큰이 있음)
      if (response.containsKey('tokens')) {
        final tokens = response['tokens'] as Map<String, dynamic>;
        final accessToken = tokens['access'] as String;
        final refreshToken = tokens['refresh'] as String;
        final userJson = response['user'] as Map<String, dynamic>;

        final user = User.fromJson(userJson);

        await _apiClient.saveAccessToken(accessToken);
        await _apiClient.saveRefreshToken(refreshToken);
        await _apiClient.saveUserInfo(jsonEncode(userJson));

        state = AuthState.authenticated(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        // 회원가입 성공, 로그인 필요
        state = const AuthState.unauthenticated();
      }
    } on ValidationException catch (e) {
      // 유효성 검증 오류 (400)
      String errorMessage = e.message;

      if (e.errors != null && e.errors!.isNotEmpty) {
        final errors = e.errors!;

        // 각 필드별 에러 메시지 조합
        final errorMessages = <String>[];

        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errorMessages.add('$key: ${value.first}');
          } else {
            errorMessages.add('$key: $value');
          }
        });

        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }

      state = AuthState.unauthenticated(errorMessage: errorMessage);
    } on ApiException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    } catch (e) {
      state = AuthState.unauthenticated(
        errorMessage: '회원가입 중 오류가 발생했습니다',
      );
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청 (선택사항)
      try {
        await _apiClient.post(ApiEndpoints.logout);
      } catch (e) {
        // 로그아웃 API 실패해도 로컬 로그아웃은 진행
      }

      // 로컬 저장소에서 토큰 및 사용자 정보 삭제
      await _apiClient.clearAll();

      // 상태 업데이트
      state = const AuthState.unauthenticated();
    } catch (e) {
      // 로그아웃 실패 처리
      state = AuthState.unauthenticated(
        errorMessage: '로그아웃 중 오류가 발생했습니다',
      );
    }
  }

  /// 사용자 정보 갱신
  Future<void> refreshUserInfo() async {
    if (!state.isAuthenticated) return;

    try {
      // 프로필 API 호출
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      final user = User.fromJson(response);

      // 사용자 정보 저장
      await _apiClient.saveUserInfo(jsonEncode(response));

      // 상태 업데이트
      state = state.copyWith(user: user);
    } on UnauthorizedException {
      // 인증 실패 시 로그아웃
      await logout();
    } catch (e) {
      // 에러 발생 시 무시 (기존 사용자 정보 유지)
    }
  }

  /// 사용자 정보 업데이트
  Future<void> updateUserInfo({
    String? nickname,
    String? gender,
    String? countryCode,
    String? bio,
  }) async {
    if (!state.isAuthenticated) return;

    try {
      // 프로필 수정 API 호출
      final response = await _apiClient.patch<Map<String, dynamic>>(
        ApiEndpoints.profile,
        data: {
          if (nickname != null) 'nickname': nickname,
          if (gender != null) 'gender': gender,
          if (countryCode != null) 'country_code': countryCode,
          if (bio != null) 'bio': bio,
        },
      );

      final user = User.fromJson(response);

      // 사용자 정보 저장
      await _apiClient.saveUserInfo(jsonEncode(response));

      // 상태 업데이트
      state = state.copyWith(user: user);
    } on ValidationException catch (e) {
      throw Exception(e.message);
    } on ApiException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('사용자 정보 업데이트 중 오류가 발생했습니다');
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: '');
  }
}

/// Auth Provider (전역 인스턴스)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});

/// 현재 사용자 Provider (편의 Provider)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// 인증 여부 Provider (편의 Provider)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});
