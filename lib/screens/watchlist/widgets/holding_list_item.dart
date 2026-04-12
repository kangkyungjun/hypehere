import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

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

  String _signalLabel(String? signal) {
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == '매수권고') return 'BUY';
    if (s == 'STRONG_BUY' || s == '적극매수') return 'STRONG BUY';
    if (s == 'SELL' || s == '매도권고') return 'SELL';
    if (s == 'STRONG_SELL' || s == '적극매도') return 'STRONG SELL';
    if (s == 'HOLD' || s == '관망') return 'HOLD';
    return '';
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                    style: TextButton.styleFrom(foregroundColor: context.mlColors.dangerColor),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: context.mlColors.dangerColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Icon(Icons.delete, color: context.mlColors.onPrimary),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Score box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: holding.score != null
                          ? _signalColor(context, holding.signal)
                              .withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          holding.score?.toStringAsFixed(0) ?? '—',
                          style: TextStyle(
                            fontSize: AppTypography.headlineMedium,
                            fontWeight: FontWeight.bold,
                            color: holding.score != null
                                ? _signalColor(context, holding.signal)
                                : theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          l10n.score,
                          style: TextStyle(
                            fontSize: AppTypography.chartMicro,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Ticker + name + shares@price + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          holding.ticker,
                          style: const TextStyle(
                            fontSize: AppTypography.headlineSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (holding.shares != null &&
                            holding.avgPrice != null)
                          Row(
                            children: [
                              Text(
                                l10n.sharesAtPrice(
                                  holding.shares!.toStringAsFixed(
                                      holding.shares! ==
                                              holding.shares!
                                                  .truncateToDouble()
                                          ? 0
                                          : 2),
                                  holding.avgPrice!.toStringAsFixed(2),
                                ),
                                style: TextStyle(
                                  fontSize: AppTypography.micro,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              if (holding.createdAt != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(Icons.calendar_today,
                                    size: 10,
                                    color: theme.colorScheme.outline),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  _formatDate(holding.createdAt!),
                                  style: TextStyle(
                                    fontSize: AppTypography.micro,
                                    color: theme.colorScheme.outline,
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
                    children: [
                      if (holding.currentPrice != null)
                        Text(
                          '\$${holding.currentValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: AppTypography.bodySmall,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${holding.pnlPct >= 0 ? '+' : ''}${holding.pnlPct.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: AppTypography.medium,
                          color:
                              holding.pnlPct >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Signal pill
                  if (holding.signal != null &&
                      _signalLabel(holding.signal).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: _signalColor(context, holding.signal),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        _signalLabel(holding.signal),
                        style: TextStyle(
                          color: context.mlColors.onPrimary,
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}
