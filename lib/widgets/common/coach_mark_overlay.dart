import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coach_mark_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A simple coach mark tooltip that appears on first visit.
///
/// Wrap any widget with this to show a one-time tooltip overlay.
/// Uses [CoachMarkProvider] to track whether it has been shown.
///
/// Usage:
/// ```dart
/// CoachMark(
///   coachKey: CoachMarkProvider.keyDashboardTreemap,
///   message: l10n.coachMarkDashboardTreemap,
///   child: TreemapChartWidget(...),
/// )
/// ```
class CoachMark extends StatefulWidget {
  final String coachKey;
  final String message;
  final Widget child;

  const CoachMark({
    super.key,
    required this.coachKey,
    required this.message,
    required this.child,
  });

  @override
  State<CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<CoachMark> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachMarkProvider>();
    final shouldShow = !_dismissed && provider.shouldShow(widget.coachKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShow)
          _CoachMarkBanner(
            message: widget.message,
            onDismiss: () {
              setState(() => _dismissed = true);
              provider.markSeen(widget.coachKey);
            },
          ),
        widget.child,
      ],
    );
  }
}

class _CoachMarkBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _CoachMarkBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                l10n.coachMarkGotIt,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  fontWeight: AppTypography.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
