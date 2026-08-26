import 'package:flutter/material.dart';
import '../../models/ticker_score.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// AI Lens List Screen — "더보기" 페이지
///
/// AI 분석 추천/주의 종목 전체 목록 (20개 + 10개마다 배너 광고)
class AILensListScreen extends StatelessWidget {
  final String title;
  final List<TickerScore> items;

  const AILensListScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final widgets = _buildListWithAds(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: widgets.length,
        itemBuilder: (context, index) => widgets[index],
      ),
    );
  }

  List<Widget> _buildListWithAds(BuildContext context) {
    final List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_buildListItem(context, items[i]));
      if ((i + 1) % 10 == 0 && i != items.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            child: BannerAdWidget(),
          ),
        );
      }
    }
    // Bottom banner
    if (items.isNotEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          child: BannerAdWidget(),
        ),
      );
    }
    return widgets;
  }

  Widget _buildListItem(BuildContext context, TickerScore ticker) {
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = ticker.scoreColor(context.mlColors);
    final primaryName = isKo ? (ticker.nameKo ?? ticker.name) : ticker.name;
    final secondaryName = isKo ? ticker.name : null;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        appPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker.ticker)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ticker.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.ticker,
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      color: context.mlColors.textPrimary,
                    ),
                  ),
                  if (primaryName != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: primaryName,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              fontWeight: AppTypography.medium,
                              color: context.mlColors.textSecondary,
                            ),
                          ),
                          if (secondaryName != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: secondaryName,
                              style: TextStyle(
                                fontSize: AppTypography.bodySmall,
                                color: context.mlColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ticker.signalLabelLocalized(l10n),
                  maxLines: 1,
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: context.mlColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
