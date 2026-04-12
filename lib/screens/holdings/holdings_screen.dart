import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../watchlist/widgets/holdings_tab.dart';

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
    );
  }
}
