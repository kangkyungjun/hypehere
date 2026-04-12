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
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.loginRequired,
              style: const TextStyle(
                fontSize: AppTypography.displayMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.loginPromptMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    child: Text(l10n.signup),
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
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: context.mlColors.onPrimary,
                    ),
                    child: Text(l10n.login),
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
