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
    required this.groupedBackground,
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

  /// 그룹 배경 — 에디토리얼 섹션 청킹용 따뜻한 뉴트럴 (카드를 흰색으로 띄움)
  /// light: 연회색 #F4F5F7, dark: #0A0A0A
  final Color groupedBackground;

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
    chartBackground: Color(0xFFFFFFFF),
    chartGridLine: Color(0xFFE9ECEF),
    chartTooltipBg: Color(0xEE111827),
    subtleBorder: Color(0xFFE5E7EB),
    sectionBackground: Color(0xFFFFFFFF),
    groupedBackground: Color(0xFFF4F5F7),
    gainColor: Color(0xFF059669),
    lossColor: Color(0xFFDC2626),
    neutralColor: Color(0xFF8A94A6),
    gainBg: Color(0xFFEAF8F1),
    lossBg: Color(0xFFFFF0F0),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF667085),
    textTertiary: Color(0xFF98A2B3),
    accentBlue: Color(0xFF2563EB),
    warningColor: Color(0xFFD97706),
    warningBg: Color(0xFFFFF7E8),
    dangerColor: Color(0xFFDC2626),
    dangerBg: Color(0xFFFFF0F0),
    onPrimary: Colors.white,
    infoBg: Color(0xFFF3F6FA),
    reportColor: Color(0xFFD97706),
    overlayDim: Color(0x14000000), // 8% black
    scoreBuyColor: Color(0xFF5BBF8A),
    scoreHoldColor: Color(0xFFD7A23A),
    scoreSellColor: Color(0xFFE07A5F),
    gaugeCautious: Color(0xFFD97706),
    gaugeBullish: Color(0xFF2563EB),
    shimmerBase: Color(0xFFE9EEF5),
    shimmerHighlight: Color(0xFFF8FAFC),
    sundayColor: Color(0xFFDC2626),
    eventFedColor: Color(0xFFB45309),
    eventEarningsColor: Color(0xFF059669),
    eventEconomicColor: Color(0xFF2563EB),
    eventOptionsColor: Color(0xFFD97706),
    eventConferenceColor: Color(0xFF667085),
    eventDividendColor: Color(0xFF64748B),
    eventShareholderColor: Color(0xFF8A94A6),
    roleMasterColor: Color(0xFFDC2626),
    roleManagerColor: Color(0xFFD97706),
    roleGoldColor: Color(0xFFB7791F),
    roleRegularColor: Color(0xFF667085),
    treemapGainBase: Color(0xFF2E4A3C),
    treemapGainFull: Color(0xFF22A06B),
    treemapLossBase: Color(0xFF4A3333),
    treemapLossFull: Color(0xFFC2413B),
  );

  static const dark = MarketLensColors(
    cardBackground: Color(0xFF111111),
    chartBackground: Color(0xFF111111),
    chartGridLine: Color(0xFF2A2A2A),
    chartTooltipBg: Color(0xFF080808),
    subtleBorder: Color(0xFF2A2A2A),
    sectionBackground: Color(0xFF000000),
    groupedBackground: Color(0xFF0A0A0A),
    gainColor: Color(0xFF34D399), // Emerald 400 — 다크 배경에 가독성 확보
    lossColor: Color(0xFFF87171), // Red 400 — 다크 배경에 가독성 확보
    neutralColor: Color(0xFFBDBDBD), // grey 400
    gainBg: Color(0xFF064E3B), // Emerald 900 계열
    lossBg: Color(0xFF450A0A), // Red 950 계열
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFF94A3B8),
    accentBlue: Color(0xFF60A5FA), // Blue 400 — 다크 배경에 선명
    warningColor: Color(0xFFFFB74D), // orange 300 — 다크 배경에 가독성 확보
    warningBg: Color(0xFF3E2A1E), // 다크 orange tint
    dangerColor: Color(0xFFEF5350), // red 400
    dangerBg: Color(0xFF3E1E1E), // 다크 red tint
    onPrimary: Colors.white,
    infoBg: Color(0xFF171A1F),
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
    treemapGainBase: Color(0xFF173326),
    treemapGainFull: Color(0xFF23885E),
    treemapLossBase: Color(0xFF331C1C),
    treemapLossFull: Color(0xFFA63A36),
  );

  @override
  MarketLensColors copyWith({
    Color? cardBackground,
    Color? chartBackground,
    Color? chartGridLine,
    Color? chartTooltipBg,
    Color? subtleBorder,
    Color? sectionBackground,
    Color? groupedBackground,
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
      groupedBackground: groupedBackground ?? this.groupedBackground,
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
      eventShareholderColor:
          eventShareholderColor ?? this.eventShareholderColor,
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
      sectionBackground: Color.lerp(
        sectionBackground,
        other.sectionBackground,
        t,
      )!,
      groupedBackground: Color.lerp(
        groupedBackground,
        other.groupedBackground,
        t,
      )!,
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
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      sundayColor: Color.lerp(sundayColor, other.sundayColor, t)!,
      eventFedColor: Color.lerp(eventFedColor, other.eventFedColor, t)!,
      eventEarningsColor: Color.lerp(
        eventEarningsColor,
        other.eventEarningsColor,
        t,
      )!,
      eventEconomicColor: Color.lerp(
        eventEconomicColor,
        other.eventEconomicColor,
        t,
      )!,
      eventOptionsColor: Color.lerp(
        eventOptionsColor,
        other.eventOptionsColor,
        t,
      )!,
      eventConferenceColor: Color.lerp(
        eventConferenceColor,
        other.eventConferenceColor,
        t,
      )!,
      eventDividendColor: Color.lerp(
        eventDividendColor,
        other.eventDividendColor,
        t,
      )!,
      eventShareholderColor: Color.lerp(
        eventShareholderColor,
        other.eventShareholderColor,
        t,
      )!,
      roleMasterColor: Color.lerp(roleMasterColor, other.roleMasterColor, t)!,
      roleManagerColor: Color.lerp(
        roleManagerColor,
        other.roleManagerColor,
        t,
      )!,
      roleGoldColor: Color.lerp(roleGoldColor, other.roleGoldColor, t)!,
      roleRegularColor: Color.lerp(
        roleRegularColor,
        other.roleRegularColor,
        t,
      )!,
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
