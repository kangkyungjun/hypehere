import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';
import '../../utils/sector_names.dart';
import 'market_news_modal.dart';

/// 기사 상세 바텀시트 — 리스트 행을 탭하면 열린다.
///
/// `MarketNewsModal.show`의 `builder` 안에 인라인으로 박혀 있었다. 그래서
/// **렌더할 방법이 없어** 레이아웃을 스크린샷이나 위젯 테스트로 볼 수 없었다.
/// 액션은 콜백으로 받아 순수 표현 위젯으로 유지한다.
class NewsDetailSheet extends StatelessWidget {
  const NewsDetailSheet({
    super.key,
    required this.item,
    this.onOpenOriginal,
    this.onOpenTicker,
  });

  final NewsItem item;

  /// null이면 버튼을 그리지 않는다(원문 URL이 없는 기사).
  final VoidCallback? onOpenOriginal;

  /// null이면 버튼을 그리지 않는다(MARKET·GEO 뉴스).
  final VoidCallback? onOpenTicker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final mlc = context.mlColors;
    final sentiment = item.sentimentColor(mlc);
    final isMarket = MarketNewsModal.isMarketNews(item);

    // 메타는 리스트 행과 **같은 형식**이다 — `감정 · 출처 · 섹터 · 시간`을
    // 11px 한 줄로. 개편 전에는 티커 pill(13) + 감정 pill(13) + 시간(13)이
    // 한 줄에 있고 출처(14)가 별도 행으로 떨어져 있었다. 리스트에서 방금 본
    // 정보를 **더 크고 더 흩어진 형태로** 다시 그리고 있었다.
    final meta = <TextSpan>[
      TextSpan(
        text: item.sentimentLabelLocalized(l10n),
        style: TextStyle(color: sentiment, fontWeight: AppTypography.semiBold),
      ),
      if (item.source != null) TextSpan(text: '  ·  ${item.source!}'),
      if (item.sector != null)
        TextSpan(text: '  ·  ${shortSectorName(item.sector!)}'),
      TextSpan(text: '  ·  ${item.timeAgoLocalized(l10n)}'),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      // 좌우 여백은 리스트와 같은 `xl`(16). 개편 전 `xxl`(20)은 같은 콘텐츠가
      // 시트에서만 좁아 보이게 만들었다.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mlc.subtleBorder,
                borderRadius: BorderRadius.circular(AppRadius.xxs),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 티커 — 리스트 행과 같은 앵커(18 w700 블루). 시트가 어느 종목의
          // 기사인지 즉시 알려준다.
          Text(
            isMarket
                ? l10n.marketNews
                : (lang == 'ko' && item.tickerNameKo != null)
                    ? '${item.ticker} ${item.tickerNameKo}'
                    : item.ticker,
            style: TextStyle(
              fontSize: AppTypography.headlineLarge,
              fontWeight: AppTypography.bold,
              color: isMarket ? mlc.textSecondary : mlc.accentBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),

          // 원문 제목이 이 시트의 **히어로**다.
          //
          // 리스트 행에서 이미 본 것은 AI 요약이고, 시트에서 새로 얻는 것은
          // 원문 제목과 **잘리지 않은** 요약이다. 개편 전에는 제목 18, 요약
          // 16으로 비가 1.125라 어느 쪽이 새 정보인지 읽히지 않았다.
          Text(
            item.title.localize(lang),
            style: AppTypography.sectionTitle.copyWith(color: mlc.textPrimary),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          Text.rich(
            TextSpan(children: meta),
            maxLines: 2,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: mlc.textTertiary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: mlc.subtleBorder),
          const SizedBox(height: AppSpacing.md),

          // 요약 본문 — 산문이므로 `body` 프리셋(15 w400 h1.45)을 쓴다.
          // 개편 전 16 w500 h1.6은 굵기·행간이 둘 다 과해 제목과 겨뤘고
          // 세로 부피만 키웠다.
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                item.aiSummary.localize(lang),
                style: AppTypography.body.copyWith(color: mlc.textPrimary),
              ),
            ),
          ),

          if (onOpenOriginal != null || onOpenTicker != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _actions(context, l10n),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    const pad = EdgeInsets.symmetric(vertical: AppSpacing.md);

    final original = OutlinedButton.icon(
      onPressed: onOpenOriginal,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(l10n.viewOriginalArticle, maxLines: 1, softWrap: false),
      ),
      style: OutlinedButton.styleFrom(padding: pad, shape: shape),
    );

    final ticker = FilledButton.icon(
      onPressed: onOpenTicker,
      icon: const Icon(Icons.show_chart, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(l10n.viewTickerDetail, maxLines: 1, softWrap: false),
      ),
      style: FilledButton.styleFrom(padding: pad, shape: shape),
    );

    if (onOpenOriginal != null && onOpenTicker != null) {
      return Row(
        children: [
          Expanded(child: original),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: ticker),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: onOpenOriginal != null ? original : ticker,
    );
  }
}
