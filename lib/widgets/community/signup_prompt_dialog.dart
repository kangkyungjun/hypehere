import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class SignupPromptDialog extends StatelessWidget {
  const SignupPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_person,
              size: 56,
              color: context.mlColors.accentBlue,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.loginRequired,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.displayMedium,
                fontWeight: AppTypography.bold,
                color: context.mlColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.loginPromptMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: context.mlColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop('signup');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      foregroundColor: context.mlColors.accentBlue,
                      side: BorderSide(
                        color: context.mlColors.accentBlue,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n.signup),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop('login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      backgroundColor: context.mlColors.accentBlue,
                      foregroundColor: context.mlColors.onPrimary,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(l10n.login),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
