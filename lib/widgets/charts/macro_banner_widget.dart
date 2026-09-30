import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/macro_data.dart';
import '../../utils/multilingual.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Compact macro economic banner — header only.
///
/// ┌──────────────────────────────────────────┐
/// │ ● ━━ 거시경제: 중립 (전반적으로 안정적) > │  ← tappable → IndexesDetailScreen
/// └──────────────────────────────────────────┘
class MacroBannerWidget extends StatelessWidget {
  final MacroIndicatorsData? data;
  final MacroSignalsData? signals;
  final VoidCallback? onNavigateToIndexes;

  const MacroBannerWidget({
    super.key,
    this.data,
    this.signals,
    this.onNavigateToIndexes,
  });

  MacroSignal? _overallMacro() {
    if (signals == null) return null;
    try {
      return signals!.signals.firstWhere(
        (s) => s.signalCode == 'overall_macro',
      );
    } catch (_) {
      return null;
    }
  }

  static String _riskAccessibilityIcon(String? riskLevel) {
    switch (riskLevel) {
      case 'BEARISH':
      case 'CRITICAL':
        return '\u25BC\u25BC';
      case 'CAUTIOUS':
      case 'WARNING':
        return '\u25BC';
      case 'NEUTRAL':
        return '\u2501';
      case 'FAVORABLE':
        return '\u25B2';
      case 'BULLISH':
      case 'OPTIMAL':
        return '\u25B2\u25B2';
      default:
        return '\u2501';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasIndicators = data != null && data!.indicators.isNotEmpty;
    final hasSignals = signals != null && signals!.signals.isNotEmpty;

    if (!hasIndicators && !hasSignals) {
      return const SizedBox.shrink();
    }

    final langCode = Localizations.localeOf(context).languageCode;
    final overall = _overallMacro();

    String summary = '';
    if (overall?.cleanMessage != null) {
      final lines = overall!.cleanMessage!.localize(langCode).split('\n');
      summary = lines.first;
      if (summary.contains(': ')) {
        summary = summary.substring(summary.indexOf(': ') + 2);
      }
    }

    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final riskLabel = overall?.riskLabelLocalized(l10n) ?? '–';

    // 탭 전체 배경을 거시경제 위험도 색으로 채우고,
    // 배경 명도에 따라 대비되는 글씨색(흰/검정)을 자동 선택해 가독성 확보.
    final bgColor = overall?.riskColor(mlc) ?? mlc.neutralColor;
    final onColor =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return GestureDetector(
      onTap: onNavigateToIndexes,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: bgColor,
        // 상하 여백은 타이트하게 유지 — above-fold 2박스 확보
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            // 방향 글리프(▲▲/▼ 등) — 색맹 사용자도 색에 의존하지 않게 상태 표시
            Text(
              _riskAccessibilityIcon(overall?.riskLevel),
              style: TextStyle(
                // 색맹 사용자에게는 이 글리프가 판정의 **유일한** 비색상 단서다.
                // 10px는 그 역할을 하기엔 작았고, 이 화면에 10px을 혼자 남겨
                // 크기 단계만 하나 더 만들고 있었다.
                fontSize: AppTypography.caption,
                color: onColor,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                // 3단 위계: 접두(13) < 판정(18 w700) < 요약(13 뮤트).
                //
                // 개편 전에는 '거시경제: 양호'가 통째로 15 w600, 괄호 요약이
                // 14 w400이었다. 인접비 1.07 — 어디가 결론값인지 안 보였다.
                // 결론은 `riskLabel` 한 단어뿐이므로 그것만 키운다. 접두와
                // 요약을 같은 13으로 내려 판정이 홀로 서게 한다.
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.macroOverall}: ',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.medium,
                        color: onColor.withValues(alpha: 0.82),
                      ),
                    ),
                    TextSpan(
                      text: riskLabel,
                      style: AppTypography.cardTitle.copyWith(color: onColor),
                    ),
                    if (summary.isNotEmpty)
                      TextSpan(
                        text: '  $summary',
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: onColor.withValues(alpha: 0.82),
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: onColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
