import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/investment_profile_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/app_page_route.dart';
import '../../onboarding/investment_profile_onboarding_screen.dart';

/// Compact one-line chip shown in the portfolio view:
/// "당신의 투자성향 · 균형형  ✎"
///
/// State handling (overwrite-safe):
/// - Not logged in                         → hidden.
/// - Profile loaded                        → style label, tap → edit.
/// - No profile locally, server HAS one    → silent recovery fetch, hidden
///   (never shows the "set up" CTA, so a failed load can't lead to the user
///   recreating a default profile that overwrites the real one).
/// - No profile anywhere (genuinely unset) → "set up" CTA, tap → onboarding.
class InvestmentStyleChip extends StatefulWidget {
  /// Horizontal padding around the chip. Defaults to [AppSpacing.xl] for the
  /// holdings list; pass 0 when the parent already applies horizontal padding
  /// (e.g. the empty-portfolio state) to keep edges aligned.
  final double horizontalPadding;

  const InvestmentStyleChip({super.key, this.horizontalPadding = AppSpacing.xl});

  @override
  State<InvestmentStyleChip> createState() => _InvestmentStyleChipState();
}

class _InvestmentStyleChipState extends State<InvestmentStyleChip> {
  /// Guards against re-issuing the recovery fetch on every rebuild.
  bool _recoveryRequested = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const SizedBox.shrink();

    final profileProvider = context.watch<InvestmentProfileProvider>();
    final profile = profileProvider.profile;
    final hasProfile = profile != null;
    final serverHasProfile = auth.currentUser?.hasInvestmentProfile ?? false;

    if (!hasProfile) {
      // Still loading the first fetch → avoid a flash of the wrong state.
      if (profileProvider.isLoading) return const SizedBox.shrink();

      // Server says a profile exists but it isn't loaded locally (e.g. the
      // startup fetch failed). Do NOT show the "set up" CTA — that would let
      // the user recreate a default and overwrite their real profile. Try to
      // recover once, and stay hidden until it loads.
      if (serverHasProfile) {
        if (!_recoveryRequested) {
          _recoveryRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<InvestmentProfileProvider>().fetchProfile();
            }
          });
        }
        return const SizedBox.shrink();
      }
      // else: genuinely no profile → fall through to the CTA below.
    }

    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;

    final (IconData icon, Color accent, String styleLabel) = hasProfile
        ? _styleVisual(profile.investmentStyle, l10n, colors)
        : (Icons.tune_rounded, colors.accentBlue, l10n.setInvestmentStyle);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          appPageRoute(
            builder: (_) =>
                InvestmentProfileOnboardingScreen(isEditing: hasProfile),
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildLabel(
                  hasProfile: hasProfile,
                  l10n: l10n,
                  colors: colors,
                  accent: accent,
                  styleLabel: styleLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel({
    required bool hasProfile,
    required AppLocalizations l10n,
    required MarketLensColors colors,
    required Color accent,
    required String styleLabel,
  }) {
    if (!hasProfile) {
      return Text(
        styleLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: AppTypography.semiBold,
          color: accent,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.yourInvestmentStyle,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: colors.textSecondary,
            ),
          ),
          TextSpan(
            text: '  ·  ',
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: colors.textTertiary,
            ),
          ),
          TextSpan(
            text: styleLabel,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.bold,
              color: accent,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  (IconData, Color, String) _styleVisual(
    String style,
    AppLocalizations l10n,
    MarketLensColors colors,
  ) {
    switch (style) {
      case 'conservative':
        return (
          Icons.shield_outlined,
          colors.accentBlue,
          l10n.investmentStyleConservative,
        );
      case 'aggressive':
        return (
          Icons.trending_up_rounded,
          colors.warningColor,
          l10n.investmentStyleAggressive,
        );
      case 'balanced':
      default:
        return (
          Icons.balance_outlined,
          colors.accentBlue,
          l10n.investmentStyleBalanced,
        );
    }
  }
}
