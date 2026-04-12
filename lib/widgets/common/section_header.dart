import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 섹션 제목 Row — 타이틀 + 선택적 우측 액션
///
/// ```dart
/// SectionHeader(
///   title: '뉴스',
///   trailing: Icon(Icons.chevron_right),
///   onTrailingTap: () => ...,
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.bold,
              color: colors.accentBlue,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
