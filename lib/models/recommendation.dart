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
  final double? pe; // 현재 PER (null 가능)
  final double? industryAvgPe; // 업종평균 PER (null 가능)

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
    this.pe,
    this.industryAvgPe,
  });

  /// pe > 업종평균 → 고평가, pe < 업종평균 → 저평가. 둘 중 하나라도 null이면 null.
  bool? get isOvervalued {
    if (pe == null || industryAvgPe == null) return null;
    if (pe == industryAvgPe) return null;
    return pe! > industryAvgPe!;
  }

  factory RecommendedTicker.fromJson(Map<String, dynamic> json) {
    final rationale = json['rationale'];
    String? summary;
    List<String> reasons = const [];
    double? pe;
    double? industryAvgPe;
    if (rationale is Map) {
      summary = rationale['summary'] as String?;
      final r = rationale['reasons'];
      if (r is List) {
        reasons = r.map((e) => e.toString()).toList();
      }
      // PER은 rationale.metrics 안(권장 경로) → rationale 최상위 순으로 탐색.
      final metrics = rationale['metrics'];
      if (metrics is Map) {
        pe = (metrics['pe'] as num?)?.toDouble();
        industryAvgPe = (metrics['industry_avg_pe'] as num?)?.toDouble();
      }
      pe ??= (rationale['pe'] as num?)?.toDouble();
      industryAvgPe ??= (rationale['industry_avg_pe'] as num?)?.toDouble();
    }
    // top-level 폴백(서버가 정규 컬럼으로 서빙하게 되는 경우 대비).
    pe ??= (json['pe'] as num?)?.toDouble();
    industryAvgPe ??= (json['industry_avg_pe'] as num?)?.toDouble();
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
      pe: pe,
      industryAvgPe: industryAvgPe,
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
