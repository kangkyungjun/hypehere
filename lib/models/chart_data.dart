import 'news_data.dart';

/// Chart data models for MarketLens analytics API
///
/// Matches the server's CompleteChartResponse and ChartDataPoint schemas
class CompleteChartData {
  final String ticker;
  final List<ChartDataPoint> data;

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

  CompleteChartData({
    required this.ticker,
    required this.data,
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
  });

  /// Safe accessor: returns last data point or null if empty.
  ChartDataPoint? get lastOrNull => data.isEmpty ? null : data.last;

  factory CompleteChartData.fromJson(Map<String, dynamic> json) {
    return CompleteChartData(
      ticker: json['ticker'] as String,
      data: (json['data'] as List)
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
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
///
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

  ChartDataPoint({
    required this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.score,
    this.signal,
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
    };
  }

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
