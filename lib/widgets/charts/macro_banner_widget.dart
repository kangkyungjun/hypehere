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
    final riskLabel = overall?.riskLabelLocalized(l10n) ?? '–';
    final dotColor =
        overall?.riskColor(context.mlColors) ?? context.mlColors.textTertiary;

    return GestureDetector(
      onTap: onNavigateToIndexes,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // 상하 여백을 기존 대비 ~30%로 축소 (md → xs) — above-fold 2박스 확보
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              _riskAccessibilityIcon(overall?.riskLevel),
              style: TextStyle(
                fontSize: AppTypography.micro,
                color: dotColor,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.macroOverall}: $riskLabel',
                      style: AppTypography.bodyStrong.copyWith(
                        color: context.mlColors.textSecondary,
                      ),
                    ),
                    if (summary.isNotEmpty)
                      TextSpan(
                        text: ' ($summary)',
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          color: context.mlColors.textTertiary,
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
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
