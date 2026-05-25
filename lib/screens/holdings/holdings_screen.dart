import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../watchlist/widgets/add_holding_sheet.dart';
import '../watchlist/widgets/holdings_tab.dart';
import '../watchlist/widgets/instant_advice_sheet.dart';
import '../watchlist/widgets/ticker_search_sheet.dart';

/// Standalone Holdings screen wrapping the existing HoldingsTab widget.
///
/// Previously part of WatchlistScreen's TabBarView; now an independent tab.
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HoldingsTab(
      onTickerTap: (ticker) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TickerDetailScreen(ticker: ticker),
          ),
        );
      },
      onSwitchToWatchlist: () {
        // No-op: Watchlist is now a separate bottom tab.
        // The button text guides users but we cannot programmatically
        // switch bottom tabs from here. Users can tap the Watchlist tab.
      },
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final portfolio = context.read<PortfolioProvider>();
        if (auth.isLoggedIn && portfolio.isInitialized) {
          await portfolio.refresh();
        }
      },
      onAddHolding: () => _onAddHoldingDirect(context),
    );
  }

  /// Direct add holding flow: login check → search → add sheet → portfolio ops.
  Future<void> _onAddHoldingDirect(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    // Login check
    if (!auth.isLoggedIn) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => const SignupPromptDialog(),
      );
      if (result == null || !context.mounted) return;
      if (result == 'login') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else if (result == 'signup') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
      }
      return;
    }

    final portfolio = context.read<PortfolioProvider>();

    // Search for ticker
    if (!context.mounted) return;
    final tickerInfo = await TickerSearchSheet.show(context);
    if (tickerInfo == null || !context.mounted) return;

    final ticker = tickerInfo.ticker;

    // Free user limit check — new ticker only (allow additional buy on existing)
    final isNewTicker = !portfolio.isInHoldings(ticker);
    if (isNewTicker && !auth.isGoldOrAbove && portfolio.holdings.length >= 3) {
      if (!context.mounted) return;
      _showHoldingsLimitDialog(context);
      return;
    }

    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && tickerInfo.nameKo != null
        ? tickerInfo.nameKo!
        : tickerInfo.name ?? ticker;

    // Show add holding sheet
    final result = await AddHoldingSheet.show(
      context,
      ticker: ticker,
      name: displayName,
    );
    if (result == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);

    try {
      // If new ticker, add fresh; if existing, calculate new average
      final existing = portfolio.holdings
          .where((h) => h.ticker == ticker.toUpperCase())
          .toList();

      if (existing.isNotEmpty) {
        final h = existing.first;
        final oldShares = h.shares ?? 0.0;
        final oldAvg = h.avgPrice ?? 0.0;
        final newTotalShares = oldShares + result.shares;
        final newAvgPrice = newTotalShares > 0
            ? ((oldShares * oldAvg) + (result.shares * result.avgPrice)) / newTotalShares
            : result.avgPrice;

        await portfolio.addTransaction(
          ticker: ticker, type: 'BUY', shares: result.shares,
          price: result.avgPrice, date: result.date,
        );
        await portfolio.addOrUpdateHolding(
          ticker: ticker, shares: newTotalShares, avgPrice: newAvgPrice,
        );
      } else {
        await portfolio.addTransaction(
          ticker: ticker, type: 'BUY', shares: result.shares,
          price: result.avgPrice, date: result.date,
        );
        await portfolio.addOrUpdateHolding(
          ticker: ticker, shares: result.shares, avgPrice: result.avgPrice,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holdingAdded(ticker))),
      );

      // Show instant advice if available
      final holdingMatch = portfolio.holdings.where(
        (h) => h.ticker == ticker.toUpperCase(),
      );
      if (holdingMatch.isNotEmpty && context.mounted) {
        final holding = holdingMatch.first;
        if (holding.instantAdvice != null) {
          await InstantAdviceSheet.show(context, holding.instantAdvice!);
          return;
        }
      }
      final adviceMatch = portfolio.advice.where(
        (a) => a.ticker == ticker.toUpperCase(),
      );
      if (adviceMatch.isNotEmpty && context.mounted) {
        await InstantAdviceSheet.show(context, adviceMatch.first);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _showHoldingsLimitDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.holdingsLimitTitle)),
          ],
        ),
        content: Text(l10n.holdingsLimitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'upgrade'),
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: Text(l10n.upgradeToGold),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == 'upgrade' && context.mounted) {
      GoldUpgradeSheet.show(context, source: 'holdings_limit');
    }
  }
}
