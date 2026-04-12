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

  const IndicesBarWidget({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.indices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.mlColors.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Row(
        children: data!.indices.map((index) {
          return Expanded(
            child: _IndexCard(index: index),
          );
        }).toList(),
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final MarketIndexData index;

  const _IndexCard({required this.index});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 지수 이름
          Text(
            index.name,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // 종가
          Text(
            index.close.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          // 변동률
          Text(
            '$arrow $sign${index.changePct.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.semiBold,
              color: changeColor,
            ),
          ),
          // 미니 스파크라인 (차트 데이터 있을 때만)
          if (index.chart.length >= 2) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 24,
              child: CustomPaint(
                size: const Size(double.infinity, 24),
                painter: _SparklinePainter(
                  data: index.chart.length > 30
                      ? index.chart.sublist(index.chart.length - 30)
                      : index.chart,
                  color: changeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 미니 스파크라인 페인터 (최근 30일)
class _SparklinePainter extends CustomPainter {
  final List<IndexChartPoint> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final values = data.map((p) => p.close).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = maxVal - minVal;
    if (range == 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 하단 그라데이션 fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
