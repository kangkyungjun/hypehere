import 'ticker_score.dart';

/// Market insights model for dashboard
///
/// Matches the server's /api/v1/scores/insights response
/// Contains both top and bottom performing tickers
class MarketInsights {
  final String? date;
  final List<TickerScore> topMovers;
  final List<TickerScore> bottomMovers;

  MarketInsights({
    this.date,
    required this.topMovers,
    required this.bottomMovers,
  });

  factory MarketInsights.fromJson(Map<String, dynamic> json) {
    return MarketInsights(
      date: json['date'] as String?,
      topMovers: (json['top_movers'] as List?)
          ?.map((item) => TickerScore.fromJson(item))
          .toList() ?? [],
      bottomMovers: (json['bottom_movers'] as List?)
          ?.map((item) => TickerScore.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'top_movers': topMovers.map((t) => t.toJson()).toList(),
      'bottom_movers': bottomMovers.map((t) => t.toJson()).toList(),
    };
  }
}
