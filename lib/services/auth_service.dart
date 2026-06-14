import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/community/community_user.dart';

class AuthService {
  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';
  static const _storage = FlutterSecureStorage();
  static const _timeout = Duration(seconds: 15);

  static const String _tokenKey = 'auth_token';

  // Get stored token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Clear token (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Register new user
  Future<CommunityUser> register({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'nickname': nickname,
          'password': password,
          'password_confirm': passwordConfirm,
        }),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Register');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Register timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final body = _parseResponseBody(response);

    if (response.statusCode == 201) {
      // Registration returns {user: {...}, token: "...", message: "..."}
      await _saveToken(body['token'] as String);
      return CommunityUser.fromJson(body['user'] as Map<String, dynamic>);
    } else {
      throw _extractApiException(response.statusCode, body);
    }
  }

  // Register with verification (atomic: verify code + register in one call)
  Future<CommunityUser> registerWithVerification({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
    required String code,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/register-with-verification/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'nickname': nickname,
          'password': password,
          'password_confirm': passwordConfirm,
          'code': code,
        }),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Register');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Register timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final body = _parseResponseBody(response);

    if (response.statusCode == 201) {
      await _saveToken(body['token'] as String);
      return CommunityUser.fromJson(body['user'] as Map<String, dynamic>);
    } else {
      throw _extractApiException(response.statusCode, body);
    }
  }

  // Login
  Future<CommunityUser> login({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Login');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Login timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final body = _parseResponseBody(response);

    if (response.statusCode == 200) {
      // Login returns {user: {...}, token: "...", message: "..."}
      await _saveToken(body['token'] as String);
      return CommunityUser.fromJson(body['user'] as Map<String, dynamic>);
    } else if (response.statusCode == 403) {
      // 이메일 미인증 체크
      if (body is Map && body['email_not_verified'] == true) {
        throw ApiException(ApiErrorCode.emailNotVerified, statusCode: 403);
      }
      throw _extractApiException(response.statusCode, body);
    } else if (response.statusCode == 401 || response.statusCode == 400) {
      throw ApiException(ApiErrorCode.invalidCredentials, statusCode: response.statusCode);
    } else {
      throw _extractApiException(response.statusCode, body);
    }
  }

  // Get current user info
  Future<CommunityUser> getCurrentUser() async {
    final token = await getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('$_baseUrl/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Get user');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Get user timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      final data = _parseResponseBody(response);
      return CommunityUser.fromJson(data);
    } else if (response.statusCode == 401) {
      await clearTokens();
      throw ApiException(ApiErrorCode.sessionExpired, statusCode: 401);
    } else {
      throw ApiException(ApiErrorCode.cannotLoadUser, statusCode: response.statusCode);
    }
  }

  // Logout
  Future<void> logout() async {
    await clearTokens();
  }

  // Delete account (withdrawal)
  Future<void> deleteAccount({
    required String email,
    String? nickname,
    String? reason,
  }) async {
    // 1) Save withdrawal reason to FastAPI (non-blocking)
    final analyticsBaseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';
    try {
      await http.post(
        Uri.parse('$analyticsBaseUrl/api/v1/internal/ingest/withdrawal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email': email,
          'user_nickname': nickname,
          'reason': reason,
        }),
      ).timeout(_timeout);
    } catch (e) {
      // Don't block withdrawal if reason save fails
      debugPrint('[AuthService] Failed to save withdrawal reason: $e');
    }

    // 2) Request deletion from Django (MUST succeed)
    final token = await getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.sessionExpired, debugMessage: 'No auth token');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/request-deletion/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      debugPrint('[AuthService] Deletion request failed: ${response.statusCode} ${response.body}');
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Delete account failed', statusCode: response.statusCode);
    }

    // 3) Clear local tokens (only after Django confirms)
    await clearTokens();
  }

  // Update profile (nickname, bio, profile_picture)
  Future<CommunityUser> updateProfile({
    String? nickname,
    String? bio,
    File? profilePicture,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    // Multipart request for file upload
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$_baseUrl/update/'),
    );

    // Add headers
    request.headers['Authorization'] = 'Token $token';

    // Add text fields
    if (nickname != null) {
      request.fields['nickname'] = nickname;
    }
    if (bio != null) {
      request.fields['bio'] = bio;
    }

    // Add file if provided
    if (profilePicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          profilePicture.path,
        ),
      );
    }

    final http.Response response;
    try {
      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Update profile');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      final data = _parseResponseBody(response);
      return CommunityUser.fromJson(data);
    } else if (response.statusCode == 401) {
      await clearTokens();
      throw ApiException(ApiErrorCode.sessionExpired, statusCode: 401);
    } else {
      final body = _parseResponseBody(response);
      throw _extractApiException(response.statusCode, body);
    }
  }

  // Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        }),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Change password');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Change password timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      // 서버가 기존 토큰 삭제 후 새 토큰을 발급하므로 저장
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return;
    } else if (response.statusCode == 401) {
      await clearTokens();
      throw ApiException(ApiErrorCode.sessionExpired, statusCode: 401);
    } else if (response.statusCode == 400) {
      final body = _parseResponseBody(response);
      if (body is Map && body.containsKey('old_password')) {
        final msg = body['old_password'];
        if (msg is List && msg.isNotEmpty) {
          throw ApiException(ApiErrorCode.badRequest, debugMessage: msg.first.toString(), statusCode: 400);
        }
      }
      throw _extractApiException(response.statusCode, body);
    } else {
      final body = _parseResponseBody(response);
      throw _extractApiException(response.statusCode, body);
    }
  }

  // Broadcast push notification (Manager+ only)
  Future<Map<String, dynamic>> broadcastPush({
    required String title,
    required String body,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/push/broadcast/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'title': title, 'body': body}),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Broadcast push');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Broadcast push timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final responseBody = _parseResponseBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(responseBody);
    } else {
      throw _extractApiException(response.statusCode, responseBody);
    }
  }

  // ── Email Verification & Password Reset ──

  /// 인증코드 발송
  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    required String purpose,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/verification/send/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'purpose': purpose}),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Send verification code');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Send verification code timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final body = _parseResponseBody(response);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body);
    } else if (response.statusCode == 429) {
      final cooldown = body is Map ? body['cooldown_remaining'] : null;
      throw ApiException(ApiErrorCode.rateLimited, debugMessage: '${cooldown ?? 60}', statusCode: 429);
    } else {
      throw _extractApiException(response.statusCode, body);
    }
  }

  /// 인증코드 확인
  Future<bool> verifyCode({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/verification/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code, 'purpose': purpose}),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Verify code');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Verify code timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    final body = _parseResponseBody(response);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw _extractApiException(response.statusCode, body);
    }
  }

  /// 비밀번호 재설정 요청 (코드 발송)
  Future<void> requestPasswordReset({required String email}) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/password-reset/request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Password reset request');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Password reset request timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 429) {
      final body = _parseResponseBody(response);
      final cooldown = body is Map ? body['cooldown_remaining'] : null;
      throw ApiException(ApiErrorCode.rateLimited, debugMessage: '${cooldown ?? 60}', statusCode: 429);
    } else {
      final body = _parseResponseBody(response);
      throw _extractApiException(response.statusCode, body);
    }
  }

  /// 비밀번호 재설정 확인 (코드 + 새 비밀번호)
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/password-reset/confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        }),
      ).timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Password reset confirm');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection, debugMessage: 'Password reset confirm timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      return;
    } else {
      final body = _parseResponseBody(response);
      throw _extractApiException(response.statusCode, body);
    }
  }

  // ── Helper methods ──

  /// Parse response body safely. Returns parsed JSON or empty map if HTML/invalid.
  dynamic _parseResponseBody(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html') ||
        response.body.trimLeft().startsWith('<!') ||
        response.body.trimLeft().startsWith('<html')) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Extract ApiException from response body with server-provided detail messages.
  ApiException _extractApiException(int statusCode, dynamic body) {
    // Try to extract server-provided error detail
    if (body is Map && body.isNotEmpty) {
      if (body.containsKey('detail')) {
        return ApiException(
          _codeFromStatus(statusCode),
          debugMessage: body['detail'].toString(),
          statusCode: statusCode,
        );
      }
      if (body.containsKey('non_field_errors')) {
        final errors = body['non_field_errors'];
        if (errors is List && errors.isNotEmpty) {
          return ApiException(
            _codeFromStatus(statusCode),
            debugMessage: errors.first.toString(),
            statusCode: statusCode,
          );
        }
      }
      // 비밀번호 정책 위반(서버 Django validators) — 가입 폼으로 돌려보내 수정하도록
      // 전용 코드로 분리(인증 화면에서 막혀 못 고치는 상황 방지).
      if (body['password'] is List && (body['password'] as List).isNotEmpty) {
        return ApiException(
          ApiErrorCode.weakPassword,
          debugMessage: (body['password'] as List).first.toString(),
          statusCode: statusCode,
        );
      }
      // Collect field-level errors
      final messages = <String>[];
      body.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          messages.add(value.first.toString());
        } else if (value is String) {
          messages.add(value);
        }
      });
      if (messages.isNotEmpty) {
        return ApiException(
          _codeFromStatus(statusCode),
          debugMessage: messages.first,
          statusCode: statusCode,
        );
      }
    }

    return ApiException(_codeFromStatus(statusCode), statusCode: statusCode);
  }

  /// Map HTTP status code to ApiErrorCode
  ApiErrorCode _codeFromStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorCode.badRequest;
      case 401:
        return ApiErrorCode.sessionExpired;
      case 403:
        return ApiErrorCode.forbidden;
      case 404:
        return ApiErrorCode.notFound;
      case 500:
        return ApiErrorCode.serverError;
      default:
        return ApiErrorCode.genericError;
    }
  }
}
