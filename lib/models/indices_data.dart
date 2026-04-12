/// Market indices API response model (SPY, QQQ, DIA)
class MarketIndicesData {
  final String date;
  final List<MarketIndexData> indices;

  MarketIndicesData({required this.date, required this.indices});

  factory MarketIndicesData.fromJson(Map<String, dynamic> json) {
    return MarketIndicesData(
      date: json['date'] as String? ?? '',
      indices: (json['indices'] as List?)
              ?.map((item) =>
                  MarketIndexData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Single market index data (e.g. SPY → S&P 500)
class MarketIndexData {
  final String code;
  final String name;
  final double close;
  final double prevClose;
  final double change;
  final double changePct;
  final double? open;
  final double? high;
  final double? low;
  final int? volume;
  final List<IndexChartPoint> chart;

  MarketIndexData({
    required this.code,
    required this.name,
    required this.close,
    required this.prevClose,
    required this.change,
    required this.changePct,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.chart = const [],
  });

  factory MarketIndexData.fromJson(Map<String, dynamic> json) {
    return MarketIndexData(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      prevClose: (json['prev_close'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      changePct: (json['change_pct'] as num?)?.toDouble() ?? 0.0,
      open: (json['open'] as num?)?.toDouble(),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      volume: json['volume'] as int?,
      chart: (json['chart'] as List?)
              ?.map((item) =>
                  IndexChartPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Single chart point for sparkline
class IndexChartPoint {
  final String date;
  final double close;

  IndexChartPoint({required this.date, required this.close});

  factory IndexChartPoint.fromJson(Map<String, dynamic> json) {
    return IndexChartPoint(
      date: json['date'] as String? ?? '',
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
