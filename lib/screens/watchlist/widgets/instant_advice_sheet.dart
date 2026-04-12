import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/multilingual.dart';

/// Bottom sheet showing instant AI advice after a stock purchase.
class InstantAdviceSheet extends StatelessWidget {
  final PortfolioAdvice advice;

  const InstantAdviceSheet({super.key, required this.advice});

  /// Show the sheet.
  static Future<void> show(BuildContext context, PortfolioAdvice advice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => InstantAdviceSheet(advice: advice),
    );
  }

  Color _signalColor(BuildContext context, String? signal) {
    final mlc = context.mlColors;
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == 'STRONG_BUY' || s.contains('매수')) {
      return mlc.gainColor;
    }
    if (s == 'SELL' || s == 'STRONG_SELL' || s.contains('매도')) {
      return mlc.lossColor;
    }
    return mlc.neutralColor;
  }

  String _signalLabel(String? signal) {
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == '매수권고') return 'BUY';
    if (s == 'STRONG_BUY' || s == '적극매수') return 'STRONG BUY';
    if (s == 'SELL' || s == '매도권고') return 'SELL';
    if (s == 'STRONG_SELL' || s == '적극매도') return 'STRONG SELL';
    if (s == 'HOLD' || s == '관망') return 'HOLD';
    return signal ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.xxs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Header: ticker + signal pill + confidence
                Row(
                  children: [
                    Text(
                      advice.ticker,
                      style: const TextStyle(
                        fontSize: AppTypography.displaySmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isKo && advice.nameKo != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        advice.nameKo!,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else if (advice.name != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        advice.name!,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (advice.signal != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _signalColor(context, advice.signal),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          _signalLabel(advice.signal),
                          style: TextStyle(
                            color: context.mlColors.onPrimary,
                            fontSize: AppTypography.bodySmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                // Confidence
                if (advice.confidence != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${l10n.confidence}: ${(advice.confidence! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  l10n.aiAdviceInstant,
                  style: const TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Summary text
                if (advice.summary != null)
                  Text(
                    localizePacked(advice.summary ?? '', effectiveLanguageCode(context)),
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // Bullish factors
                if (advice.bullishReasons.isNotEmpty) ...[
                  Text(
                    l10n.bullishFactorsPortfolio,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.semiBold,
                      color: context.mlColors.gainColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...advice.bullishReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('+ ', style: TextStyle(color: context.mlColors.gainColor, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                localizePacked(r, effectiveLanguageCode(context)),
                                style: const TextStyle(fontSize: AppTypography.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Bearish factors
                if (advice.bearishReasons.isNotEmpty) ...[
                  Text(
                    l10n.bearishFactorsPortfolio,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.semiBold,
                      color: context.mlColors.lossColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...advice.bearishReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('- ', style: TextStyle(color: context.mlColors.lossColor, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                localizePacked(r, effectiveLanguageCode(context)),
                                style: const TextStyle(fontSize: AppTypography.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Footer
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.detailedAnalysisComingSoon,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
