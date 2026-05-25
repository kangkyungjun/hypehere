import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/investment_profile.dart';

class InvestmentProfileService {
  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';
  static const _storage = FlutterSecureStorage();
  static const _timeout = Duration(seconds: 15);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  /// GET /api/accounts/investment-profile/
  /// Returns null if profile not set (404).
  Future<InvestmentProfile?> getProfile() async {
    final token = await _getToken();
    if (token == null) return null;

    final http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$_baseUrl/investment-profile/'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'InvestmentProfile GET');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'InvestmentProfile GET timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort,
          debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return InvestmentProfile.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else if (response.statusCode == 401) {
      return null;
    } else {
      debugPrint('[InvestmentProfileService] GET failed: ${response.statusCode}');
      return null;
    }
  }

  /// POST /api/accounts/investment-profile/  (upsert)
  Future<InvestmentProfile> saveProfile(InvestmentProfile profile) async {
    final token = await _getToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired);
    }

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/investment-profile/'),
            headers: _authHeaders(token),
            body: jsonEncode(profile.toJson()),
          )
          .timeout(_timeout);
    } on SocketException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'InvestmentProfile POST');
    } on TimeoutException {
      throw ApiException(ApiErrorCode.serverConnection,
          debugMessage: 'InvestmentProfile POST timeout');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.serverConnectionShort,
          debugMessage: '$e');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return InvestmentProfile.fromJson(data);
    } else if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.sessionExpired, statusCode: 401);
    } else {
      throw ApiException(ApiErrorCode.genericError,
          statusCode: response.statusCode,
          debugMessage: 'InvestmentProfile POST ${response.statusCode}');
    }
  }
}
