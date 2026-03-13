import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../utils/error_localizer.dart';
import 'add_holding_sheet.dart';
import 'sell_holding_sheet.dart';
import 'edit_holding_sheet.dart';

/// Bottom sheet showing holding details, transaction history, and action buttons.
class HoldingDetailSheet {
  HoldingDetailSheet._();

  static Future<void> show(BuildContext context, PortfolioHolding holding) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _HoldingDetailContent(
          holding: holding,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _HoldingDetailContent extends StatefulWidget {
  final PortfolioHolding holding;
  final ScrollController scrollController;

  const _HoldingDetailContent({
    required this.holding,
    required this.scrollController,
  });

  @override
  State<_HoldingDetailContent> createState() => _HoldingDetailContentState();
}

class _HoldingDetailContentState extends State<_HoldingDetailContent> {
  List<PortfolioTransaction> _transactions = [];
  bool _loadingTxn = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final portfolio = context.read<PortfolioProvider>();
    await portfolio.loadTransactions(ticker: widget.holding.ticker);
    if (mounted) {
      setState(() {
        _transactions = portfolio.getTransactionsForTicker(widget.holding.ticker);
        _loadingTxn = false;
      });
    }
  }

  Color _signalColor(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY': case 'STRONG_BUY': return Colors.green;
      case 'SELL': case 'STRONG_SELL': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _signalLabel(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY': return 'BUY';
      case 'STRONG_BUY': return 'STRONG BUY';
      case 'SELL': return 'SELL';
      case 'STRONG_SELL': return 'STRONG SELL';
      case 'HOLD': return 'HOLD';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = widget.holding;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && h.nameKo != null ? h.nameKo! : h.name ?? h.ticker;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header: ticker + price + signal
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.ticker, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(displayName, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (h.currentPrice != null)
                  Text('\$${h.currentPrice!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  '${h.pnlPct >= 0 ? '+' : ''}${h.pnlPct.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 13, color: h.pnlPct >= 0 ? Colors.green : Colors.red),
                ),
              ],
            ),
            if (h.signal != null && _signalLabel(h.signal).isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _signalColor(h.signal),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _signalLabel(h.signal),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Holding status card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.holdingStatus, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InfoItem(label: l10n.shares, value: h.shares?.toStringAsFixed(h.shares == h.shares?.truncateToDouble() ? 0 : 2) ?? '—'),
                    _InfoItem(label: l10n.avgPriceLabel, value: '\$${h.avgPrice?.toStringAsFixed(2) ?? '—'}'),
                    _InfoItem(label: l10n.currentValueLabel, value: '\$${h.currentValue.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${l10n.unrealizedPnl}: ',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${h.pnl >= 0 ? '+' : ''}\$${h.pnl.toStringAsFixed(2)} (${h.pnlPct >= 0 ? '+' : ''}${h.pnlPct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: h.pnl >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Transaction history
        Text(l10n.transactionHistory, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (_loadingTxn)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (_transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('—', style: TextStyle(color: theme.colorScheme.outline)),
          )
        else
          ..._transactions.map((txn) => _TransactionRow(txn: txn, avgPrice: h.avgPrice ?? 0)),

        const SizedBox(height: 16),

        // Action buttons: 2x2 grid
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.additionalBuy, style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () => _onAdditionalBuy(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.sell, size: 18, color: Colors.red.shade400),
                label: Text(l10n.partialSell, style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.red.shade300),
                ),
                onPressed: () => _onSell(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: Text(l10n.editHolding, style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: () => _onEdit(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                label: Text(l10n.deleteHolding, style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.red.shade300),
                ),
                onPressed: () => _onDelete(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onAdditionalBuy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context); // Close detail sheet first
    final h = widget.holding;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && h.nameKo != null ? h.nameKo! : h.name ?? h.ticker;

    final result = await AddHoldingSheet.show(context, ticker: h.ticker, name: displayName);
    if (result == null || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      // Calculate new average: (old_cost + new_cost) / (old_shares + new_shares)
      final oldShares = h.shares ?? 0;
      final oldAvg = h.avgPrice ?? 0;
      final newTotalShares = oldShares + result.shares;
      final newAvgPrice = ((oldShares * oldAvg) + (result.shares * result.avgPrice)) / newTotalShares;

      await portfolio.addTransaction(
        ticker: h.ticker, type: 'BUY', shares: result.shares,
        price: result.avgPrice, date: result.date,
      );
      await portfolio.addOrUpdateHolding(
        ticker: h.ticker, shares: newTotalShares, avgPrice: newAvgPrice,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holdingAdded(h.ticker))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _onSell(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context);
    final h = widget.holding;

    final result = await SellHoldingSheet.show(
      context,
      ticker: h.ticker,
      name: h.name,
      currentShares: h.shares ?? 0,
      avgPrice: h.avgPrice ?? 0,
    );
    if (result == null || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      await portfolio.sellHolding(
        ticker: h.ticker,
        shares: result.shares,
        price: result.price,
        date: result.date,
        currentShares: h.shares ?? 0,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holdingSold(h.ticker))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _onEdit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context);
    final h = widget.holding;

    final result = await EditHoldingSheet.show(
      context,
      ticker: h.ticker,
      name: h.name,
      currentShares: h.shares ?? 0,
      avgPrice: h.avgPrice ?? 0,
      purchaseDate: h.createdAt,
    );
    if (result == null || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      await portfolio.addOrUpdateHolding(
        ticker: h.ticker, shares: result.shares, avgPrice: result.avgPrice,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holdingUpdated(h.ticker))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.removeHoldingConfirm(widget.holding.ticker)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    Navigator.pop(context);
    final portfolio = context.read<PortfolioProvider>();
    try {
      await portfolio.deleteHolding(widget.holding.ticker);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holdingRemoved(widget.holding.ticker))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final PortfolioTransaction txn;
  final double avgPrice;

  const _TransactionRow({required this.txn, required this.avgPrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = txn.type == 'BUY';
    final dateStr = '${txn.date.year}-${txn.date.month.toString().padLeft(2, '0')}-${txn.date.day.toString().padLeft(2, '0')}';
    final realizedPnl = !isBuy ? (txn.price - avgPrice) * txn.shares : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Text(dateStr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBuy ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              txn.type,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isBuy ? Colors.green : Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${txn.shares.toStringAsFixed(txn.shares == txn.shares.truncateToDouble() ? 0 : 2)} x \$${txn.price.toStringAsFixed(2)} = \$${txn.totalValue.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
            ),
          ),
          if (realizedPnl != null)
            Text(
              '${realizedPnl >= 0 ? '+' : ''}\$${realizedPnl.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: realizedPnl >= 0 ? Colors.green : Colors.red),
            ),
        ],
      ),
    );
  }
}
