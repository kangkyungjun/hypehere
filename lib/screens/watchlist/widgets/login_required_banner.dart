import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/community/signup_prompt_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';

/// Compact banner prompting non-logged-in users to log in for portfolio features.
class LoginRequiredBanner extends StatelessWidget {
  const LoginRequiredBanner({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const SignupPromptDialog(),
    );

    if (result == null || !context.mounted) return;

    if (result == 'login') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (result == 'signup') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: BentoCard(
        emphasized: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        onTap: () => _handleLogin(context),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: mlc.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.lock_outline, size: 19, color: mlc.accentBlue),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.loginForPortfolio,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: mlc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.loginForPortfolioHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: mlc.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.tonal(
              onPressed: () => _handleLogin(context),
              style: FilledButton.styleFrom(
                backgroundColor: mlc.infoBg,
                foregroundColor: mlc.accentBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.login,
                style: const TextStyle(fontSize: AppTypography.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
