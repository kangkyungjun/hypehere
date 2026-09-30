import 'package:flutter/material.dart';
import '../../models/treemap_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/sector_names.dart';

/// 컴팩트 섹터 등락 막대 차트 (홈-오늘 above-fold용)
///
/// - 섹터별 등락률(avgChangePct)을 0 기준선 위(상승)/아래(하락) 막대로 표시
/// - 상승=gainColor, 하락=lossColor (앱 테마)
/// - 전체 탭 시 [onTap] 호출 → 섹터별 시장현황(트리맵) 화면으로 이동
/// (VIX는 거시 배너 아래 MacroStripWidget으로 이동됨)
class SectorBarChartWidget extends StatelessWidget {
  const SectorBarChartWidget({
    super.key,
    required this.sectors,
    required this.onTap,
    this.maxBars = 7,
  });

  /// 섹터 목록 (treemap 데이터)
  final List<TreemapSector> sectors;

  /// 막대 탭 → 섹터별 시장현황 화면 이동
  final VoidCallback onTap;

  /// 표시할 최대 막대 개수
  final int maxBars;

  static const double _maxBarHeight = 40;

  // ⚠️ 라벨·섹터명 박스는 **배율에 연동해야 한다.** 고정값이면 접근성 확대에서
  // 텍스트가 박스를 넘고, 넘친 만큼 막대 영역을 밀어내 막대가 섹터명 위로
  // 번진다(1.3배 캡쳐에서 실제로 그랬다).
  //
  // 개편 전에도 `_nameHeight = 28`은 1.3배에서 이미 넘치고 있었다
  // (micro 10 × 1.3 × 1.15 × 2줄 = 29.9 > 28). 축 라벨을 caption(11)으로
  // 올리면서 `_labelHeight`까지 같이 넘쳤다(17.2 > 16).
  @visibleForTesting
  static const double labelLineHeight = 1.2;
  static const double _nameLineHeight = 1.15;

  // +1은 반올림 여유다. 0으로 두면 부동소수점 오차만으로 오버플로가 난다.
  double _labelHeightOf(double scale) =>
      AppTypography.caption * scale * labelLineHeight + 1;

  double _nameHeightOf(double scale) =>
      AppTypography.caption * scale * _nameLineHeight * 2 + 1;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final labelHeight = _labelHeightOf(scale);
    final nameHeight = _nameHeightOf(scale);

    // 등락률 보유 섹터만, 내림차순 정렬 후 상위 maxBars개
    final shown = sectors.where((s) => s.avgChangePct != null).toList()
      ..sort((a, b) => b.avgChangePct!.compareTo(a.avgChangePct!));
    final bars = shown.take(maxBars).toList();

    if (bars.isEmpty) {
      return _wrap(
        context,
        SizedBox(
          height: 96,
          child: Center(
            child: Text('—', style: TextStyle(color: mlc.textTertiary)),
          ),
        ),
      );
    }

    final maxAbs = bars
        .map((s) => s.avgChangePct!.abs())
        .fold<double>(1.0, (m, v) => v > m ? v : m);

    // 위/아래 **예산을 실제 필요한 만큼만** 잡는다.
    //
    // 개편 전에는 0 기준선이 위에서 `labelHeight + 40`에 고정돼 있어,
    // 하락장(양수 폭이 작을 때) 상단 44.6px — 차트 높이의 32% — 가 그냥
    // 비었다. 사용자의 "여백 타이트" 선호에 정면으로 어긋난다.
    //
    // ⚠️ 스케일은 **단일**로 유지한다(`pct / maxAbs`). 각 방향을 자기 최대값에
    // 맞춰 늘리면 +0.4%와 -1.4% 막대가 같은 길이로 보여 데이터를 왜곡한다.
    // 바꾸는 것은 막대 길이가 아니라 **빈 칸의 크기**다.
    final maxPos = bars
        .map((s) => s.avgChangePct!)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final maxNeg = bars
        .map((s) => -s.avgChangePct!)
        .fold<double>(0, (m, v) => v > m ? v : m);

    // 막대 최소 3px(아래 clamp와 같은 값)보다 작은 예산은 막대를 넘치게 한다.
    double budget(double side) =>
        side <= 0 ? 0 : (side / maxAbs * _maxBarHeight).clamp(3.0, _maxBarHeight);

    final upBudget = budget(maxPos);
    final downBudget = budget(maxNeg);

    // 막대가 없는 쪽은 라벨 줄도 통째로 없앤다.
    final upLabelHeight = upBudget > 0 ? labelHeight : 0.0;
    final downLabelHeight = downBudget > 0 ? labelHeight : 0.0;
    final upHeight = upLabelHeight + upBudget;
    final downHeight = downBudget + downLabelHeight;

    return _wrap(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 막대 영역 (상단 라벨+막대 / 기준선 / 하단 막대+라벨 / 섹터명)
          SizedBox(
            height: upHeight + downHeight + nameHeight,
            child: Stack(
              children: [
                // 0 기준선
                Positioned(
                  left: 0,
                  right: 0,
                  top: upHeight,
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
                          upHeight: upHeight,
                          downHeight: downHeight,
                          nameHeight: nameHeight,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
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
}

/// 개별 섹터 막대 (상단=상승, 하단=하락)
class _SectorBar extends StatelessWidget {
  const _SectorBar({
    required this.sector,
    required this.maxAbs,
    required this.maxBarHeight,
    required this.upHeight,
    required this.downHeight,
    required this.nameHeight,
  });

  final TreemapSector sector;
  final double maxAbs;
  final double maxBarHeight;

  /// 0 기준선 **위** 영역(라벨 + 막대). 양수 섹터가 없으면 0이다.
  final double upHeight;

  /// 0 기준선 **아래** 영역(막대 + 라벨).
  final double downHeight;

  final double nameHeight;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final pct = sector.avgChangePct ?? 0;
    final isUp = pct >= 0;
    final color = isUp ? mlc.gainColor : mlc.lossColor;
    final barH = (pct.abs() / maxAbs * maxBarHeight).clamp(3.0, maxBarHeight);
    final pctLabel = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%';

    // 부록 C: 차트성 라벨은 caption(11). micro(10)는 읽기 어려웠다.
    // 섹터명도 11이지만 이쪽은 w700 + 방향색이라 위계가 굵기·색으로 갈린다.
    final labelStyle = TextStyle(
      fontSize: AppTypography.caption,
      fontWeight: AppTypography.bold,
      // ⚠️ `height`를 비워두면 Pretendard 기본 행간(1.2보다 크다)으로 렌더돼
      // `_labelHeightOf`의 계산과 어긋나고, 그 차이만큼 막대 영역을 밀어낸다.
      // 렌더와 계산은 **같은 상수**를 봐야 한다.
      height: SectorBarChartWidget.labelLineHeight,
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
        // 상단(상승) 영역 — 양수 섹터가 하나도 없으면 높이 0이라 사라진다.
        SizedBox(
          height: upHeight,
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
          height: downHeight,
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
        // 섹터명 — 긴 이름은 잘리지 않고 2줄까지 표시
        SizedBox(
          height: nameHeight,
          child: Text(
            // 서버 원문(`Consumer Discretionary`)을 그대로 넣으면 열당 ~50pt
            // 안에서 **단어 중간에 끊긴다**(`Consum / er Discre…`). 끊긴
            // 조각은 읽히지 않는다. 축약형은 대부분 한 줄에 들어간다.
            shortSectorName(sector.sector),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              // 7열이 병렬로 늘어서는 축 라벨은 뮤트가 정석이다. 진한 회색이면
              // 바로 위 방향값(-1%)과 경쟁해 둘 다 안 읽힌다.
              fontSize: AppTypography.caption,
              height: 1.15,
              color: mlc.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
