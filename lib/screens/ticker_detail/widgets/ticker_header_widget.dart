import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../models/stock_classification.dart';
import '../../../models/ticker_info.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'ticker_intraday_chart.dart';

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

    // 가격 옆 미니 추세 스파크라인 — 최근 일봉 종가 기반(추가 통신 0).
    // 탭하면 진짜 intraday(1h/1d) 모달을 띄운다.
    final sparkCloses = _recentCloses();
    final hasSpark = sparkCloses.length >= 2;

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

          // 섹터 칩과 가격 사이 간격 — xxl(과대) → md 로 타이트하게.
          const SizedBox(height: AppSpacing.md),

          // 2행: 가격 + 인트라데이 미니 추세(탭 → 모달)
          if (hasSpark)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: priceWidget),
                const SizedBox(width: AppSpacing.lg),
                _buildSparkline(context, sparkCloses),
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
        color: mlc.infoBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.badge),
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

  /// 최근 종가 리스트(최대 30개) — 미니 스파크라인용.
  List<double> _recentCloses() {
    final closes = <double>[];
    for (final dp in chartData.data) {
      if (dp.close != null && dp.close! > 0) closes.add(dp.close!);
    }
    if (closes.length > 30) {
      return closes.sublist(closes.length - 30);
    }
    return closes;
  }

  /// 가격 옆 미니 추세 스파크라인. 보는 용도 + 탭하면 intraday 모달.
  Widget _buildSparkline(BuildContext context, List<double> closes) {
    final mlc = context.mlColors;
    final up = closes.last >= closes.first;
    final color = up ? mlc.gainColor : mlc.lossColor;
    return Semantics(
      button: true,
      label: 'Intraday',
      child: InkWell(
        onTap: () => _openIntradayModal(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 116,
          height: 54,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SparklinePainter(
                    closes: closes,
                    color: color,
                    fillColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.open_in_full_rounded,
                  size: 16,
                  color: mlc.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// intraday(1h/1d) 전체 차트 모달 — 본문에 있던 섹션을 그대로 담음(크기·기능 동일).
  void _openIntradayModal(BuildContext context) {
    final mlc = context.mlColors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: mlc.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            top: AppSpacing.xs,
            bottom: MediaQuery.of(ctx).viewPadding.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, size: 22),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: TickerIntradayChart(
                    ticker: chartData.ticker,
                    dailyData: chartData.data,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가격 옆 미니 추세 스파크라인 Painter — 최근 종가 라인 + 옅은 면.
class _SparklinePainter extends CustomPainter {
  final List<double> closes;
  final Color color;
  final Color fillColor;

  _SparklinePainter({
    required this.closes,
    required this.color,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (closes.length < 2) return;
    final minV = closes.reduce((a, b) => a < b ? a : b);
    final maxV = closes.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final dx = size.width / (closes.length - 1);

    // 위/아래 4px 여백 확보해 라인이 잘리지 않게.
    const pad = 4.0;
    final h = size.height - pad * 2;
    final pts = <Offset>[
      for (int i = 0; i < closes.length; i++)
        Offset(dx * i, pad + h - ((closes[i] - minV) / range) * h),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.closes != closes ||
        oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor;
  }
}
