import 'package:flutter/material.dart';

/// MarketLens 타이포그래피 상수
///
/// 전체 앱에서 일관된 글꼴 크기/굵기 사용을 위한 시맨틱 토큰.
/// 값 변경 시 이 파일만 수정하면 전체 앱에 반영됨(하드코딩 fontSize는 앱 전체에 0건).
///
/// ## 스케일 설계 (2026-08-30 개편)
///
/// 레퍼런스(헤이딜러, `docs/reference/heydealer/SPEC.md`)는 13↔40px = **약 3.1배**
/// 진폭을 한 화면 안에서 실제로 쓴다. 개편 전 우리 앱은 토큰상 8↔30이었으나
/// 실사용 호출부 951개 중 **76.2%가 12~16px 구간**에 몰려 있어 체감 진폭이
/// 1.8배에 그쳤다 — 1px 차이는 눈이 읽지 못하므로 사실상 전부 같은 크기였다.
///
/// 그래서 **읽기 스케일 7단계 + 기물 스케일 3단계**로 재편한다.
///
/// ```
/// 읽기(위계 담당):  40 · 30 · 24 · 20 · 17 · 14 · 12
/// 기물(위계 아님):  11(배지) · 10(차트축) · 9(차트미세)
/// 인접비:          1.33  1.25  1.20  1.18  1.21  1.17
/// ```
///
/// ### 두 가지 불변 원칙
///
/// 1. **하한 동결** — 12/11/10/9는 절대 올리지 않는다. 밀집도(사용자 최우선
///    제약)를 지키는 방어선이며, 고정높이 pill 31곳·차트 `reservedSize`가
///    여기에 하드 의존한다.
/// 2. **상한 개방** — 히어로는 자기 행을 독점하므로 크기를 키워도 밀집도
///    비용이 0이다. 30→40으로 열어 위계를 만든다.
///
/// 결과: 크기가 **줄어드는 호출부 0건**, 여백 토큰 변경 0건,
/// 리스트 행 높이 +1px(+1.3%).
///
/// ### 이름을 바꾸지 않는 이유
/// 사라지는 5단계(22·18·15·13·8)는 삭제하지 않고 **이웃 값으로 재정의**한다.
/// 951개 호출부를 한 줄도 수정하지 않고 스케일을 교체하기 위함이다.
abstract final class AppTypography {
  // ── 읽기 스케일 (7단계) ──────────────────────────────────
  // 위계를 만드는 단계. 인접 비율 1.17배 이상을 유지한다.

  /// 화면당 단 하나뿐인 히어로 숫자 — 티커 현재가, 총자산 평가액. (34px)
  ///
  /// 1차 개편에서 40으로 열었으나 사용자 판정 "과하다" → 34로 후퇴.
  /// 34/13 = 2.6배로 히어로 대비는 유지하면서 부피를 덜어낸다.
  static const double heroMedium = 37.0;

  /// 2순위 히어로 — 카드 내 대표 숫자, 종합점수, 애널리스트 목표가. (28px)
  static const double heroSmall = 31.0;

  /// 화면 최상단 타이틀. (24px)
  static const double displayLarge = 24.0;

  /// `displayLarge`와 통합됨(구 22px). 22와 24는 눈이 구분하지 못한다. (24px, 4 호출부)
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

  /// 본문 기준선, 키밸류 값. (14px)
  static const double bodyLarge = 15.0;

  /// 보조 본문, 키밸류 라벨. (13px)
  ///
  /// 1차 개편에서 14로 병합했으나 호출부가 147개라 앱 전체가 부풀어 보였다.
  /// 13으로 원복 — 라벨/값 위계는 1px + 굵기(w500↔w600) + 색으로 만든다.
  static const double bodyMedium = 14.0;

  /// 라벨 기준선, 보조 정보. (12px)
  ///
  /// **최다 사용 단계(300건)이며 불변이 밀집도를 보증한다.**
  static const double bodySmall = 13.0;

  // ── 기물 스케일 (3단계) ──────────────────────────────────
  // 위계 요소가 아니라 고정 크기 부품. 스케일 개편에서 값을 바꾸지 않는다.

  /// 배지/pill 전용. (11px)
  ///
  /// ⚠️ 세로 패딩 ≤4px인 pill이 앱 전체에 31곳 있다. 올리면 전부 넘친다.
  static const double caption = 11.0;

  /// 차트 축 라벨 전용. (10px)
  ///
  /// ⚠️ fl_chart `reservedSize`는 하드 클립 경계라 소프트 폴백이 없다.
  /// 현재 여유가 2~3px뿐이므로 **동결**.
  static const double micro = 10.0;

  /// 차트 미세 라벨. (9px)
  static const double chartLabel = 9.0;

  /// `chartLabel`과 통합됨(구 8px). 8px는 접근성 하한 미달이었다. (9px)
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

  /// 섹션 타이틀. (20 w700)
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

  /// 산문 본문 — AI 답변·뉴스 요약·채팅. (14 w400)
  static const TextStyle body = TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    height: 1.45,
  );

  /// 강조 본문. (14 w600)
  static const TextStyle bodyStrong = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.40,
  );

  /// 라벨, 부가 정보. (12 w500)
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

  /// 키밸류 라벨 — `textSecondary`와 함께 쓴다. (14 w500)
  static const TextStyle kvLabel = TextStyle(
    fontSize: bodyMedium,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// 키밸류 값 — `textPrimary`와 함께 쓴다. 라벨과 **같은 크기**. (14 w600)
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

  /// 소형 값(≤17px) 뒤 단위 — `%`/`pt`. (12 w500)
  static const TextStyle unitSuffix = TextStyle(
    fontSize: 12.0,
    fontWeight: medium,
    height: 1.2,
  );

  /// 30px 히어로 뒤 단위 — `M`/`T`/`만원`. (14 w600)
  static const TextStyle unitSuffixLarge = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.1,
  );

  /// 40px 히어로 뒤/앞 단위 — 통화기호 `$`. (17 w600)
  static const TextStyle unitSuffixHero = TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    height: 1.0,
  );

  // ── Numeric Styles (주가, 수익률 등 숫자 강조용) ──────────

  /// 화면당 유일한 히어로 숫자. (40 w700 tabular)
  static const TextStyle priceHero = TextStyle(
    fontSize: heroMedium,
    fontWeight: bold,
    height: 1.00,
    letterSpacing: -1.2,
    fontFeatures: tabularFigures,
  );

  /// 카드 내 대표 숫자. (30 w700 tabular)
  static const TextStyle priceLarge = TextStyle(
    fontSize: heroSmall,
    fontWeight: bold,
    height: 1.05,
    letterSpacing: -0.8,
    fontFeatures: tabularFigures,
  );

  /// 리스트 행의 값. (17 w600 tabular)
  static const TextStyle priceCard = TextStyle(
    fontSize: displayMedium,
    fontWeight: semiBold,
    height: 1.15,
    letterSpacing: -0.2,
    fontFeatures: tabularFigures,
  );

  /// 변동률 배지 — 크기는 그대로, **굵기만 승격**(w600→w700). 오버플로 0. (14 w700)
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

  /// 보조 숫자 — 거래량, 시가총액 등. (12 w500 tabular)
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

  /// 칩·세그먼트 탭 라벨 전용. (12 w600)
  static const TextStyle chipLabel = TextStyle(
    fontSize: 12.0,
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
