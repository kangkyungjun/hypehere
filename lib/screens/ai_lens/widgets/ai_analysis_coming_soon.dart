import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Placeholder for the future conversational AI ("AI분석") tab.
///
/// Polished, on-brand "coming soon" screen shown until the messenger-style
/// AI query feature ships.
class AiAnalysisComingSoon extends StatelessWidget {
  const AiAnalysisComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent icon disc
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mlc.accentBlue.withValues(alpha: 0.22),
                    mlc.infoBg.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: mlc.accentBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Title
            Text(
              l10n.aiAnalysisComingSoonTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.headlineLarge,
                fontWeight: AppTypography.bold,
                color: mlc.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Body
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                l10n.aiAnalysisComingSoonBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  height: 1.5,
                  color: mlc.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Badge pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: mlc.infoBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(
                  color: mlc.accentBlue.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 16,
                    color: mlc.accentBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.comingSoonBadge,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      fontWeight: AppTypography.bold,
                      color: mlc.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
