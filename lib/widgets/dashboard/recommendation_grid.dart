import 'package:flutter/material.dart';
import '../../models/treemap_data.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/score_mapper.dart';
import '../common/bento_card.dart';

/// 오늘의집 스타일 큐레이션 그리드 — "오늘의 추천 종목".
///
/// 추천 로직: AI 점수(질) × 오늘 모멘텀(변동률) 블렌드.
/// 데이터는 이미 로드된 트리맵(TreemapItem)에서 뽑아 추가 API 호출 0.
/// 상위 8개를 2열 그리드로 표시하고, 카드 탭 시 개별 상세 종목 페이지로 이동.
class RecommendationGrid extends StatelessWidget {
  const RecommendationGrid({
    super.key,
    required this.items,
    required this.onTickerTap,
  });

  /// 이미 추천 로직으로 필터·정렬된 종목 리스트 (상위 N)
  final List<TreemapItem> items;
  final void Function(String ticker) onTickerTap;

  /// 트리맵에서 추천 종목을 계산한다.
  /// 1) score ≥ 65 (긍정~강력긍정 구간) 후보
  /// 2) 종합점수 = 0.7×(score/100) + 0.3×clamp(오늘 변동률, 0~+5%)/5%
  /// 3) 상위 [limit]개
  static List<TreemapItem> compute(TreemapData? treemap, {int limit = 8}) {
    if (treemap == null) return const [];
    final candidates = <TreemapItem>[];
    final seen = <String>{};
    for (final sector in treemap.sectors) {
      for (final item in sector.items) {
        final s = item.score;
        if (s == null || s < 65) continue;
        // 매도 신호는 제외 (혹시 점수와 신호가 어긋날 때 방어)
        if ((item.signal ?? '').toUpperCase() == 'SELL') continue;
        if (!seen.add(item.ticker)) continue;
        candidates.add(item);
      }
    }
    double composite(TreemapItem t) {
      final score = (t.score ?? 0) / 100.0;
      final momentum = ((t.changePct ?? 0).clamp(0.0, 5.0)) / 5.0;
      return 0.7 * score + 0.3 * momentum;
    }

    candidates.sort((a, b) => composite(b).compareTo(composite(a)));
    return candidates.take(limit).toList();
  }

  /// 섹션 제목 — "오늘의" 접두 없이 "추천 종목" (인라인 5개국어).
  static String _picksLabel(String lang) =>
      const {
        'ko': '추천 종목',
        'zh': '推荐',
        'ja': 'おすすめ銘柄',
        'es': 'Selección',
      }[lang] ??
      'Picks';

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final mlc = context.mlColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션 헤더 ──
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.md,
            left: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: mlc.accentBlue, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                // "오늘의" 접두 제거 — 단순 "추천 종목"(인라인 5개국어, l10n 무변경).
                _picksLabel(Localizations.localeOf(context).languageCode),
                style: AppTypography.sectionTitle.copyWith(
                  color: mlc.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // ── 2열 그리드 (상위 8개) ──
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 160,
          ),
          itemBuilder: (context, i) => _RecoCard(
            item: items[i],
            onTap: () => onTickerTap(items[i].ticker),
          ),
        ),
      ],
    );
  }
}

class _RecoCard extends StatelessWidget {
  const _RecoCard({required this.item, required this.onTap});

  final TreemapItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = (isKo && item.nameKo != null)
        ? item.nameKo!
        : (item.name ?? item.ticker);
    final score = item.score ?? 0;
    final scoreColor = ScoreMapper.getScoreColor(score, mlc);
    final fraction = (score / 100).clamp(0.0, 1.0);

    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 티커 + 점수 배지
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ticker,
                          style: TextStyle(
                            fontSize: AppTypography.headlineMedium,
                            fontWeight: AppTypography.bold,
                            color: mlc.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: mlc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                    ),
                    child: Text(
                      '${score.round()}',
                      style: TextStyle(
                        // 홈 핵심 AI 신호(점수) 12→15로 또렷하게.
                        fontSize: AppTypography.headlineSmall,
                        fontWeight: AppTypography.bold,
                        color: scoreColor,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 점수 게이지 (히어로)
              SizedBox(
                height: 7,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: mlc.overlayDim)),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        heightFactor: 1.0,
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(color: scoreColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ScoreMapper.getScoreLabelLocalized(score, l10n),
                style: AppTypography.label.copyWith(color: scoreColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // 종가 + 변동률
              if (item.close != null)
                Text(
                  '\$${_formatClose(item.close!)}',
                  style: AppTypography.priceCard.copyWith(
                    color: mlc.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.xxs),
              _buildChangePct(item.changePct, mlc),
            ],
      ),
    );
  }

  Widget _buildChangePct(double? pct, MarketLensColors mlc) {
    if (pct == null) return const SizedBox.shrink();
    final String arrow;
    final Color color;
    if (pct > 0) {
      arrow = '▲';
      color = mlc.gainColor;
    } else if (pct < 0) {
      arrow = '▼';
      color = mlc.lossColor;
    } else {
      arrow = '─';
      color = mlc.neutralColor;
    }
    final sign = pct >= 0 ? '+' : '';
    return Text(
      '$arrow $sign${pct.toStringAsFixed(2)}%',
      style: AppTypography.numericSecondary.copyWith(
        color: color,
        fontWeight: AppTypography.semiBold,
      ),
    );
  }

  String _formatClose(double price) {
    if (price >= 1000) {
      final intPart = price.truncate();
      final buf = StringBuffer();
      final str = intPart.toString();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
        buf.write(str[i]);
      }
      final decimal = ((price - intPart) * 100).round();
      return decimal == 0
          ? buf.toString()
          : '${buf.toString()}.${decimal.toString().padLeft(2, '0')}';
    }
    return price.toStringAsFixed(2);
  }
}
