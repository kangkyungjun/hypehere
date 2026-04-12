import 'package:flutter/material.dart';

@immutable
class MarketLensColors extends ThemeExtension<MarketLensColors> {
  const MarketLensColors({
    required this.cardBackground,
    required this.chartBackground,
    required this.chartGridLine,
    required this.chartTooltipBg,
    required this.subtleBorder,
    required this.sectionBackground,
    required this.gainColor,
    required this.lossColor,
    required this.neutralColor,
    required this.gainBg,
    required this.lossBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accentBlue,
    required this.warningColor,
    required this.warningBg,
    required this.dangerColor,
    required this.dangerBg,
    required this.onPrimary,
    required this.infoBg,
    required this.reportColor,
    required this.overlayDim,
  });

  final Color cardBackground;
  final Color chartBackground;
  final Color chartGridLine;
  final Color chartTooltipBg;
  final Color subtleBorder;
  final Color sectionBackground;

  /// 상승, 매수, 긍정 (light: Material Green 500, dark: Green 400)
  final Color gainColor;

  /// 하락, 매도, 부정 (light: Material Red 500, dark: Red 400)
  final Color lossColor;

  /// 보합, 관망, 중립
  final Color neutralColor;

  /// 상승 배경 — 연한 green (뱃지, 칩 배경용)
  final Color gainBg;

  /// 하락 배경 — 연한 red (뱃지, 칩 배경용)
  final Color lossBg;

  /// 주요 텍스트 — 본문, 제목 (light: grey800, dark: grey200)
  final Color textPrimary;

  /// 보조 텍스트 — 부제, 설명 (light: grey600, dark: grey400)
  final Color textSecondary;

  /// 3차 텍스트 — 힌트, 비활성 (light: grey400, dark: grey600)
  final Color textTertiary;

  /// 액센트 블루 — 링크, 강조, 선택 (light: blue600, dark: blue400)
  final Color accentBlue;

  /// 경고 텍스트 — 주의 표시 (light: orange700, dark: orange300)
  final Color warningColor;

  /// 경고 배경 — 주의 배너 배경 (light: orange50, dark: 다크 orange tint)
  final Color warningBg;

  /// 위험/삭제 — 에러·삭제 버튼·경고 (light: red500, dark: red400)
  final Color dangerColor;

  /// 위험 배경 — 에러 배너 배경 (light: red50, dark: 다크 red tint)
  final Color dangerBg;

  /// Primary 위 텍스트/아이콘 — 버튼 라벨 등
  final Color onPrimary;

  /// 정보 배경 — 안내 배너 배경 (light: blue50, dark: 다크 blue tint)
  final Color infoBg;

  /// 신고 — 리포트 버튼 (light: orange, dark: orange300)
  final Color reportColor;

  /// 반투명 오버레이 — 하이라이트, 스플래시 (light: 8% black, dark: 8% white)
  final Color overlayDim;

  static const light = MarketLensColors(
    cardBackground: Colors.white,
    chartBackground: Colors.white,
    chartGridLine: Color(0xFFE0E0E0), // Colors.grey.shade300
    chartTooltipBg: Color(0xDD000000), // Colors.black87
    subtleBorder: Color(0xFFE0E0E0), // Colors.grey.shade300
    sectionBackground: Color(0xFFF5F5F5), // Colors.grey.shade100
    gainColor: Color(0xFF4CAF50), // green 500
    lossColor: Color(0xFFF44336), // red 500
    neutralColor: Color(0xFF9E9E9E), // grey 500
    gainBg: Color(0xFFE8F5E9), // green 50
    lossBg: Color(0xFFFFEBEE), // red 50
    textPrimary: Color(0xFF424242), // grey 800
    textSecondary: Color(0xFF757575), // grey 600
    textTertiary: Color(0xFFBDBDBD), // grey 400
    accentBlue: Color(0xFF1E88E5), // blue 600
    warningColor: Color(0xFFF57C00), // orange 700
    warningBg: Color(0xFFFFF3E0), // orange 50
    dangerColor: Color(0xFFF44336), // red 500
    dangerBg: Color(0xFFFFEBEE), // red 50
    onPrimary: Colors.white,
    infoBg: Color(0xFFE3F2FD), // blue 50
    reportColor: Color(0xFFFF9800), // orange
    overlayDim: Color(0x14000000), // 8% black
  );

  static const dark = MarketLensColors(
    cardBackground: Color(0xFF1E1E1E),
    chartBackground: Color(0xFF2A2A2A),
    chartGridLine: Color(0xFF424242),
    chartTooltipBg: Color(0xFF424242),
    subtleBorder: Color(0xFF424242),
    sectionBackground: Color(0xFF2A2A2A),
    gainColor: Color(0xFF66BB6A), // green 400 — 다크 배경에 가독성 확보
    lossColor: Color(0xFFEF5350), // red 400 — 다크 배경에 가독성 확보
    neutralColor: Color(0xFFBDBDBD), // grey 400
    gainBg: Color(0xFF1B3A1E), // 다크 green tint
    lossBg: Color(0xFF3E1E1E), // 다크 red tint
    textPrimary: Color(0xFFEEEEEE), // grey 200
    textSecondary: Color(0xFFBDBDBD), // grey 400
    textTertiary: Color(0xFF757575), // grey 600
    accentBlue: Color(0xFF42A5F5), // blue 400 — 다크 배경에 가독성 확보
    warningColor: Color(0xFFFFB74D), // orange 300 — 다크 배경에 가독성 확보
    warningBg: Color(0xFF3E2A1E), // 다크 orange tint
    dangerColor: Color(0xFFEF5350), // red 400
    dangerBg: Color(0xFF3E1E1E), // 다크 red tint
    onPrimary: Colors.white,
    infoBg: Color(0xFF1A2940), // 다크 blue tint
    reportColor: Color(0xFFFFB74D), // orange 300
    overlayDim: Color(0x14FFFFFF), // 8% white
  );

  @override
  MarketLensColors copyWith({
    Color? cardBackground,
    Color? chartBackground,
    Color? chartGridLine,
    Color? chartTooltipBg,
    Color? subtleBorder,
    Color? sectionBackground,
    Color? gainColor,
    Color? lossColor,
    Color? neutralColor,
    Color? gainBg,
    Color? lossBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accentBlue,
    Color? warningColor,
    Color? warningBg,
    Color? dangerColor,
    Color? dangerBg,
    Color? onPrimary,
    Color? infoBg,
    Color? reportColor,
    Color? overlayDim,
  }) {
    return MarketLensColors(
      cardBackground: cardBackground ?? this.cardBackground,
      chartBackground: chartBackground ?? this.chartBackground,
      chartGridLine: chartGridLine ?? this.chartGridLine,
      chartTooltipBg: chartTooltipBg ?? this.chartTooltipBg,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      sectionBackground: sectionBackground ?? this.sectionBackground,
      gainColor: gainColor ?? this.gainColor,
      lossColor: lossColor ?? this.lossColor,
      neutralColor: neutralColor ?? this.neutralColor,
      gainBg: gainBg ?? this.gainBg,
      lossBg: lossBg ?? this.lossBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accentBlue: accentBlue ?? this.accentBlue,
      warningColor: warningColor ?? this.warningColor,
      warningBg: warningBg ?? this.warningBg,
      dangerColor: dangerColor ?? this.dangerColor,
      dangerBg: dangerBg ?? this.dangerBg,
      onPrimary: onPrimary ?? this.onPrimary,
      infoBg: infoBg ?? this.infoBg,
      reportColor: reportColor ?? this.reportColor,
      overlayDim: overlayDim ?? this.overlayDim,
    );
  }

  @override
  MarketLensColors lerp(MarketLensColors? other, double t) {
    if (other is! MarketLensColors) return this;
    return MarketLensColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      chartBackground: Color.lerp(chartBackground, other.chartBackground, t)!,
      chartGridLine: Color.lerp(chartGridLine, other.chartGridLine, t)!,
      chartTooltipBg: Color.lerp(chartTooltipBg, other.chartTooltipBg, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      sectionBackground:
          Color.lerp(sectionBackground, other.sectionBackground, t)!,
      gainColor: Color.lerp(gainColor, other.gainColor, t)!,
      lossColor: Color.lerp(lossColor, other.lossColor, t)!,
      neutralColor: Color.lerp(neutralColor, other.neutralColor, t)!,
      gainBg: Color.lerp(gainBg, other.gainBg, t)!,
      lossBg: Color.lerp(lossBg, other.lossBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      reportColor: Color.lerp(reportColor, other.reportColor, t)!,
      overlayDim: Color.lerp(overlayDim, other.overlayDim, t)!,
    );
  }
}

extension MarketLensColorsBuildContext on BuildContext {
  MarketLensColors get mlColors =>
      Theme.of(this).extension<MarketLensColors>()!;
}
