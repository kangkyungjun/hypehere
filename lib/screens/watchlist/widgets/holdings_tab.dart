import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../models/portfolio_data.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';
import '../../../widgets/common/section_header.dart';
import '../../../utils/error_localizer.dart';
import 'portfolio_summary_card.dart';
import 'investment_style_chip.dart';
import 'tax_estimate_card.dart';
import 'portfolio_ai_card.dart';
import 'holding_list_item.dart';
import 'holding_detail_sheet.dart';
import 'add_holding_sheet.dart';
import 'sell_holding_sheet.dart';
import 'edit_holding_sheet.dart';
import 'transaction_row.dart';
import 'login_required_banner.dart';
import '../../../widgets/common/coach_mark_overlay.dart';
import '../../../providers/coach_mark_provider.dart';

/// Holdings tab: summary card, AI card, holdings list, recent transactions, empty state.
class HoldingsTab extends StatefulWidget {
  final void Function(String) onTickerTap;
  final VoidCallback onSwitchToWatchlist;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddHolding;

  const HoldingsTab({
    super.key,
    required this.onTickerTap,
    required this.onSwitchToWatchlist,
    required this.onRefresh,
    this.onAddHolding,
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

  Future<void> _onEditHolding(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
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

  Future<void> _handleAdditionalBuy(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
    final l10n = AppLocalizations.of(context);
    final h = holding;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && h.nameKo != null
        ? h.nameKo!
        : h.name ?? h.ticker;

    final result = await AddHoldingSheet.show(
      context,
      ticker: h.ticker,
      name: displayName,
    );
    if (result == null || !context.mounted) return;

    final portfolio = context.read<PortfolioProvider>();
    try {
      final oldShares = h.shares ?? 0.0;
      final oldAvg = h.avgPrice ?? 0.0;
      final newTotalShares = oldShares + result.shares;
      final newAvgPrice = newTotalShares > 0
          ? ((oldShares * oldAvg) + (result.shares * result.avgPrice)) /
                newTotalShares
          : result.avgPrice;

      await portfolio.addTransaction(
        ticker: h.ticker,
        type: 'BUY',
        shares: result.shares,
        price: result.avgPrice,
        date: result.date,
      );
      await portfolio.addOrUpdateHolding(
        ticker: h.ticker,
        shares: newTotalShares,
        avgPrice: newAvgPrice,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.holdingAdded(h.ticker))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _handleSell(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.holdingSold(h.ticker))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
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
        ticker: h.ticker,
        shares: result.shares,
        avgPrice: result.avgPrice,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.holdingUpdated(h.ticker))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.holdingRemoved(ticker))));
  }

  Widget _benefitItem(ThemeData theme, String text) {
    final mlc = context.mlColors;
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: mlc.accentBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: mlc.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final isLoggedIn = auth.isLoggedIn;

    // Not logged in — centered empty state
    if (!isLoggedIn) {
      final mlc = context.mlColors;
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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: mlc.infoBg.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.business_center_outlined,
                          size: 34,
                          color: mlc.textTertiary,
                        ),
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

    // Empty state (logged in but no holdings) — AI benefit preview + direct add
    if (holdings.isEmpty) {
      final theme = Theme.of(context);
      final mlc = context.mlColors;
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Investment style chip ("당신의 투자성향 · 균형형").
                      // Parent already applies horizontal padding, so use 0.
                      const InvestmentStyleChip(horizontalPadding: 0),
                      const SizedBox(height: AppSpacing.xl),
                      CoachMark(
                        coachKey: CoachMarkProvider.keyHoldings,
                        message: l10n.coachMarkHoldings,
                        child: const SizedBox.shrink(),
                      ),
                      BentoCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: mlc.infoBg.withValues(alpha: 0.58),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: mlc.accentBlue,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.portfolioAIAnalysis,
                              style: TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                fontWeight: AppTypography.bold,
                                color: mlc.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.aiPortfolioBenefitTitle,
                              style: TextStyle(
                                fontSize: AppTypography.bodyLarge,
                                color: mlc.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _benefitItem(theme, l10n.aiPortfolioBenefit1),
                            const SizedBox(height: AppSpacing.sm),
                            _benefitItem(theme, l10n.aiPortfolioBenefit2),
                            const SizedBox(height: AppSpacing.sm),
                            _benefitItem(theme, l10n.aiPortfolioBenefit3),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Primary CTA — direct add holding
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onAddHolding,
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            l10n.addHoldingDirect,
                            style: const TextStyle(
                              fontSize: AppTypography.headlineSmall,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Secondary — go to watchlist
                      TextButton(
                        onPressed: widget.onSwitchToWatchlist,
                        child: Text(
                          l10n.goToWatchlistTab,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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
    final displayRecentTxn = _showAllRecentTxn
        ? allTxn
        : allTxn.take(5).toList();
    final hasMoreRecentTxn = allTxn.length > 5;

    // Has holdings
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          // Holdings subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Text(
                l10n.holdingsSubtitle,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: context.mlColors.textSecondary,
                ),
              ),
            ),
          ),
          // Portfolio summary card
          SliverToBoxAdapter(child: PortfolioSummaryCard(portfolio: portfolio)),

          // Investment style chip ("당신의 투자성향 · 균형형")
          const SliverToBoxAdapter(child: InvestmentStyleChip()),

          // Tax estimate card (Korean only)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(child: TaxEstimateCard(portfolio: portfolio)),

          // Portfolio AI card
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: PortfolioAICard(
              summary: portfolio.summary,
              isAdFree: auth.shouldHideAds || sub.isGoldActive,
            ),
          ),

          // Holdings section header
          SliverToBoxAdapter(
            child: SectionHeader(
              title: l10n.myHoldings,
              subtitle: l10n.nHoldings(holdings.length),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
            ),
          ),

          // Holdings list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final holding = holdings[index];
                return HoldingListItem(
                  holding: holding,
                  onTap: () => _onEditHolding(context, holding),
                  onDelete: () => _onDeleteHolding(context, holding.ticker),
                );
              }, childCount: holdings.length),
            ),
          ),

          // Recent transactions section
          if (allTxn.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: l10n.recentTransactions,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final txn = displayRecentTxn[index];
                // Find matching holding for avg price
                final matchingHolding = holdings
                    .where((h) => h.ticker == txn.ticker)
                    .toList();
                final avgPrice = matchingHolding.isNotEmpty
                    ? (matchingHolding.first.avgPrice ?? 0.0)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0 ||
                          displayRecentTxn[index - 1].ticker != txn.ticker)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            bottom: AppSpacing.xxs,
                          ),
                          child: Text(
                            txn.ticker,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              fontWeight: AppTypography.semiBold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      TransactionRow(txn: txn, avgPrice: avgPrice),
                    ],
                  ),
                );
              }, childCount: displayRecentTxn.length),
            ),
            if (hasMoreRecentTxn && !_showAllRecentTxn)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAllRecentTxn = true),
                    child: Text(
                      l10n.viewAllTransactions(allTxn.length),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              )
            else if (_showAllRecentTxn)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAllRecentTxn = false),
                    icon: Icon(
                      Icons.keyboard_arrow_up,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      Localizations.localeOf(context).languageCode == 'ko'
                          ? '줄이기'
                          : 'Show less',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}
