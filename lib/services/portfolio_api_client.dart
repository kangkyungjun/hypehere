import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/portfolio_data.dart';
import 'auth_service.dart';

/// API client for portfolio endpoints (FastAPI:8001).
///
/// All endpoints require Django Token authentication.
/// Uses same base URL as AnalyticsApiClient but adds Authorization header.
class PortfolioApiClient {
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  final http.Client _httpClient;
  final AuthService _authService;

  PortfolioApiClient({
    http.Client? httpClient,
    AuthService? authService,
  })  : _httpClient = httpClient ?? http.Client(),
        _authService = authService ?? AuthService();

  /// Get auth headers (Django Token format)
  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw ApiException(ApiErrorCode.loginRequired,
          debugMessage: 'Portfolio requires login');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  /// Generic authenticated GET
  Future<http.Response> _authGet(String path,
      {Map<String, String>? params}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: params?.isNotEmpty == true ? params : null);

    return _httpClient.get(uri, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timeout'),
    );
  }

  /// Generic authenticated POST
  Future<http.Response> _authPost(String path, {Object? body}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl$path');

    return _httpClient
        .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timeout'),
    );
  }

  /// Generic authenticated DELETE
  Future<http.Response> _authDelete(String path) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl$path');

    return _httpClient.delete(uri, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timeout'),
    );
  }

  /// Handle response errors
  void _checkResponse(http.Response response, String context) {
    if (response.statusCode == 401) {
      throw ApiException(ApiErrorCode.sessionExpired,
          debugMessage: context, statusCode: 401);
    }
    if (response.statusCode != 200) {
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: '$context: ${response.statusCode}',
          statusCode: response.statusCode);
    }
  }

  // ============================================================
  // Holdings
  // ============================================================

  Future<List<PortfolioHolding>> getHoldings() async {
    try {
      final response = await _authGet('/api/v1/portfolio/holdings');
      _checkResponse(response, 'Get holdings');
      final json = jsonDecode(response.body) as List;
      return json.map((e) => PortfolioHolding.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Holdings');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Holdings');
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<PortfolioHolding> addOrUpdateHolding({
    required String ticker,
    required double shares,
    required double avgPrice,
    String? notes,
  }) async {
    try {
      final response = await _authPost('/api/v1/portfolio/holdings', body: {
        'ticker': ticker.toUpperCase(),
        'shares': shares,
        'avg_price': avgPrice,
        if (notes != null) 'notes': notes,
      });
      _checkResponse(response, 'Add holding');
      return PortfolioHolding.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Add holding');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed,
          debugMessage: 'Add holding');
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> deleteHolding(String ticker) async {
    try {
      final response =
          await _authDelete('/api/v1/portfolio/holdings/${ticker.toUpperCase()}');
      _checkResponse(response, 'Delete holding');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  // ============================================================
  // Watchlist
  // ============================================================

  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      final response = await _authGet('/api/v1/portfolio/watchlist');
      _checkResponse(response, 'Get watchlist');
      final json = jsonDecode(response.body) as List;
      return json.map((e) => WatchlistItem.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Watchlist');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Watchlist');
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> addWatchlistItem(String ticker, {String? notes}) async {
    try {
      final response = await _authPost('/api/v1/portfolio/watchlist', body: {
        'ticker': ticker.toUpperCase(),
        if (notes != null) 'notes': notes,
      });
      _checkResponse(response, 'Add watchlist');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> removeWatchlistItem(String ticker) async {
    try {
      final response =
          await _authDelete('/api/v1/portfolio/watchlist/${ticker.toUpperCase()}');
      _checkResponse(response, 'Remove watchlist');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Bulk sync watchlist (SharedPreferences → Server migration)
  Future<Map<String, dynamic>> syncWatchlist(List<String> tickers) async {
    try {
      final response = await _authPost('/api/v1/portfolio/watchlist/sync',
          body: {'tickers': tickers});
      _checkResponse(response, 'Sync watchlist');
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  // ============================================================
  // Transactions
  // ============================================================

  Future<PortfolioTransaction> addTransaction({
    required String ticker,
    required String type, // BUY | SELL
    required double shares,
    required double price,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final response = await _authPost('/api/v1/portfolio/transactions', body: {
        'ticker': ticker.toUpperCase(),
        'type': type,
        'shares': shares,
        'price': price,
        'date': _formatDate(date),
        if (notes != null) 'notes': notes,
      });
      _checkResponse(response, 'Add transaction');
      return PortfolioTransaction.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<List<PortfolioTransaction>> getTransactions({
    String? ticker,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (ticker != null) params['ticker'] = ticker.toUpperCase();

      final response =
          await _authGet('/api/v1/portfolio/transactions', params: params);
      _checkResponse(response, 'Get transactions');
      final json = jsonDecode(response.body) as List;
      return json.map((e) => PortfolioTransaction.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final response =
          await _authDelete('/api/v1/portfolio/transactions/$id');
      _checkResponse(response, 'Delete transaction');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  // ============================================================
  // AI Advice & Summary
  // ============================================================

  Future<List<PortfolioAdvice>> getAdvice({DateTime? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = _formatDate(date);

      final response =
          await _authGet('/api/v1/portfolio/advice', params: params);
      _checkResponse(response, 'Get advice');
      final json = jsonDecode(response.body) as List;
      return json.map((e) => PortfolioAdvice.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<PortfolioSummary> getSummary({DateTime? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = _formatDate(date);

      final response =
          await _authGet('/api/v1/portfolio/summary', params: params);
      _checkResponse(response, 'Get summary');
      return PortfolioSummary.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  // ============================================================
  // Alerts
  // ============================================================

  Future<List<UserAlert>> getAlerts({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (unreadOnly) params['unread_only'] = 'true';

      final response = await _authGet('/api/v1/alerts', params: params);
      _checkResponse(response, 'Get alerts');
      final json = jsonDecode(response.body) as List;
      return json.map((e) => UserAlert.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> markAlertRead(int alertId) async {
    try {
      final response = await _authPost('/api/v1/alerts/$alertId/read');
      _checkResponse(response, 'Mark alert read');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  Future<void> markAllAlertsRead() async {
    try {
      final response = await _authPost('/api/v1/alerts/read-all');
      _checkResponse(response, 'Mark all read');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  // ============================================================
  // Exchange Rate (public, no auth needed)
  // ============================================================

  Future<ExchangeRate> getExchangeRate({DateTime? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = _formatDate(date);

      final uri = Uri.parse('$_baseUrl/api/v1/portfolio/exchange-rate')
          .replace(
              queryParameters: params.isNotEmpty ? params : null);

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Exchange rate timeout'),
      );

      if (response.statusCode == 200) {
        return ExchangeRate.fromJson(jsonDecode(response.body));
      }
      throw ApiException(ApiErrorCode.genericError,
          debugMessage: 'Exchange rate: ${response.statusCode}');
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s,
          debugMessage: 'Exchange rate');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed,
          debugMessage: 'Exchange rate');
    } catch (e) {
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _httpClient.close();
  }
}
