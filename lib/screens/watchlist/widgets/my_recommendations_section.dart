import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/recommendation.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/recommendation_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/app_page_route.dart';
import '../../ticker_detail/ticker_detail_screen.dart';

/// "내 추천 종목" 섹션 (Phase C) — 보유종목 화면 투자성향 칩 아래 노출.
///
/// - 비로그인 → 숨김.
/// - 추천 없음(미생성/로딩) → 숨김(잡음 방지). 서버 파이프라인이 데이터 생성 시 자동 표시.
/// - 추천 있음 → 헤더 + 카드 목록(탭 시 종목 상세).
class MyRecommendationsSection extends StatelessWidget {
  /// 부모가 이미 가로 패딩을 줄 때 0으로 넘긴다(빈 포트폴리오 상태와 정렬).
  final double horizontalPadding;

  const MyRecommendationsSection({super.key, this.horizontalPadding = AppSpacing.xl});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const SizedBox.shrink();

    final provider = context.watch<RecommendationProvider>();
    final items = provider.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: colors.accentBlue),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.myRecommendations,
                style: TextStyle(
                  fontSize: AppTypography.headlineSmall,
                  fontWeight: AppTypography.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((r) => _RecommendationCard(rec: r, isKo: isKo)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendedTicker rec;
  final bool isKo;

  const _RecommendationCard({required this.rec, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final MarketLensColors colors = context.mlColors;
    final l10n = AppLocalizations.of(context);
    final name = isKo
        ? (rec.nameKo ?? rec.name ?? rec.ticker)
        : (rec.name ?? rec.ticker);
    final changePct = rec.changePct;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            appPageRoute(
              builder: (_) => TickerDetailScreen(ticker: rec.ticker),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // 순위 배지
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${rec.rank}',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      fontWeight: AppTypography.bold,
                      color: colors.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 종목 + 이름
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.ticker,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          fontWeight: AppTypography.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 적합도 + 등락
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.recommendationFit} ${rec.fitScore.round()}',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.semiBold,
                        color: colors.accentBlue,
                      ),
                    ),
                    if (changePct != null)
                      Text(
                        '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: changePct >= 0
                              ? colors.gainColor
                              : colors.lossColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
