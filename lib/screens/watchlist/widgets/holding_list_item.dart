import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';

/// A single holding row in the portfolio section.
///
/// Layout:
/// [Score] [Ticker + name + shares@price + 📅date] [Value + P&L%] [Signal] [✏️]
class HoldingListItem extends StatelessWidget {
  final PortfolioHolding holding;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HoldingListItem({
    super.key,
    required this.holding,
    required this.onTap,
    required this.onDelete,
  });

  Color _signalColor(BuildContext context, String? signal) {
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == 'STRONG_BUY' || s.contains('매수')) {
      return context.mlColors.gainColor;
    }
    if (s == 'SELL' || s == 'STRONG_SELL' || s.contains('매도')) {
      return context.mlColors.lossColor;
    }
    return context.mlColors.neutralColor;
  }

  String _signalLabel(BuildContext context, String? signal) {
    final l10n = AppLocalizations.of(context);
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == '매수권고') return l10n.scoreBuy;
    if (s == 'STRONG_BUY' || s == '적극매수') return l10n.scoreStrongBuy;
    if (s == 'SELL' || s == '매도권고') return l10n.scoreSell;
    if (s == 'STRONG_SELL' || s == '적극매도') return l10n.scoreStrongSell;
    if (s == 'HOLD' || s == '관망') return l10n.scoreHold;
    return '';
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && holding.nameKo != null
        ? holding.nameKo!
        : holding.name ?? holding.ticker;

    return Dismissible(
      key: Key('holding_${holding.ticker}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.confirm),
                content: Text(l10n.removeHoldingConfirm(holding.ticker)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: context.mlColors.dangerColor,
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.mlColors.dangerColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Icon(Icons.delete, color: context.mlColors.onPrimary),
      ),
      child: BentoCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: onTap,
        child: Row(
          children: [
            // Score box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: holding.score != null
                    ? _signalColor(
                        context,
                        holding.signal,
                      ).withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    holding.score?.toStringAsFixed(0) ?? '—',
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      color: holding.score != null
                          ? _signalColor(context, holding.signal)
                          : theme.colorScheme.outline,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                  Text(
                    l10n.score,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: mlc.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // Ticker + name + shares@price + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.ticker,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                  ),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: mlc.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (holding.shares != null && holding.avgPrice != null)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.sharesAtPrice(
                              holding.shares!.toStringAsFixed(
                                holding.shares! ==
                                        holding.shares!.truncateToDouble()
                                    ? 0
                                    : 2,
                              ),
                              holding.avgPrice!.toStringAsFixed(2),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: mlc.textSecondary,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ),
                        if (holding.createdAt != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: mlc.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            _formatDate(holding.createdAt!),
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: mlc.textSecondary,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // Current value + P&L%
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (holding.currentPrice != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${holding.currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.semiBold,
                        color: mlc.textPrimary,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${holding.pnlPct >= 0 ? '▲' : '▼'} ${holding.pnlPct.abs().toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: holding.pnlPct >= 0
                        ? context.mlColors.gainColor
                        : context.mlColors.lossColor,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // Signal pill
            if (holding.signal != null &&
                _signalLabel(context, holding.signal).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _signalColor(context, holding.signal),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  _signalLabel(context, holding.signal),
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),

            // Chevron
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: mlc.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
