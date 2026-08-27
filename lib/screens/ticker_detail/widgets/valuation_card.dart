import 'package:flutter/material.dart';

import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';

/// 헤더(업데이트 날짜) ↔ 전문가 요약 사이의 작은 밸류에이션 카드.
///  - 접힘: 현재 PER · 선행 PER · EPS (한 줄)
///  - 탭 → 아래로 확장: PBR/ROE/ROA · 영업이익률/PSR/BPS · 매출성장/이익성장/부채비율
///  - 라벨=작은 회색, 숫자=크고 검정. 여백은 타이트하게, 기존 디자인 톤 유지.
///  - l10n 파일 변경 회피 위해 라벨은 인라인 다국어.
class ValuationCard extends StatefulWidget {
  final KeyMetrics? metrics;

  const ValuationCard({super.key, required this.metrics});

  @override
  State<ValuationCard> createState() => _ValuationCardState();
}

class _ValuationCardState extends State<ValuationCard> {
  bool _expanded = false;

  // ── 포맷 헬퍼 ──
  static String _num(double? v) => v == null ? '-' : v.toStringAsFixed(1);
  static String _money(double? v) =>
      v == null ? '-' : '\$${v.toStringAsFixed(2)}';
  static String _pct(double? v) =>
      v == null ? '-' : '${(v * 100).toStringAsFixed(1)}%';
  static String _pctSigned(double? v) => v == null
      ? '-'
      : '${v >= 0 ? '+' : ''}${(v * 100).toStringAsFixed(1)}%';

  // ── 라벨 (인라인 다국어). 약어는 만국 공용. ──
  static String _lbl(String key, String lang) {
    const m = {
      'curPe': {'ko': '현재 PER', 'zh': '市盈率', 'ja': 'PER', 'es': 'P/E'},
      'fwdPe': {'ko': '선행 PER', 'zh': '预期PER', 'ja': '予想PER', 'es': 'P/E adel.'},
      'opMargin': {'ko': '영업이익률', 'zh': '营业利润率', 'ja': '営業利益率', 'es': 'M. oper.'},
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
      const {'ko': '밸류에이션', 'zh': '估值', 'ja': 'バリュエーション', 'es': 'Valuación'}[lang] ??
      'Valuation';

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;
    final mlc = context.mlColors;
    final lang = Localizations.localeOf(context).languageCode;

    // 접힘 3개가 전부 없으면 카드 숨김.
    final topEmpty = m == null || (m.pe == null && m.forwardPe == null && m.eps == null);
    if (topEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: BentoCard(
        onTap: () => setState(() => _expanded = !_expanded),
        padding: const EdgeInsets.all(AppDensity.cardPad),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 헤더(볼드·near-black) + chevron
                Row(
                  children: [
                    Text(
                      _title(lang),
                      style: AppTypography.sectionTitle.copyWith(
                        color: mlc.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: mlc.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // 헤더 아래 헤어라인(섹션 구분)
                Divider(
                  height: 1,
                  color: mlc.subtleBorder.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.md),
                // 접힘 줄
                _row(mlc, [
                  (_lbl('curPe', lang), _num(m.pe)),
                  (_lbl('fwdPe', lang), _num(m.forwardPe)),
                  ('EPS', _money(m.eps)),
                ]),
                // 펼침
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Divider(
                              height: 1,
                              color: mlc.subtleBorder.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _row(mlc, [
                              ('PBR', _num(m.pb)),
                              ('ROE', _pct(m.roe)),
                              ('ROA', _pct(m.roa)),
                            ]),
                            const SizedBox(height: AppSpacing.md),
                            _row(mlc, [
                              (_lbl('opMargin', lang), _pct(m.operatingMargin)),
                              ('PSR', _num(m.ps)),
                              ('BPS', _money(m.bps)),
                            ]),
                            const SizedBox(height: AppSpacing.md),
                            _row(mlc, [
                              (_lbl('revG', lang), _pctSigned(m.revenueGrowth)),
                              (_lbl('earnG', lang), _pctSigned(m.earningsGrowth)),
                              (_lbl('de', lang), _num(m.debtToEquity)),
                            ]),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
      ),
    );
  }

  Widget _row(MarketLensColors mlc, List<(String, String)> cells) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: _cell(mlc, cells[i].$1, cells[i].$2)),
        ],
      ],
    );
  }

  Widget _cell(MarketLensColors mlc, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          // 라벨 11→13 medium: 작아서 안 읽히던 문제 해소(위계는 값과 색·굵기로).
          style: AppTypography.kvLabel.copyWith(color: mlc.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        // 값 14→16 semiBold near-black: 카드의 주인공 숫자를 또렷하게.
        // FittedBox(scaleDown): 좁은 폭에서 '…'로 숫자를 숨기지 않고 살짝 축소
        // — 데이터 손실 없이 구조도 안 깨진다.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.semiBold,
              height: 1.15,
              color: value == '-' ? mlc.textTertiary : mlc.textPrimary,
              fontFeatures: AppTypography.tabularFigures,
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
