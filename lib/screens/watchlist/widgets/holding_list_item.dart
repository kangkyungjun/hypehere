import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';

/// A single holding row in the portfolio section.
///
/// Layout:
/// [Score] [Ticker + name + shares@price + 📅date] [Value + P&L%] [Signal] [✏️]
class HoldingListItem extends StatelessWidget {
  final PortfolioHolding holding;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HoldingListItem({
    super.key,
    required this.holding,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  Color _signalColor(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY':
      case 'STRONG_BUY':
        return Colors.green;
      case 'SELL':
      case 'STRONG_SELL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _signalLabel(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY':
        return 'BUY';
      case 'STRONG_BUY':
        return 'STRONG BUY';
      case 'SELL':
        return 'SELL';
      case 'STRONG_SELL':
        return 'STRONG SELL';
      case 'HOLD':
        return 'HOLD';
      default:
        return '';
    }
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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Score box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: holding.score != null
                          ? _signalColor(holding.signal)
                              .withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          holding.score?.toStringAsFixed(0) ?? '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: holding.score != null
                                ? _signalColor(holding.signal)
                                : theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          l10n.score,
                          style: TextStyle(
                            fontSize: 8,
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 12,
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
                                  fontSize: 10,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              if (holding.createdAt != null) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.calendar_today,
                                    size: 10,
                                    color: theme.colorScheme.outline),
                                const SizedBox(width: 2),
                                Text(
                                  _formatDate(holding.createdAt!),
                                  style: TextStyle(
                                    fontSize: 10,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${holding.pnlPct >= 0 ? '+' : ''}${holding.pnlPct.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              holding.pnlPct >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 6),

                  // Signal pill
                  if (holding.signal != null &&
                      _signalLabel(holding.signal).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _signalColor(holding.signal),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _signalLabel(holding.signal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Edit button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onEdit,
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
