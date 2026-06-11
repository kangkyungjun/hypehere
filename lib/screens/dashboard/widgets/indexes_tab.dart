import 'package:flutter/material.dart';
import '../../../models/macro_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/multilingual.dart';
import '../../../widgets/ads/banner_ad_widget.dart';
import '../../../widgets/charts/macro_gauge_painter.dart';
import '../../../widgets/common/bento_card.dart';
import '../../indexes/macro_history_screen.dart';

/// Dashboard "Indexes" tab showing detailed macro economic indicators as a list.
///
/// Combines [MacroIndicatorsData] indicators and [MacroSignalsData] signals
/// (excluding `overall_macro`) into a unified card list with risk badges
/// and 3-month statistics. Banner ads inserted every 4 cards.
class IndexesTab extends StatefulWidget {
  final MacroIndicatorsData? data;
  final MacroSignalsData? signals;

  const IndexesTab({
    super.key,
    this.data,
    this.signals,
  });

  @override
  State<IndexesTab> createState() => _IndexesTabState();
}

class _IndexesTabState extends State<IndexesTab> {
  bool _showAll = false;

  // ── Risk helpers ──────────────────────────────────────────

  Color _riskColor(String? riskLevel, MarketLensColors mlc) {
    switch (riskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return mlc.lossColor;
      case 'CAUTIOUS':
      case 'WARNING':
        return mlc.warningColor;
      case 'NEUTRAL':
      case 'NORMAL':
        return mlc.neutralColor;
      case 'POSITIVE':
        return mlc.gainColor;
      case 'BULLISH':
        return mlc.accentBlue;
      default:
        return mlc.neutralColor;
    }
  }

  String _riskLabel(BuildContext context, String? riskLevel) {
    final l10n = AppLocalizations.of(context);
    switch (riskLevel) {
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
        return '\u2013'; // en-dash
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);

    // Merge indicators + signals (exclude overall_macro)
    final items = <_IndexItem>[];

    if (widget.data != null) {
      for (final ind in widget.data!.indicators) {
        items.add(_IndexItem.fromIndicator(ind));
      }
    }

    if (widget.signals != null) {
      for (final sig in widget.signals!.signals) {
        if (sig.signalCode == 'overall_macro') continue;
        items.add(_IndexItem.fromSignal(sig));
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Text(
            '\u2013',
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              color: mlc.textTertiary,
            ),
          ),
        ),
      );
    }

    // Limit to 10 items unless "show all" is toggled
    final displayItems = _showAll ? items : items.take(10).toList();
    final hasMore = items.length > 10 && !_showAll;

    // Build children with banner ads every 4 cards
    final children = <Widget>[];
    for (int i = 0; i < displayItems.length; i++) {
      children.add(_buildCard(context, displayItems[i], mlc, l10n));
      if ((i + 1) % 4 == 0 && i < displayItems.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(child: BannerAdWidget()),
          ),
        );
      }
    }

    // "더보기" button
    if (hasMore) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: mlc.subtleBorder),
                ),
              ),
              child: Text(
                l10n.viewMore,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.semiBold,
                  color: mlc.accentBlue,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        MediaQuery.of(context).viewPadding.bottom + 64,
      ),
      children: [
        _buildGaugeHeader(context, mlc, l10n),
        ...children,
      ],
    );
  }

  // ── Gauge header ─────────────────────────────────────────

  MacroSignal? _overallMacro() {
    if (widget.signals == null) return null;
    try {
      return widget.signals!.signals
          .firstWhere((s) => s.signalCode == 'overall_macro');
    } catch (_) {
      return null;
    }
  }

  Widget _buildGaugeHeader(
    BuildContext context,
    MarketLensColors mlc,
    AppLocalizations l10n,
  ) {
    final overall = _overallMacro();
    if (overall == null) return const SizedBox.shrink();

    final langCode = Localizations.localeOf(context).languageCode;
    final riskLabel = overall.riskLabelLocalized(l10n);
    final dotColor = overall.riskColor(mlc);

    String summary = '';
    if (overall.cleanMessage != null) {
      final lines = overall.cleanMessage!.localize(langCode).split('\n');
      summary = lines.first;
      if (summary.contains(': ')) {
        summary = summary.substring(summary.indexOf(': ') + 2);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        children: [
          // Gauge arc
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: MacroGaugePainter(
                riskLevel: overall.effectiveRiskLevel,
                needleColor: mlc.textSecondary,
                innerDotColor: mlc.cardBackground,
                bearishColor: mlc.lossColor,
                cautiousColor: mlc.gaugeCautious,
                neutralSegColor: mlc.neutralColor,
                positiveColor: mlc.gainColor,
                bullishColor: mlc.gaugeBullish,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Label: ● 거시경제: 중립
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.macroOverall}: $riskLabel',
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: AppTypography.bold,
                  color: mlc.textPrimary,
                ),
              ),
            ],
          ),
          // Summary text
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '($summary)',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: mlc.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Legend
          _buildGaugeLegend(mlc, l10n),
        ],
      ),
    );
  }

  Widget _buildGaugeLegend(MarketLensColors mlc, AppLocalizations l10n) {
    final items = <(Color, String)>[
      (mlc.lossColor, l10n.riskBearish),
      (mlc.gaugeCautious, l10n.riskCautious),
      (mlc.neutralColor, l10n.riskNeutral),
      (mlc.gainColor, l10n.riskPositive),
      (mlc.gaugeBullish, l10n.riskBullish),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.$1,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              item.$2,
              style: TextStyle(
                fontSize: AppTypography.micro,
                color: mlc.textTertiary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Card builder ────────────────────────────────────────────

  Widget _buildCard(
    BuildContext context,
    _IndexItem item,
    MarketLensColors mlc,
    AppLocalizations l10n,
  ) {
    final riskColor = _riskColor(item.riskLevel, mlc);
    final riskLabel = item.isSignal
        ? item.signal!.riskLabelLocalized(l10n)
        : _riskLabel(context, item.riskLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MacroHistoryScreen(
              indicatorCode: item.code,
              title: item.label(l10n),
              isSignal: item.isSignal,
            ),
          ),
        ),
        child: BentoCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: dot + label + value% + change% (left) + risk badge (right)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      item.label(l10n),
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.semiBold,
                        color: mlc.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${item.formattedValue}${item.percentSuffix}',
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                  ),
                  if (item.isIndicator && item.indicator!.changePct != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.indicator!.changeArrow}${item.indicator!.changePct!.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: AppTypography.medium,
                        color: item.indicator!.changeColor(mlc),
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      riskLabel,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: AppTypography.medium,
                        color: riskColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Row 3: 3M High / Avg / Low
              if (item.high3m != null ||
                  item.avg3m != null ||
                  item.low3m != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (item.high3m != null)
                      _stat3m(l10n, l10n.macro3mHigh, item.high3m!, mlc),
                    if (item.avg3m != null) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _stat3m(l10n, l10n.macro3mAvg, item.avg3m!, mlc),
                    ],
                    if (item.low3m != null) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _stat3m(l10n, l10n.macro3mLow, item.low3m!, mlc),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Compact 3-month stat: "3M H: 4.25"
  Widget _stat3m(
    AppLocalizations l10n,
    String abbrev,
    double value,
    MarketLensColors mlc,
  ) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.macro3mTitle} $abbrev: ',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: mlc.textTertiary,
            ),
          ),
          TextSpan(
            text: value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.medium,
              color: mlc.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unified item wrapper ──────────────────────────────────────

/// Internal wrapper that unifies [MacroIndicator] and [MacroSignal]
/// into a single interface for the list builder.
class _IndexItem {
  final MacroIndicator? indicator;
  final MacroSignal? signal;

  const _IndexItem._({this.indicator, this.signal});

  factory _IndexItem.fromIndicator(MacroIndicator ind) =>
      _IndexItem._(indicator: ind);

  factory _IndexItem.fromSignal(MacroSignal sig) =>
      _IndexItem._(signal: sig);

  bool get isIndicator => indicator != null;
  bool get isSignal => signal != null;

  String get code {
    if (isIndicator) return indicator!.indicatorCode;
    return signal!.signalCode;
  }

  String label(AppLocalizations l10n) {
    if (isIndicator) return indicator!.shortLabelLocalized(l10n);
    return signal!.shortLabelLocalized(l10n);
  }

  String? get riskLevel {
    if (isIndicator) return indicator!.riskLevel;
    return signal!.effectiveRiskLevel;
  }

  String get formattedValue {
    if (isIndicator) return indicator!.formattedValue;
    return signal!.formattedValue;
  }

  String get percentSuffix {
    if (isIndicator && indicator!.showPercentSuffix) return '%';
    return '';
  }

  double? get high3m => isIndicator ? indicator!.high3m : signal!.high3m;
  double? get avg3m => isIndicator ? indicator!.avg3m : signal!.avg3m;
  double? get low3m => isIndicator ? indicator!.low3m : signal!.low3m;
}
