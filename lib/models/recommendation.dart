/// 맥미니(deep_bot)가 생성한 유저별 스타일 추천종목 (Phase C).
///
/// 서버 응답: GET /api/marketlens/accounts/recommendations/?date=...
/// {
///   "date": "2026-06-03", "style": "balanced",
///   "recommendations": [ { rank, ticker, name, name_ko, fit_score,
///       current_price, change_pct, signal, rationale: {summary, reasons} } ]
/// }
class RecommendedTicker {
  final int rank;
  final String ticker;
  final String? name;
  final String? nameKo;
  final double fitScore;
  final double? currentPrice;
  final double? changePct;
  final String? signal;
  final String? rationaleSummary;
  final List<String> rationaleReasons;

  const RecommendedTicker({
    required this.rank,
    required this.ticker,
    this.name,
    this.nameKo,
    required this.fitScore,
    this.currentPrice,
    this.changePct,
    this.signal,
    this.rationaleSummary,
    this.rationaleReasons = const [],
  });

  factory RecommendedTicker.fromJson(Map<String, dynamic> json) {
    final rationale = json['rationale'];
    String? summary;
    List<String> reasons = const [];
    if (rationale is Map) {
      summary = rationale['summary'] as String?;
      final r = rationale['reasons'];
      if (r is List) {
        reasons = r.map((e) => e.toString()).toList();
      }
    }
    return RecommendedTicker(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      ticker: json['ticker'] as String? ?? '',
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      fitScore: (json['fit_score'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      signal: json['signal'] as String?,
      rationaleSummary: summary,
      rationaleReasons: reasons,
    );
  }
}

/// 추천 조회 결과 묶음 (날짜 + 유저 성향 + 목록).
class RecommendationResult {
  final DateTime? date;
  final String? style; // conservative | balanced | aggressive
  final List<RecommendedTicker> items;

  const RecommendationResult({
    required this.date,
    required this.style,
    required this.items,
  });

  bool get isEmpty => items.isEmpty;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final list = json['recommendations'];
    return RecommendationResult(
      date: dateStr != null ? DateTime.tryParse(dateStr) : null,
      style: json['style'] as String?,
      items: list is List
          ? list
              .whereType<Map<String, dynamic>>()
              .map(RecommendedTicker.fromJson)
              .toList()
          : const [],
    );
  }
}
