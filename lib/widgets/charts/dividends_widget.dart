import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/bento_card.dart';

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
                  fontWeight: AppTypography.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Yield + Annual total — 라벨=뮤트, 값=blue(비방향성 집계). 오버플로 방어.
          Row(
            children: [
              if (dividendYield != null) ...[
                Text(
                  '${l10n.dividendYield} ',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.textSecondary),
                ),
                Flexible(
                  child: Text(
                    '${(dividendYield! * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.semiBold,
                      color: context.mlColors.accentBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (dividendYield != null && annualTotal > 0)
                const SizedBox(width: AppSpacing.xxl),
              if (annualTotal > 0) ...[
                Text(
                  '${l10n.annualDividend} ',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.textSecondary),
                ),
                Flexible(
                  child: Text(
                    '\$${annualTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.semiBold,
                      color: context.mlColors.accentBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                return BentoCard(
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
                  child: SizedBox(
                    width: 72 - AppSpacing.sm * 2,
                    child: Column(
                      children: [
                        Text(
                          shortDate,
                          style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            d.amount != null
                                ? '\$${d.amount!.toStringAsFixed(2)}'
                                : '--',
                            style: const TextStyle(
                              fontSize: AppTypography.bodyMedium,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
