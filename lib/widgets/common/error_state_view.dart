import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 에러 상태 — 아이콘 + 메시지 + 선택적 재시도 버튼
///
/// ```dart
/// ErrorStateView(
///   message: l10n.searchFailed,
///   detail: error.toString(),
///   onRetry: () => _reload(),
/// )
/// ```
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colors.lossColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: TextStyle(
                fontSize: AppTypography.headlineMedium,
                fontWeight: AppTypography.semiBold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                detail!,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
