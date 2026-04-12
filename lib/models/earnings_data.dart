import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Single earnings event for weekly calendar
class EarningsWeekEvent {
  final String ticker;
  final String earningsDate;
  final String? nameEn;
  final String? nameKo;
  final double? prevSurprisePct;
  final double? score;
  final double? epsEstimateAvg;
  final bool earningsConfirmed;
  final int? dDay;

  EarningsWeekEvent({
    required this.ticker,
    required this.earningsDate,
    this.nameEn,
    this.nameKo,
    this.prevSurprisePct,
    this.score,
    this.epsEstimateAvg,
    this.earningsConfirmed = false,
    this.dDay,
  });

  factory EarningsWeekEvent.fromJson(Map<String, dynamic> json) {
    return EarningsWeekEvent(
      ticker: json['ticker'] as String,
      earningsDate: json['earnings_date'] as String,
      nameEn: json['name_en'] as String?,
      nameKo: json['name_ko'] as String?,
      prevSurprisePct: (json['prev_surprise_pct'] as num?)?.toDouble(),
      score: (json['score'] as num?)?.toDouble(),
      epsEstimateAvg: (json['eps_estimate_avg'] as num?)?.toDouble(),
      earningsConfirmed: json['earnings_confirmed'] as bool? ?? false,
      dDay: json['d_day'] as int?,
    );
  }

  /// Display name (Korean preferred, fallback English)
  String get displayName => nameKo ?? nameEn ?? ticker;

  /// Locale-aware display name
  String displayNameLocalized(String langCode) {
    if (langCode == 'ko') return nameKo ?? nameEn ?? ticker;
    return nameEn ?? ticker;
  }

  /// Surprise label: "▲4.5%" / "▼2.6%" / "–"
  String get surpriseLabel {
    if (prevSurprisePct == null) return '–';
    final abs = prevSurprisePct!.abs().toStringAsFixed(1);
    return prevSurprisePct! >= 0 ? '▲$abs%' : '▼$abs%';
  }

  /// Surprise color: green(beat) / red(miss) / grey(no data)
  Color surpriseColor(MarketLensColors colors) {
    if (prevSurprisePct == null) return colors.neutralColor;
    return prevSurprisePct! >= 0 ? colors.gainColor : colors.lossColor;
  }
}

/// Upcoming earnings response (grouped by date)
class EarningsUpcomingData {
  final String weekStart;
  final String weekEnd;
  final int totalCount;
  final Map<String, List<EarningsWeekEvent>> byDate;

  EarningsUpcomingData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalCount,
    required this.byDate,
  });

  factory EarningsUpcomingData.fromJson(Map<String, dynamic> json) {
    final byDateJson = json['by_date'] as Map<String, dynamic>? ?? {};
    final byDate = byDateJson.map(
      (key, value) => MapEntry(
        key,
        (value as List)
            .map((e) => EarningsWeekEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );

    return EarningsUpcomingData(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalCount: json['total_count'] as int? ?? 0,
      byDate: byDate,
    );
  }
}
