import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Dividend history and yield widget
///
/// Shows dividend yield, estimated annual total (sum of last 4 entries),
/// and a list of recent ex-date / amount entries.
class DividendsWidget extends StatelessWidget {
  final List<DividendEntry>? dividends;
  final double? dividendYield;
  final EdgeInsetsGeometry? margin;

  const DividendsWidget({
    super.key,
    required this.dividends,
    this.dividendYield,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (dividends == null || dividends!.isEmpty) return const SizedBox.shrink();

    final entries = dividends!;

    // Annual total: sum of last 4 entries (quarterly assumption)
    final recentForAnnual = entries.length >= 4 ? entries.sublist(0, 4) : entries;
    final annualTotal = recentForAnnual
        .where((d) => d.amount != null)
        .fold<double>(0.0, (sum, d) => sum + d.amount!);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            l10n.dividends,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Yield + Annual total
          Row(
            children: [
              if (dividendYield != null) ...[
                Text(
                  '${l10n.dividendYield} ',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${(dividendYield! * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
              if (dividendYield != null && annualTotal > 0)
                Text(
                  '     ',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              if (annualTotal > 0) ...[
                Text(
                  '${l10n.annualDividend} ',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  '\$${annualTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Recent dividend entries (up to 8) – horizontal scroll cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: entries.take(8).map((d) {
                // Format date: "2025-02-14" → "25.02"
                final parts = d.exDate.split('-');
                final shortDate = parts.length >= 2
                    ? '${parts[0].substring(2)}.${parts[1]}'
                    : d.exDate;
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.mlColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.mlColors.subtleBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        shortDate,
                        style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        d.amount != null
                            ? '\$${d.amount!.toStringAsFixed(2)}'
                            : '--',
                        style: const TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: AppTypography.semiBold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
