import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Card showing portfolio totals: value | unrealized P&L | realized P&L.
///
/// Only displayed when logged in AND has holdings.
class PortfolioSummaryCard extends StatelessWidget {
  final PortfolioProvider portfolio;

  const PortfolioSummaryCard({super.key, required this.portfolio});

  String _formatMoney(double value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${value >= 0 ? '' : '-'}\$${(abs / 1000000).toStringAsFixed(2)}M';
    }
    if (abs >= 1000) {
      return '${value >= 0 ? '' : '-'}\$${(abs / 1000).toStringAsFixed(1)}K';
    }
    return '${value >= 0 ? '' : '-'}\$${abs.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final totalVal = portfolio.totalValue;
    final totalPnl = portfolio.totalPnl;
    final totalPnlPct = portfolio.totalPnlPct;
    final realized = portfolio.realizedPnl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Row(
            children: [
              // Total Value
              Expanded(
                child: _MetricColumn(
                  label: l10n.totalValue,
                  value: _formatMoney(totalVal),
                  valueColor: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              // Unrealized P&L
              Expanded(
                child: _MetricColumn(
                  label: l10n.unrealizedPnl,
                  value:
                      '${totalPnl >= 0 ? '+' : ''}${_formatMoney(totalPnl)}',
                  subValue:
                      '${totalPnlPct >= 0 ? '+' : ''}${totalPnlPct.toStringAsFixed(2)}%',
                  valueColor: totalPnl >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              // Realized P&L
              Expanded(
                child: _MetricColumn(
                  label: l10n.realizedPnl,
                  value:
                      '${realized >= 0 ? '+' : ''}${_formatMoney(realized)}',
                  valueColor: realized >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color valueColor;

  const _MetricColumn({
    required this.label,
    required this.value,
    this.subValue,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.bodyLarge,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: valueColor,
            ),
          ),
      ],
    );
  }
}
