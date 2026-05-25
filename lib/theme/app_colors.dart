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
    required this.scoreBuyColor,
    required this.scoreHoldColor,
    required this.scoreSellColor,
    required this.gaugeCautious,
    required this.gaugeBullish,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.sundayColor,
    required this.eventFedColor,
    required this.eventEarningsColor,
    required this.eventEconomicColor,
    required this.eventOptionsColor,
    required this.eventConferenceColor,
    required this.eventDividendColor,
    required this.eventShareholderColor,
    required this.roleMasterColor,
    required this.roleManagerColor,
    required this.roleGoldColor,
    required this.roleRegularColor,
    required this.treemapGainBase,
    required this.treemapGainFull,
    required this.treemapLossBase,
    required this.treemapLossFull,
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

  /// 5단계 점수 긍정 (light: Green 300, dark: Green 200)
  final Color scoreBuyColor;

  /// 5단계 점수 중립 (light: Orange 400, dark: Orange 200)
  final Color scoreHoldColor;

  /// 5단계 점수 부정 (light: D.Orange 300, dark: D.Orange 200)
  final Color scoreSellColor;

  /// 매크로 게이지 경계 (light: Orange 600, dark: Orange 300)
  final Color gaugeCautious;

  /// 매크로 게이지 강세 (light: Blue 600, dark: Blue 400)
  final Color gaugeBullish;

  /// Shimmer 베이스 (light: grey300, dark: 다크 grey)
  final Color shimmerBase;

  /// Shimmer 하이라이트 (light: grey100, dark: 약간 밝은 grey)
  final Color shimmerHighlight;

  /// 일요일/공휴일 텍스트 (light: Red 600, dark: Red 300)
  final Color sundayColor;

  /// 이벤트 타입: FOMC/Fed (light: Red 600, dark: Red 300)
  final Color eventFedColor;

  /// 이벤트 타입: 실적발표 (light: Green 600, dark: Green 300)
  final Color eventEarningsColor;

  /// 이벤트 타입: 경제지표 (light: Blue 600, dark: Blue 400)
  final Color eventEconomicColor;

  /// 이벤트 타입: 옵션만기 (light: Orange, dark: Orange 300)
  final Color eventOptionsColor;

  /// 이벤트 타입: 컨퍼런스/제품출시 (light: Purple 600, dark: Purple 300)
  final Color eventConferenceColor;

  /// 이벤트 타입: 배당 (light: BlueGrey 400, dark: BlueGrey 300)
  final Color eventDividendColor;

  /// 이벤트 타입: 주주 (light: Yellow 600, dark: Yellow 400)
  final Color eventShareholderColor;

  /// 역할 뱃지: Master (light: Red 700, dark: Red 400)
  final Color roleMasterColor;

  /// 역할 뱃지: Manager (light: Orange 700, dark: Orange 400)
  final Color roleManagerColor;

  /// 역할 뱃지: Gold (light: Amber 700, dark: Amber 400)
  final Color roleGoldColor;

  /// 역할 뱃지: Regular (light: Grey 600, dark: Grey 500)
  final Color roleRegularColor;

  /// Treemap 양봉 기준 (lerp 시작) (light: 어두운 초록, dark: 더 어두운 초록)
  final Color treemapGainBase;

  /// Treemap 양봉 최대 (lerp 끝) (light: 밝은 초록, dark: 밝은 초록)
  final Color treemapGainFull;

  /// Treemap 음봉 기준 (lerp 시작) (light: 어두운 빨강, dark: 더 어두운 빨강)
  final Color treemapLossBase;

  /// Treemap 음봉 최대 (lerp 끝) (light: 밝은 빨강, dark: 밝은 빨강)
  final Color treemapLossFull;

  static const light = MarketLensColors(
    cardBackground: Colors.white,
    chartBackground: Colors.white,
    chartGridLine: Color(0xFFE0E0E0), // Colors.grey.shade300
    chartTooltipBg: Color(0xDD000000), // Colors.black87
    subtleBorder: Color(0xFFE0E0E0), // Colors.grey.shade300
    sectionBackground: Color(0xFFF9FAFB), // Gray 50
    gainColor: Color(0xFF10B981), // Emerald 500
    lossColor: Color(0xFFEF4444), // Red 500
    neutralColor: Color(0xFF9E9E9E), // grey 500
    gainBg: Color(0xFFECFDF5), // Emerald 50
    lossBg: Color(0xFFFEF2F2), // Red 50
    textPrimary: Color(0xFF1F2937), // Gray 800
    textSecondary: Color(0xFF6B7280), // Gray 500
    textTertiary: Color(0xFF9CA3AF), // Gray 400
    accentBlue: Color(0xFF1A56DB), // Deep Trust Blue
    warningColor: Color(0xFFF57C00), // orange 700
    warningBg: Color(0xFFFFF3E0), // orange 50
    dangerColor: Color(0xFFF44336), // red 500
    dangerBg: Color(0xFFFFEBEE), // red 50
    onPrimary: Colors.white,
    infoBg: Color(0xFFEFF6FF), // Blue 50
    reportColor: Color(0xFFFF9800), // orange
    overlayDim: Color(0x14000000), // 8% black
    scoreBuyColor: Color(0xFF81C784), // Green 300
    scoreHoldColor: Color(0xFFFFA726), // Orange 400
    scoreSellColor: Color(0xFFFF7043), // Deep Orange 300
    gaugeCautious: Color(0xFFFB8C00), // Orange 600
    gaugeBullish: Color(0xFF1E88E5), // Blue 600
    shimmerBase: Color(0xFFE0E0E0), // Grey 300
    shimmerHighlight: Color(0xFFF5F5F5), // Grey 100
    sundayColor: Color(0xFFE53935), // Red 600
    eventFedColor: Color(0xFFE53935), // Red 600
    eventEarningsColor: Color(0xFF43A047), // Green 600
    eventEconomicColor: Color(0xFF1E88E5), // Blue 600
    eventOptionsColor: Color(0xFFFF9800), // Orange
    eventConferenceColor: Color(0xFF8E24AA), // Purple 600
    eventDividendColor: Color(0xFF78909C), // BlueGrey 400
    eventShareholderColor: Color(0xFFFDD835), // Yellow 600
    roleMasterColor: Color(0xFFD32F2F), // Red 700
    roleManagerColor: Color(0xFFF57C00), // Orange 700
    roleGoldColor: Color(0xFFFFA000), // Amber 700
    roleRegularColor: Color(0xFF757575), // Grey 600
    treemapGainBase: Color(0xFF2D4A2D), // Dark green
    treemapGainFull: Color(0xFF00C853), // Bright green
    treemapLossBase: Color(0xFF4A2D2D), // Dark red
    treemapLossFull: Color(0xFFD50000), // Deep red
  );

  static const dark = MarketLensColors(
    cardBackground: Color(0xFF1E1E1E),
    chartBackground: Color(0xFF2A2A2A),
    chartGridLine: Color(0xFF424242),
    chartTooltipBg: Color(0xFF424242),
    subtleBorder: Color(0xFF424242),
    sectionBackground: Color(0xFF2A2A2A),
    gainColor: Color(0xFF34D399), // Emerald 400 — 다크 배경에 가독성 확보
    lossColor: Color(0xFFF87171), // Red 400 — 다크 배경에 가독성 확보
    neutralColor: Color(0xFFBDBDBD), // grey 400
    gainBg: Color(0xFF064E3B), // Emerald 900 계열
    lossBg: Color(0xFF450A0A), // Red 950 계열
    textPrimary: Color(0xFFF3F4F6), // Gray 100
    textSecondary: Color(0xFFD1D5DB), // Gray 300
    textTertiary: Color(0xFF757575), // grey 600
    accentBlue: Color(0xFF60A5FA), // Blue 400 — 다크 배경에 선명
    warningColor: Color(0xFFFFB74D), // orange 300 — 다크 배경에 가독성 확보
    warningBg: Color(0xFF3E2A1E), // 다크 orange tint
    dangerColor: Color(0xFFEF5350), // red 400
    dangerBg: Color(0xFF3E1E1E), // 다크 red tint
    onPrimary: Colors.white,
    infoBg: Color(0xFF1A2940), // 다크 blue tint
    reportColor: Color(0xFFFFB74D), // orange 300
    overlayDim: Color(0x14FFFFFF), // 8% white
    scoreBuyColor: Color(0xFFA5D6A7), // Green 200
    scoreHoldColor: Color(0xFFFFCC80), // Orange 200
    scoreSellColor: Color(0xFFFF8A65), // Deep Orange 200
    gaugeCautious: Color(0xFFFFB74D), // Orange 300
    gaugeBullish: Color(0xFF42A5F5), // Blue 400
    shimmerBase: Color(0xFF2A2A2A), // Dark Grey
    shimmerHighlight: Color(0xFF3A3A3A), // Slightly lighter
    sundayColor: Color(0xFFEF9A9A), // Red 200
    eventFedColor: Color(0xFFEF9A9A), // Red 200
    eventEarningsColor: Color(0xFFA5D6A7), // Green 200
    eventEconomicColor: Color(0xFF42A5F5), // Blue 400
    eventOptionsColor: Color(0xFFFFB74D), // Orange 300
    eventConferenceColor: Color(0xFFCE93D8), // Purple 200
    eventDividendColor: Color(0xFFB0BEC5), // BlueGrey 200
    eventShareholderColor: Color(0xFFFFF176), // Yellow 300
    roleMasterColor: Color(0xFFEF5350), // Red 400
    roleManagerColor: Color(0xFFFFB74D), // Orange 300
    roleGoldColor: Color(0xFFFFCA28), // Amber 400
    roleRegularColor: Color(0xFF9E9E9E), // Grey 500
    treemapGainBase: Color(0xFF1B3A1B), // Darker green (dark mode)
    treemapGainFull: Color(0xFF2E7D32), // Green 800 (less bright)
    treemapLossBase: Color(0xFF3A1B1B), // Darker red (dark mode)
    treemapLossFull: Color(0xFFC62828), // Red 800 (less bright)
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
    Color? scoreBuyColor,
    Color? scoreHoldColor,
    Color? scoreSellColor,
    Color? gaugeCautious,
    Color? gaugeBullish,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? sundayColor,
    Color? eventFedColor,
    Color? eventEarningsColor,
    Color? eventEconomicColor,
    Color? eventOptionsColor,
    Color? eventConferenceColor,
    Color? eventDividendColor,
    Color? eventShareholderColor,
    Color? roleMasterColor,
    Color? roleManagerColor,
    Color? roleGoldColor,
    Color? roleRegularColor,
    Color? treemapGainBase,
    Color? treemapGainFull,
    Color? treemapLossBase,
    Color? treemapLossFull,
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
      scoreBuyColor: scoreBuyColor ?? this.scoreBuyColor,
      scoreHoldColor: scoreHoldColor ?? this.scoreHoldColor,
      scoreSellColor: scoreSellColor ?? this.scoreSellColor,
      gaugeCautious: gaugeCautious ?? this.gaugeCautious,
      gaugeBullish: gaugeBullish ?? this.gaugeBullish,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      sundayColor: sundayColor ?? this.sundayColor,
      eventFedColor: eventFedColor ?? this.eventFedColor,
      eventEarningsColor: eventEarningsColor ?? this.eventEarningsColor,
      eventEconomicColor: eventEconomicColor ?? this.eventEconomicColor,
      eventOptionsColor: eventOptionsColor ?? this.eventOptionsColor,
      eventConferenceColor: eventConferenceColor ?? this.eventConferenceColor,
      eventDividendColor: eventDividendColor ?? this.eventDividendColor,
      eventShareholderColor: eventShareholderColor ?? this.eventShareholderColor,
      roleMasterColor: roleMasterColor ?? this.roleMasterColor,
      roleManagerColor: roleManagerColor ?? this.roleManagerColor,
      roleGoldColor: roleGoldColor ?? this.roleGoldColor,
      roleRegularColor: roleRegularColor ?? this.roleRegularColor,
      treemapGainBase: treemapGainBase ?? this.treemapGainBase,
      treemapGainFull: treemapGainFull ?? this.treemapGainFull,
      treemapLossBase: treemapLossBase ?? this.treemapLossBase,
      treemapLossFull: treemapLossFull ?? this.treemapLossFull,
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
      scoreBuyColor: Color.lerp(scoreBuyColor, other.scoreBuyColor, t)!,
      scoreHoldColor: Color.lerp(scoreHoldColor, other.scoreHoldColor, t)!,
      scoreSellColor: Color.lerp(scoreSellColor, other.scoreSellColor, t)!,
      gaugeCautious: Color.lerp(gaugeCautious, other.gaugeCautious, t)!,
      gaugeBullish: Color.lerp(gaugeBullish, other.gaugeBullish, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      sundayColor: Color.lerp(sundayColor, other.sundayColor, t)!,
      eventFedColor: Color.lerp(eventFedColor, other.eventFedColor, t)!,
      eventEarningsColor: Color.lerp(eventEarningsColor, other.eventEarningsColor, t)!,
      eventEconomicColor: Color.lerp(eventEconomicColor, other.eventEconomicColor, t)!,
      eventOptionsColor: Color.lerp(eventOptionsColor, other.eventOptionsColor, t)!,
      eventConferenceColor: Color.lerp(eventConferenceColor, other.eventConferenceColor, t)!,
      eventDividendColor: Color.lerp(eventDividendColor, other.eventDividendColor, t)!,
      eventShareholderColor: Color.lerp(eventShareholderColor, other.eventShareholderColor, t)!,
      roleMasterColor: Color.lerp(roleMasterColor, other.roleMasterColor, t)!,
      roleManagerColor: Color.lerp(roleManagerColor, other.roleManagerColor, t)!,
      roleGoldColor: Color.lerp(roleGoldColor, other.roleGoldColor, t)!,
      roleRegularColor: Color.lerp(roleRegularColor, other.roleRegularColor, t)!,
      treemapGainBase: Color.lerp(treemapGainBase, other.treemapGainBase, t)!,
      treemapGainFull: Color.lerp(treemapGainFull, other.treemapGainFull, t)!,
      treemapLossBase: Color.lerp(treemapLossBase, other.treemapLossBase, t)!,
      treemapLossFull: Color.lerp(treemapLossFull, other.treemapLossFull, t)!,
    );
  }
}

extension MarketLensColorsBuildContext on BuildContext {
  MarketLensColors get mlColors =>
      Theme.of(this).extension<MarketLensColors>()!;
}
