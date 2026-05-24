import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community/community_user.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// 인증 상태 전역 관리 Provider
///
/// ChangeNotifier를 통해 로그인/로그아웃 상태를 앱 전체에 반응형으로 전파합니다.
///
/// 주요 기능:
/// - 로그인 상태 추적 (isLoggedIn)
/// - 현재 사용자 정보 캐싱 (currentUser)
/// - 자동 토큰 검증 및 갱신
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  /// 현재 로그인 상태
  bool _isLoggedIn = false;

  /// 현재 로그인한 사용자 정보 (null이면 비로그인)
  CommunityUser? _currentUser;

  /// 상태 확인 중 여부
  bool _isLoading = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  CommunityUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // ========================================
  // MarketLens 권한 체크 메서드
  // ========================================

  /// Master 권한 체크 (오너)
  bool get isMaster => _currentUser?.isMaster ?? false;

  /// Manager 이상 권한 체크 (Manager, Master)
  bool get isManagerOrAbove => _currentUser?.isManagerOrAbove ?? false;

  /// Gold 이상 권한 체크 (Gold, Manager, Master)
  bool get isGoldOrAbove => _currentUser?.isGoldOrAbove ?? false;

  /// 광고 제거 권한 (Gold 이상)
  bool get hasAdFreeAccess => _currentUser?.hasAdFreeAccess ?? false;

  /// 광고 면제 여부 (중앙 판단)
  /// - Gold(role='gold'): 항상 광고 면제 (결제/수동 승급 혜택)
  /// - Manager/Master: adsEnabled 토글로 제어 (테스트용)
  /// - Regular/비로그인: 항상 광고 대상
  bool get shouldHideAds {
    if (isManagerOrAbove) return !_adsEnabled;
    return _currentUser?.role == 'gold';
  }

  /// 모든 게시글 삭제 권한 (Manager 이상)
  bool get canDeleteAnyPost => _currentUser?.canDeleteAnyPost ?? false;

  /// Gold로 승급 권한 (Manager 이상)
  bool get canPromoteToGold => _currentUser?.canPromoteToGold ?? false;

  /// Manager로 승급 권한 (Master만)
  bool get canPromoteToManager => _currentUser?.canPromoteToManager ?? false;

  /// 사용자 관리 권한 (Manager 이상)
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;

  /// 역할 표시 이름 (한글)
  String get roleDisplayName => _currentUser?.roleDisplayName ?? 'Guest';

  /// 현재 사용자 역할
  String get userRole => _currentUser?.role ?? 'guest';

  // ========================================
  // 광고 제어 (Manager/Master 전용)
  // ========================================

  /// 광고 표시 여부 (기본: true)
  bool _adsEnabled = true;
  bool get adsEnabled => _adsEnabled;

  /// 광고 토글 설정
  Future<void> setAdsEnabled(bool enabled) async {
    _adsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_enabled', enabled);
    notifyListeners();
  }

  /// 광고 설정 로드 (SharedPreferences에서)
  Future<void> _loadAdPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _adsEnabled = prefs.getBool('ads_enabled') ?? true;
  }

  /// 초기화 시 자동으로 로그인 상태 확인
  AuthProvider() {
    _loadAdPreference();
    checkLoginStatus();
  }

  /// 저장된 토큰으로 로그인 상태 확인
  ///
  /// - 토큰이 있으면 서버에서 사용자 정보 조회
  /// - 토큰이 만료되었으면 자동 갱신 시도
  /// - 갱신 실패 시 로그아웃 상태로 전환
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _authService.isLoggedIn();

      if (hasToken) {
        // 토큰이 있으면 사용자 정보 조회 (자동 토큰 갱신 포함)
        final user = await _authService.getCurrentUser();
        _currentUser = user;
        _isLoggedIn = true;

        // 앱 재시작 시 FCM 토큰 재등록 (기존 세션 유지 사용자)
        NotificationService().requestPermissionAndRegister();
      } else {
        _currentUser = null;
        _isLoggedIn = false;
      }
    } catch (e) {
      // 토큰이 완전히 만료되었거나 서버 오류
      debugPrint('[AuthProvider] Login status check failed: $e');
      _currentUser = null;
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그인 처리
  ///
  /// - 성공 시 사용자 정보 저장 + 로그인 상태 업데이트
  /// - 실패 시 예외 throw (화면에서 처리)
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _isLoggedIn = true;

      // RevenueCat logIn은 main.dart의 authListener에서 통합 처리

      // FCM 토큰 등록 + watchlist 구독 동기화
      NotificationService().requestPermissionAndRegister();
      if (user.watchlistTickers != null && user.watchlistTickers!.isNotEmpty) {
        NotificationService().syncWatchlistSubscriptions(user.watchlistTickers!).catchError((e) {
          debugPrint('syncWatchlistSubscriptions failed: $e');
        });
      }

      debugPrint('[AuthProvider] Login successful: ${user.nickname}');
    } catch (e) {
      debugPrint('[AuthProvider] Login failed: $e');
      rethrow;  // 화면에서 에러 메시지 표시할 수 있도록 재throw
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 회원가입 처리
  ///
  /// - 성공 시 자동으로 로그인 상태로 전환
  /// - 실패 시 예외 throw (화면에서 처리)
  Future<void> register({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.register(
        email: email,
        nickname: nickname,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      _currentUser = user;
      _isLoggedIn = true;

      // FCM 토큰 등록
      NotificationService().requestPermissionAndRegister();

      debugPrint('[AuthProvider] Registration successful: ${user.nickname}');
    } catch (e) {
      debugPrint('[AuthProvider] Registration failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithVerification({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
    required String code,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.registerWithVerification(
        email: email,
        nickname: nickname,
        password: password,
        passwordConfirm: passwordConfirm,
        code: code,
      );

      _currentUser = user;
      _isLoggedIn = true;

      // FCM 토큰 등록
      NotificationService().requestPermissionAndRegister();

      debugPrint('[AuthProvider] Registration with verification successful: ${user.nickname}');
    } catch (e) {
      debugPrint('[AuthProvider] Registration with verification failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그아웃 처리
  ///
  /// - 서버 토큰 삭제
  /// - 로컬 상태 초기화
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // RevenueCat logOut은 main.dart의 authListener에서 통합 처리

      // FCM 토큰 비활성화 + 스트림 구독 정리 (로그아웃 전에 실행)
      final notifService = NotificationService();
      await notifService.deactivateToken();
      await notifService.dispose();

      await _authService.logout();

      _currentUser = null;
      _isLoggedIn = false;

      debugPrint('[AuthProvider] Logout successful');
    } catch (e) {
      // 로그아웃은 실패해도 로컬 상태 초기화
      debugPrint('[AuthProvider] Logout warning: $e');
      _currentUser = null;
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 회원탈퇴 처리
  Future<void> deleteAccount({String? reason}) async {
    if (!_isLoggedIn || _currentUser == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    _isLoading = true;
    notifyListeners();

    try {
      // FCM 정리
      final notifService = NotificationService();
      await notifService.deactivateToken();
      await notifService.dispose();

      await _authService.deleteAccount(
        email: _currentUser!.email,
        nickname: _currentUser!.nickname,
        reason: reason,
      );

      _currentUser = null;
      _isLoggedIn = false;

      debugPrint('[AuthProvider] Account withdrawal requested');
    } catch (e) {
      debugPrint('[AuthProvider] Account withdrawal failed: $e');
      // Keep user logged in — server didn't confirm deletion
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 정보 새로고침
  ///
  /// - 프로필 수정 후 호출하여 최신 정보 반영
  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn) return;

    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
      notifyListeners();

      debugPrint('[AuthProvider] User info refreshed');
    } catch (e) {
      debugPrint('[AuthProvider] Refresh failed: $e');
      // 실패해도 기존 정보 유지
    }
  }

  /// 프로필 업데이트
  ///
  /// - 닉네임, 소개글, 프로필 사진 수정
  /// - 성공 시 사용자 정보 자동 업데이트
  Future<void> updateProfile({
    String? nickname,
    String? bio,
    File? profilePicture,
  }) async {
    if (!_isLoggedIn) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(
        nickname: nickname,
        bio: bio,
        profilePicture: profilePicture,
      );

      _currentUser = updatedUser;
      debugPrint('[AuthProvider] Profile updated: ${updatedUser.nickname}');
    } catch (e) {
      debugPrint('[AuthProvider] Profile update failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
