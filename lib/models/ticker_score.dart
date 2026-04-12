import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/score_mapper.dart';

/// Ticker score model for top tickers list
///
/// Matches the server's TopTickerResponse schema
class TickerScore {
  final String ticker;
  final double score;
  final String? signal;
  final String? name;
  final String? nameKo;
  final List<String>? membership;
  final double? close;
  final double? changePct;

  TickerScore({
    required this.ticker,
    required this.score,
    this.signal,
    this.name,
    this.nameKo,
    this.membership,
    this.close,
    this.changePct,
  });

  factory TickerScore.fromJson(Map<String, dynamic> json) {
    return TickerScore(
      ticker: json['ticker'] as String,
      score: (json['score'] as num).toDouble(),
      signal: json['signal'] as String?,
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      membership: (json['membership'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      close: (json['close'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'score': score,
      'signal': signal,
      'name': name,
      'name_ko': nameKo,
      'membership': membership,
      'close': close,
      'change_pct': changePct,
    };
  }

  /// Get display name (fallback to ticker if name is null)
  String get displayName => name ?? ticker;

  /// Get signal type enum
  SignalType get signalType {
    if (signal == null) return SignalType.neutral;
    switch (signal!.toUpperCase()) {
      case 'BUY':
        return SignalType.buy;
      case 'SELL':
        return SignalType.sell;
      case 'HOLD':
        return SignalType.hold;
      default:
        return SignalType.neutral;
    }
  }

  /// Check if this is a strong buy signal (score >= 70)
  bool get isStrongBuy => score >= 70 && signalType == SignalType.buy;

  /// Check if this is a strong sell signal (score <= 30)
  bool get isStrongSell => score <= 30 && signalType == SignalType.sell;

  /// Get Korean display label for signal (score-based, 5-level system)
  /// Uses centralized ScoreMapper for consistency across all screens
  String get signalLabel {
    final emoji = ScoreMapper.getScoreEmoji(score);
    final label = ScoreMapper.getScoreLabel(score);
    return emoji != null ? '$emoji$label' : label;
  }

  /// Localized signal label (score-based, 5-level system)
  String signalLabelLocalized(AppLocalizations l10n) {
    final emoji = ScoreMapper.getScoreEmoji(score);
    final label = ScoreMapper.getScoreLabelLocalized(score, l10n);
    return emoji != null ? '$emoji$label' : label;
  }

  /// Get score-based color (명세서 기준: 5단계 색상 체계)
  Color scoreColor(MarketLensColors colors) {
    return ScoreMapper.getScoreColor(score, colors);
  }

  /// Get score category
  ScoreCategory get scoreCategory {
    if (score >= 80) return ScoreCategory.excellent;
    if (score >= 60) return ScoreCategory.good;
    if (score >= 40) return ScoreCategory.neutral;
    if (score >= 20) return ScoreCategory.poor;
    return ScoreCategory.bad;
  }
}

/// Signal type enumeration
enum SignalType {
  buy,
  sell,
  hold,
  neutral,
}

/// Score category enumeration
enum ScoreCategory {
  excellent, // 80-100
  good, // 60-79
  neutral, // 40-59
  poor, // 20-39
  bad, // 0-19
}
