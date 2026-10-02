import 'news_data.dart';
import 'stock_classification.dart';

/// Chart data models for MarketLens analytics API
///
/// 이 종목 데이터가 얼마나 최신인가 (서버 `freshness`, S2).
///
/// **판정은 서버가 한다.** 앱은 시장의 최신 거래일을 모르고, 앱이 쓸 수 있는
/// 유일한 비교 대상(다른 종목의 날짜)은 공급원 장애로 일부 종목만 하루
/// 늦으면 무너진다 — 2026-10-01이 그런 날이었다. 그때 앱이 추측하면 멀쩡한
/// 종목에 경고가 붙는데, 그건 아무 말도 안 하는 것보다 나쁘다.
///
/// 서버가 판정을 못 하면(두 날짜 중 하나라도 모르면) 필드 자체가 없다.
/// 그래서 이 객체가 null인 것과 `stale == false`는 **다른 뜻**이다.
class Freshness {
  /// 이 종목의 최신 분석일.
  final DateTime asOf;

  /// 전 종목 기준 최신 분석일.
  final DateTime marketAsOf;

  /// 시장 대비 몇 거래일 뒤인가. 달력일이 아니다 — 금요일 종가를 월요일에
  /// 보는 건 1거래일 뒤다.
  final int tradingDaysBehind;

  /// 사용자에게 경고할 것인가. 임계값 판단도 서버가 한다.
  final bool stale;

  /// `stale`이 켜지는 경계. 서버가 정책을 바꾸면 앱 배포 없이 따라간다.
  final int staleThreshold;

  const Freshness({
    required this.asOf,
    required this.marketAsOf,
    required this.tradingDaysBehind,
    required this.stale,
    required this.staleThreshold,
  });

  factory Freshness.fromJson(Map<String, dynamic> json) => Freshness(
        asOf: DateTime.parse(json['as_of'] as String),
        marketAsOf: DateTime.parse(json['market_as_of'] as String),
        tradingDaysBehind: (json['trading_days_behind'] as num?)?.toInt() ?? 0,
        stale: (json['stale'] as bool?) ?? false,
        staleThreshold: (json['stale_threshold'] as num?)?.toInt() ?? 2,
      );

  Map<String, dynamic> toJson() => {
        'as_of': asOf.toIso8601String().split('T').first,
        'market_as_of': marketAsOf.toIso8601String().split('T').first,
        'trading_days_behind': tradingDaysBehind,
        'stale': stale,
        'stale_threshold': staleThreshold,
      };
}

/// Matches the server's CompleteChartResponse and ChartDataPoint schemas
class CompleteChartData {
  final String ticker;
  final List<ChartDataPoint> data;

  /// 데이터 최신성 (S2). 서버가 판정을 못 하면 null — `stale == false`와 다르다.
  ///
  /// ⚠️ `data`가 **비어 있을 때도 온다.** 개명·상장폐지 종목이 그 경우인데,
  /// 거기서 "며칠 전까지의 데이터인가"가 제일 쓸모 있다.
  final Freshness? freshness;

  // Trendline coefficients (latest calculation)
  final double? highSlope;
  final double? highIntercept;
  final double? highRSquared;
  final double? lowSlope;
  final double? lowIntercept;
  final double? lowRSquared;

  // Analyst data (top-level, not time-series)
  final AnalystConsensus? analystConsensus;
  final List<AnalystRating>? analystRatings;

  // Fundamentals (top-level, not time-series)
  final CompanyProfile? profile;
  final KeyMetrics? keyMetrics;
  final FinancialsData? financials;
  final List<DividendEntry>? dividends;

  // Calendar & Earnings (top-level)
  final TickerCalendar? calendar;
  final List<EarningsHistoryEntry>? earningsHistory;

  // News
  final List<NewsItem>? news;
  final NewsSentimentStats? newsSentimentStats;

  // Classification (Peter Lynch)
  final StockClassification? classification;

  CompleteChartData({
    required this.ticker,
    required this.data,
    this.freshness,
    this.highSlope,
    this.highIntercept,
    this.highRSquared,
    this.lowSlope,
    this.lowIntercept,
    this.lowRSquared,
    this.analystConsensus,
    this.analystRatings,
    this.profile,
    this.keyMetrics,
    this.financials,
    this.dividends,
    this.calendar,
    this.earningsHistory,
    this.news,
    this.newsSentimentStats,
    this.classification,
  });

  /// Safe accessor: returns last data point or null if empty.
  ChartDataPoint? get lastOrNull => data.isEmpty ? null : data.last;

  factory CompleteChartData.fromJson(Map<String, dynamic> json) {
    return CompleteChartData(
      ticker: json['ticker'] as String,
      data: (json['data'] as List)
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      freshness: json['freshness'] != null
          ? Freshness.fromJson(json['freshness'] as Map<String, dynamic>)
          : null,
      highSlope: json['high_slope'] as double?,
      highIntercept: json['high_intercept'] as double?,
      highRSquared: json['high_r_squared'] as double?,
      lowSlope: json['low_slope'] as double?,
      lowIntercept: json['low_intercept'] as double?,
      lowRSquared: json['low_r_squared'] as double?,
      analystConsensus: json['analyst_consensus'] != null
          ? AnalystConsensus.fromJson(json['analyst_consensus'] as Map<String, dynamic>)
          : null,
      analystRatings: json['analyst_ratings'] != null
          ? (json['analyst_ratings'] as List)
              .map((item) => AnalystRating.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      profile: json['profile'] != null
          ? CompanyProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      keyMetrics: json['key_metrics'] != null
          ? KeyMetrics.fromJson(json['key_metrics'] as Map<String, dynamic>)
          : null,
      financials: json['financials'] != null
          ? FinancialsData.fromJson(json['financials'] as Map<String, dynamic>)
          : null,
      dividends: json['dividends'] != null
          ? (json['dividends'] as List)
              .map((item) => DividendEntry.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      calendar: json['calendar'] != null
          ? TickerCalendar.fromJson(json['calendar'] as Map<String, dynamic>)
          : null,
      earningsHistory: json['earnings_history'] != null
          ? (json['earnings_history'] as List)
              .map((item) => EarningsHistoryEntry.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      news: json['news'] != null
          ? (json['news'] as List)
              .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      newsSentimentStats: json['news_sentiment_stats'] != null
          ? NewsSentimentStats.fromJson(json['news_sentiment_stats'] as Map<String, dynamic>)
          : null,
      classification: json['classification'] != null
          ? StockClassification.fromJson(json['classification'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'data': data.map((item) => item.toJson()).toList(),
      'high_slope': highSlope,
      'high_intercept': highIntercept,
      'high_r_squared': highRSquared,
      'low_slope': lowSlope,
      'low_intercept': lowIntercept,
      'low_r_squared': lowRSquared,
      'analyst_consensus': analystConsensus?.toJson(),
      'analyst_ratings': analystRatings?.map((r) => r.toJson()).toList(),
      'profile': profile?.toJson(),
      'key_metrics': keyMetrics?.toJson(),
      'financials': financials?.toJson(),
      'dividends': dividends?.map((d) => d.toJson()).toList(),
      'calendar': calendar?.toJson(),
      'earnings_history': earningsHistory?.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculate trendline value for a given x position
  double? calculateHighTrendline(int dayIndex) {
    if (highSlope == null || highIntercept == null) return null;
    return highSlope! * dayIndex + highIntercept!;
  }

  double? calculateLowTrendline(int dayIndex) {
    if (lowSlope == null || lowIntercept == null) return null;
    return lowSlope! * dayIndex + lowIntercept!;
  }
}

/// Single day complete chart data point
/// 서버가 내려주는 분석 품질 메타 (`data_quality`).
///
/// 왜 필요한가: 파이프라인은 상장 40~119거래일인 종목(신규상장·분사)에
/// **AI 예측 헤드를 돌리지 않는다.** 그런데 `ai_probability`를 비워 보내는
/// 대신 **0.5로 채워서** 보낸다. 앱이 그 숫자를 그대로 그리면
/// "AI 상승 확률 50% + 상승"이 되는데, 서버가 판단을 포기한 자리에 앱이
/// 중립 판정을 지어내는 것이다.
///
/// 그래서 **확률의 유효성은 확률값으로 판단할 수 없다.** `aiAvailable`이
/// 정본이다.
///
/// 서버는 이 컬럼이 생기기 전(2026-10-02 이전) 행도 `full`로 환산해서
/// 내려준다. 즉 앱은 NULL 분기를 하지 않는다.
class DataQuality {
  /// `full` | `limited`
  final String analysisMode;

  /// 분석에 쓴 거래일 수. `limited` 종목의 상장 경과일.
  final int? historyDays;

  /// AI 예측 헤드가 돌았는가. **`aiProbability`를 그릴지 결정하는 신호다.**
  final bool aiAvailable;

  const DataQuality({
    required this.analysisMode,
    this.historyDays,
    required this.aiAvailable,
  });

  bool get isLimited => analysisMode == 'limited';

  factory DataQuality.fromJson(Map<String, dynamic> json) {
    final mode = (json['analysis_mode'] as String?) ?? 'full';
    return DataQuality(
      analysisMode: mode,
      historyDays: (json['history_days'] as num?)?.toInt(),
      // 서버는 항상 채워 보내지만, 빠진 응답에서도 모드와 어긋나지 않게 한다.
      aiAvailable: (json['ai_available'] as bool?) ?? (mode == 'full'),
    );
  }

  Map<String, dynamic> toJson() => {
        'analysis_mode': analysisMode,
        'history_days': historyDays,
        'ai_available': aiAvailable,
      };
}

/// Combines price, score, indicators, targets, institutions, and shorts
class ChartDataPoint {
  final DateTime date;

  // Price data (OHLCV)
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final int? volume;

  // Score data
  final double? score;
  final String? signal;

  /// 분석 품질 메타. 해당 날짜에 점수 행이 없으면 null이다.
  final DataQuality? dataQuality;

  // Target levels
  final double? targetPrice;
  final double? stopLoss;

  // Technical indicators
  final double? rsi;
  final double? mfi;
  final double? macd;
  final double? macdSignal;
  final double? macdHist;
  final double? bbWidth;
  final double? bbUpper;
  final double? bbLower;
  final double? bbMiddle;

  // Institutional data
  final double? instOwnership;
  final double? foreignOwnership;
  final double? insiderOwnership;
  final double? instChg1d;
  final double? instChg5d;
  final double? foreignChg1d;
  final double? foreignChg5d;

  // Short data
  final double? shortRatio;
  final double? shortPercentFloat;

  // AI Analysis data
  final double? aiProbability;
  final String? aiSummary;
  final List<String>? aiBullishReasons;
  final List<String>? aiBearishReasons;
  final String? aiFinalComment;

  // Expert analysis (5-language, per-field)
  final String? aiAnalysisKo;
  final String? aiAnalysisEn;
  final String? aiAnalysisZh;
  final String? aiAnalysisJa;
  final String? aiAnalysisEs;
  final String? aiExpertPrediction;    // "bullish" / "bearish" / "neutral"
  final List<String>? aiExpertKeyFactors;

  ChartDataPoint({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.score,
    this.signal,
    this.dataQuality,
    this.targetPrice,
    this.stopLoss,
    this.rsi,
    this.mfi,
    this.macd,
    this.macdSignal,
    this.macdHist,
    this.bbWidth,
    this.bbUpper,
    this.bbLower,
    this.bbMiddle,
    this.instOwnership,
    this.foreignOwnership,
    this.insiderOwnership,
    this.instChg1d,
    this.instChg5d,
    this.foreignChg1d,
    this.foreignChg5d,
    this.shortRatio,
    this.shortPercentFloat,
    this.aiProbability,
    this.aiSummary,
    this.aiBullishReasons,
    this.aiBearishReasons,
    this.aiFinalComment,
    this.aiAnalysisKo,
    this.aiAnalysisEn,
    this.aiAnalysisZh,
    this.aiAnalysisJa,
    this.aiAnalysisEs,
    this.aiExpertPrediction,
    this.aiExpertKeyFactors,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: DateTime.parse(json['date'] as String),
      open: json['open'] as double?,
      high: json['high'] as double?,
      low: json['low'] as double?,
      close: json['close'] as double?,
      volume: (json['volume'] as num?)?.toInt(),
      score: json['score'] as double?,
      signal: json['signal'] as String?,
      dataQuality: json['data_quality'] != null
          ? DataQuality.fromJson(json['data_quality'] as Map<String, dynamic>)
          : null,
      targetPrice: json['target_price'] as double?,
      stopLoss: json['stop_loss'] as double?,
      rsi: json['rsi'] as double?,
      mfi: json['mfi'] as double?,
      macd: json['macd'] as double?,
      macdSignal: json['macd_signal'] as double?,
      macdHist: json['macd_hist'] as double?,
      bbWidth: json['bb_width'] as double?,
      bbUpper: json['bb_upper'] as double?,
      bbLower: json['bb_lower'] as double?,
      bbMiddle: json['bb_middle'] as double?,
      instOwnership: json['inst_ownership'] as double?,
      foreignOwnership: json['foreign_ownership'] as double?,
      insiderOwnership: json['insider_ownership'] as double?,
      instChg1d: json['inst_chg_1d'] as double?,
      instChg5d: json['inst_chg_5d'] as double?,
      foreignChg1d: json['foreign_chg_1d'] as double?,
      foreignChg5d: json['foreign_chg_5d'] as double?,
      shortRatio: json['short_ratio'] as double?,
      shortPercentFloat: json['short_percent_float'] as double?,
      aiProbability: json['ai_probability'] as double?,
      aiSummary: json['ai_summary'] as String?,
      aiBullishReasons: json['ai_bullish_reasons'] != null
          ? List<String>.from(json['ai_bullish_reasons'] as List)
          : null,
      aiBearishReasons: json['ai_bearish_reasons'] != null
          ? List<String>.from(json['ai_bearish_reasons'] as List)
          : null,
      aiFinalComment: json['ai_final_comment'] as String?,
      aiAnalysisKo: json['ai_analysis_ko'] as String?,
      aiAnalysisEn: json['ai_analysis_en'] as String?,
      aiAnalysisZh: json['ai_analysis_zh'] as String?,
      aiAnalysisJa: json['ai_analysis_ja'] as String?,
      aiAnalysisEs: json['ai_analysis_es'] as String?,
      aiExpertPrediction: json['ai_expert_prediction'] as String?,
      aiExpertKeyFactors: json['ai_expert_key_factors'] != null
          ? List<String>.from(json['ai_expert_key_factors'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'score': score,
      'signal': signal,
      'data_quality': dataQuality?.toJson(),
      'target_price': targetPrice,
      'stop_loss': stopLoss,
      'rsi': rsi,
      'mfi': mfi,
      'macd': macd,
      'macd_signal': macdSignal,
      'macd_hist': macdHist,
      'bb_width': bbWidth,
      'bb_upper': bbUpper,
      'bb_lower': bbLower,
      'bb_middle': bbMiddle,
      'inst_ownership': instOwnership,
      'foreign_ownership': foreignOwnership,
      'insider_ownership': insiderOwnership,
      'inst_chg_1d': instChg1d,
      'inst_chg_5d': instChg5d,
      'foreign_chg_1d': foreignChg1d,
      'foreign_chg_5d': foreignChg5d,
      'short_ratio': shortRatio,
      'short_percent_float': shortPercentFloat,
      'ai_probability': aiProbability,
      'ai_summary': aiSummary,
      'ai_bullish_reasons': aiBullishReasons,
      'ai_bearish_reasons': aiBearishReasons,
      'ai_final_comment': aiFinalComment,
      'ai_analysis_ko': aiAnalysisKo,
      'ai_analysis_en': aiAnalysisEn,
      'ai_analysis_zh': aiAnalysisZh,
      'ai_analysis_ja': aiAnalysisJa,
      'ai_analysis_es': aiAnalysisEs,
      'ai_expert_prediction': aiExpertPrediction,
      'ai_expert_key_factors': aiExpertKeyFactors,
    };
  }

  /// `aiProbability`를 숫자로 보여줘도 되는가.
  ///
  /// 두 가지를 다 본다:
  /// - 서버가 AI 헤드를 돌렸는가 (`data_quality.ai_available`)
  /// - 확률이 실제로 왔는가 (null이면 그릴 것이 없다)
  ///
  /// `data_quality`가 없는 응답은 **보여주는 쪽으로** 기울인다. 그 경우는
  /// 점수 행이 없는 날짜이거나 구버전 서버 응답인데, 거기서 숨기는 쪽으로
  /// 기울이면 정상 종목의 AI 블록이 통째로 사라진다.
  bool get hasUsableAiProbability =>
      aiProbability != null && (dataQuality?.aiAvailable ?? true);

  /// Calculate price change percentage
  double? get priceChangePercent {
    if (open == null || close == null || open == 0) return null;
    return ((close! - open!) / open!) * 100;
  }

  /// Check if this is a bullish candle
  bool get isBullish => close != null && open != null && close! > open!;

  /// Check if this is a bearish candle
  bool get isBearish => close != null && open != null && close! < open!;

  /// Get signal color indicator
  SignalType get signalType {
    if (signal == null) return SignalType.neutral;
    switch (signal!.toUpperCase()) {
      case 'BUY':
        return SignalType.buy;
      case 'SELL':
        return SignalType.sell;
      case 'HOLD':
        return SignalType.hold;
      default:
        return SignalType.neutral;
    }
  }

  /// Returns expert analysis text matching the given locale
  String? expertAnalysisForLang(String langCode) {
    switch (langCode) {
      case 'ko': return aiAnalysisKo;
      case 'zh': return aiAnalysisZh;
      case 'ja': return aiAnalysisJa;
      case 'es': return aiAnalysisEs;
      default:   return aiAnalysisEn;
    }
  }
}

/// Signal type enumeration
enum SignalType {
  buy,
  sell,
  hold,
  neutral,
}

/// Analyst consensus data (aggregated target prices and recommendation)
class AnalystConsensus {
  final double? mean;
  final double? high;
  final double? low;
  final int? count;
  final String? recommendation;

  AnalystConsensus({this.mean, this.high, this.low, this.count, this.recommendation});

  factory AnalystConsensus.fromJson(Map<String, dynamic> json) {
    return AnalystConsensus(
      mean: (json['mean'] as num?)?.toDouble(),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      count: json['count'] as int?,
      recommendation: json['recommendation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mean': mean, 'high': high, 'low': low,
    'count': count, 'recommendation': recommendation,
  };
}

/// Company profile data
class CompanyProfile {
  final String? longName;
  final String? industry;
  final String? website;
  final String? country;
  final int? employees;
  final String? summary;

  CompanyProfile({
    this.longName,
    this.industry,
    this.website,
    this.country,
    this.employees,
    this.summary,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      longName: json['long_name'] as String?,
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      country: json['country'] as String?,
      employees: json['employees'] as int?,
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'long_name': longName,
    'industry': industry,
    'website': website,
    'country': country,
    'employees': employees,
    'summary': summary,
  };
}

/// Key valuation and financial metrics
class KeyMetrics {
  final double? marketCap;
  final double? pe;
  final double? forwardPe;
  final double? peg;
  final double? pb;
  final double? ps;
  final double? eps;
  final double? bps;
  final double? evRevenue;
  final double? evEbitda;
  final double? profitMargin;
  final double? operatingMargin;
  final double? grossMargin;
  final double? roe;
  final double? roa;
  final double? debtToEquity;
  final double? currentRatio;
  final double? beta;
  final double? dividendYield;
  final double? payoutRatio;
  final double? earningsGrowth;
  final double? revenueGrowth;

  KeyMetrics({
    this.marketCap,
    this.pe,
    this.forwardPe,
    this.peg,
    this.pb,
    this.ps,
    this.eps,
    this.bps,
    this.evRevenue,
    this.evEbitda,
    this.profitMargin,
    this.operatingMargin,
    this.grossMargin,
    this.roe,
    this.roa,
    this.debtToEquity,
    this.currentRatio,
    this.beta,
    this.dividendYield,
    this.payoutRatio,
    this.earningsGrowth,
    this.revenueGrowth,
  });

  factory KeyMetrics.fromJson(Map<String, dynamic> json) {
    return KeyMetrics(
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      pe: (json['pe'] as num?)?.toDouble(),
      forwardPe: (json['forward_pe'] as num?)?.toDouble(),
      peg: (json['peg'] as num?)?.toDouble(),
      pb: (json['pb'] as num?)?.toDouble(),
      ps: (json['ps'] as num?)?.toDouble(),
      eps: (json['eps'] as num?)?.toDouble(),
      bps: (json['bps'] as num?)?.toDouble(),
      evRevenue: (json['ev_revenue'] as num?)?.toDouble(),
      evEbitda: (json['ev_ebitda'] as num?)?.toDouble(),
      profitMargin: (json['profit_margin'] as num?)?.toDouble(),
      operatingMargin: (json['operating_margin'] as num?)?.toDouble(),
      grossMargin: (json['gross_margin'] as num?)?.toDouble(),
      roe: (json['roe'] as num?)?.toDouble(),
      roa: (json['roa'] as num?)?.toDouble(),
      debtToEquity: (json['debt_to_equity'] as num?)?.toDouble(),
      currentRatio: (json['current_ratio'] as num?)?.toDouble(),
      beta: (json['beta'] as num?)?.toDouble(),
      dividendYield: (json['dividend_yield'] as num?)?.toDouble(),
      payoutRatio: (json['payout_ratio'] as num?)?.toDouble(),
      earningsGrowth: (json['earnings_growth'] as num?)?.toDouble(),
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'market_cap': marketCap,
    'pe': pe,
    'forward_pe': forwardPe,
    'peg': peg,
    'pb': pb,
    'ps': ps,
    'eps': eps,
    'bps': bps,
    'ev_revenue': evRevenue,
    'ev_ebitda': evEbitda,
    'profit_margin': profitMargin,
    'operating_margin': operatingMargin,
    'gross_margin': grossMargin,
    'roe': roe,
    'roa': roa,
    'debt_to_equity': debtToEquity,
    'current_ratio': currentRatio,
    'beta': beta,
    'dividend_yield': dividendYield,
    'payout_ratio': payoutRatio,
    'earnings_growth': earningsGrowth,
    'revenue_growth': revenueGrowth,
  };
}

/// Financial statements data
class FinancialsData {
  final String? latestQuarter;
  final Map<String, dynamic>? income;
  final Map<String, dynamic>? balanceSheet;
  final Map<String, dynamic>? cashFlow;

  FinancialsData({this.latestQuarter, this.income, this.balanceSheet, this.cashFlow});

  factory FinancialsData.fromJson(Map<String, dynamic> json) {
    return FinancialsData(
      latestQuarter: json['latest_quarter'] as String?,
      income: json['income'] as Map<String, dynamic>?,
      balanceSheet: json['balance_sheet'] as Map<String, dynamic>?,
      cashFlow: json['cash_flow'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_quarter': latestQuarter,
    'income': income,
    'balance_sheet': balanceSheet,
    'cash_flow': cashFlow,
  };
}

/// Single dividend payment entry
class DividendEntry {
  final String exDate;
  final double? amount;

  DividendEntry({required this.exDate, this.amount});

  factory DividendEntry.fromJson(Map<String, dynamic> json) {
    return DividendEntry(
      exDate: json['ex_date'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ex_date': exDate,
    'amount': amount,
  };
}

/// Individual analyst rating entry (firm-level target price and rating)
class AnalystRating {
  final String? date;
  final String? status;
  final String? firm;
  final String? rating;
  final double? targetFrom;
  final double? targetTo;

  AnalystRating({this.date, this.status, this.firm, this.rating, this.targetFrom, this.targetTo});

  factory AnalystRating.fromJson(Map<String, dynamic> json) {
    return AnalystRating(
      date: json['date'] as String?,
      status: json['status'] as String?,
      firm: json['firm'] as String?,
      rating: json['rating'] as String?,
      targetFrom: (json['target_from'] as num?)?.toDouble(),
      targetTo: (json['target_to'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date, 'status': status, 'firm': firm,
    'rating': rating, 'target_from': targetFrom, 'target_to': targetTo,
  };
}

/// Calendar events for a ticker (earnings date, dividends, estimates)
class TickerCalendar {
  final String? nextEarningsDate;
  final String? nextEarningsDateEnd;
  final bool? earningsConfirmed;
  final int? dDay;
  final String? urgency;
  final int? earningsDaysRemaining;
  final String? exDividendDate;
  final String? dividendDate;
  final Map<String, double?>? earningsEstimate;
  final Map<String, double?>? revenueEstimate;

  TickerCalendar({
    this.nextEarningsDate,
    this.nextEarningsDateEnd,
    this.earningsConfirmed,
    this.dDay,
    this.urgency,
    this.earningsDaysRemaining,
    this.exDividendDate,
    this.dividendDate,
    this.earningsEstimate,
    this.revenueEstimate,
  });

  factory TickerCalendar.fromJson(Map<String, dynamic> json) {
    return TickerCalendar(
      nextEarningsDate: json['next_earnings_date'] as String?,
      nextEarningsDateEnd: json['next_earnings_date_end'] as String?,
      earningsConfirmed: json['earnings_confirmed'] as bool?,
      dDay: json['d_day'] as int?,
      urgency: json['urgency'] as String?,
      earningsDaysRemaining: json['earnings_days_remaining'] as int?,
      exDividendDate: json['ex_dividend_date'] as String?,
      dividendDate: json['dividend_date'] as String?,
      earningsEstimate: json['earnings_estimate'] != null
          ? (json['earnings_estimate'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num?)?.toDouble()),
            )
          : null,
      revenueEstimate: json['revenue_estimate'] != null
          ? (json['revenue_estimate'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num?)?.toDouble()),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'next_earnings_date': nextEarningsDate,
    'next_earnings_date_end': nextEarningsDateEnd,
    'earnings_confirmed': earningsConfirmed,
    'd_day': dDay,
    'urgency': urgency,
    'earnings_days_remaining': earningsDaysRemaining,
    'ex_dividend_date': exDividendDate,
    'dividend_date': dividendDate,
    'earnings_estimate': earningsEstimate,
    'revenue_estimate': revenueEstimate,
  };
}

/// Single earnings history entry (EPS estimate vs reported)
class EarningsHistoryEntry {
  final String date;
  final double? epsEstimate;
  final double? reportedEps;
  final double? surprisePct;

  EarningsHistoryEntry({
    required this.date,
    this.epsEstimate,
    this.reportedEps,
    this.surprisePct,
  });

  factory EarningsHistoryEntry.fromJson(Map<String, dynamic> json) {
    return EarningsHistoryEntry(
      date: json['date'] as String,
      epsEstimate: (json['eps_estimate'] as num?)?.toDouble(),
      reportedEps: (json['reported_eps'] as num?)?.toDouble(),
      surprisePct: (json['surprise_pct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'eps_estimate': epsEstimate,
    'reported_eps': reportedEps,
    'surprise_pct': surprisePct,
  };

  /// Whether reported EPS beat estimate
  bool get isBeat => (surprisePct ?? 0) > 0;

  /// Whether both estimate and reported values exist
  bool get hasBothValues => epsEstimate != null && reportedEps != null;
}
