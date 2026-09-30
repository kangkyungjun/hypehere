import 'package:flutter/material.dart';

/// MarketLens 타이포그래피 상수
///
/// 전체 앱에서 일관된 글꼴 크기/굵기 사용을 위한 시맨틱 토큰.
///
/// ## 스케일 정본은 `docs/reference/heydealer/SPEC.md` **부록 A**다
///
/// 레퍼런스를 화면폭 대비 천분율(‰)로 재측정하고 402pt 화면으로 환산한 값을
/// 반올림해 쓴다. 절대 dp 추정은 기기 폭 가정이 틀리면 전부 틀어지므로 폐기했다.
///
/// ```
/// 읽기:  37 · 31 · 24 · 22 · 20 · 18 · 16 · 15 · 14 · 13
/// 기물:  11(배지) · 10(차트축) · 9(차트미세)
/// ```
///
/// ⚠️ `docs/UIUX_CONFIRMED_SPEC.md` §3의 표(34/28/…/12)는 **이 파일과 일치한 적이
/// 없다.** 그 문서를 작성한 바로 그 커밋(`b760b5e`, 2026-08-30)이 처음부터 부록 A
/// 값을 코드에 썼다. 2026-09-30에 문서를 코드에 맞춰 정정했다 — **값의 정본은
/// 여기고, 문서가 코드를 따른다.**
///
/// ### 불변 원칙
///
/// 1. **하한 동결** — 13/11/10/9는 올리지 않는다. 밀집도(사용자 최우선 제약)를
///    지키는 방어선이며, 고정높이 pill과 차트 `reservedSize`가 하드 의존한다.
/// 2. **상한 개방** — 히어로는 자기 행을 독점하므로 키워도 밀집도 비용이 0이다.
/// 3. **프리셋을 쓴다** — `TextStyle(fontSize: AppTypography.x)`로 크기만 빌려
///    쓰면 `height`·`letterSpacing`·tabular가 빠진다. 현재 이 우회가 **629건
///    (68.5%)** 이라 행간이 흩어져 있다. 신규 코드는 프리셋(`body`·`cardTitle`·
///    `priceCard` …)을 쓸 것.
///
/// 하드코딩 `fontSize:` 숫자는 `trend_modal.dart:430` 1건만 남아 있다.
abstract final class AppTypography {
  // ── 읽기 스케일 (7단계) ──────────────────────────────────
  // 위계를 만드는 단계. 인접 비율 1.17배 이상을 유지한다.

  /// 화면당 단 하나뿐인 히어로 숫자 — 티커 현재가, 총자산 평가액. (37px)
  ///
  /// 부록 A 계측 37.5를 반올림. 37/14 = 2.64배로 게이트(≥2.5)를 넘긴다.
  static const double heroMedium = 37.0;

  /// 2순위 히어로 — 카드 내 대표 숫자, 종합점수, 애널리스트 목표가. (31px)
  ///
  /// 부록 A의 번호판 칩 31.4 대응. 31/14 = 2.21배.
  static const double heroSmall = 31.0;

  /// 화면 최상단 타이틀. (24px)
  static const double displayLarge = 24.0;

  /// 섹션 타이틀의 기반값. (22px)
  ///
  /// ⚠️ 별칭이 **아니다.** 스펙 §3은 "`displayLarge`와 통합(24)"이라 기록했으나
  /// 실제로는 독립값 22로 남았고, `sectionTitle` → `SectionHeader`·`MlCardTitle`
  /// 경로로 앱 전체 제목에 파급된다.
  static const double displaySmall = 22.0;

  /// 화면 타이틀, AppBar. (20px)
  ///
  /// ⚠️ **동결 필수** — `lib/main.dart`의 `AppBar(toolbarHeight: 34)`가 이 값에
  /// 의존한다. 22로만 올려도 텍스트 확대 1.3×에서 34.3 > 34로 넘쳐 깨진다.
  static const double displayMedium = 20.0;

  /// 섹션 타이틀. (18px)
  ///
  /// 1차 개편에서 20으로 올렸다가 "과하다" 판정으로 원복. 섹션 가시성은
  /// **크기가 아니라 구조**로 만든다 — `SectionHeader`의 액센트 바 +
  /// 비대칭 여백(위 넓게/아래 좁게)이 그 역할을 맡는다.
  static const double headlineLarge = 18.0;

  /// 카드 타이틀, 리스트 행 대표값. (16px)
  ///
  /// 1차 개편의 17에서 원복 — 53개 호출부의 부피가 체감상 과했다.
  static const double headlineMedium = 16.0;

  /// `headlineMedium`과 통합됨(구 15px). 14와 16 사이에 낀 死단계였다. (16px)
  static const double headlineSmall = headlineMedium;

  /// 본문 기준선, 키밸류 값. (15px)
  ///
  /// 부록 A의 "값·2행 `520i 럭셔리` 15.1" 대응.
  static const double bodyLarge = 15.0;

  /// 보조 본문, 키밸류 라벨. (14px)
  ///
  /// 부록 A의 "라벨·KV·그룹헤더 14.5" 대응.
  ///
  /// ⚠️ 라벨/값 위계는 **크기가 아니라 색·굵기로만** 만든다(레퍼런스의 라벨:값
  /// 크기비는 1.04배). 현재 `kvLabel`(14)과 `kvValue`(15)가 1px 벌어져 있어
  /// 그 기법이 무력화돼 있다 — 둘을 같은 값으로 맞추는 것이 통일 규약 2다.
  static const double bodyMedium = 14.0;

  /// 라벨 기준선, 보조 정보. (13px)
  ///
  /// **앱 최다 사용 단계(183 호출부 / 67파일).** 여기가 읽기 스케일의 하한이며
  /// 동결한다. 더 작은 것은 전부 기물 스케일(11/10/9)로 내려보낸다.
  ///
  /// ⚠️ 스펙 §3은 이 값을 "12 동결"이라 기록했으나 코드는 처음부터 13이었다.
  static const double bodySmall = 13.0;

  // ── 기물 스케일 (3단계) ──────────────────────────────────
  // 위계 요소가 아니라 고정 크기 부품. 스케일 개편에서 값을 바꾸지 않는다.

  /// 배지/pill 전용 + 차트 축 라벨. (11px)
  ///
  /// 부록 C 규정: 축 라벨은 `caption`(11)을 쓴다. `micro`(10)는 읽기 어려웠다.
  ///
  /// ⚠️ 세로 패딩 ≤4px인 pill이 앱 전체에 31곳 있다. 올리면 전부 넘친다.
  static const double caption = 11.0;

  /// 하단 탭 라벨·알림 뱃지 등 초소형 기물. (10px)
  ///
  /// ⚠️ 차트 축에는 쓰지 않는다 — 부록 C가 `caption`(11)으로 규정했다.
  ///
  /// ⚠️ fl_chart `reservedSize`는 하드 클립 경계라 소프트 폴백이 없다.
  /// 현재 여유가 2~3px뿐이므로 **동결**.
  static const double micro = 10.0;

  /// 차트 미세 라벨. (9px)
  static const double chartLabel = 9.0;

  /// `chartLabel`과 통합됨(구 8px). 8px는 접근성 하한 미달이었다. (9px)
  ///
  /// 호출부 1곳. 사실상 死토큰이다.
  static const double chartMicro = chartLabel;

  // ── Font Weights ────────────────────────────────────────

  /// 강한 강조, 히어로 숫자 (w700)
  ///
  /// ⚠️ 남용 주의 — 개편 전 명시적 굵기 510건 중 273건(53.5%)이 이 값이었다.
  /// 절반이 굵으면 아무것도 굵지 않다. **하나의 카드 안에 w700은 최대 1개.**
  static const FontWeight bold = FontWeight.bold;

  /// 중간 강조, 카드 타이틀·키밸류 값 (w600)
  static const FontWeight semiBold = FontWeight.w600;

  /// 약한 강조, 라벨 (w500)
  static const FontWeight medium = FontWeight.w500;

  /// 기본 굵기, 일반 본문 텍스트 (w400)
  static const FontWeight regular = FontWeight.normal;

  /// 숫자 정렬을 위한 fontFeatures
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  // ── Semantic Text Styles ───────────────────────────────

  /// 화면 최상단 타이틀. (24 w700)
  static const TextStyle screenTitle = TextStyle(
    fontSize: displayLarge,
    fontWeight: bold,
    height: 1.20,
    letterSpacing: -0.4,
  );

  /// 섹션 타이틀. (22 w700 — `displaySmall`)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: displaySmall,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: -0.3,
  );

  /// 카드·리스트 제목. (18 w700)
  ///
  /// 처음엔 w600으로 두고 "카드 안의 w700은 숫자 몫"이라 규정했으나,
  /// **호출부 55%가 `copyWith(fontWeight: bold)`로 덮고 있었다** — 토큰이
  /// 틀렸다는 신호다. 레퍼런스도 카드 제목(`비슷한 차 견적결과`)과 리스트
  /// 1행(`2023년형 │ 3만km`)이 Bold다.
  ///
  /// 규율은 "카드당 w700 1개"가 아니라 **"제목 1 + 히어로 숫자 1"** 이다.
  static const TextStyle cardTitle = TextStyle(
    fontSize: headlineLarge,
    fontWeight: bold,
    height: 1.30,
    letterSpacing: -0.2,
  );

  /// 산문 본문 — AI 답변·뉴스 요약·채팅. (15 w400 — `bodyLarge`)
  static const TextStyle body = TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    height: 1.45,
  );

  /// 채팅 산문 — 대화는 길게 읽으므로 본문(15)보다 한 단계 크고 행간도 넉넉히.
  ///
  /// 개편 전 두 말풍선이 각각 `body.copyWith(fontSize: headlineMedium,
  /// height: 1.55)`로 같은 오버라이드를 반복하고 있었다.
  static const TextStyle chatBody = TextStyle(
    fontSize: headlineMedium,
    fontWeight: regular,
    height: 1.55,
  );

  /// 강조 본문. (15 w600 — `bodyLarge`)
  static const TextStyle bodyStrong = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.40,
  );

  /// 라벨, 부가 정보. (13 w500 — `bodySmall`)
  static const TextStyle label = TextStyle(
    fontSize: bodySmall,
    fontWeight: medium,
    height: 1.25,
    letterSpacing: 0.1,
  );

  // ── Key-Value 패턴 ──────────────────────────────────────
  //
  // ★ 레퍼런스 계측(`docs/reference/heydealer/SPEC.md` §1)의 결정적 발견:
  //   `사고 / 완전무사고`, `모델명 / BMW 5시리즈` — 라벨과 값의 **크기가 같다**
  //   (둘 다 15~16px). 위계는 오직 **색(뮤트↔검정) + 굵기(w500↔w600)** 로
  //   만든다.
  //
  //   이것이 "여백 타이트 유지"와 위계를 양립시키는 정확한 기법이다.
  //   크기를 벌리면 행 높이가 늘지만, 색과 굵기는 **픽셀 비용이 0**이다.

  /// 키밸류 라벨 — `textTertiary`와 함께 쓴다. (14 w500 — `bodyMedium`)
  static const TextStyle kvLabel = TextStyle(
    fontSize: bodyMedium,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// 키밸류 값 — `textPrimary`와 함께 쓴다. (15 w600 — `bodyLarge`)
  ///
  /// ⚠️ 라벨(14)과 **1px 벌어져 있다.** 레퍼런스의 기법은 크기를 같게 두고
  /// 색·굵기로만 나누는 것이다 — 통일 규약 2에서 맞춘다.
  static const TextStyle kvValue = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.2,
    fontFeatures: tabularFigures,
  );

  // ── 단위 접미사 (레퍼런스 시그니처) ────────────────────────
  //
  // ★ "큰 값 + 작은 단위" — `3,500`(40) + `만원`(20~24), `3,230`(21) + `만원`(13).
  //   계측된 비율은 **1.6~1.7 : 1**로 일정하다. 단위는 같은 색 계열에서
  //   한 단계 뮤트하고 굵기를 한 단계 낮춘다. 여백 추가는 0.
  //
  //   값 스케일에 맞는 단위 토큰을 짝지어 쓸 것:
  //     priceHero(40)  ↔ unitSuffixHero(17)   비 2.35
  //     priceLarge(30) ↔ unitSuffixLarge(14)  비 2.14
  //     priceCard(17)  ↔ unitSuffix(12)       비 1.42

  /// 소형 값 뒤 단위 — `%`/`pt`. (12 w500 — `chipLabelSize`)
  static const TextStyle unitSuffix = TextStyle(
    fontSize: chipLabelSize,
    fontWeight: medium,
    height: 1.2,
  );

  /// 31px 히어로 뒤 단위 — `M`/`T`/`만원`. (15 w600) ⚠️ 호출부 0 — 死토큰
  static const TextStyle unitSuffixLarge = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.1,
  );

  /// 37px 히어로 뒤/앞 단위 — 통화기호 `\$`. (16 w600) ⚠️ 호출부 0 — 死토큰
  static const TextStyle unitSuffixHero = TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    height: 1.0,
  );

  // ── Numeric Styles (주가, 수익률 등 숫자 강조용) ──────────

  /// 화면당 유일한 히어로 숫자. (37 w700 tabular — `heroMedium`)
  static const TextStyle priceHero = TextStyle(
    fontSize: heroMedium,
    fontWeight: bold,
    height: 1.00,
    letterSpacing: -1.2,
    fontFeatures: tabularFigures,
  );

  /// 카드 내 대표 숫자. (31 w700 tabular — `heroSmall`)
  static const TextStyle priceLarge = TextStyle(
    fontSize: heroSmall,
    fontWeight: bold,
    height: 1.05,
    letterSpacing: -0.8,
    fontFeatures: tabularFigures,
  );

  /// 리스트 행의 값. (20 w600 tabular — `displayMedium`)
  static const TextStyle priceCard = TextStyle(
    fontSize: displayMedium,
    fontWeight: semiBold,
    height: 1.15,
    letterSpacing: -0.2,
    fontFeatures: tabularFigures,
  );

  /// 변동률 배지 — 굵기 승격(w600→w700). 오버플로 0. (15 w700 — `bodyLarge`)
  static const TextStyle changeBadge = TextStyle(
    fontSize: bodyLarge,
    fontWeight: bold,
    height: 1.1,
    fontFeatures: tabularFigures,
  );

  /// 히어로 옆에 붙는 변동률 — 히어로와 2:1 리듬을 만든다. (20 w700 tabular)
  static const TextStyle changeHero = TextStyle(
    fontSize: displayMedium,
    fontWeight: bold,
    height: 1.1,
    fontFeatures: tabularFigures,
  );

  /// 보조 숫자 — 거래량, 시가총액 등. (13 w500 tabular — `bodySmall`)
  static const TextStyle numericSecondary = TextStyle(
    fontSize: bodySmall,
    fontWeight: medium,
    height: 1.2,
    fontFeatures: tabularFigures,
  );

  // ── 고정높이 위젯 전용 (스케일 개편으로부터 격리) ──────────
  //
  // 칩·pill은 고정 높이(32~44px) 안에 들어가야 하므로 읽기 스케일을 따르면
  // 텍스트 확대 1.3×에서 넘친다. 전용 토큰으로 묶어 영구 격리한다.
  //
  // **규칙: pill 내부 텍스트는 badgeLabel, 칩/탭 라벨은 chipLabel만 쓴다.**

  /// 칩·세그먼트 탭 라벨 크기. (12)
  ///
  /// 읽기 스케일(13~37)과 기물 스케일(11/10/9) **사이**에 끼어 있는 격리 값이다.
  /// 굵기만 다르게 써야 하는 곳(선택/비선택 탭)을 위해 크기를 따로 노출한다 —
  /// 이름 없는 `12.0` 리터럴이 프리셋 안에 박혀 있어 참조할 수가 없었다.
  static const double chipLabelSize = 12.0;

  /// 칩·세그먼트 탭 라벨 전용. (12 w600)
  static const TextStyle chipLabel = TextStyle(
    fontSize: chipLabelSize,
    fontWeight: semiBold,
    height: 1.15,
  );

  /// 배지 pill 내부 텍스트 전용. (11 w700)
  static const TextStyle badgeLabel = TextStyle(
    fontSize: caption,
    fontWeight: bold,
    height: 1.05,
    letterSpacing: 0.2,
  );
}
