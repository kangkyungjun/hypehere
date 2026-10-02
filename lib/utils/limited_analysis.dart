/// `limited`(제한 분석) 종목의 **임시** 판별.
///
/// ## 왜 임시인가
///
/// 정본 신호는 `data_quality.analysis_mode`다. 맥미니는 2026-10-01부터
/// `/ingest/scores`로 보내고 있지만, **조회 API에 노출되기 전까지 앱은 받을
/// 방법이 없다**(서버 요청 S1). 맥미니 회신(2026-10-02)도 아래 방법을
/// "권장하지 않는 임시 방편"이라고 명시했다.
///
/// 그럼에도 쓰는 이유: `limited` 종목은 `probability`를 **0.5로 명시해서**
/// 보낸다. 앱은 그걸 "AI 상승 확률 50% + 상승"으로 그린다 —
/// **서버가 판단을 포기한 자리에 앱이 중립 판정을 지어내는 것**이다.
/// 지금 FDXF·HONA·SPCX 셋이 그 상태다. 틀린 숫자를 몇 주 더 보여주는 것보다
/// 문자열 매칭의 위험이 작다고 판단했다.
///
/// ## 안전 설계
///
/// - **숨기는 방향으로만** 쓴다. 오탐이 나도 "AI 블록이 안 보임"이 최악이고,
///   미탐이면 지금과 같다. 반대로 쓰면(이걸로 뭔가를 보여주면) 오탐이 거짓
///   정보가 된다.
/// - 맥미니가 제시한 신호 둘 중 **접두사만** 쓴다. `probability_multi == null`은
///   과거 single-head 모델 행에서도 null이라 오탐이 크다고 회신에 적혀 있다.
///
/// ## 제거 조건
///
/// `data_quality`가 조회 API에 나오면 **이 파일을 통째로 지우고**
/// `analysis_mode == 'limited'`로 교체한다.
library;

/// 서버가 `limited` 종목의 요약 맨 앞에 붙이는 안내문의 언어별 접두사.
///
/// 맥미니 회신은 "ko 세그먼트가 `[제한 분석]`으로 시작"이라 했다. 다른 언어도
/// 같은 자리에 해당 언어 안내문이 붙으므로 함께 본다 — 사용자 언어가 무엇이든
/// 같은 판정이 나와야 한다.
const _limitedPrefixes = <String>[
  '[제한 분석]',
  '[Limited analysis]',
  '[限定分析]',
  '[限定的な分析]',
  '[Análisis limitado]',
];

/// 요약 텍스트가 `limited` 안내문으로 시작하는가.
///
/// [rawSummary]는 `ko|||en|||zh|||ja|||es` 팩 문자열이거나 단일 문자열이다.
/// **어느 세그먼트든** 접두사로 시작하면 `limited`로 본다 — 사용자 언어를
/// 몰라도 되고, 일부 언어만 채워진 과거 행에서도 걸린다.
bool looksLimited(String? rawSummary) {
  if (rawSummary == null || rawSummary.isEmpty) return false;
  for (final seg in rawSummary.split('|||')) {
    final t = seg.trimLeft();
    for (final p in _limitedPrefixes) {
      if (t.startsWith(p)) return true;
    }
  }
  return false;
}
