import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// MarketLens 점수 체계 - 단일 진실 원천 (Single Source of Truth)
///
/// 점수 구간:
/// - 80-100: 강력긍정 (Green, 🔥)
/// - 60-79:  긍정 (Light Green)
/// - 40-59:  중립 (Orange)
/// - 20-39:  부정 (Deep Orange)
/// - 0-19:   강력부정 (Red, 📉)
///
/// ⚠️ 주의: 이 파일의 기준을 변경하면 전체 앱에 적용됩니다.

/// 점수 레벨 (5단계)
enum ScoreLevel {
  strongBuy, // 80-100: 강력긍정
  buy, // 60-79: 긍정
  hold, // 40-59: 중립
  sell, // 20-39: 부정
  strongSell, // 0-19: 강력부정
}

/// 점수 매핑 유틸리티
class ScoreMapper {

  /// 점수 → 레벨 변환
  static ScoreLevel getScoreLevel(double score) {
    if (score >= 80) return ScoreLevel.strongBuy;
    if (score >= 60) return ScoreLevel.buy;
    if (score >= 40) return ScoreLevel.hold;
    if (score >= 20) return ScoreLevel.sell;
    return ScoreLevel.strongSell;
  }

  /// 점수 → 색상 변환 (Green=긍정, Red=부정)
  static Color getScoreColor(double score, MarketLensColors colors) {
    if (score >= 80) return colors.gainColor; // 강력긍정 (green)
    if (score >= 60) return colors.scoreBuyColor; // 긍정
    if (score >= 40) return colors.scoreHoldColor; // 중립
    if (score >= 20) return colors.scoreSellColor; // 부정
    return colors.lossColor; // 강력부정 (red)
  }

  /// 점수 → 한국어 라벨 변환
  static String getScoreLabel(double score) {
    if (score >= 80) return '강력긍정';
    if (score >= 60) return '긍정';
    if (score >= 40) return '중립';
    if (score >= 20) return '부정';
    return '강력부정';
  }

  /// 점수 → 이모지 (선택적)
  static String? getScoreEmoji(double score) {
    if (score >= 80) return '🔥'; // 강력긍정
    if (score < 20) return '📉'; // 강력부정
    return null; // 중간 단계는 이모지 없음
  }

  /// 점수 → 레벨별 색상 (enum 기반)
  static Color getColorForLevel(ScoreLevel level, MarketLensColors colors) {
    switch (level) {
      case ScoreLevel.strongBuy:
        return colors.gainColor; // green
      case ScoreLevel.buy:
        return colors.scoreBuyColor;
      case ScoreLevel.hold:
        return colors.scoreHoldColor;
      case ScoreLevel.sell:
        return colors.scoreSellColor;
      case ScoreLevel.strongSell:
        return colors.lossColor; // red
    }
  }

  /// 점수 → 레벨별 라벨 (enum 기반)
  static String getLabelForLevel(ScoreLevel level) {
    switch (level) {
      case ScoreLevel.strongBuy:
        return '강력긍정';
      case ScoreLevel.buy:
        return '긍정';
      case ScoreLevel.hold:
        return '중립';
      case ScoreLevel.sell:
        return '부정';
      case ScoreLevel.strongSell:
        return '강력부정';
    }
  }

  /// Localized score label (점수 → 로컬라이즈 라벨)
  static String getScoreLabelLocalized(double score, AppLocalizations l10n) {
    if (score >= 80) return l10n.scoreStrongBuy;
    if (score >= 60) return l10n.scoreBuy;
    if (score >= 40) return l10n.scoreHold;
    if (score >= 20) return l10n.scoreSell;
    return l10n.scoreStrongSell;
  }

  /// Localized level label (레벨 → 로컬라이즈 라벨, enum 기반)
  static String getLabelForLevelLocalized(ScoreLevel level, AppLocalizations l10n) {
    switch (level) {
      case ScoreLevel.strongBuy:
        return l10n.scoreStrongBuy;
      case ScoreLevel.buy:
        return l10n.scoreBuy;
      case ScoreLevel.hold:
        return l10n.scoreHold;
      case ScoreLevel.sell:
        return l10n.scoreSell;
      case ScoreLevel.strongSell:
        return l10n.scoreStrongSell;
    }
  }
}
