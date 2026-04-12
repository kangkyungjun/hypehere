import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// MarketLens 점수 체계 - 단일 진실 원천 (Single Source of Truth)
///
/// 점수 구간:
/// - 80-100: 강력매수 (Red, 🔥)
/// - 60-79:  매수권고 (Pink)
/// - 40-59:  하락관망 (Gray)
/// - 20-39:  매도권고 (Sky Blue)
/// - 0-19:   강력매도 (Blue, 📉)
///
/// ⚠️ 주의: 이 파일의 기준을 변경하면 전체 앱에 적용됩니다.

/// 점수 레벨 (5단계)
enum ScoreLevel {
  strongBuy, // 80-100: 강력매수
  buy, // 60-79: 매수권고
  hold, // 40-59: 하락관망
  sell, // 20-39: 매도권고
  strongSell, // 0-19: 강력매도
}

/// 점수 매핑 유틸리티
class ScoreMapper {
  /// 매수권고 (Pink) — 5단계 점수 팔레트 전용
  static const _buyColor = Color(0xFFE91E63);

  /// 매도권고 (Light Blue) — 5단계 점수 팔레트 전용
  static const _sellColor = Color(0xFF03A9F4);
  /// 점수 → 레벨 변환
  static ScoreLevel getScoreLevel(double score) {
    if (score >= 80) return ScoreLevel.strongBuy;
    if (score >= 60) return ScoreLevel.buy;
    if (score >= 40) return ScoreLevel.hold;
    if (score >= 20) return ScoreLevel.sell;
    return ScoreLevel.strongSell;
  }

  /// 점수 → 색상 변환 (명세서 기준)
  static Color getScoreColor(double score, MarketLensColors colors) {
    if (score >= 80) return colors.lossColor; // 강력매수 (red)
    if (score >= 60) return _buyColor; // 매수권고
    if (score >= 40) return colors.neutralColor; // 하락관망
    if (score >= 20) return _sellColor; // 매도권고
    return colors.accentBlue; // 강력매도
  }

  /// 점수 → 한국어 라벨 변환
  static String getScoreLabel(double score) {
    if (score >= 80) return '강력매수';
    if (score >= 60) return '매수권고';
    if (score >= 40) return '하락관망';
    if (score >= 20) return '매도권고';
    return '강력매도';
  }

  /// 점수 → 이모지 (선택적)
  static String? getScoreEmoji(double score) {
    if (score >= 80) return '🔥'; // 강력매수
    if (score < 20) return '📉'; // 강력매도
    return null; // 중간 단계는 이모지 없음
  }

  /// 점수 → 레벨별 색상 (enum 기반)
  static Color getColorForLevel(ScoreLevel level, MarketLensColors colors) {
    switch (level) {
      case ScoreLevel.strongBuy:
        return colors.lossColor; // red
      case ScoreLevel.buy:
        return _buyColor;
      case ScoreLevel.hold:
        return colors.neutralColor;
      case ScoreLevel.sell:
        return _sellColor;
      case ScoreLevel.strongSell:
        return colors.accentBlue;
    }
  }

  /// 점수 → 레벨별 라벨 (enum 기반)
  static String getLabelForLevel(ScoreLevel level) {
    switch (level) {
      case ScoreLevel.strongBuy:
        return '강력매수';
      case ScoreLevel.buy:
        return '매수권고';
      case ScoreLevel.hold:
        return '하락관망';
      case ScoreLevel.sell:
        return '매도권고';
      case ScoreLevel.strongSell:
        return '강력매도';
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
