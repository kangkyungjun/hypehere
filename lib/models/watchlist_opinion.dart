/// 관심종목 개인화 AI 의견 1건 (유저·종목·거래일별).
/// 서버 `watchlist_opinion` 테이블 / `GET /watchlist/opinion` 응답 항목과 1:1.
///
/// `opinion` 은 서버 컨벤션에 따라 두 형태 모두 허용:
///  - 다국어 `ko|||en|||zh|||ja|||es` 5세그먼트 (기존 final_comment 포맷) → 언어별 추출
///  - 서버가 lang 세그먼트만 추출해 내려준 단일 문자열 → 그대로 사용
class WatchlistOpinion {
  final String ticker;
  final String? date; // YYYY-MM-DD
  final String opinionRaw; // 원문(||| 5세그먼트 또는 단일)
  final String? stance; // BUY | HOLD | SELL (선택)
  final double? confidence; // 0.0 ~ 1.0 (선택)
  final double? targetBuyPrice; // 참고 에코 (선택)

  const WatchlistOpinion({
    required this.ticker,
    this.date,
    this.opinionRaw = '',
    this.stance,
    this.confidence,
    this.targetBuyPrice,
  });

  factory WatchlistOpinion.fromJson(Map<String, dynamic> j) => WatchlistOpinion(
        ticker: j['ticker'] as String? ?? '',
        date: (j['date'] as String?)?.split('T').first,
        opinionRaw: j['opinion'] as String? ?? '',
        stance: (j['stance'] as String?)?.toUpperCase(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        targetBuyPrice: (j['target_buy_price'] as num?)?.toDouble(),
      );

  /// opinion 이 비었으면(NULL/'') 앱에 노출하지 않는다 (서버 게이트와 동일 규칙).
  bool get isEmpty => opinionRaw.trim().isEmpty;

  /// 다국어 세그먼트 순서 — 기존 final_comment 포맷과 동일.
  static const List<String> _segOrder = ['ko', 'en', 'zh', 'ja', 'es'];

  /// 현재 언어에 맞는 서술 텍스트. `|||` 없으면 원문 그대로.
  /// 요청 언어 세그먼트가 비면 en → 첫 비어있지 않은 세그먼트로 폴백.
  String localizedOpinion(String langCode) {
    final raw = opinionRaw.trim();
    if (!raw.contains('|||')) return raw;
    final segs = raw.split('|||');
    String pick(String lang) {
      final i = _segOrder.indexOf(lang);
      if (i >= 0 && i < segs.length) {
        final s = segs[i].trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    final wanted = pick(langCode);
    if (wanted.isNotEmpty) return wanted;
    final en = pick('en');
    if (en.isNotEmpty) return en;
    return segs
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
  }
}
