import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';
import 'market_news_modal.dart';

/// 뉴스 타임라인의 기사 한 행.
///
/// `news_list_screen`의 private 메서드였다. 화면이 API에서 직접 로드하는
/// 구조라 **목데이터로 렌더할 방법이 없었고**, 그래서 레이아웃 회귀를
/// 스크린샷이나 위젯 테스트로 확인할 수 없었다. 순수 표현 위젯으로 꺼낸다.
///
/// 개편 전 이 행에는 **13px 텍스트가 다섯 개**(티커·감정·섹터·시간·출처)
/// 있었고 그중 둘은 굵기까지 w700으로 같았다 — 사용자가 말한 "다닥다닥"의
/// 기계적 정체다. 지금은 18(티커) / 16(헤드라인) / 11(메타) 3단이다.
class NewsArticleRow extends StatelessWidget {
  const NewsArticleRow({super.key, required this.item, this.onTap});

  final NewsItem item;

  /// 기본 동작은 `MarketNewsModal`. 테스트·캡쳐에서 주입해 가로챈다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {

      final l10n = AppLocalizations.of(context);
      final langCode = Localizations.localeOf(context).languageCode;
      final dotColor = item.sentimentColor(context.mlColors);
      final mlc = context.mlColors;

      final isMarket = MarketNewsModal.isMarketNews(item);

      // 메타 4종(감정·출처·섹터·시간)을 한 줄 11px로 합친다.
      // 개편 전에는 이 넷이 전부 13px이었고 그중 둘(티커·감정)은 굵기까지
      // w700으로 같았다 — 한 행에 13px이 다섯 개. 사용자가 말한 "다닥다닥"의
      // 기계적 정체다. 감정 라벨은 **지우지 않는다**: 점 색만 남기면 색맹
      // 사용자에게 단서가 사라진다. pill 배경만 걷고 색 + 텍스트 2중 인코딩을 유지한다.
      final meta = <TextSpan>[
        TextSpan(
          text: item.sentimentLabelLocalized(l10n),
          style: TextStyle(color: dotColor, fontWeight: AppTypography.semiBold),
        ),
        if (item.source != null) TextSpan(text: '  ·  ${item.source!}'),
        if (item.sectorShort != null) TextSpan(text: '  ·  ${item.sectorShort!}'),
        TextSpan(text: '  ·  ${item.timeAgoLocalized(l10n)}'),
      ];

      return InkWell(
        onTap: onTap ?? () => MarketNewsModal.show(context, item),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타임라인 점. 세로 연결선은 제거했다 — 같은 날짜 그룹이라는
              // 정보를 바로 위 날짜 헤더가 이미 명시하므로 중복이었고,
              // 32pt(가용폭의 8.6%)를 점 하나에 쓰고 있었다. 12+8 = 20pt로 줄여
              // 헤드라인 가로폭 12pt를 회수한다.
              SizedBox(
                width: 12,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1행 — 티커가 이 행의 히어로다.
                      //
                      // 레퍼런스 리스트 행에서 유일하게 크고 블루인 것은 가격이다.
                      // 우리 도메인의 대응물은 티커다. pill을 해체하고 18 w700로
                      // 세우면 18/11 = 1.64로 레퍼런스(1.62)와 같은 리듬이 된다.
                      // 블루가 행당 한 곳뿐이라 "블루=탭 가능" 신호도 순수해진다.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMarket
                                  ? l10n.marketNews
                                  : (langCode == 'ko' && item.tickerNameKo != null)
                                      ? '${item.ticker} ${item.tickerNameKo}'
                                      : item.ticker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTypography.headlineLarge,
                                fontWeight: AppTypography.bold,
                                color: isMarket
                                    ? mlc.textSecondary
                                    : mlc.accentBlue,
                              ),
                            ),
                          ),
                          if (item.isBreaking) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Text(
                              '\u{1F6A8}',
                              style: TextStyle(fontSize: AppTypography.bodySmall),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // 2행 — 헤드라인(AI 요약).
                      Text(
                        item.aiSummary.localize(langCode),
                        style: AppTypography.bodyStrong.copyWith(
                          fontSize: AppTypography.headlineMedium,
                          height: 1.35,
                          color: mlc.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // 3행 — 메타 한 줄. 별도의 '출처' 행을 없애 21pt 회수.
                      Text.rich(
                        TextSpan(children: meta),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: mlc.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
