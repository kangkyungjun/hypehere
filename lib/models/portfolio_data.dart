// Portfolio data models for AI Investment Brain system.
//
// Used by PortfolioApiClient and PortfolioProvider.

class PortfolioHolding {
  final String ticker;
  final double? shares;
  final double? avgPrice;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Server-enriched fields
  final String? name;
  final String? nameKo;
  final double? currentPrice;
  final double? changePct;
  final double? score;
  final String? signal;
  // Instant AI advice (generated on add/update from existing DB data)
  final PortfolioAdvice? instantAdvice;

  PortfolioHolding({
    required this.ticker,
    this.shares,
    this.avgPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.name,
    this.nameKo,
    this.currentPrice,
    this.changePct,
    this.score,
    this.signal,
    this.instantAdvice,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      ticker: json['ticker'] as String,
      shares: (json['shares'] as num?)?.toDouble(),
      avgPrice: (json['avg_price'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
      signal: json['signal'] as String?,
      instantAdvice: json['instant_advice'] != null
          ? PortfolioAdvice.fromJson(json['instant_advice'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Cost basis (avg_price * shares)
  double get costBasis => (shares ?? 0) * (avgPrice ?? 0);

  /// Current value
  double get currentValue => (shares ?? 0) * (currentPrice ?? 0);

  /// P&L in USD (0 when price unknown)
  double get pnl => currentPrice != null ? currentValue - costBasis : 0;

  /// P&L percentage (0 when price unknown)
  double get pnlPct {
    if (currentPrice == null || costBasis == 0) return 0;
    return (pnl / costBasis) * 100;
  }
}

class WatchlistItem {
  final String ticker;
  final String? notes;
  final DateTime? createdAt;
  final String? name;
  final String? nameKo;
  final double? currentPrice;
  final double? changePct;
  final double? score;
  final String? signal;

  WatchlistItem({
    required this.ticker,
    this.notes,
    this.createdAt,
    this.name,
    this.nameKo,
    this.currentPrice,
    this.changePct,
    this.score,
    this.signal,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      ticker: json['ticker'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
      signal: json['signal'] as String?,
    );
  }
}

class PortfolioTransaction {
  final int id;
  final String ticker;
  final String type; // BUY | SELL
  final double shares;
  final double price;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;
  final double? realizedPnl;

  PortfolioTransaction({
    required this.id,
    required this.ticker,
    required this.type,
    required this.shares,
    required this.price,
    required this.date,
    this.notes,
    this.createdAt,
    this.realizedPnl,
  });

  factory PortfolioTransaction.fromJson(Map<String, dynamic> json) {
    return PortfolioTransaction(
      id: json['id'] as int,
      ticker: json['ticker'] as String,
      type: json['type'] as String,
      shares: (json['shares'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      realizedPnl: (json['realized_pnl'] as num?)?.toDouble(),
    );
  }

  /// Total transaction value
  double get totalValue => shares * price;
}

class PortfolioAdvice {
  final String ticker;
  final DateTime date;
  final String? signal;
  final double? confidence;
  final String? summary;
  final Map<String, dynamic>? reasons;
  final String? targetAction;
  final String? name;
  final String? nameKo;
  final double? currentPrice;
  final double? score;

  PortfolioAdvice({
    required this.ticker,
    required this.date,
    this.signal,
    this.confidence,
    this.summary,
    this.reasons,
    this.targetAction,
    this.name,
    this.nameKo,
    this.currentPrice,
    this.score,
  });

  factory PortfolioAdvice.fromJson(Map<String, dynamic> json) {
    return PortfolioAdvice(
      ticker: json['ticker'] as String,
      date: DateTime.parse(json['date'] as String),
      signal: json['signal'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      summary: json['summary'] as String?,
      reasons: json['reasons'] as Map<String, dynamic>?,
      targetAction: json['target_action'] as String?,
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  List<String> get bullishReasons =>
      (reasons?['bullish'] as List?)?.cast<String>() ?? [];

  List<String> get bearishReasons =>
      (reasons?['bearish'] as List?)?.cast<String>() ?? [];
}

class PortfolioSummary {
  final DateTime date;
  final double? totalValue;
  final double? totalCost;
  final double? totalPnl;
  final double? totalPnlPct;
  final double? dayPnl;
  final double? dayPnlPct;
  final List<Map<String, dynamic>>? holdingsDetail;
  final String? aiSummary;
  final List<Map<String, dynamic>>? aiRecommendations;
  final double? realizedPnl;
  final Map<String, dynamic>? periods;
  final List<Map<String, dynamic>>? tradeHistory;

  PortfolioSummary({
    required this.date,
    this.totalValue,
    this.totalCost,
    this.totalPnl,
    this.totalPnlPct,
    this.dayPnl,
    this.dayPnlPct,
    this.holdingsDetail,
    this.aiSummary,
    this.aiRecommendations,
    this.realizedPnl,
    this.periods,
    this.tradeHistory,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      date: DateTime.parse(json['date'] as String),
      totalValue: (json['total_value'] as num?)?.toDouble(),
      totalCost: (json['total_cost'] as num?)?.toDouble(),
      totalPnl: (json['total_pnl'] as num?)?.toDouble(),
      totalPnlPct: (json['total_pnl_pct'] as num?)?.toDouble(),
      dayPnl: (json['day_pnl'] as num?)?.toDouble(),
      dayPnlPct: (json['day_pnl_pct'] as num?)?.toDouble(),
      holdingsDetail: (json['holdings_detail'] as List?)
          ?.cast<Map<String, dynamic>>(),
      aiSummary: json['ai_summary'] as String?,
      aiRecommendations: (json['ai_recommendations'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      realizedPnl: (json['realized_pnl'] as num?)?.toDouble(),
      periods: json['periods'] as Map<String, dynamic>?,
      tradeHistory: (json['trade_history'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

class UserAlert {
  final int id;
  final String? ticker;
  final String alertType;
  final String title;
  final String? message;
  final String? priority;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  UserAlert({
    required this.id,
    this.ticker,
    required this.alertType,
    required this.title,
    this.message,
    this.priority,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  factory UserAlert.fromJson(Map<String, dynamic> json) {
    return UserAlert(
      id: json['id'] as int,
      ticker: json['ticker'] as String?,
      alertType: json['alert_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      priority: json['priority'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ExchangeRate {
  final DateTime date;
  final double usdKrw;

  ExchangeRate({required this.date, required this.usdKrw});

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      date: DateTime.parse(json['date'] as String),
      usdKrw: (json['usd_krw'] as num).toDouble(),
    );
  }
}
