import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// 히어로로 세울 지수. 시장 벤치마크인 S&P 500을 우선하고, 없으면 첫 번째.
  ///
  /// **선택 상태와 무관하다.** 개편 전에는 `isSelected ? priceLarge : priceCard`
  /// 였는데 `_selectedIndex`가 초기화 없는 null이라 히어로가 **기본 화면에서
  /// 한 번도 렌더되지 않았다** — 앱을 켠 사용자는 100% 확률로 20px만 봤다.
  /// 선택은 트리맵 필터를 구동하므로 기본값을 넣을 수도 없다(대시보드 전체가
  /// 한 지수로 필터링된다). 그래서 **크기와 선택을 분리한다.**
  int _leadIndexOf(List<MarketIndexData> indices) {
    final i = indices.indexWhere((e) => etfToIndex(e.code) == 'SP500');
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.indices.isEmpty) {
      return const SizedBox.shrink();
    }

    final indices = data!.indices;
    final leadPos = _leadIndexOf(indices);
    final rest = [
      for (var i = 0; i < indices.length; i++)
        if (i != leadPos) indices[i],
    ];

    Widget wrap(MarketIndexData index, Widget child) {
      final code = etfToIndex(index.code);
      return GestureDetector(
        onTap: onIndexTap != null && code != null
            ? () => onIndexTap!(code)
            : null,
        child: child,
      );
    }

    bool selected(MarketIndexData index) {
      final code = etfToIndex(index.code);
      return selectedIndex != null && selectedIndex == code;
    }

    final lead = indices[leadPos];

    // 지수가 하나뿐이면 히어로 카드만 전폭으로.
    if (rest.isEmpty) {
      return wrap(
        lead,
        _IndexHeroCard(index: lead, isSelected: selected(lead)),
      );
    }

    // 1(히어로) + N(보조) 비대칭. 3분할 균등이었을 때는 카드당 가용폭이
    // ≈102px이라 31px 6자리(≈102px)가 경계치였고, `FittedBox`가 실제 렌더를
    // 조용히 축소해 히어로 지정이 무효가 됐다. 5:4로 벌려 폭을 확보한다.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: wrap(
              lead,
              _IndexHeroCard(index: lead, isSelected: selected(lead)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                for (var i = 0; i < rest.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: wrap(
                      rest[i],
                      _IndexCompactCard(
                        index: rest[i],
                        isSelected: selected(rest[i]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 지수 종가 표기 — **정수 + 천 단위 구분자**.
///
/// 개편 전에는 `toStringAsFixed(2)`로 `43535.06`처럼 구분자 없이 소수점까지
/// 찍었다. 지수에서 소수 두 자리는 0.005% 수준의 노이즈인데 히어로 폭을
/// 40% 잡아먹어 37px을 못 쓰게 만들었고, 구분자가 없어 자릿수도 즉시 안 읽혔다.
/// 레퍼런스의 히어로(`3,500 ~ 3,680`)도 소수점이 없다. 정밀도는 바로 아래
/// 등락률이 담당한다.
final _closeFormat = NumberFormat('#,##0');

/// 지수 카드 공통 — 방향색·화살표·부호를 한곳에서 계산한다.
class _IndexVisuals {
  _IndexVisuals(MarketIndexData index, MarketLensColors mlc)
    : color = index.changePct > 0
          ? mlc.gainColor
          : index.changePct < 0
          ? mlc.lossColor
          : mlc.textTertiary,
      arrow = index.changePct > 0
          ? '▲'
          : index.changePct < 0
          ? '▼'
          : '─',
      changeText =
          '${index.changePct >= 0 ? '+' : ''}${index.changePct.toStringAsFixed(2)}%';

  final Color color;
  final String arrow;
  final String changeText;
}

BoxDecoration _cardDecoration(
  MarketLensColors mlc,
  Color changeColor,
  bool isSelected,
) {
  return BoxDecoration(
    color: isSelected
        ? changeColor.withValues(alpha: 0.08)
        : mlc.cardBackground,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: isSelected ? changeColor.withValues(alpha: 0.6) : mlc.subtleBorder,
      width: isSelected ? 1.5 : 1.0,
    ),
  );
}

/// 홈 화면의 **유일한 히어로**. 종가를 `priceHero`(37)로 세운다.
class _IndexHeroCard extends StatelessWidget {
  const _IndexHeroCard({required this.index, required this.isSelected});

  final MarketIndexData index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final v = _IndexVisuals(index, mlc);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: _cardDecoration(mlc, v.color, isSelected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨은 뮤트·Regular. 레퍼런스의 KV 라벨과 같은 취급이다 —
          // 값과 크기로 겨루지 않고 색으로만 물러선다.
          Text(
            index.name,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: mlc.textTertiary,
              fontWeight: AppTypography.regular,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          // ⚠️ FittedBox로 감싸지 않는다. 폭이 모자라면 37px 지정이 조용히
          // 축소돼 히어로가 사라진다 — 그게 개편 전의 실패였다. 폭은 5:4
          // 분할로 예산을 확보했다.
          Text(
            _closeFormat.format(index.close),
            style: AppTypography.priceHero.copyWith(color: mlc.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          // 히어로에 붙는 등락률은 `changeHero`(20)다 — 레퍼런스의
          // 히어로:단위 = 37.5:19.9 = 1.88:1 리듬과 일치한다(우리는 37:20 = 1.85:1).
          // `changeBadge`(15)면 2.47:1이라 히어로가 홀로 붕 뜨고, 15가 이 화면에
          // 혼자 남아 크기 단계만 하나 더 늘린다.
          Text(
            '${v.arrow} ${v.changeText}',
            style: AppTypography.changeHero.copyWith(color: v.color),
            maxLines: 1,
          ),
          if (index.chart.length >= 2) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 32,
              child: CustomPaint(
                size: const Size(double.infinity, 32),
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
    );
  }
}

/// 보조 지수 카드 — 히어로 옆에 세로로 쌓인다. 종가는 `priceCard`(20).
///
/// 37 : 20 = 1.85배로 히어로와의 관계가 눈에 읽힌다. 스파크라인은 넣지 않는다
/// (높이 예산이 없고, 세 개가 다 있으면 히어로가 묻힌다).
class _IndexCompactCard extends StatelessWidget {
  const _IndexCompactCard({required this.index, required this.isSelected});

  final MarketIndexData index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final v = _IndexVisuals(index, mlc);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: _cardDecoration(mlc, v.color, isSelected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1행: 이름 + 등락률. 둘 다 기물 크기(11)라 종가와 겨루지 않는다.
          // 2행 옆에 붙이면 1.3배에서 폭이 모자라 **종가가 잘린다**(= 틀린 숫자).
          Row(
            children: [
              Expanded(
                child: Text(
                  index.name,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: mlc.textTertiary,
                    fontWeight: AppTypography.regular,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '${v.arrow}${v.changeText}',
                style: AppTypography.badgeLabel.copyWith(color: v.color),
                maxLines: 1,
              ),
            ],
          ),
          // 2행: 종가가 자기 행을 독점한다 — 폭 예산 전부를 쓴다.
          Text(
            _closeFormat.format(index.close),
            style: AppTypography.priceCard.copyWith(color: mlc.textPrimary),
            maxLines: 1,
          ),
        ],
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
