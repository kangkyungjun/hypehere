import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/indices_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 3대 주요 지수 콤팩트 바 (대시보드 최상단)
///
/// 거시경제 배너와 동일한 높이감의 얇은 바 형태.
/// ┌───────────────────────────────────────────────┐
/// │  S&P 500          NASDAQ 100       Dow Jones  │
/// │  605.12 ▲+0.57%   530.80 ▼-1.23%  438.50 ... │
/// │  ▁▂▃▄▅▆▇ (미니 스파크라인)                     │
/// └───────────────────────────────────────────────┘
class IndicesBarWidget extends StatelessWidget {
  final MarketIndicesData? data;
  final void Function(String indexCode)? onIndexTap;
  final String? selectedIndex;

  const IndicesBarWidget({
    super.key,
    this.data,
    this.onIndexTap,
    this.selectedIndex,
  });

  /// Map ETF code to index filter code
  static String? etfToIndex(String etfCode) {
    switch (etfCode) {
      case 'SPY':
        return 'SP500';
      case 'QQQ':
        return 'NASDAQ100';
      case 'DIA':
        return 'DOW30';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.indices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: data!.indices.map((index) {
        final indexCode = etfToIndex(index.code);
        final isSelected = selectedIndex != null && selectedIndex == indexCode;
        return Expanded(
          child: GestureDetector(
            onTap: onIndexTap != null && indexCode != null
                ? () => onIndexTap!(indexCode)
                : null,
            child: _IndexCard(index: index, isSelected: isSelected),
          ),
        );
      }).toList(),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final MarketIndexData index;
  final bool isSelected;

  const _IndexCard({required this.index, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final isPositive = index.changePct >= 0;
    final mlc = context.mlColors;
    final changeColor = index.changePct > 0
        ? mlc.gainColor
        : index.changePct < 0
        ? mlc.lossColor
        : Theme.of(context).colorScheme.outline;
    final arrow = index.changePct > 0
        ? '▲'
        : index.changePct < 0
        ? '▼'
        : '─';
    final sign = isPositive ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? changeColor.withValues(alpha: 0.08)
              : mlc.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? changeColor.withValues(alpha: 0.6)
                : mlc.subtleBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 지수 이름
            Text(
              index.name,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: mlc.textSecondary,
                fontWeight: AppTypography.medium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            // 종가
            Text(
              index.close.toStringAsFixed(2),
              style: AppTypography.priceCard.copyWith(color: mlc.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            // 변동률
            Text(
              '$arrow $sign${index.changePct.toStringAsFixed(2)}%',
              style: AppTypography.numericSecondary.copyWith(
                color: changeColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
            // 미니 스파크라인 (차트 데이터 있을 때만)
            if (index.chart.length >= 2) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 28,
                child: CustomPaint(
                  size: const Size(double.infinity, 28),
                  painter: _SparklinePainter(
                    data: index.chart.length > 30
                        ? index.chart.sublist(index.chart.length - 30)
                        : index.chart,
                    gainColor: mlc.gainColor,
                    lossColor: mlc.lossColor,
                    referencePrice: index.prevClose,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 미니 스파크라인 페인터 (최근 30일)
/// 기준선(전일 종가) 위: gainColor, 아래: lossColor 분리
class _SparklinePainter extends CustomPainter {
  final List<IndexChartPoint> data;
  final Color gainColor;
  final Color lossColor;
  final double? referencePrice;

  _SparklinePainter({
    required this.data,
    required this.gainColor,
    required this.lossColor,
    this.referencePrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final values = data.map((p) => p.close).toList();
    var minVal = values.reduce(min);
    var maxVal = values.reduce(max);

    // Include reference price in range calculation
    if (referencePrice != null) {
      minVal = min(minVal, referencePrice!);
      maxVal = max(maxVal, referencePrice!);
    }

    final range = maxVal - minVal;
    if (range == 0) return;

    double toY(double value) =>
        size.height - ((value - minVal) / range) * size.height;

    final refY = referencePrice != null ? toY(referencePrice!) : size.height;

    // Draw reference price baseline (dashed, neutral color)
    if (referencePrice != null) {
      final dashPaint = Paint()
        ..color = gainColor.withValues(alpha: 0.25)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      const dashWidth = 3.0;
      const dashSpace = 2.0;
      var startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, refY),
          Offset(min(startX + dashWidth, size.width), refY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Build sparkline path
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = toY(values[i]);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Clip and draw gain (above reference) portion
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, refY));
    canvas.drawPath(
      path,
      Paint()
        ..color = gainColor.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    // Gain fill (above → reference line)
    final gainFillPath = Path.from(path)
      ..lineTo(points.last.dx, refY)
      ..lineTo(points.first.dx, refY)
      ..close();
    canvas.drawPath(
      gainFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gainColor.withValues(alpha: 0.18),
            gainColor.withValues(alpha: 0.03),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, refY)),
    );
    canvas.restore();

    // Clip and draw loss (below reference) portion
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, refY, size.width, size.height));
    canvas.drawPath(
      path,
      Paint()
        ..color = lossColor.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    // Loss fill (reference line → bottom)
    final lossFillPath = Path.from(path)
      ..lineTo(points.last.dx, refY)
      ..lineTo(points.first.dx, refY)
      ..close();
    canvas.drawPath(
      lossFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lossColor.withValues(alpha: 0.03),
            lossColor.withValues(alpha: 0.18),
          ],
        ).createShader(Rect.fromLTRB(0, refY, size.width, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.gainColor != gainColor ||
        oldDelegate.lossColor != lossColor ||
        oldDelegate.referencePrice != referencePrice;
  }
}
