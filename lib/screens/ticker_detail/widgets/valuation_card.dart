import 'package:flutter/material.dart';

import '../../../models/chart_data.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/ml_key_value_row.dart';
import '../../../widgets/common/ml_expandable_card.dart';

/// 헤더(업데이트 날짜) ↔ 전문가 요약 사이의 작은 밸류에이션 카드.
///  - 접힘: 현재 PER · 선행 PER · EPS (한 줄)
///  - 탭 → 아래로 확장: PBR/ROE/ROA · 영업이익률/PSR/BPS · 매출성장/이익성장/부채비율
///  - 라벨=작은 회색, 숫자=크고 검정. 여백은 타이트하게, 기존 디자인 톤 유지.
///  - l10n 파일 변경 회피 위해 라벨은 인라인 다국어.
class ValuationCard extends StatelessWidget {
  final KeyMetrics? metrics;

  const ValuationCard({super.key, required this.metrics});

  // ── 포맷 헬퍼 ──
  static String _num(double? v) => v == null ? '-' : v.toStringAsFixed(1);
  static String _money(double? v) =>
      v == null ? '-' : '\$${v.toStringAsFixed(2)}';
  static String _pct(double? v) =>
      v == null ? '-' : '${(v * 100).toStringAsFixed(1)}%';
  static String _pctSigned(double? v) =>
      v == null ? '-' : '${v >= 0 ? '+' : ''}${(v * 100).toStringAsFixed(1)}%';

  // ── 라벨 (인라인 다국어). 약어는 만국 공용. ──
  static String _lbl(String key, String lang) {
    const m = {
      'curPe': {'ko': '현재 PER', 'zh': '市盈率', 'ja': 'PER', 'es': 'P/E'},
      'fwdPe': {
        'ko': '선행 PER',
        'zh': '预期PER',
        'ja': '予想PER',
        'es': 'P/E adel.',
      },
      'opMargin': {
        'ko': '영업이익률',
        'zh': '营业利润率',
        'ja': '営業利益率',
        'es': 'M. oper.',
      },
      'revG': {'ko': '매출성장', 'zh': '营收增长', 'ja': '売上成長', 'es': 'Cr. ingr.'},
      'earnG': {'ko': '이익성장', 'zh': '利润增长', 'ja': '利益成長', 'es': 'Cr. benef.'},
      'de': {'ko': '부채비율', 'zh': '负债率', 'ja': '負債比率', 'es': 'Deuda/Cap.'},
    };
    final byLang = m[key];
    if (byLang == null) return key;
    return byLang[lang] ??
        const {
          'curPe': 'P/E',
          'fwdPe': 'Fwd P/E',
          'opMargin': 'Op. margin',
          'revG': 'Rev. growth',
          'earnG': 'Earn. growth',
          'de': 'Debt/Eq.',
        }[key]!;
  }

  static String _title(String lang) =>
      const {
        'ko': '밸류에이션',
        'zh': '估值',
        'ja': 'バリュエーション',
        'es': 'Valuación',
      }[lang] ??
      'Valuation';

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final lang = Localizations.localeOf(context).languageCode;

    // 접힘 3개가 전부 없으면 카드 숨김.
    final topEmpty =
        m == null || (m.pe == null && m.forwardPe == null && m.eps == null);
    if (topEmpty) return const SizedBox.shrink();

    // 확장 상태·chevron 회전·AnimatedSize·divider·Semantics는 전부
    // MlExpandableCard가 담당한다. 여기 남는 건 "무엇을 접을지"뿐이다.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: MlExpandableCard(
        header: MlCardTitle(_title(lang)),
        summary: _row([
          (_lbl('curPe', lang), _num(m.pe)),
          (_lbl('fwdPe', lang), _num(m.forwardPe)),
          ('EPS', _money(m.eps)),
        ]),
        detail: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row([
              ('PBR', _num(m.pb)),
              ('ROE', _pct(m.roe)),
              ('ROA', _pct(m.roa)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _row([
              (_lbl('opMargin', lang), _pct(m.operatingMargin)),
              ('PSR', _num(m.ps)),
              ('BPS', _money(m.bps)),
            ]),
            const SizedBox(height: AppSpacing.md),
            _row([
              (_lbl('revG', lang), _pctSigned(m.revenueGrowth)),
              (_lbl('earnG', lang), _pctSigned(m.earningsGrowth)),
              (_lbl('de', lang), _num(m.debtToEquity)),
            ]),
          ],
        ),
      ),
    );
  }

  /// 3열 지표 행 — 각 셀은 [MlKeyValueRow]`(stack)`.
  ///
  /// 손수 만들던 `_cell`(라벨/값 스타일·FittedBox·빈값 처리)은 프리미티브가
  /// 전부 담당한다. 여기 남는 건 "3등분"이라는 레이아웃 결정뿐이다.
  Widget _row(List<(String, String)> cells) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MlKeyValueRow(
              label: cells[i].$1,
              value: cells[i].$2,
              layout: MlKvLayout.stack,
              emphasis: MlKvEmphasis.strong,
              dense: true,
            ),
          ),
        ],
      ],
    );
  }
}
