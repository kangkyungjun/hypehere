/// 티커 검색어 정규화 — 클래스주 표기 차이를 흡수한다.
///
/// 파이프라인은 **하이픈 표기**를 쓴다: `BRK-B`, `BF-B`.
/// 하지만 사용자는 같은 종목을 `BRK.B`(야후·블룸버그 표기)나 `BRKB`(공백
/// 없는 축약)로도 친다. 서버가 정확 일치만 하면 **멀쩡한 종목이 검색에서
/// 안 나온다.**
///
/// ## 현재 역할: 완충장치
///
/// 2026-10-02부터 **서버가 정규화한다**(S3 적용 완료). `BRKB`·`BRK.B`·
/// `brk b` 모두 서버가 `BRK-B`를 찾아 준다. 호출부는 원본으로 먼저 묻고
/// **빈 결과일 때만** 변형을 시도하므로, 평상시엔 변형 질의가 아예
/// 나가지 않는다.
///
/// 그래도 남겨 둔다 — 틀린 코드가 아니고, 런타임 비용이 0이며, 서버가
/// 회귀하면 그때 다시 동작한다.
library;

/// `.`·`-`·공백을 제거하고 대문자로. 비교용 키다.
///
/// `BRK.B` · `BRK-B` · `brk b` → 전부 `BRKB`
String normalizeTicker(String raw) =>
    raw.replaceAll(RegExp(r'[.\-\s]'), '').toUpperCase();

/// 서버에 시도해 볼 질의 변형들. **입력 순서가 우선순위**다.
///
/// 원본을 먼저 둔다 — 사용자가 친 그대로가 맞을 가능성이 가장 높고,
/// 서버가 이미 정규화를 한다면 한 번에 끝난다.
///
/// 변형은 **티커로 보일 때만** 만든다. `애플`이나 `apple inc`처럼 회사명을
/// 친 경우까지 변형하면 의미 없는 질의만 늘린다.
///
/// ⚠️ 구분자 없이 `BRKB`로 친 경우는 변형하지 않는다 — `NVDA`·`TSLA` 같은
/// 4글자 일반 티커와 구분할 방법이 없다. 그 케이스는 **서버 정규화(S3)**가
/// 맡는다. 2026-10-02 적용 확인: `BRKB` → `BRK-B` 1건.
List<String> tickerQueryVariants(String raw) {
  final q = raw.trim();
  if (q.isEmpty) return const [];

  final out = <String>[q];
  if (!looksLikeTicker(q)) return out;

  final stripped = normalizeTicker(q);

  // 클래스주 변형은 **입력에 구분자가 있을 때만** 만든다.
  //
  // 끝 글자가 A·B·C면 클래스주로 보는 휴리스틱을 먼저 썼다가
  // `NVDA` → `NVD-A`, `TSLA` → `TSL-A` 같은 쓰레기 질의를 만들었다.
  // 4글자 일반 티커와 `BRKB` 같은 축약 표기는 **문자열만으로 구분할 수 없다.**
  // 구분자(`.`·`-`)는 사용자가 클래스주를 의도했다는 명확한 신호다.
  final hasSeparator = RegExp(r'[.\-]').hasMatch(q);
  if (hasSeparator && stripped.length >= 3) {
    final head = stripped.substring(0, stripped.length - 1);
    final tail = stripped.substring(stripped.length - 1);
    for (final v in ['$head-$tail', '$head.$tail']) {
      if (!out.contains(v)) out.add(v);
    }
  }

  // 구분자를 뗀 형태도 시도한다. 원본과 같으면 추가하지 않는다.
  if (!out.contains(stripped)) out.add(stripped);
  return out;
}

/// 티커처럼 보이는가 — 영문자·숫자와 `.`·`-`만으로 된 짧은 토큰.
///
/// 한글이나 공백이 들어가면 회사명 검색으로 본다.
bool looksLikeTicker(String raw) {
  final q = raw.trim();
  return q.isNotEmpty &&
      q.length <= 8 &&
      RegExp(r'^[A-Za-z0-9.\-]+$').hasMatch(q);
}
