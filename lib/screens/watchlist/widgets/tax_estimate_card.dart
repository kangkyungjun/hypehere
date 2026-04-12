import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/tax_calculator.dart';

/// Korean-only card showing estimated capital gains tax on US stock trades.
///
/// Filters current-year SELL transactions, computes gains using TaxCalculator,
/// and displays annual tax estimate. Returns SizedBox.shrink() for non-Korean locales.
class TaxEstimateCard extends StatelessWidget {
  final PortfolioProvider portfolio;

  const TaxEstimateCard({super.key, required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (!isKo) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exchangeRate = portfolio.exchangeRate;

    // Need exchange rate and transactions to calculate
    if (exchangeRate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final currentYear = now.year;

    // Filter SELL transactions for current year
    final sellTxns = portfolio.transactions
        .where((t) => t.type == 'SELL' && t.date.year == currentYear)
        .toList();

    if (sellTxns.isEmpty) return const SizedBox.shrink();

    // Build TaxResult list from SELL transactions
    // Use avgPrice of matching holding as buy price, or the transaction's own context
    final trades = <TaxResult>[];
    for (final txn in sellTxns) {
      // Find matching holding for avg buy price
      final matchingHolding = portfolio.holdings
          .where((h) => h.ticker == txn.ticker)
          .toList();
      final avgBuyPrice = matchingHolding.isNotEmpty
          ? (matchingHolding.first.avgPrice ?? txn.price)
          : txn.price;

      trades.add(TaxCalculator.estimateSellTax(
        avgBuyPriceUsd: avgBuyPrice,
        currentPriceUsd: txn.price,
        shares: txn.shares,
        exchangeRate: exchangeRate.usdKrw,
      ));
    }

    final summary = TaxCalculator.calculateAnnualTax(trades: trades);
    final krwFormat = NumberFormat('#,###', 'ko');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.taxEstimateTitle,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.semiBold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$currentYear',
                    style: TextStyle(fontSize: AppTypography.caption, color: theme.colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Gain / Exemption / Tax / Net rows
              _TaxRow(
                label: l10n.totalGains,
                value: '${krwFormat.format(summary.netGainKrw.round())}${l10n.krwSuffix}',
                valueColor: summary.netGainKrw >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              _TaxRow(
                label: l10n.annualExemption,
                value: '-${krwFormat.format(summary.exemptionUsedKrw.round())}${l10n.krwSuffix}',
                valueColor: theme.colorScheme.onSurfaceVariant,
              ),
              const Divider(height: 12),
              _TaxRow(
                label: l10n.estimatedTax,
                value: '${krwFormat.format(summary.estimatedTaxKrw.round())}${l10n.krwSuffix}',
                valueColor: context.mlColors.lossColor,
                bold: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              _TaxRow(
                label: l10n.netProfit,
                value: '${krwFormat.format(summary.afterTaxGainKrw.round())}${l10n.krwSuffix}',
                valueColor: summary.afterTaxGainKrw >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                bold: true,
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(
                '${sellTxns.length}${l10n.taxTradeCount} | 1\$ = ${krwFormat.format(exchangeRate.usdKrw.round())}${l10n.krwSuffix}',
                style: TextStyle(fontSize: AppTypography.micro, color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _TaxRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: bold ? AppTypography.semiBold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: bold ? AppTypography.bold : AppTypography.medium,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
