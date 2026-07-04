import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Valuation metrics, profitability, and financial health grade widget
///
/// Displays PE/PB/PEG/PS grid, profitability metrics, and a computed
/// financial health grade (S/A/B/C) based on debt, liquidity, and margins.
class ValuationMetricsWidget extends StatelessWidget {
  final KeyMetrics? metrics;
  final EdgeInsetsGeometry? margin;

  const ValuationMetricsWidget({super.key, required this.metrics, this.margin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (metrics == null) return const SizedBox.shrink();
    final m = metrics!;

    // Hide if no valuation data at all
    if (m.pe == null && m.pb == null && m.peg == null && m.ps == null &&
        m.profitMargin == null && m.roe == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market Cap header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.valuation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
              ),
              if (m.marketCap != null)
                Text(
                  _formatMarketCap(m.marketCap!),
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: AppTypography.semiBold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Valuation grid (2 rows x 3 cols)
          _buildMetricGrid(context, [
            _MetricItem('PER', _fmtNum(m.pe)),
            _MetricItem('PBR', _fmtNum(m.pb)),
            _MetricItem('PEG', _fmtNum(m.peg)),
            _MetricItem('PSR', _fmtNum(m.ps)),
            _MetricItem(l10n.forwardPE, _fmtNum(m.forwardPe)),
            _MetricItem(l10n.beta, _fmtNum(m.beta)),
            _MetricItem('EV/EBITDA', _fmtNum(m.evEbitda)),
          ]),

          const SizedBox(height: AppSpacing.md),

          // Profitability & Growth
          Text(
            l10n.profitabilityGrowth,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _buildMetricGrid(context, [
            _MetricItem(l10n.netProfitMargin, _fmtPct(m.profitMargin)),
            _MetricItem('ROE', _fmtPct(m.roe)),
            _MetricItem(l10n.revenueGrowth, _fmtPctSigned(m.revenueGrowth)),
            _MetricItem(l10n.operatingMargin, _fmtPct(m.operatingMargin)),
            _MetricItem('ROA', _fmtPct(m.roa)),
            _MetricItem(l10n.earningsGrowth, _fmtPctSigned(m.earningsGrowth)),
          ]),

          const SizedBox(height: AppSpacing.md),

          // Financial Health Grade
          _buildHealthGrade(context, m),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, List<_MetricItem> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final end = (i + 3).clamp(0, items.length);
      final rowItems = items.sublist(i, end);
      rows.add(
        Row(
          children: rowItems.map((item) {
            return Expanded(
              child: _buildMetricTile(context, item.label, item.value),
            );
          }).toList(),
        ),
      );
      if (end < items.length) rows.add(const SizedBox(height: AppSpacing.md));
    }
    return Column(children: rows);
  }

  Widget _buildMetricTile(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.headlineSmall,
              fontWeight: AppTypography.semiBold,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGrade(BuildContext context, KeyMetrics m) {
    final grade = _calculateGrade(m);
    final gradeColor = _gradeColor(context, grade);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          // Grade badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  color: context.mlColors.onPrimary,
                  fontSize: AppTypography.headlineLarge,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Label + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).financialHealth,
                  style: const TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _healthDetails(context, m),
                  style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateGrade(KeyMetrics m) {
    final de = m.debtToEquity;
    final cr = m.currentRatio;
    final pm = m.profitMargin;

    if (de != null && cr != null && pm != null) {
      if (de < 0.5 && cr > 2.0 && pm > 0.2) return 'S';
      if (de < 1.0 && cr > 1.5 && pm > 0.1) return 'A';
      if (de < 2.0 && cr > 1.0 && pm > 0.0) return 'B';
    }
    return 'C';
  }

  Color _gradeColor(BuildContext context, String grade) {
    switch (grade) {
      case 'S':
        return Theme.of(context).colorScheme.tertiary;
      case 'A':
        return context.mlColors.gainColor;
      case 'B':
        return context.mlColors.warningColor;
      default:
        return context.mlColors.lossColor;
    }
  }

  String _healthDetails(BuildContext context, KeyMetrics m) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];
    if (m.debtToEquity != null) parts.add('${l10n.debtRatio}: ${_fmtNum(m.debtToEquity)}');
    if (m.currentRatio != null) parts.add('${l10n.liquidityRatio}: ${_fmtNum(m.currentRatio)}');
    return parts.join('  ·  ');
  }

  static String _fmtNum(double? v) {
    if (v == null) return '--';
    if (v.abs() >= 1000) return v.toStringAsFixed(0);
    if (v.abs() >= 100) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  static String _fmtPct(double? v) {
    if (v == null) return '--';
    return '${(v * 100).toStringAsFixed(1)}%';
  }

  static String _fmtPctSigned(double? v) {
    if (v == null) return '--';
    final pct = v * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String _formatMarketCap(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(1)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _MetricItem {
  final String label;
  final String value;
  _MetricItem(this.label, this.value);
}
