import 'package:flutter/material.dart';

/// MarketLens 타이포그래피 상수
///
/// 전체 앱에서 일관된 글꼴 크기/굵기 사용을 위한 시맨틱 토큰.
/// 값 변경 시 이 파일만 수정하면 전체 앱에 반영됨.
abstract final class AppTypography {
  // ── Font Sizes ──────────────────────────────────────────

  /// 대형 히어로 숫자, 프로필 통계 (30px)
  static const double heroMedium = 30.0;

  /// 히어로 숫자, 애널리스트 가격 (28px)
  static const double heroSmall = 28.0;

  /// 화면 최상단 타이틀, 히어로 숫자 (24px)
  static const double displayLarge = 24.0;

  /// 강조 숫자, 점수 하이라이트 (22px)
  static const double displaySmall = 22.0;

  /// 화면 타이틀, 큰 헤더 (20px)
  static const double displayMedium = 20.0;

  /// 섹션 타이틀, 중간 헤더 (18px)
  static const double headlineLarge = 18.0;

  /// 섹션 헤더, 카드 타이틀 (16px)
  static const double headlineMedium = 16.0;

  /// 약간 큰 본문, 서브헤더 (15px)
  static const double headlineSmall = 15.0;

  /// 카드/항목 제목, 주요 본문 (14px)
  static const double bodyLarge = 14.0;

  /// 보조 본문 텍스트 (13px)
  static const double bodyMedium = 13.0;

  /// 부가 정보, 일반 소형 텍스트 (12px)
  static const double bodySmall = 12.0;

  /// 범례, 태그, 배지 텍스트 (11px)
  static const double caption = 11.0;

  /// 차트 축 레이블, 최소 텍스트 (10px)
  static const double micro = 10.0;

  /// 차트 축 텍스트, 작은 데이터 포인트 (9px)
  static const double chartLabel = 9.0;

  /// 극소 차트 텍스트, 캘린더 보조 (8px)
  static const double chartMicro = 8.0;

  // ── Semantic Text Styles ───────────────────────────────

  static const TextStyle screenTitle = TextStyle(
    fontSize: displayLarge,
    fontWeight: bold,
    height: 1.22,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: headlineLarge,
    fontWeight: bold,
    height: 1.28,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    height: 1.45,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: bodySmall,
    fontWeight: medium,
    height: 1.25,
  );

  // ── Key-Value 패턴 (레퍼런스 영수증/카드 라벨→값) ──────────
  // 라벨=뮤트 medium, 값=near-black semiBold. 위계를 여백 없이 대비로 만든다.

  /// 키밸류 라벨 — 뮤트 블루그레이(textSecondary와 함께 사용). (13px medium)
  static const TextStyle kvLabel = TextStyle(
    fontSize: bodyMedium,
    fontWeight: medium,
    height: 1.2,
  );

  /// 키밸류 값 — near-black 강조(textPrimary와 함께 사용), tabular. (14px semiBold)
  static const TextStyle kvValue = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.2,
    fontFeatures: tabularFigures,
  );

  /// 값 뒤 작은 단위 접미사("만원"/"%"/"pt") — 값보다 2단 낮춤. (12px medium)
  static const TextStyle unitSuffix = TextStyle(
    fontSize: bodySmall,
    fontWeight: medium,
    height: 1.2,
  );

  // ── Font Weights ────────────────────────────────────────

  /// 강한 강조, 주요 헤더 (w700)
  static const FontWeight bold = FontWeight.bold;

  /// 중간 강조, 섹션 헤더 (w600)
  static const FontWeight semiBold = FontWeight.w600;

  /// 약한 강조, 보조 레이블 (w500)
  static const FontWeight medium = FontWeight.w500;

  /// 기본 굵기, 일반 본문 텍스트 (w400)
  static const FontWeight regular = FontWeight.normal;

  // ── Numeric Styles (주가, 수익률 등 숫자 강조용) ──────────

  /// 숫자 정렬을 위한 fontFeatures
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// 대형 주가 표시 (heroMedium + bold + tabular)
  static const TextStyle priceHero = TextStyle(
    fontSize: heroMedium,
    fontWeight: bold,
    height: 1.05,
    fontFeatures: tabularFigures,
  );

  /// 중형 주가 표시 (displayMedium + semiBold + tabular)
  static const TextStyle priceLarge = TextStyle(
    fontSize: displayMedium,
    fontWeight: semiBold,
    height: 1.1,
    fontFeatures: tabularFigures,
  );

  /// 카드 내 주가 (headlineMedium + semiBold + tabular)
  static const TextStyle priceCard = TextStyle(
    fontSize: headlineMedium,
    fontWeight: semiBold,
    height: 1.15,
    fontFeatures: tabularFigures,
  );

  /// 변동률 배지 텍스트 (bodyLarge + semiBold + tabular)
  static const TextStyle changeBadge = TextStyle(
    fontSize: bodyLarge,
    fontWeight: semiBold,
    height: 1.1,
    fontFeatures: tabularFigures,
  );

  /// 보조 숫자 — 거래량, 시가총액 등 (bodySmall + medium + tabular)
  static const TextStyle numericSecondary = TextStyle(
    fontSize: bodySmall,
    fontWeight: medium,
    height: 1.2,
    fontFeatures: tabularFigures,
  );
}
