import 'dart:ui';

/// Treemap API response model
///
/// Matches the server's GET /api/v1/market/treemap response
/// Contains sectors with grouped tickers for treemap visualization
class TreemapData {
  final String date;
  final int totalTickers;
  final List<TreemapSector> sectors;

  TreemapData({
    required this.date,
    required this.totalTickers,
    required this.sectors,
  });

  factory TreemapData.fromJson(Map<String, dynamic> json) {
    return TreemapData(
      date: json['date'] as String,
      totalTickers: json['total_tickers'] as int,
      sectors: (json['sectors'] as List)
          .map((item) => TreemapSector.fromJson(item))
          .toList(),
    );
  }
}

/// Sector group in treemap
class TreemapSector {
  final String sector;
  final int tickerCount;
  final double? avgChangePct;
  final double? totalTradingValue;
  final List<TreemapItem> items;

  TreemapSector({
    required this.sector,
    required this.tickerCount,
    this.avgChangePct,
    this.totalTradingValue,
    required this.items,
  });

  factory TreemapSector.fromJson(Map<String, dynamic> json) {
    return TreemapSector(
      sector: json['sector'] as String,
      tickerCount: json['ticker_count'] as int,
      avgChangePct: (json['avg_change_pct'] as num?)?.toDouble(),
      totalTradingValue: (json['total_trading_value'] as num?)?.toDouble(),
      items: (json['items'] as List)
          .map((item) => TreemapItem.fromJson(item))
          .toList(),
    );
  }

  /// Color based on avg_change_pct
  Color get changeColor => getChangeColor(avgChangePct);

  /// Formatted trading value: $50.2B, $1.3M, etc.
  String get formattedTradingValue => formatDollar(totalTradingValue);
}

/// Individual ticker in treemap
class TreemapItem {
  final String ticker;
  final String? name;
  final String? sector;
  final String? subIndustry;
  final double? changePct;
  final double? tradingValue;
  final double? close;
  final int? volume;
  final double? score;
  final String? signal;

  TreemapItem({
    required this.ticker,
    this.name,
    this.sector,
    this.subIndustry,
    this.changePct,
    this.tradingValue,
    this.close,
    this.volume,
    this.score,
    this.signal,
  });

  factory TreemapItem.fromJson(Map<String, dynamic> json) {
    return TreemapItem(
      ticker: json['ticker'] as String,
      name: json['name'] as String?,
      sector: json['sector'] as String?,
      subIndustry: json['sub_industry'] as String?,
      changePct: (json['change_pct'] as num?)?.toDouble(),
      tradingValue: (json['trading_value'] as num?)?.toDouble(),
      close: (json['close'] as num?)?.toDouble(),
      volume: json['volume'] as int?,
      score: (json['score'] as num?)?.toDouble(),
      signal: json['signal'] as String?,
    );
  }

  /// Color based on change_pct
  Color get changeColor => getChangeColor(changePct);

  /// Formatted trading value
  String get formattedTradingValue => formatDollar(tradingValue);
}

/// Color mapping: green for positive, red for negative, grey for null
/// Clamped to +/-5% range for intensity
Color getChangeColor(double? changePct) {
  if (changePct == null) return const Color(0xFF757575);
  final clamped = changePct.clamp(-5.0, 5.0);
  final t = clamped.abs() / 5.0;
  if (changePct >= 0) {
    return Color.lerp(
      const Color(0xFF2D4A2D),
      const Color(0xFF00C853),
      t,
    )!;
  } else {
    return Color.lerp(
      const Color(0xFF4A2D2D),
      const Color(0xFFD50000),
      t,
    )!;
  }
}

/// Format dollar value: $15.2B, $320.5M, $1.2K
String formatDollar(double? value) {
  if (value == null) return '-';
  final abs = value.abs();
  String formatted;
  if (abs >= 1e9) {
    formatted = '\$${(value / 1e9).toStringAsFixed(1)}B';
  } else if (abs >= 1e6) {
    formatted = '\$${(value / 1e6).toStringAsFixed(1)}M';
  } else if (abs >= 1e3) {
    formatted = '\$${(value / 1e3).toStringAsFixed(1)}K';
  } else {
    formatted = '\$${value.toStringAsFixed(0)}';
  }
  return formatted;
}
