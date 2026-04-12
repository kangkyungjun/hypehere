import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/portfolio_data.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/ml_divider.dart';
import '../../../utils/error_localizer.dart';
import 'portfolio_summary_card.dart';
import 'tax_estimate_card.dart';
import 'portfolio_ai_card.dart';
import 'holding_list_item.dart';
import 'holding_detail_sheet.dart';
import 'add_holding_sheet.dart';
import 'sell_holding_sheet.dart';
import 'edit_holding_sheet.dart';
import 'transaction_row.dart';
import 'login_required_banner.dart';

/// Holdings tab: summary card, AI card, holdings list, recent transactions, empty state.
class HoldingsTab extends StatefulWidget {
  final void Function(String) onTickerTap;
  final VoidCallback onSwitchToWatchlist;
  final Future<void> Function() onRefresh;

  const HoldingsTab({
    super.key,
    required this.onTickerTap,
    required this.onSwitchToWatchlist,
    required this.onRefresh,
  });

  @override
  State<HoldingsTab> createState() => _HoldingsTabState();
}

class _HoldingsTabState extends State<HoldingsTab> {
  bool _showAllRecentTxn = false;
  bool _txnLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_txnLoaded) {
      _txnLoaded = true;
      final portfolio = context.read<PortfolioProvider>();
      if (portfolio.holdings.isNotEmpty) {
        portfolio.loadTransactions();
      }
    }
  }

  Future<void> _onEditHolding(BuildContext context, PortfolioHolding holding) async {
    final action = await HoldingDetailSheet.show(context, holding);
    if (action == null || !context.mounted) return;

    switch (action) {
      case HoldingAction.additionalBuy:
        await _handleAdditionalBuy(context, holding);
      case HoldingAction.sell:
        await _handleSell(context, holding);
      case HoldingAction.edit:
        await _handleEdit(context, holding);
      case HoldingAction.delete:
        await _handleDelete(context, holding);
      case HoldingAction.viewDetail:
        widget.onTickerTap(holding.ticker);
    }
  }

  Future<void> _handleAdditionalBuy(BuildContext context, PortfolioHolding holding) async {
    final l10n = AppLocalizations.of(context);
    final h = holding;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && h.nameKo != null ? h.nameKo! : h.name ?? h.ticker;

    final result = await AddHoldingSheet.show(context, ticker: h.ticker, name: displayName);
    if (result == null || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      final oldShares = h.shares ?? 0.0;
      final oldAvg = h.avgPrice ?? 0.0;
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

  Future<void> _handleSell(BuildContext context, PortfolioHolding holding) async {
    final l10n = AppLocalizations.of(context);
    final h = holding;

    final result = await SellHoldingSheet.show(
      context,
      ticker: h.ticker,
      name: h.name,
      currentShares: h.shares ?? 0,
      avgPrice: h.avgPrice ?? 0,
      currentPrice: h.currentPrice,
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

  Future<void> _handleEdit(BuildContext context, PortfolioHolding holding) async {
    final l10n = AppLocalizations.of(context);
    final h = holding;

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

  Future<void> _handleDelete(BuildContext context, PortfolioHolding holding) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.removeHoldingConfirm(holding.ticker)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.mlColors.dangerColor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      await portfolio.deleteHolding(holding.ticker);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.holdingRemoved(holding.ticker))),
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

  void _onDeleteHolding(BuildContext context, String ticker) {
    final l10n = AppLocalizations.of(context);
    final portfolio = context.read<PortfolioProvider>();
    portfolio.deleteHolding(ticker);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.holdingRemoved(ticker))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final isLoggedIn = auth.isLoggedIn;

    // Not logged in — centered empty state
    if (!isLoggedIn) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoginRequiredBanner(),
                      const SizedBox(height: 48),
                      Icon(
                        Icons.business_center_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.noHoldingsHint,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final holdings = portfolio.holdings;

    // Empty state (logged in but no holdings) — centered
    if (holdings.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.noHoldingsHint,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OutlinedButton.icon(
                        onPressed: widget.onSwitchToWatchlist,
                        icon: const Icon(Icons.bookmark_outline, size: 18),
                        label: Text(l10n.goToWatchlistTab),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Recent transactions for all holdings
    final allTxn = portfolio.transactions;
    final displayRecentTxn = _showAllRecentTxn ? allTxn : allTxn.take(5).toList();
    final hasMoreRecentTxn = allTxn.length > 5;

    // Has holdings
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          // Portfolio summary card
          SliverToBoxAdapter(
            child: PortfolioSummaryCard(portfolio: portfolio),
          ),

          // Tax estimate card (Korean only)
          const SliverToBoxAdapter(child: MlDivider()),
          SliverToBoxAdapter(
            child: TaxEstimateCard(portfolio: portfolio),
          ),

          // Portfolio AI card
          const SliverToBoxAdapter(child: MlDivider()),
          SliverToBoxAdapter(
            child: PortfolioAICard(summary: portfolio.summary),
          ),

          // Holdings section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxs),
              child: Row(
                children: [
                  Text(
                    l10n.myHoldings,
                    style: const TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.nHoldings(holdings.length),
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Holdings list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final holding = holdings[index];
                return HoldingListItem(
                  holding: holding,
                  onTap: () => _onEditHolding(context, holding),
                  onDelete: () => _onDeleteHolding(context, holding.ticker),
                );
              },
              childCount: holdings.length,
            ),
          ),

          // Recent transactions section
          if (allTxn.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                child: Text(
                  l10n.recentTransactions,
                  style: const TextStyle(fontSize: AppTypography.headlineMedium, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final txn = displayRecentTxn[index];
                  // Find matching holding for avg price
                  final matchingHolding = holdings.where((h) => h.ticker == txn.ticker).toList();
                  final avgPrice = matchingHolding.isNotEmpty ? (matchingHolding.first.avgPrice ?? 0.0) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0 || displayRecentTxn[index - 1].ticker != txn.ticker)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxs),
                            child: Text(
                              txn.ticker,
                              style: TextStyle(
                                fontSize: AppTypography.bodySmall,
                                fontWeight: AppTypography.semiBold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        TransactionRow(txn: txn, avgPrice: avgPrice),
                      ],
                    ),
                  );
                },
                childCount: displayRecentTxn.length,
              ),
            ),
            if (hasMoreRecentTxn && !_showAllRecentTxn)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAllRecentTxn = true),
                    child: Text(
                      l10n.viewAllTransactions(allTxn.length),
                      style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              )
            else if (_showAllRecentTxn)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAllRecentTxn = false),
                    icon: Icon(Icons.keyboard_arrow_up, size: 16, color: Theme.of(context).colorScheme.primary),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'ko' ? '줄이기' : 'Show less',
                      style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}
