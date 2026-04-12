import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/multilingual.dart';

/// Macro indicators API response model
class MacroIndicatorsData {
  final String date;
  final List<MacroIndicator> indicators;

  MacroIndicatorsData({required this.date, required this.indicators});

  factory MacroIndicatorsData.fromJson(Map<String, dynamic> json) {
    return MacroIndicatorsData(
      date: json['date'] as String? ?? '',
      indicators: (json['indicators'] as List?)
              ?.map((item) =>
                  MacroIndicator.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Single macro economic indicator
class MacroIndicator {
  final String indicatorCode;
  final String? indicatorName;
  final double value;
  final String? observationDate;
  final double? previousValue;
  final double? changePct;
  final String? riskLevel;
  final String? signalMessage;
  final double? high3m;
  final double? avg3m;
  final double? low3m;

  MacroIndicator({
    required this.indicatorCode,
    this.indicatorName,
    required this.value,
    this.observationDate,
    this.previousValue,
    this.changePct,
    this.riskLevel,
    this.signalMessage,
    this.high3m,
    this.avg3m,
    this.low3m,
  });

  factory MacroIndicator.fromJson(Map<String, dynamic> json) {
    return MacroIndicator(
      indicatorCode: json['indicator_code'] as String,
      indicatorName: json['indicator_name'] as String?,
      value: (json['value'] as num).toDouble(),
      observationDate: json['observation_date'] as String?,
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      riskLevel: json['risk_level'] as String?,
      signalMessage: json['signal_message'] as String?,
      high3m: (json['high_3m'] as num?)?.toDouble(),
      avg3m: (json['avg_3m'] as num?)?.toDouble(),
      low3m: (json['low_3m'] as num?)?.toDouble(),
    );
  }

  /// Localized short display label
  String shortLabelLocalized(AppLocalizations l10n) {
    final labels = {
      'FEDFUNDS': l10n.macroFedFunds,
      'DGS10': l10n.macroDGS10,
      'DGS2': l10n.macroDGS2,
      'T10Y2Y': l10n.macroT10Y2Y,
      'VIXCLS': l10n.macroVIXCLS,
      'CPIAUCSL': l10n.macroCPIAUCSL,
      'UNRATE': l10n.macroUNRATE,
    };
    return labels[indicatorCode] ?? indicatorName ?? indicatorCode;
  }

  /// Formatted value with appropriate precision
  String get formattedValue {
    if (indicatorCode == 'CPIAUCSL') {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  /// Whether change is positive
  bool get isPositive => (changePct ?? 0) > 0;

  /// Change color (red for up, blue for down - stock convention)
  Color changeColor(MarketLensColors colors) {
    if (changePct == null || changePct == 0) return colors.neutralColor;
    return isPositive ? colors.lossColor : colors.accentBlue;
  }

  /// Change arrow symbol
  String get changeArrow {
    if (changePct == null || changePct == 0) return '';
    return isPositive ? '▲' : '▼';
  }

  /// Localized description (supports packed string `|||` format)
  String? descriptionLocalized(AppLocalizations l10n, String langCode) {
    if (signalMessage != null && signalMessage!.isNotEmpty) {
      final cleaned = signalMessage!.replaceFirst(
          RegExp(r'^[\p{So}\p{Cn}\u200d\ufe0f\s]+', unicode: true), '');
      return cleaned.localize(langCode);
    }
    final descriptions = {
      'FEDFUNDS': l10n.macroFedFundsDesc,
      'DGS10': l10n.macroDGS10Desc,
      'DGS2': l10n.macroDGS2Desc,
      'T10Y2Y': l10n.macroT10Y2YDesc,
      'VIXCLS': l10n.macroVIXCLSDesc,
      'CPIAUCSL': l10n.macroCPIAUCSLDesc,
      'UNRATE': l10n.macroUNRATEDesc,
    };
    return descriptions[indicatorCode];
  }

  /// Whether to show percentage suffix
  bool get showPercentSuffix {
    return const ['FEDFUNDS', 'UNRATE', 'DGS10', 'DGS2', 'T10Y2Y']
        .contains(indicatorCode);
  }

  /// Risk level color (dot + chip background)
  Color riskColor(MarketLensColors colors) {
    switch (riskLevel) {
      case 'BEARISH':
        return colors.dangerColor;
      case 'CAUTIOUS':
        return colors.warningColor;
      case 'NEUTRAL':
        return colors.neutralColor;
      case 'POSITIVE':
        return colors.gainColor;
      case 'BULLISH':
        return colors.accentBlue;
      default:
        return colors.neutralColor;
    }
  }

  /// Risk level background color (light shade)
  Color riskBackgroundColor(MarketLensColors colors) {
    switch (riskLevel) {
      case 'BEARISH':
        return colors.dangerBg;
      case 'CAUTIOUS':
        return colors.warningBg;
      case 'NEUTRAL':
        return colors.sectionBackground;
      case 'POSITIVE':
        return colors.gainBg;
      case 'BULLISH':
        return colors.infoBg;
      default:
        return colors.sectionBackground;
    }
  }
}

/// Macro signals API response model
class MacroSignalsData {
  final String date;
  final List<MacroSignal> signals;

  MacroSignalsData({required this.date, required this.signals});

  factory MacroSignalsData.fromJson(Map<String, dynamic> json) {
    return MacroSignalsData(
      date: json['date'] as String? ?? '',
      signals: (json['signals'] as List?)
              ?.map((item) =>
                  MacroSignal.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Single macro signal (yield_curve, m2_liquidity, overall_macro)
class MacroSignal {
  final String signalCode;
  final double value;
  final String? riskLevel;
  final String? liquidityStatus;
  final String? message;
  final String date;
  final double? high3m;
  final double? avg3m;
  final double? low3m;

  MacroSignal({
    required this.signalCode,
    required this.value,
    this.riskLevel,
    this.liquidityStatus,
    this.message,
    required this.date,
    this.high3m,
    this.avg3m,
    this.low3m,
  });

  factory MacroSignal.fromJson(Map<String, dynamic> json) {
    return MacroSignal(
      signalCode: json['signal_code'] as String,
      value: (json['value'] as num).toDouble(),
      riskLevel: json['risk_level'] as String?,
      liquidityStatus: json['liquidity_status'] as String?,
      message: json['message'] as String?,
      date: json['date'] as String? ?? '',
      high3m: (json['high_3m'] as num?)?.toDouble(),
      avg3m: (json['avg_3m'] as num?)?.toDouble(),
      low3m: (json['low_3m'] as num?)?.toDouble(),
    );
  }

  /// Formatted value
  String get formattedValue {
    return value.toStringAsFixed(2);
  }

  // ── Emoji pattern for cleanMessage ────────────────────────────
  static final _leadingEmojiRe = RegExp(
    r'^[\p{So}\p{Cn}\u200d\ufe0f\s]+',
    unicode: true,
  );

  /// Message with leading emoji + whitespace stripped.
  /// "🟢 양호: 경제가..." → "양호: 경제가..."
  String? get cleanMessage {
    if (message == null || message!.isEmpty) return message;
    final cleaned = message!.replaceFirst(_leadingEmojiRe, '');
    return cleaned.isEmpty ? message : cleaned;
  }

  // ── Fallback risk level ──────────────────────────────────────

  /// Effective risk level with fallback when server sends null.
  ///
  /// Priority:
  /// 1. Explicit riskLevel from server
  /// 2. Korean keyword in message → mapped level
  /// 3. liquidityStatus → mapped level
  /// 4. null (renders as grey/default)
  String? get effectiveRiskLevel {
    if (riskLevel != null) return riskLevel;

    // Infer from message keywords (use Korean segment for packed strings)
    if (message != null && message!.isNotEmpty) {
      final msg = message!.contains('|||')
          ? message!.split('|||').first
          : message!;
      if (msg.contains('위험') || msg.contains('경고') || msg.contains('약세')) {
        return 'BEARISH';
      }
      if (msg.contains('주의') || msg.contains('불안')) return 'CAUTIOUS';
      if (msg.contains('양호') || msg.contains('안정') || msg.contains('확장')) {
        return 'POSITIVE';
      }
      if (msg.contains('강세') || msg.contains('과열')) return 'BULLISH';
      if (msg.contains('정상') || msg.contains('중립')) return 'NORMAL';
    }

    // Infer from liquidityStatus (m2_liquidity signal)
    if (liquidityStatus != null) {
      switch (liquidityStatus) {
        case 'EXPANDING':
          return 'POSITIVE';
        case 'CONTRACTING':
          return 'CAUTIOUS';
        case 'NEUTRAL':
          return 'NEUTRAL';
      }
    }

    return null;
  }

  /// Risk level color — uses effectiveRiskLevel for fallback
  Color riskColor(MarketLensColors colors) {
    switch (effectiveRiskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return colors.dangerColor;
      case 'CAUTIOUS':
      case 'WARNING':
        return colors.warningColor;
      case 'NEUTRAL':
      case 'NORMAL':
        return colors.neutralColor;
      case 'POSITIVE':
        return colors.gainColor;
      case 'BULLISH':
        return colors.accentBlue;
      default:
        return colors.neutralColor;
    }
  }

  /// Risk level background color — uses effectiveRiskLevel for fallback
  Color riskBackgroundColor(MarketLensColors colors) {
    switch (effectiveRiskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return colors.dangerBg;
      case 'CAUTIOUS':
      case 'WARNING':
        return colors.warningBg;
      case 'NEUTRAL':
      case 'NORMAL':
        return colors.sectionBackground;
      case 'POSITIVE':
        return colors.gainBg;
      case 'BULLISH':
        return colors.infoBg;
      default:
        return colors.sectionBackground;
    }
  }

  /// Localized short display label for signal
  String shortLabelLocalized(AppLocalizations l10n) {
    final labels = {
      'yield_curve': l10n.macroYieldCurve,
      'm2_liquidity': l10n.macroLiquidity,
      'overall_macro': l10n.macroOverall,
    };
    return labels[signalCode] ?? signalCode;
  }

  /// Localized risk label — uses effectiveRiskLevel for fallback
  String riskLabelLocalized(AppLocalizations l10n) {
    switch (effectiveRiskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return l10n.riskBearish;
      case 'CAUTIOUS':
      case 'WARNING':
        return l10n.riskCautious;
      case 'NEUTRAL':
      case 'NORMAL':
        return l10n.riskNeutral;
      case 'POSITIVE':
        return l10n.riskPositive;
      case 'BULLISH':
        return l10n.riskBullish;
      default:
        return '–';
    }
  }
}
