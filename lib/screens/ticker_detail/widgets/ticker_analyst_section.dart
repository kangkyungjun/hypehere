import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'ticker_detail_helpers.dart';

class TickerAnalystSection extends StatefulWidget {
  final CompleteChartData chartData;

  const TickerAnalystSection({
    super.key,
    required this.chartData,
  });

  @override
  State<TickerAnalystSection> createState() => _TickerAnalystSectionState();
}

class _TickerAnalystSectionState extends State<TickerAnalystSection> {
  bool _showAllRatings = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final consensus = widget.chartData.analystConsensus;
    final ratings = widget.chartData.analystRatings;

    // 데이터 없으면 숨김
    if (consensus == null && (ratings == null || ratings.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consensus 섹션
          if (consensus != null) ...[
            // 헤더: 타이틀 (분석가 수 포함) + recommendation 뱃지 (한글)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.analystConsensus((consensus.count ?? '-').toString()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                ),
                if (consensus.recommendation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: getRecommendationColor(context, consensus.recommendation),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      translateRecommendation(consensus.recommendation, l10n),
                      style: TextStyle(
                        color: context.mlColors.onPrimary,
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 평균 목표가 + 현재가 대비 %
            if (consensus.mean != null) ...[
              Builder(builder: (context) {
                final latestClose = widget.chartData.data.isNotEmpty ? widget.chartData.data.last.close : null;
                String upsideStr = '';
                Color upsideColor = Theme.of(context).colorScheme.outline;
                if (latestClose != null && latestClose > 0) {
                  final upside = ((consensus.mean! - latestClose) / latestClose) * 100;
                  final sign = upside >= 0 ? '+' : '';
                  upsideStr = ' ($sign${upside.toStringAsFixed(1)}%)';
                  upsideColor = upside >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor;
                }
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${consensus.mean!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTypography.heroSmall,
                          fontWeight: AppTypography.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                      if (upsideStr.isNotEmpty)
                        TextSpan(
                          text: upsideStr,
                          style: TextStyle(
                            fontSize: AppTypography.heroSmall,
                            fontWeight: AppTypography.bold,
                            color: upsideColor,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.averageTargetPrice,
              style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 목표가 범위 바
            if (consensus.low != null && consensus.high != null) ...[
              _buildTargetRangeBar(consensus),
              const SizedBox(height: AppSpacing.md),
            ],

            // 구분선 (ratings가 있을 때만)
            if (ratings != null && ratings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Divider(color: context.mlColors.subtleBorder),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],

          // Ratings 리스트 (접기/펼치기)
          if (ratings != null && ratings.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showAllRatings = !_showAllRatings),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentAnalystRatings,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                  ),
                  Icon(
                    _showAllRatings ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
            if (_showAllRatings) ...[
              const SizedBox(height: AppSpacing.md),

              // 상태 분포 요약
              _buildStatusDistribution(ratings),
              const SizedBox(height: AppSpacing.md),

              // 정렬: target_to 기준 내림차순
              ..._buildRatingsListAll(ratings),
            ],
          ],
        ],
      ),
    );
  }

  /// 목표가 범위 시각화 바
  Widget _buildTargetRangeBar(AnalystConsensus consensus) {
    final l10n = AppLocalizations.of(context);
    final low = consensus.low!;
    final high = consensus.high!;
    final range = high - low;

    // 현재가 위치 계산
    final latestClose = widget.chartData.data.isNotEmpty ? widget.chartData.data.last.close : null;
    double? currentPosition;
    if (latestClose != null && range > 0) {
      currentPosition = ((latestClose - low) / range).clamp(0.0, 1.0);
    }

    // 평균 목표가 위치
    double? meanPosition;
    if (consensus.mean != null && range > 0) {
      meanPosition = ((consensus.mean! - low) / range).clamp(0.0, 1.0);
    }

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 배경 바
                  Positioned(
                    top: 36,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.mlColors.lossColor, context.mlColors.scoreHoldColor, context.mlColors.gainColor],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xxs),
                      ),
                    ),
                  ),

                  // 평균 목표가 마커 + 라벨
                  if (meanPosition != null)
                    Positioned(
                      top: 0,
                      left: barWidth * meanPosition - 24,
                      width: 48,
                      child: Column(
                        children: [
                          Text(l10n.targetPrice, style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text(
                            '\$${consensus.mean?.toStringAsFixed(0) ?? ''}',
                            style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: AppTypography.semiBold, fontFeatures: AppTypography.tabularFigures),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: context.mlColors.accentBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.mlColors.sectionBackground, width: 2),
                              boxShadow: AppShadow.sm(context.mlColors.overlayDim),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 현재가 마커 + 라벨
                  if (currentPosition != null)
                    Positioned(
                      top: 0,
                      left: barWidth * currentPosition - 24,
                      width: 48,
                      child: Column(
                        children: [
                          Text(l10n.currentPrice, style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text(
                            '\$${latestClose?.toStringAsFixed(0) ?? ''}',
                            style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: AppTypography.semiBold, fontFeatures: AppTypography.tabularFigures),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.mlColors.cardBackground, width: 2),
                              boxShadow: AppShadow.sm(context.mlColors.overlayDim),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 10,
                              color: context.mlColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Low / High 라벨
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.lowestPrice('\$${low.toStringAsFixed(0)}'),
              style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures),
            ),
            Text(
              l10n.highestPrice('\$${high.toStringAsFixed(0)}'),
              style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant, fontFeatures: AppTypography.tabularFigures),
            ),
          ],
        ),
      ],
    );
  }

  /// Ratings 리스트 빌드 (전체 표시, 섹션 레벨에서 접기/펼치기 관리)
  List<Widget> _buildRatingsListAll(List<AnalystRating> ratings) {
    final l10n = AppLocalizations.of(context);
    // target_to 기준 내림차순 정렬
    final sorted = List<AnalystRating>.from(ratings)
      ..sort((a, b) => (b.targetTo ?? 0).compareTo(a.targetTo ?? 0));

    final widgets = <Widget>[];

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      widgets.add(
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.mlColors.cardBackground,
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(AppRadius.md))
                : i == sorted.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.md))
                    : BorderRadius.zero,
            border: Border(
              bottom: i < sorted.length - 1
                  ? BorderSide(color: context.mlColors.chartGridLine)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              // 왼쪽: firm + status/rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.firm ?? l10n.unknownFirm,
                          style: const TextStyle(
                            fontSize: AppTypography.bodyMedium,
                            fontWeight: AppTypography.semiBold,
                          ),
                        ),
                        if (r.status != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: getStatusColor(context, r.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              translateStatus(r.status, l10n),
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                fontWeight: AppTypography.semiBold,
                                color: getStatusColor(context, r.status),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (r.rating != null)
                      Text(
                        translateRating(r.rating, l10n),
                        style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              // 오른쪽: target price + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (r.targetFrom != null || r.targetTo != null)
                    Text(
                      r.targetFrom != null && r.targetTo != null
                          ? '\$${r.targetFrom!.toStringAsFixed(0)} → \$${r.targetTo!.toStringAsFixed(0)}'
                          : '\$${(r.targetTo ?? r.targetFrom)?.toStringAsFixed(0) ?? '--'}',
                      style: const TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: AppTypography.semiBold,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  if (r.date != null)
                    Text(
                      r.date!,
                      style: TextStyle(fontSize: AppTypography.micro, color: Theme.of(context).colorScheme.outline),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  /// 상태 분포 요약 위젯 (stacked bar + legend)
  Widget _buildStatusDistribution(List<AnalystRating> ratings) {
    final counts = {'initiated': 0, 'upgrade': 0, 'reiterated': 0, 'downgrade': 0};
    for (final r in ratings) {
      final key = r.status?.toLowerCase() ?? '';
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
    final total = ratings.length;

    final l10n = AppLocalizations.of(context);
    final items = [
      ('initiated', l10n.ratingActionInitiated, counts['initiated']!),
      ('upgrade', l10n.ratingActionUpgrade, counts['upgrade']!),
      ('reiterated', l10n.ratingActionReiterated, counts['reiterated']!),
      ('downgrade', l10n.ratingActionDowngrade, counts['downgrade']!),
    ];

    return Column(
      children: [
        // Stacked horizontal bar
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: SizedBox(
              height: 8,
              child: Row(
                children: items
                    .where((item) => item.$3 > 0)
                    .map((item) => Expanded(
                          flex: item.$3,
                          child: Container(
                            color: getStatusColor(context, item.$1),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        // Legend row
        Row(
          children: items.map((item) {
            final isZero = item.$3 == 0;
            final color = isZero ? Theme.of(context).colorScheme.outline : getStatusColor(context, item.$1);
            return Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    item.$2,
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: isZero ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${item.$3}',
                    style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.bold, color: color, fontFeatures: AppTypography.tabularFigures),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
