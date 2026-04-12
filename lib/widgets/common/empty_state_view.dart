import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 빈 데이터 상태 — 아이콘 + 메시지 (+ 선택적 부제)
///
/// ```dart
/// EmptyStateView(
///   icon: Icons.event_busy,
///   message: l10n.noEventsThisMonth,
/// )
/// ```
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconSize = 48,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
