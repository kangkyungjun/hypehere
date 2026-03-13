import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/portfolio_provider.dart';
import 'portfolio_summary_card.dart';
import 'portfolio_ai_card.dart';
import 'holding_list_item.dart';
import 'holding_detail_sheet.dart';
import 'login_required_banner.dart';

/// Holdings tab: summary card, AI card, holdings list, empty state.
class HoldingsTab extends StatelessWidget {
  final void Function(String) onTickerTap;
  final VoidCallback onSwitchToWatchlist;
  final Future<void> Function() onRefresh;

  const HoldingsTab({
    super.key,
    required this.onTickerTap,
    required this.onSwitchToWatchlist,
    required this.onRefresh,
  });

  void _onEditHolding(BuildContext context, dynamic holding) {
    HoldingDetailSheet.show(context, holding);
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

    // Not logged in
    if (!isLoggedIn) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const LoginRequiredBanner(),
                const SizedBox(height: 48),
                Icon(
                  Icons.business_center_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noHoldingsHint,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final holdings = portfolio.holdings;

    // Empty state (logged in but no holdings)
    if (holdings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.business_center_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noHoldingsHint,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onSwitchToWatchlist,
                  icon: const Icon(Icons.bookmark_outline, size: 18),
                  label: Text(l10n.goToWatchlistTab),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Has holdings
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // Portfolio summary card
          SliverToBoxAdapter(
            child: PortfolioSummaryCard(portfolio: portfolio),
          ),

          // Portfolio AI card
          SliverToBoxAdapter(
            child: PortfolioAICard(summary: portfolio.summary),
          ),

          // Holdings section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Row(
                children: [
                  Text(
                    l10n.myHoldings,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.nHoldings(holdings.length),
                    style: TextStyle(
                      fontSize: 12,
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
                  onTap: () => onTickerTap(holding.ticker),
                  onDelete: () => _onDeleteHolding(context, holding.ticker),
                  onEdit: () => _onEditHolding(context, holding),
                );
              },
              childCount: holdings.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
}
