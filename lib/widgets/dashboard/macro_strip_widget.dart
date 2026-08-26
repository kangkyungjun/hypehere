import 'package:flutter/material.dart';

import '../../models/macro_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/bento_card.dart';

/// 오늘 탭 — 거시 배너 바로 아래의 긴 가로 막대.
///  - 좌: VIX (값·등락%·3M, 기존과 동일)
///  - 우: 10년물 국채금리 (임계 색상: 4.3%↑ 노랑, 4.5%↑ 빨강)
/// 각 반쪽은 **영역 전체**가 탭 대상 → 해당 상세 페이지로 이동(글씨만이 아니라 영역 탭).
class MacroStripWidget extends StatelessWidget {
  const MacroStripWidget({
    super.key,
    this.vix,
    this.treasury10y,
    this.onVixTap,
    this.onTreasuryTap,
  });

  final MacroIndicator? vix;
  final MacroIndicator? treasury10y;
  final VoidCallback? onVixTap;
  final VoidCallback? onTreasuryTap;

  /// 국채 상세 페이지 제목용(내부 라벨과 동일). 대시보드에서 참조.
  static String treasuryTitle(String lang) => _treasuryLabel(lang);

  // 10년물 국채금리 라벨 — 인라인 5개국어 (l10n 파일 무변경).
  static String _treasuryLabel(String lang) =>
      const {
        'ko': '10년물 국채금리',
        'zh': '10年期国债收益率',
        'ja': '10年国債利回り',
        'es': 'Bono 10 años',
      }[lang] ??
      '10Y Treasury';

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return BentoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _vixHalf(context)),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              color: context.mlColors.subtleBorder,
            ),
            Expanded(child: _treasuryHalf(context, lang)),
          ],
        ),
      ),
    );
  }

  // ── 좌: VIX ──
  Widget _vixHalf(BuildContext context) {
    final mlc = context.mlColors;
    final v = vix;
    Widget content;
    if (v == null) {
      content = _cell(context, 'VIX', const [], placeholder: true);
    } else {
      final pct = v.changePct;
      final String arrow;
      final Color pctColor;
      if (pct == null || pct == 0) {
        arrow = '─';
        pctColor = mlc.neutralColor;
      } else if (pct > 0) {
        arrow = '▲';
        pctColor = mlc.gainColor;
      } else {
        arrow = '▼';
        pctColor = mlc.lossColor;
      }
      content = _cell(context, 'VIX', [
        _ValuePart(v.value.toStringAsFixed(2), mlc.textPrimary, big: true),
        if (pct != null)
          _ValuePart(
            '$arrow ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
            pctColor,
          ),
        if (v.avg3m != null)
          _ValuePart('· 3M ${v.avg3m!.toStringAsFixed(1)}', mlc.textSecondary),
      ]);
    }
    return _tappable(context, onVixTap, content);
  }

  // ── 우: 10년물 국채금리 ──
  Widget _treasuryHalf(BuildContext context, String lang) {
    final mlc = context.mlColors;
    final t = treasury10y;
    final label = _treasuryLabel(lang);
    Widget content;
    if (t == null) {
      content = _cell(context, label, const [], placeholder: true);
    } else {
      // 임계 색상: <4.3 기본(검정) / 4.3~4.5 노랑 / ≥4.5 빨강.
      final val = t.value;
      final Color color = val >= 4.5
          ? mlc.dangerColor
          : (val >= 4.3 ? mlc.warningColor : mlc.textPrimary);
      content = _cell(context, label, [
        _ValuePart('${val.toStringAsFixed(2)}%', color, big: true),
      ]);
    }
    return _tappable(context, onTreasuryTap, content);
  }

  /// 영역 전체 탭 → 상세 이동. (글씨뿐 아니라 반쪽 전체가 히트 영역)
  Widget _tappable(BuildContext context, VoidCallback? onTap, Widget child) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }

  /// 라벨(작은 회색) + 값 줄. 값이 없으면 '-'.
  Widget _cell(
    BuildContext context,
    String label,
    List<_ValuePart> parts, {
    bool placeholder = false,
  }) {
    final mlc = context.mlColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.medium,
                  color: mlc.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: mlc.accentBlue),
          ],
        ),
        const SizedBox(height: 2),
        if (placeholder)
          Text(
            '-',
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.bold,
              color: mlc.textTertiary,
            ),
          )
        else
          Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in parts)
                Text(
                  p.text,
                  style: TextStyle(
                    fontSize: p.big
                        ? AppTypography.bodyLarge
                        : AppTypography.bodySmall,
                    fontWeight: p.big
                        ? AppTypography.bold
                        : AppTypography.semiBold,
                    color: p.color,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ValuePart {
  final String text;
  final Color color;
  final bool big;
  const _ValuePart(this.text, this.color, {this.big = false});
}
