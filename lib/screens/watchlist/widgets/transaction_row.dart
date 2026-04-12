import 'package:flutter/material.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Shared transaction row widget used in HoldingDetailSheet and HoldingsTab.
class TransactionRow extends StatelessWidget {
  final PortfolioTransaction txn;
  final double avgPrice;

  const TransactionRow({super.key, required this.txn, required this.avgPrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mlc = context.mlColors;
    final isBuy = txn.type == 'BUY';
    final dateStr = '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}-${txn.date.day.toString().padLeft(2, '0')}';
    final realizedPnl = !isBuy ? (txn.price - avgPrice) * txn.shares : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Text(dateStr, style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: isBuy ? mlc.gainColor.withValues(alpha: 0.1) : mlc.lossColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              txn.type,
              style: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.bold, color: isBuy ? mlc.gainColor : mlc.lossColor),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${txn.shares.toStringAsFixed(txn.shares == txn.shares.truncateToDouble() ? 0 : 2)} x \$${txn.price.toStringAsFixed(2)} = \$${txn.totalValue.toStringAsFixed(2)}',
              style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.onSurface),
            ),
          ),
          if (realizedPnl != null)
            Text(
              '${realizedPnl >= 0 ? '+' : ''}\$${realizedPnl.toStringAsFixed(2)}',
              style: TextStyle(fontSize: AppTypography.caption, fontWeight: AppTypography.semiBold, color: realizedPnl >= 0 ? mlc.gainColor : mlc.lossColor),
            ),
        ],
      ),
    );
  }
}
