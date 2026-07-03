import 'package:flutter/material.dart';

import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 개별 기업 투자지표 섹션 — PER·PBR·ROE·EPS·BPS·EV/EBITDA 6종.
/// 값 null은 "-". 6종 전부 null이면 섹션 숨김.
/// ROE는 서버가 비율(0.2133)로 주므로 ×100 %표기.
/// (l10n 파일 변경 회피 위해 제목만 인라인 다국어, 지표명은 만국 공용 약어)
class InvestmentMetricsSection extends StatelessWidget {
  final KeyMetrics? metrics;

  const InvestmentMetricsSection({super.key, required this.metrics});

  static String _title(String lang) =>
      const {'ko': '투자지표', 'zh': '投资指标', 'ja': '投資指標', 'es': 'Métricas'}[lang] ??
      'Valuation';

  static String _num(double? v) => v == null ? '-' : v.toStringAsFixed(1);
  static String _money(double? v) => v == null ? '-' : '\$${v.toStringAsFixed(2)}';
  static String _pct(double? v) =>
      v == null ? '-' : '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    if (m == null) return const SizedBox.shrink();
    final cells = <(String, String)>[
      ('PER', _num(m.pe)),
      ('PBR', _num(m.pb)),
      ('ROE', _pct(m.roe)),
      ('EPS', _money(m.eps)),
      ('BPS', _money(m.bps)),
      ('EV/EBITDA', _num(m.evEbitda)),
    ];
    // 전부 "-" 이면 숨김.
    if (cells.every((c) => c.$2 == '-')) return const SizedBox.shrink();

    final mlc = context.mlColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: mlc.chartGridLine.withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(lang),
            style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          // 2열 × 3행 그리드.
          for (var i = 0; i < cells.length; i += 2) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _cell(mlc, cells[i].$1, cells[i].$2)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < cells.length
                      ? _cell(mlc, cells[i + 1].$1, cells[i + 1].$2)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(MarketLensColors mlc, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTypography.bodyLarge,
            fontWeight: AppTypography.bold,
            color: value == '-' ? mlc.textTertiary : mlc.textPrimary,
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ],
    );
  }
}
