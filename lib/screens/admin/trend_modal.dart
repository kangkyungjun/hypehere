import 'package:flutter/material.dart';

import '../../models/management_record.dart';
import '../../services/admin_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 경영·운영 손익 추이 모달.
/// - 1단(기본): 최근 5년 연도별 순익 막대그래프
/// - 2단(연도 탭): 그 해 12개월 순익 막대그래프
/// - 월 탭: 모달 닫히고 부모에 'YYYY-MM' 반환 → 메인 화면이 그 연/월로 전환
Future<String?> showTrendModal(
  BuildContext context, {
  required AdminApiClient api,
  required String selectedMonth,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TrendModal(api: api, selectedMonth: selectedMonth),
  );
}

class _TrendModal extends StatefulWidget {
  final AdminApiClient api;
  final String selectedMonth;
  const _TrendModal({required this.api, required this.selectedMonth});

  @override
  State<_TrendModal> createState() => _TrendModalState();
}

class _TrendModalState extends State<_TrendModal> {
  bool _loading = true;
  String? _error;
  List<OpsMonthlyPoint> _all = const [];
  int? _drilledYear; // null=연도 뷰, non-null=그 해의 월별 뷰

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      // 최근 5년: (current year - 4)년 1월 ~ 현재 월. months = 48 + currentMonth.
      final monthsBack = 4 * 12 + now.month;
      final all = await widget.api.getOpsMonthly(months: monthsBack);
      if (!mounted) return;
      setState(() {
        _all = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // 최근 5년 연도 리스트 (오래된→최신)
  List<int> _years() {
    final cy = DateTime.now().year;
    return List.generate(5, (i) => cy - 4 + i);
  }

  Map<int, double> _yearlyNet() {
    final m = <int, double>{};
    for (final p in _all) {
      final y = int.parse(p.month.split('-')[0]);
      m[y] = (m[y] ?? 0) + p.net;
    }
    return m;
  }

  List<OpsMonthlyPoint> _monthsOf(int year) {
    final by = {for (final p in _all) p.month: p};
    return List.generate(12, (i) {
      final ym =
          '$year-${(i + 1).toString().padLeft(2, '0')}';
      return by[ym] ??
          OpsMonthlyPoint(
            month: ym, income: 0, expense: 0, dividend: 0, net: 0,
          );
    });
  }

  static String won(double v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}₩$b';
  }

  static String wonShort(double v) {
    final a = v.abs();
    String body;
    if (a >= 1e8) {
      body = '${(a / 1e8).toStringAsFixed(1)}억';
    } else if (a >= 1e4) {
      body = '${(a / 1e4).toStringAsFixed(1)}만';
    } else {
      body = a.round().toString();
    }
    return '${v < 0 ? '-' : ''}$body';
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(mlc),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    '불러오지 못했습니다\n$_error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mlc.textTertiary),
                  ),
                ),
              )
            else if (_drilledYear == null)
              _yearStage(mlc)
            else
              _monthStage(mlc, _drilledYear!),
          ],
        ),
      ),
    );
  }

  Widget _header(MarketLensColors mlc) {
    final drilled = _drilledYear != null;
    return Row(
      children: [
        if (drilled)
          IconButton(
            onPressed: () => setState(() => _drilledYear = null),
            icon: const Icon(Icons.arrow_back),
            visualDensity: VisualDensity.compact,
          ),
        Expanded(
          child: Text(
            drilled ? '$_drilledYear년 손익' : '손익 추이',
            style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  // ── 1단: 연도별 ──
  Widget _yearStage(MarketLensColors mlc) {
    final years = _years();
    final yearlyNet = _yearlyNet();
    final cy = DateTime.now().year;
    final values = years.map((y) => yearlyNet[y] ?? 0).toList();
    final maxAbs =
        values.map((v) => v.abs()).fold<double>(1, (a, b) => b > a ? b : a);

    // 인사이트: 전년 대비 % + 흑자 연속 카운트
    String insight = '데이터 없음';
    if (values.length >= 2) {
      final cur = values.last;
      final prev = values[values.length - 2];
      String? deltaPct;
      if (prev.abs() > 0) {
        final pct = (cur - prev) / prev.abs() * 100;
        deltaPct =
            '전년 대비 ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
      }
      // 흑자 연속 N년: 최신부터 거꾸로
      int streak = 0;
      for (int i = values.length - 1; i >= 0; i--) {
        if (values[i] > 0) {
          streak++;
        } else {
          break;
        }
      }
      final parts = <String>[
        if (deltaPct != null) '📈 $deltaPct',
        if (streak >= 2) '$streak년 연속 흑자',
      ];
      if (parts.isNotEmpty) insight = parts.join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight,
          style: AppTypography.label.copyWith(color: mlc.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _chart(
          values: values,
          maxAbs: maxAbs,
          labels: years.map((y) => '$y').toList(),
          highlighted: cy,
          highlightKey: (idx) => years[idx],
          onTap: (idx) => setState(() => _drilledYear = years[idx]),
          mlc: mlc,
        ),
        const SizedBox(height: AppSpacing.md),
        // 연도 → 합계 한 줄 요약
        ...List.generate(years.length, (i) {
          final y = years[i];
          final v = values[i];
          final pos = v >= 0;
          return InkWell(
            onTap: () => setState(() => _drilledYear = y),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '$y년${y == cy ? ' (현재)' : ''}',
                      style: AppTypography.label.copyWith(
                        color: y == cy ? mlc.textPrimary : mlc.textSecondary,
                        fontWeight: y == cy
                            ? AppTypography.bold
                            : AppTypography.regular,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${pos ? '+' : ''}${won(v)}',
                      style: AppTypography.body.copyWith(
                        color: pos ? mlc.gainColor : mlc.lossColor,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: mlc.textTertiary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── 2단: 월별 ──
  Widget _monthStage(MarketLensColors mlc, int year) {
    final months = _monthsOf(year);
    final values = months.map((m) => m.net).toList();
    final maxAbs =
        values.map((v) => v.abs()).fold<double>(1, (a, b) => b > a ? b : a);
    final yearSum = values.fold<double>(0, (a, b) => a + b);
    final gainMonths = values.where((v) => v > 0).length;
    final lossMonths = values.where((v) => v < 0).length;
    final insight =
        '📊 연 합계 ${yearSum >= 0 ? '+' : ''}${won(yearSum)}  ·  흑자 $gainMonths개월 / 적자 $lossMonths개월';

    final curYM = widget.selectedMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight,
          style: AppTypography.label.copyWith(color: mlc.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _chart(
          values: values,
          maxAbs: maxAbs,
          labels:
              List.generate(12, (i) => '${i + 1}'),
          highlighted: -1,
          highlightKey: (idx) => months[idx].month == curYM ? 1 : 0,
          highlightedKeyValue: 1,
          onTap: (idx) => Navigator.of(context).pop(months[idx].month),
          mlc: mlc,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '월 탭하면 해당 월 상세로 이동',
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
      ],
    );
  }

  // ── 차트 본체: +위 / -아래, 0선 기준 ──
  Widget _chart({
    required List<double> values,
    required double maxAbs,
    required List<String> labels,
    required int highlighted, // 연도 뷰: 현재 연도 / 월 뷰: 사용 안 함(-1)
    required dynamic Function(int idx) highlightKey,
    dynamic highlightedKeyValue,
    required void Function(int idx) onTap,
    required MarketLensColors mlc,
  }) {
    const halfH = 72.0;
    const barW = 20.0;
    return LayoutBuilder(
      builder: (context, c) {
        final totalW = c.maxWidth;
        final gap = ((totalW - barW * values.length) / (values.length + 1))
            .clamp(2.0, 24.0);
        return Column(
          children: [
            SizedBox(
              height: halfH * 2 + 1,
              child: Row(
                children: [
                  SizedBox(width: gap),
                  for (int i = 0; i < values.length; i++) ...[
                    GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: _bar(
                        v: values[i],
                        maxAbs: maxAbs,
                        halfH: halfH,
                        barW: barW,
                        selected: highlighted >= 0
                            ? labels[i] == highlighted.toString()
                            : highlightKey(i) == highlightedKeyValue,
                        mlc: mlc,
                      ),
                    ),
                    SizedBox(width: gap),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(width: gap),
                for (int i = 0; i < values.length; i++) ...[
                  GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: barW,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: AppTypography.label.copyWith(
                          color: highlighted >= 0
                              ? (labels[i] == highlighted.toString()
                                  ? mlc.textPrimary
                                  : mlc.textTertiary)
                              : (highlightKey(i) == highlightedKeyValue
                                  ? mlc.textPrimary
                                  : mlc.textTertiary),
                          fontWeight: (highlighted >= 0 &&
                                      labels[i] == highlighted.toString()) ||
                                  (highlighted < 0 &&
                                      highlightKey(i) == highlightedKeyValue)
                              ? AppTypography.bold
                              : AppTypography.regular,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                ],
              ],
            ),
            // 값 한 줄(컴팩트)
            const SizedBox(height: 2),
            Row(
              children: [
                SizedBox(width: gap),
                for (int i = 0; i < values.length; i++) ...[
                  SizedBox(
                    width: barW,
                    child: Text(
                      values[i] == 0 ? '—' : wonShort(values[i]),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: values[i] == 0
                            ? mlc.textTertiary
                            : (values[i] >= 0
                                ? mlc.gainColor
                                : mlc.lossColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  SizedBox(width: gap),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar({
    required double v,
    required double maxAbs,
    required double halfH,
    required double barW,
    required bool selected,
    required MarketLensColors mlc,
  }) {
    final posH = (v > 0 ? (v / maxAbs * halfH) : 0.0).clamp(0.0, halfH);
    final negH = (v < 0 ? (-v / maxAbs * halfH) : 0.0).clamp(0.0, halfH);
    BoxDecoration deco(Color color, {bool top = true}) => BoxDecoration(
          color: color,
          borderRadius: BorderRadius.vertical(
            top: top ? const Radius.circular(3) : Radius.zero,
            bottom: top ? Radius.zero : const Radius.circular(3),
          ),
          border: selected
              ? Border.all(color: mlc.textPrimary, width: 1)
              : null,
        );
    return SizedBox(
      width: barW,
      child: Column(
        children: [
          SizedBox(
            height: halfH,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: barW - 4,
                height: posH,
                decoration: deco(mlc.gainColor, top: true),
              ),
            ),
          ),
          Container(height: 1, color: mlc.subtleBorder),
          SizedBox(
            height: halfH,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: barW - 4,
                height: negH,
                decoration: deco(mlc.lossColor, top: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
