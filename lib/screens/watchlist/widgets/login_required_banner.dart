import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/community/signup_prompt_dialog.dart';
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleLogin(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loginForPortfolio,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.loginForPortfolioHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _handleLogin(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
