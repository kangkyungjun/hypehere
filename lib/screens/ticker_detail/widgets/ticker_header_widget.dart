import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../models/stock_classification.dart';
import '../../../models/ticker_info.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class TickerHeaderWidget extends StatelessWidget {
  final CompleteChartData chartData;
  final TickerInfo? tickerInfo;
  final VoidCallback onScrollToAIInsight;

  const TickerHeaderWidget({
    super.key,
    required this.chartData,
    this.tickerInfo,
    required this.onScrollToAIInsight,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.data.isEmpty) return const SizedBox.shrink();
    final latestData = chartData.data.last;
    final previousData = chartData.data.length > 1
        ? chartData.data[chartData.data.length - 2]
        : null;

    // 반응형: 작은 화면에서는 폰트 크기 축소
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // 전일 대비 변동 계산
    double? priceChangeAmt;
    double? priceChangePct;
    if (latestData.close != null &&
        previousData?.close != null &&
        previousData!.close! > 0) {
      priceChangeAmt = latestData.close! - previousData.close!;
      priceChangePct = (priceChangeAmt / previousData.close!) * 100;
    }

    final isPositive = priceChangeAmt != null && priceChangeAmt >= 0;

    // 30D/60D 가격
    final currentPrice = latestData.close;
    final price30 = _findPriceNDaysAgo(30);
    final price60 = _findPriceNDaysAgo(60);
    final hasBarChart =
        currentPrice != null &&
        currentPrice > 0 &&
        (price30 != null || price60 != null);

    final mlc = context.mlColors;
    final changeColor = isPositive ? mlc.gainColor : mlc.lossColor;

    // 가격 + 변동 위젯
    Widget priceWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$${latestData.close?.toStringAsFixed(2) ?? '--'}',
          style: AppTypography.priceHero.copyWith(
            fontSize: isSmallScreen
                ? AppTypography.displayLarge
                : AppTypography.heroMedium,
            color: mlc.textPrimary,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (priceChangeAmt != null && priceChangePct != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: changeColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${isPositive ? '+' : ''}\$${priceChangeAmt.abs().toStringAsFixed(2)} (${isPositive ? '+' : ''}${priceChangePct.toStringAsFixed(2)}%)',
                  style: AppTypography.changeBadge.copyWith(
                    fontWeight: AppTypography.semiBold,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    // 섹터 정보 (category 또는 profile.industry)
    final sector = tickerInfo?.category ?? chartData.profile?.industry;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartData.ticker,
                      style: AppTypography.screenTitle.copyWith(
                        color: mlc.textPrimary,
                      ),
                    ),
                    if (tickerInfo?.name != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        (Localizations.localeOf(context).languageCode == 'ko' &&
                                tickerInfo!.nameKo != null)
                            ? '${tickerInfo!.nameKo} / ${tickerInfo!.name}'
                            : tickerInfo!.name!,
                        style: AppTypography.body.copyWith(
                          color: mlc.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (sector != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoChip(context, sector),
                    ],
                  ],
                ),
              ),
              if (chartData.classification != null) ...[
                const SizedBox(width: AppSpacing.md),
                _buildClassificationBadge(context, chartData.classification!),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 2행: 가격 + 바차트
          if (hasBarChart)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: priceWidget),
                const SizedBox(width: AppSpacing.xl),
                _buildMiniBarChart(context, price60, price30, currentPrice),
              ],
            )
          else
            priceWidget,

          const SizedBox(height: AppSpacing.lg),

          Text(
            '${AppLocalizations.of(context).updatedDate} ${latestData.date.toString().split(' ')[0]}',
            style: AppTypography.label.copyWith(color: mlc.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label) {
    final mlc = context.mlColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: mlc.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: mlc.subtleBorder),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: mlc.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Classification badge widget (Peter Lynch category)
  Widget _buildClassificationBadge(
    BuildContext context,
    StockClassification cls,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    final label = cls.localizedName(langCode);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cls.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: cls.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cls.icon, size: 14, color: cls.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.semiBold,
              color: cls.color,
            ),
          ),
        ],
      ),
    );
  }

  /// 30D/60D 미니 막대 그래프 (CustomPaint 기반)
  Widget _buildMiniBarChart(
    BuildContext context,
    double? price60,
    double? price30,
    double currentPrice,
  ) {
    return SizedBox(
      width: 108,
      height: 112,
      child: CustomPaint(
        size: const Size(108, 112),
        painter: _MiniBarChartPainter(
          price60: price60,
          price30: price30,
          currentPrice: currentPrice,
          baselineColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.15),
          labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          sublabelColor: Theme.of(context).colorScheme.outline,
          gainColor: context.mlColors.gainColor,
          lossColor: context.mlColors.lossColor,
          label60d: AppLocalizations.of(context).nDaysAgo(60),
          label30d: AppLocalizations.of(context).nDaysAgo(30),
        ),
      ),
    );
  }

  /// 특정 일수 전의 close 가격을 찾는 헬퍼
  double? _findPriceNDaysAgo(int days) {
    final data = chartData.data;
    if (data.isEmpty) return null;

    final latestDate = data.last.date;
    final targetDate = latestDate.subtract(Duration(days: days));

    ChartDataPoint? closest;
    int minDiff = 999;
    for (final dp in data) {
      if (dp.close == null) continue;
      final diff = dp.date.difference(targetDate).inDays.abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = dp;
      }
    }

    // 오차 7일 이내만 허용 (주말/공휴일 감안)
    if (closest != null &&
        minDiff <= 7 &&
        closest.close != null &&
        closest.close! > 0) {
      return closest.close;
    }
    return null;
  }
}

/// 30D/60D 미니 바 차트 Painter
///
/// 기준선 = 현재가 (가로선)
/// 과거 > 현재 → 바 위로 (빨강, 주가 하락)
/// 과거 < 현재 → 바 아래로 (초록, 주가 상승)
class _MiniBarChartPainter extends CustomPainter {
  final double? price60;
  final double? price30;
  final double currentPrice;
  final Color baselineColor;
  final Color labelColor;
  final Color sublabelColor;
  final Color gainColor;
  final Color lossColor;
  final String label60d;
  final String label30d;

  _MiniBarChartPainter({
    required this.price60,
    required this.price30,
    required this.currentPrice,
    required this.baselineColor,
    required this.labelColor,
    required this.sublabelColor,
    required this.gainColor,
    required this.lossColor,
    required this.label60d,
    required this.label30d,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 28.0;
    const barGap = 10.0;
    const maxBarHeight = 30.0;
    const textBlockHeight = 34.0; // 3줄 텍스트 (9+8+8 + gaps)

    final greenColor = gainColor;
    final redColor = lossColor;

    // diffPct 계산
    final diff60 = price60 != null
        ? (price60! - currentPrice) / currentPrice * 100
        : null;
    final diff30 = price30 != null
        ? (price30! - currentPrice) / currentPrice * 100
        : null;

    // 최대 변화율 (바 높이 정규화 기준)
    final maxDiff = <double>[
      if (diff60 != null) diff60.abs(),
      if (diff30 != null) diff30.abs(),
    ];
    final maxAbsDiff = maxDiff.isEmpty
        ? 1.0
        : maxDiff.reduce((a, b) => a > b ? a : b);

    // 기준선 Y 동적 계산
    // 위로 가는 바가 있으면 위쪽 공간 필요, 아래로 가면 아래쪽 공간 필요
    final hasUp =
        (diff60 != null && diff60 > 0) || (diff30 != null && diff30 > 0);
    final hasDown =
        (diff60 != null && diff60 < 0) || (diff30 != null && diff30 < 0);

    double baselineY;
    if (hasUp && hasDown) {
      baselineY = size.height / 2; // 혼합: 중앙
    } else if (hasUp) {
      baselineY = size.height - textBlockHeight - 2; // 위로만: 기준선 아래쪽
    } else {
      baselineY = textBlockHeight + 2; // 아래로만: 기준선 위쪽
    }

    // 바 위치 계산
    final hasTwo = price60 != null && price30 != null;
    final totalWidth = hasTwo ? barWidth * 2 + barGap : barWidth;
    final startX = (size.width - totalWidth) / 2;

    // 기준선 그리기
    final baselinePaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(startX - 4, baselineY),
      Offset(startX + totalWidth + 4, baselineY),
      baselinePaint,
    );

    // 바 그리기 헬퍼
    void drawBar(
      double x,
      double diffPct,
      double pastPrice,
      String periodLabel,
    ) {
      final isUp = diffPct > 0; // 과거 > 현재 → 위로 (빨강)
      final color = isUp ? redColor : greenColor;

      // 바 높이: 비례 축소, 최소 4px
      final availableHeight = isUp
          ? (baselineY - textBlockHeight)
          : (size.height - baselineY - textBlockHeight);
      final effectiveMaxHeight = availableHeight.clamp(4.0, maxBarHeight);
      final barHeight = (effectiveMaxHeight * (diffPct.abs() / maxAbsDiff))
          .clamp(4.0, effectiveMaxHeight);

      final barPaint = Paint()..color = color;
      const radius = Radius.circular(3);

      if (isUp) {
        // 바 위로 (기준선 위)
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baselineY - barHeight, barWidth, barHeight),
          topLeft: radius,
          topRight: radius,
        );
        canvas.drawRRect(rect, barPaint);

        // 텍스트: 바 위에 (위로 가는 순서: 기간, 가격, %)
        _drawText(
          canvas,
          periodLabel,
          x + barWidth / 2,
          baselineY - barHeight - 34,
          AppTypography.chartLabel,
          sublabelColor,
          AppTypography.regular,
        );
        _drawText(
          canvas,
          '\$${pastPrice.toStringAsFixed(2)}',
          x + barWidth / 2,
          baselineY - barHeight - 23,
          AppTypography.chartMicro,
          labelColor,
          AppTypography.regular,
          fontFeatures: AppTypography.tabularFigures,
        );
        _drawText(
          canvas,
          '+${diffPct.toStringAsFixed(1)}%',
          x + barWidth / 2,
          baselineY - barHeight - 12,
          AppTypography.chartMicro,
          redColor,
          AppTypography.bold,
          fontFeatures: AppTypography.tabularFigures,
        );
      } else {
        // 바 아래로 (기준선 아래)
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baselineY, barWidth, barHeight),
          bottomLeft: radius,
          bottomRight: radius,
        );
        canvas.drawRRect(rect, barPaint);

        // 텍스트: 바 아래에 (아래로 가는 순서: %, 가격, 기간)
        _drawText(
          canvas,
          '${diffPct.toStringAsFixed(1)}%',
          x + barWidth / 2,
          baselineY + barHeight + 3,
          AppTypography.chartMicro,
          greenColor,
          AppTypography.bold,
          fontFeatures: AppTypography.tabularFigures,
        );
        _drawText(
          canvas,
          '\$${pastPrice.toStringAsFixed(2)}',
          x + barWidth / 2,
          baselineY + barHeight + 14,
          AppTypography.chartMicro,
          labelColor,
          AppTypography.regular,
          fontFeatures: AppTypography.tabularFigures,
        );
        _drawText(
          canvas,
          periodLabel,
          x + barWidth / 2,
          baselineY + barHeight + 25,
          AppTypography.chartLabel,
          sublabelColor,
          AppTypography.regular,
        );
      }
    }

    // 60D bar (left)
    if (diff60 != null && price60 != null) {
      drawBar(startX, diff60, price60!, label60d);
    }

    // 30D bar (right or only bar)
    if (diff30 != null && price30 != null) {
      final x30 = price60 != null ? startX + barWidth + barGap : startX;
      drawBar(x30, diff30, price30!, label30d);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double centerX,
    double topY,
    double fontSize,
    Color color,
    FontWeight fontWeight, {
    List<FontFeature>? fontFeatures,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontFeatures: fontFeatures,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, topY));
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.price60 != price60 ||
        oldDelegate.price30 != price30 ||
        oldDelegate.currentPrice != currentPrice ||
        oldDelegate.baselineColor != baselineColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.sublabelColor != sublabelColor ||
        oldDelegate.label60d != label60d ||
        oldDelegate.label30d != label30d;
  }
}
