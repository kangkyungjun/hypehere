import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/common/webview_screen.dart';
import '../../models/news_data.dart';
import '../../screens/ticker_detail/ticker_detail_screen.dart';
import 'news_detail_sheet.dart';
import '../../utils/app_page_route.dart';

/// Shared modal for MARKET ticker news items.
///
/// Shows full AI summary, English title, source, and a button
/// to open the original article URL in an external browser.
class MarketNewsModal {
  MarketNewsModal._();

  /// Returns true if the news item is a non-stock news (MARKET, GEO, etc.).
  static bool isMarketNews(NewsItem item) =>
      item.ticker == 'MARKET' || item.ticker == 'GEO';

  /// Show the market news detail modal bottom sheet.
  static void show(BuildContext context, NewsItem item) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewsDetailSheet(
        item: item,
        onOpenOriginal: item.sourceUrl == null
            ? null
            : () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  appPageRoute(
                    builder: (_) => WebViewScreen(
                      // 제목은 동사구("원문 기사 보기")가 아니라 출처명이어야
                      // 한다 — 웹뷰가 어디를 열었는지 알려주는 유일한 단서다.
                      title: item.source ?? l10n.viewOriginalArticle,
                      url: item.sourceUrl!,
                    ),
                  ),
                );
              },
        onOpenTicker: (isMarketNews(item) || item.ticker.isEmpty)
            ? null
            : () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  appPageRoute(
                    builder: (_) => TickerDetailScreen(ticker: item.ticker),
                  ),
                );
              },
      ),
    );
  }

}
