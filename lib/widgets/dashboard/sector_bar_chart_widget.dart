import 'package:flutter/material.dart';
import '../../models/macro_data.dart';
import '../../models/treemap_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 컴팩트 섹터 등락 막대 차트 (홈-오늘 above-fold용)
///
/// - 섹터별 등락률(avgChangePct)을 0 기준선 위(상승)/아래(하락) 막대로 표시
/// - 상승=gainColor, 하락=lossColor (앱 테마)
/// - 하단에 VIX 한 줄
/// - 전체 탭 시 [onTap] 호출 → 섹터별 시장현황(트리맵) 화면으로 이동
class SectorBarChartWidget extends StatelessWidget {
  const SectorBarChartWidget({
    super.key,
    required this.sectors,
    required this.onTap,
    this.vix,
    this.maxBars = 7,
  });

  /// 섹터 목록 (treemap 데이터)
  final List<TreemapSector> sectors;

  /// VIX 지표 (macro indicators의 VIXCLS) — 없으면 VIX 줄 숨김
  final MacroIndicator? vix;

  /// 막대 탭 → 섹터별 시장현황 화면 이동
  final VoidCallback onTap;

  /// 표시할 최대 막대 개수
  final int maxBars;

  static const double _maxBarHeight = 40;
  static const double _labelHeight = 16;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;

    // 등락률 보유 섹터만, 내림차순 정렬 후 상위 maxBars개
    final shown =
        sectors.where((s) => s.avgChangePct != null).toList()
          ..sort((a, b) => b.avgChangePct!.compareTo(a.avgChangePct!));
    final bars = shown.take(maxBars).toList();

    if (bars.isEmpty) {
      return _wrap(
        context,
        SizedBox(
          height: 96,
          child: Center(
            child: Text(
              '—',
              style: TextStyle(color: mlc.textTertiary),
            ),
          ),
        ),
      );
    }

    final maxAbs = bars
        .map((s) => s.avgChangePct!.abs())
        .fold<double>(1.0, (m, v) => v > m ? v : m);

    return _wrap(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 막대 영역 (상단 라벨+막대 / 기준선 / 하단 막대+라벨 / 섹터명)
          SizedBox(
            height: (_labelHeight + _maxBarHeight) * 2 + 18,
            child: Stack(
              children: [
                // 0 기준선
                Positioned(
                  left: 0,
                  right: 0,
                  top: _labelHeight + _maxBarHeight,
                  child: Divider(height: 1, color: mlc.subtleBorder),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in bars)
                      Expanded(
                        child: _SectorBar(
                          sector: s,
                          maxAbs: maxAbs,
                          maxBarHeight: _maxBarHeight,
                          labelHeight: _labelHeight,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (vix != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: mlc.subtleBorder),
            const SizedBox(height: AppSpacing.sm),
            _buildVixLine(context, vix!),
          ],
        ],
      ),
    );
  }

  /// 탭 가능한 카드로 감싸기
  Widget _wrap(BuildContext context, Widget child) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }

  Widget _buildVixLine(BuildContext context, MacroIndicator v) {
    final mlc = context.mlColors;
    final pct = v.changePct;
    final String arrow;
    final Color color;
    if (pct == null || pct == 0) {
      arrow = '─';
      color = mlc.neutralColor;
    } else if (pct > 0) {
      arrow = '▲';
      color = mlc.gainColor;
    } else {
      arrow = '▼';
      color = mlc.lossColor;
    }
    final pctStr = pct == null
        ? ''
        : ' $arrow ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';

    return Row(
      children: [
        Text(
          'VIX ${v.value.toStringAsFixed(2)}',
          style: AppTypography.numericSecondary.copyWith(
            color: mlc.textPrimary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        if (pctStr.isNotEmpty)
          Text(
            pctStr,
            style: AppTypography.numericSecondary.copyWith(color: color),
          ),
        if (v.avg3m != null) ...[
          Text(
            '  ·  ',
            style: TextStyle(color: mlc.textTertiary),
          ),
          Text(
            '3M ${v.avg3m!.toStringAsFixed(2)}',
            style: AppTypography.numericSecondary.copyWith(
              color: mlc.textSecondary,
            ),
          ),
        ],
        const Spacer(),
        Icon(Icons.chevron_right, size: 18, color: mlc.textTertiary),
      ],
    );
  }
}

/// 개별 섹터 막대 (상단=상승, 하단=하락)
class _SectorBar extends StatelessWidget {
  const _SectorBar({
    required this.sector,
    required this.maxAbs,
    required this.maxBarHeight,
    required this.labelHeight,
  });

  final TreemapSector sector;
  final double maxAbs;
  final double maxBarHeight;
  final double labelHeight;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final pct = sector.avgChangePct ?? 0;
    final isUp = pct >= 0;
    final color = isUp ? mlc.gainColor : mlc.lossColor;
    final barH = (pct.abs() / maxAbs * maxBarHeight).clamp(3.0, maxBarHeight);
    final pctLabel = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%';

    final labelStyle = TextStyle(
      fontSize: AppTypography.micro,
      fontWeight: AppTypography.bold,
      color: color,
    );

    final bar = Container(
      height: barH,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return Column(
      children: [
        // 상단(상승) 영역
        SizedBox(
          height: labelHeight + maxBarHeight,
          child: isUp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(pctLabel, style: labelStyle),
                    bar,
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // 하단(하락) 영역
        SizedBox(
          height: labelHeight + maxBarHeight,
          child: !isUp
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    bar,
                    Text(pctLabel, style: labelStyle),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // 섹터명
        SizedBox(
          height: 18,
          child: Text(
            sector.sector,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: mlc.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
