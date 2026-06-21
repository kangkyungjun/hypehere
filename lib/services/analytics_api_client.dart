import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../exceptions/api_error_codes.dart';
import '../exceptions/api_exception.dart';
import '../models/chart_data.dart';
import '../models/intraday_chart.dart';
import '../models/ticker_score.dart';
import '../models/ticker_info.dart';
import '../models/market_insights.dart';
import '../models/treemap_data.dart';
import '../models/macro_data.dart';
import '../models/earnings_data.dart';
import '../models/indices_data.dart';
import '../models/news_data.dart';
import '../models/mention_bubble_data.dart';
import '../models/market_event.dart';

class AnalyticsApiClient {
  // Base URL for analytics API
  // Loaded from .env file (API_BASE_URL)
  // Development: local server or EC2 instance
  // Production: Load balancer or CloudFront URL
  static final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://43.201.45.60:8001';

  final http.Client _httpClient;

  AnalyticsApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client() {
    // Debug logging for APK troubleshooting
    debugPrint('[AnalyticsApiClient] 🌐 Base URL: $_baseUrl');
    debugPrint('[AnalyticsApiClient] 📁 dotenv loaded: ${dotenv.env['API_BASE_URL']}');
  }

  /// 시간봉(1h) intraday 차트 데이터.
  /// [dateEt]가 지정되면 그 ET 일자의 봉만 반환(드릴다운). 미지정 시 최신 거래일.
  /// 응답이 비어있어도 정상(아직 ingest 전이거나 신규 종목).
  Future<IntradayChartData> getIntradayChartData(
    String ticker, {
    String interval = '1h',
    String? dateEt, // 'YYYY-MM-DD'
  }) async {
    final base = '$_baseUrl/api/v1/charts/${ticker.toUpperCase()}/intraday';
    final url = dateEt != null && dateEt.isNotEmpty ? '$base/$dateEt' : base;
    final uri = Uri.parse(url).replace(queryParameters: {'interval': interval});
    try {
      final response = await _httpClient.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Intraday chart timeout'),
          );
      if (response.statusCode == 200) {
        return IntradayChartData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 404) {
        // 데이터 없음을 정상 빈 응답으로 처리
        return IntradayChartData(
          ticker: ticker.toUpperCase(),
          interval: interval,
          data: const [],
        );
      }
      throw ApiException(
        ApiErrorCode.genericError,
        statusCode: response.statusCode,
        debugMessage: 'Intraday chart failed',
      );
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Intraday');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Intraday');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get complete chart data for a ticker
  ///
  /// Returns OHLCV prices, scores, indicators, targets, trendlines,
  /// institutional ownership, and short data in a single API call.
  ///
  /// Example:
  /// ```dart
  /// final data = await client.getChartData('AAPL',
  ///   fromDate: DateTime(2026, 1, 1),
  ///   toDate: DateTime(2026, 2, 6)
  /// );
  /// ```
  Future<CompleteChartData> getChartData(
    String ticker, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final params = <String, String>{};
      if (fromDate != null) {
        params['from'] = _formatDate(fromDate);
      }
      if (toDate != null) {
        params['to'] = _formatDate(toDate);
      }

      final uri = Uri.parse('$_baseUrl/api/v1/charts/$ticker')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      debugPrint('[CHART_REQUEST] baseUrl=$_baseUrl');
      debugPrint('[CHART_REQUEST] ticker=$ticker');
      debugPrint('[CHART_REQUEST] fullUrl=$uri');
      debugPrint('[CHART_REQUEST] params from=${params['from']} to=${params['to']}');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Chart data timeout');
        },
      );

      debugPrint('[CHART_RESPONSE] status=${response.statusCode} bytes=${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // 서버 키가 data/prices 중 무엇이든 대응
        final list = (json['data'] ?? json['prices']) as List?;
        final count = list?.length ?? 0;

        String latest = 'N/A';
        if (list != null && list.isNotEmpty) {
          // date 문자열 최대값으로 최신일 계산 (정렬 가정 금지)
          final dates = list
              .map((e) => (e as Map)['date']?.toString() ?? '')
              .where((d) => d.isNotEmpty);
          if (dates.isNotEmpty) {
            latest = dates.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
          }
        }

        debugPrint('[CHART_RESPONSE] points=$count latest_date=$latest');

        return CompleteChartData.fromJson(json);
      } else if (response.statusCode == 404) {
        throw TickerNotFoundException(ticker: ticker);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load chart data: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Chart data');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Chart data');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Chart data');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get top scoring tickers for a specific date
  ///
  /// Example:
  /// ```dart
  /// final topTickers = await client.getTopTickers(
  ///   date: DateTime(2026, 2, 6),
  ///   limit: 20
  /// );
  /// ```
  Future<List<TickerScore>> getTopTickers({
    DateTime? date,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
      };
      if (date != null) {
        params['date'] = _formatDate(date);
      }

      final uri = Uri.parse('$_baseUrl/api/v1/scores/top')
          .replace(queryParameters: params);

      debugPrint('[API] 🏆 GET $_baseUrl/api/v1/scores/top?limit=$limit');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Top tickers timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => TickerScore.fromJson(item)).toList();
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load top tickers: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Top tickers');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Top tickers');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Top tickers');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get top tickers by **market cap** (individual stocks only).
  ///
  /// GET /api/v1/market/top-marketcap — SP500/DOW30/NASDAQ100 구성종목을
  /// 시가총액 내림차순으로 반환 (ETF·종합지수 제외). 응답은 scores/top과 동일
  /// (TopTickerResponse) 이므로 [TickerScore]로 그대로 파싱.
  Future<List<TickerScore>> getTopByMarketCap({
    DateTime? date,
    int limit = 20,
    String? index,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
      };
      if (date != null) {
        params['date'] = _formatDate(date);
      }
      if (index != null) {
        params['index'] = index;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/market/top-marketcap')
          .replace(queryParameters: params);

      debugPrint('[API] 💰 GET $_baseUrl/api/v1/market/top-marketcap?limit=$limit');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Top market cap timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => TickerScore.fromJson(item)).toList();
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load top market cap: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Top market cap');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Top market cap');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Top market cap');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get scores for specific tickers by batch
  ///
  /// Used by watchlist screen to fetch exact tickers instead of top N.
  ///
  /// Example:
  /// ```dart
  /// final scores = await client.getTickerScoresBatch(['AAPL', 'TSLA', 'MSFT']);
  /// ```
  Future<List<TickerScore>> getTickerScoresBatch(List<String> tickers) async {
    if (tickers.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/api/v1/scores/batch')
          .replace(queryParameters: {'tickers': tickers.join(',')});

      debugPrint('[API] GET $_baseUrl/api/v1/scores/batch?tickers=${tickers.join(',')}');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Batch scores timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => TickerScore.fromJson(item)).toList();
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load batch scores: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Batch scores');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Batch scores');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Batch scores');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get market insights with top and bottom performers
  ///
  /// Example:
  /// ```dart
  /// final insights = await client.getMarketInsights(
  ///   date: DateTime(2026, 2, 6),
  ///   top: 50,
  ///   bottom: 50
  /// );
  /// ```
  Future<MarketInsights> getMarketInsights({
    DateTime? date,
    int top = 50,
    int bottom = 50,
    String? index,
  }) async {
    try {
      final params = <String, String>{
        'top': top.toString(),
        'bottom': bottom.toString(),
      };
      if (date != null) {
        params['date'] = _formatDate(date);
      }
      if (index != null) {
        params['index'] = index;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/scores/insights')
          .replace(queryParameters: params);

      debugPrint('[API] 📊 GET $_baseUrl/api/v1/scores/insights?top=$top&bottom=$bottom${index != null ? '&index=$index' : ''}');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Market insights timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MarketInsights.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load market insights: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Market insights');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Market insights');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Market insights');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Search tickers by symbol or name
  ///
  /// Example:
  /// ```dart
  /// final results = await client.searchTickers('AAPL');
  /// ```
  Future<List<TickerInfo>> searchTickers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final uri = Uri.parse('$_baseUrl/api/v1/tickers/search')
          .replace(queryParameters: {'q': query});

      debugPrint('[API] 🔍 GET $_baseUrl/api/v1/tickers/search?q=$query');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Search timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        return json.map((item) => TickerInfo.fromJson(item)).toList();
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to search tickers: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Ticker search');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Ticker search');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get ticker metadata (name, category)
  ///
  /// Example:
  /// ```dart
  /// final info = await client.getTickerInfo('AAPL');
  /// ```
  Future<TickerInfo> getTickerInfo(String ticker) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/tickers/$ticker');

      debugPrint('[API] ℹ️  GET $_baseUrl/api/v1/tickers/$ticker');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Ticker info timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TickerInfo.fromJson(json);
      } else if (response.statusCode == 404) {
        throw TickerNotFoundException(ticker: ticker);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load ticker info: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Ticker info');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Ticker info');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get treemap data for sector visualization
  ///
  /// Returns S&P 500 tickers grouped by GICS sector with change_pct
  /// and trading_value for treemap chart rendering.
  ///
  /// Example:
  /// ```dart
  /// final data = await client.getTreemapData();
  /// ```
  Future<TreemapData> getTreemapData({DateTime? date, String? index, String? classification}) async {
    try {
      final params = <String, String>{};
      if (date != null) {
        params['date'] = _formatDate(date);
      }
      if (index != null) {
        params['index'] = index;
      }
      if (classification != null) {
        params['classification'] = classification;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/market/treemap')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      debugPrint('[API] GET $_baseUrl/api/v1/market/treemap${index != null ? '?index=$index' : ''}');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Treemap timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TreemapData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load treemap data: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout15s, debugMessage: 'Treemap');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Treemap');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Treemap');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get macro economic indicators for dashboard banner
  ///
  /// Returns FRED macro indicators (Fed Funds Rate, Treasury yields,
  /// VIX, CPI, Unemployment Rate) with change percentages.
  ///
  /// Example:
  /// ```dart
  /// final data = await client.getMacroIndicators();
  /// ```
  Future<MacroIndicatorsData> getMacroIndicators({String? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) {
        params['date'] = date;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/macro/indicators')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      debugPrint('[API] GET $_baseUrl/api/v1/macro/indicators');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Macro indicators timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MacroIndicatorsData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load macro indicators: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Macro indicators');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Macro indicators');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Macro indicators');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get macro signals (yield_curve, m2_liquidity, overall_macro)
  ///
  /// Returns signals from the macro signals API including overall_macro
  /// for the dashboard header display.
  Future<MacroSignalsData> getMacroSignals({String? date}) async {
    try {
      final params = <String, String>{};
      if (date != null) {
        params['date'] = date;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/macro/signals')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      debugPrint('[API] GET $_baseUrl/api/v1/macro/signals');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Macro signals timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MacroSignalsData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load macro signals: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Macro signals');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Macro signals');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Macro signals');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get upcoming earnings events for the week
  ///
  /// Returns earnings events grouped by date for the calendar screen.
  Future<EarningsUpcomingData> getUpcomingEarnings({int days = 7}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/earnings/upcoming')
          .replace(queryParameters: {'days': days.toString()});

      debugPrint('[API] GET $_baseUrl/api/v1/earnings/upcoming?days=$days');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Earnings timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return EarningsUpcomingData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load earnings data: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Earnings');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Earnings');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Earnings');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get latest news across all tickers (dashboard preview)
  Future<NewsListData> getLatestNews({int limit = 3}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/news/latest')
          .replace(queryParameters: {'limit': limit.toString()});

      debugPrint('[API] GET $_baseUrl/api/v1/news/latest?limit=$limit');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('News timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NewsListData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load news: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Latest news');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Latest news');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Latest news');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get paginated news list (infinite scroll) with optional filters
  Future<NewsListData> getNewsList({
    int limit = 20,
    int offset = 0,
    String? tickers,
    String? sentiment,
    String? sectors,
    bool? isBreaking,
    bool? excludeMarket,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (tickers != null) params['tickers'] = tickers;
      if (sentiment != null) params['sentiment'] = sentiment;
      if (sectors != null) params['sectors'] = sectors;
      if (isBreaking != null) params['is_breaking'] = isBreaking.toString();
      if (excludeMarket != null) params['exclude_market'] = excludeMarket.toString();

      final uri = Uri.parse('$_baseUrl/api/v1/news/latest')
          .replace(queryParameters: params);

      debugPrint('[API] GET $uri');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('News list timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NewsListData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load news list: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'News list');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'News list');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'News list');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get hot topic news (last 48h, sorted by priority)
  Future<NewsListData> getHotTopics({int limit = 5}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/news/hot-topics')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Hot topics timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NewsListData.fromJson(json);
      } else {
        return NewsListData(items: [], total: 0);
      }
    } catch (e) {
      return NewsListData(items: [], total: 0);
    }
  }

  /// Get mention bubble data (top tickers by mention count in last N hours)
  Future<MentionBubbleData> getMentionBubble({
    int hours = 24,
    int limit = 15,
    String? sectors,
    String? tickers,
  }) async {
    try {
      final params = <String, String>{
        'hours': hours.toString(),
        'limit': limit.toString(),
      };
      if (sectors != null) params['sectors'] = sectors;
      if (tickers != null) params['tickers'] = tickers;
      final uri = Uri.parse('$_baseUrl/api/v1/news/mention-bubble')
          .replace(queryParameters: params);

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Mention bubble timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MentionBubbleData.fromJson(json);
      } else {
        return MentionBubbleData(items: [], periodHours: hours);
      }
    } catch (e) {
      return MentionBubbleData(items: [], periodHours: hours);
    }
  }

  /// Bull/bear/neutral counts over the last [hours] window, computed
  /// client-side (no dedicated backend endpoint). Honors the category
  /// filters (tickers/sectors/excludeMarket) but NOT sentiment, so the
  /// result reflects the full sentiment mix of the current category.
  ///
  /// Uses bounded pagination over [getNewsList] (assumed newest-first),
  /// stopping once an item older than the cutoff is seen or [maxFetch]
  /// is reached. Returns empty [SentimentCounts] on any error.
  Future<SentimentCounts> getRecentSentimentCounts({
    int hours = 24,
    int maxFetch = 1000,
    int pageSize = 100,
    String? tickers,
    String? sectors,
    bool? excludeMarket,
  }) async {
    try {
      final cutoff = DateTime.now().toUtc().subtract(Duration(hours: hours));
      int bullish = 0, neutral = 0, bearish = 0;
      int offset = 0;
      bool reachedOlder = false;

      while (offset < maxFetch && !reachedOlder) {
        final limit = (maxFetch - offset).clamp(0, pageSize);
        if (limit == 0) break;

        final data = await getNewsList(
          limit: limit,
          offset: offset,
          tickers: tickers,
          sectors: sectors,
          excludeMarket: excludeMarket,
          // deliberately NOT passing sentiment — need the full mix
        );
        if (data.items.isEmpty) break;

        for (final item in data.items) {
          if (item.publishedAt.isBefore(cutoff)) {
            reachedOlder = true;
            continue;
          }
          switch (item.sentimentGrade) {
            case 'bullish':
              bullish++;
              break;
            case 'bearish':
              bearish++;
              break;
            default:
              neutral++;
          }
        }

        if (data.items.length < limit) break; // no more pages
        offset += data.items.length;
      }

      if (!reachedOlder && offset >= maxFetch) {
        debugPrint('[getRecentSentimentCounts] hit maxFetch=$maxFetch before '
            'reaching ${hours}h cutoff; counts are an approximation.');
      }

      return SentimentCounts(
        bullish: bullish,
        neutral: neutral,
        bearish: bearish,
      );
    } catch (e) {
      debugPrint('[getRecentSentimentCounts] error: $e');
      return SentimentCounts();
    }
  }

  /// Top key news within the last [hours] hours (max [limit]).
  /// Reuses [getHotTopics] (48h, priority-sorted), then filters to the
  /// recent window and re-sorts by hot_topic_priority (higher = more
  /// important, nulls last) then recency. Returns [] on any error.
  Future<List<NewsItem>> getKeyNews({int hours = 10, int limit = 5}) async {
    try {
      final data = await getHotTopics(limit: 20);
      final cutoff = DateTime.now().toUtc().subtract(Duration(hours: hours));
      final recent =
          data.items.where((n) => !n.publishedAt.isBefore(cutoff)).toList();

      recent.sort((a, b) {
        final pa = a.hotTopicPriority;
        final pb = b.hotTopicPriority;
        if (pa != pb) {
          if (pa == null) return 1; // nulls last
          if (pb == null) return -1;
          return pb.compareTo(pa); // higher priority first
        }
        return b.publishedAt.compareTo(a.publishedAt); // newer first
      });

      return recent.take(limit).toList();
    } catch (e) {
      debugPrint('[getKeyNews] error: $e');
      return [];
    }
  }

  /// Get available news sectors from DB
  Future<List<String>> getNewsSectors() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/news/sectors');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('News sectors timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<String>.from(json['sectors'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get news for a specific ticker (infinite scroll)
  Future<NewsListData> getTickerNews(String ticker, {int limit = 20, int offset = 0}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/news/')
          .replace(queryParameters: {
        'ticker': ticker,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      debugPrint('[API] GET $_baseUrl/api/v1/news/?ticker=$ticker&limit=$limit&offset=$offset');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Ticker news timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return NewsListData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load ticker news: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Ticker news');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Ticker news');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Ticker news');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get event calendar for a specific month
  Future<EventCalendarData> getEventCalendar(int year, int month, String lang) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/events/calendar')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
        'lang': lang,
      });

      debugPrint('[API] GET $_baseUrl/api/v1/events/calendar?year=$year&month=$month&lang=$lang');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Event calendar timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return EventCalendarData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load event calendar: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Event calendar');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Event calendar');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Event calendar');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await _httpClient.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Format DateTime to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get macro indicator history (latest N entries, date DESC)
  Future<MacroHistoryData> getMacroHistory(String code, {int limit = 15}) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/macro/history/$code')
          .replace(queryParameters: {'limit': limit.toString()});

      debugPrint('[API] GET $_baseUrl/api/v1/macro/history/$code?limit=$limit');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Macro history timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MacroHistoryData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load macro history: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Macro history');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Macro history');
    } on FormatException {
      throw ApiException(ApiErrorCode.responseFormat, debugMessage: 'Macro history');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get market indices (SPY, QQQ, DIA) for dashboard header
  Future<MarketIndicesData> getMarketIndices() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/market/indices');

      debugPrint('[API] 📊 GET $_baseUrl/api/v1/market/indices');

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Market indices timeout');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MarketIndicesData.fromJson(json);
      } else {
        throw ApiException(
          ApiErrorCode.genericError,
          debugMessage: 'Failed to load market indices: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s, debugMessage: 'Market indices');
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed, debugMessage: 'Market indices');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorCode.genericError, debugMessage: '$e');
    }
  }

  /// Get closing price for a specific date (for add/sell holding).
  /// Falls back to prior trading day if target date is a holiday.
  Future<({String date, double? close})> getClosePrice(String ticker, DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final uri = Uri.parse('$_baseUrl/api/v1/prices/${ticker.toUpperCase()}/close')
          .replace(queryParameters: {'date': dateStr});

      final response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Close price timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (
          date: json['date'] as String,
          close: (json['close'] as num?)?.toDouble(),
        );
      }
      return (date: dateStr, close: null);
    } catch (e) {
      if (e is ApiException) rethrow;
      return (date: _formatDate(date), close: null);
    }
  }

  /// Get classification summary (category → count)
  Future<Map<String, int>> getClassificationSummary() async {
    final uri = Uri.parse('$_baseUrl/api/v1/market/classifications/summary');
    try {
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      throw ApiException(ApiErrorCode.serverError, statusCode: response.statusCode);
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s);
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed);
    }
  }

  /// Get stocks by classification category
  Future<List<Map<String, dynamic>>> getStocksByClassification(String category, {int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/market/classifications/stocks?category=$category&limit=$limit');
    try {
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
      throw ApiException(ApiErrorCode.serverError, statusCode: response.statusCode);
    } on TimeoutException {
      throw ApiException(ApiErrorCode.timeout10s);
    } on SocketException {
      throw ApiException(ApiErrorCode.networkFailed);
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
