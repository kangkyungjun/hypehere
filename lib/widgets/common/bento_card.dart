import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';

/// Reusable surface card wrapper for dense financial content.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final radius = BorderRadius.circular(AppRadius.card);

    // 오늘의집 톤: 테두리 없이 부드러운 그림자로 카드를 띄운다.
    // 기본은 옅은 card 그림자, emphasized는 한 단계 강한 md 그림자.
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: emphasized
            ? AppShadow.md(Colors.black)
            : AppShadow.card(Colors.black),
      ),
      child: Material(
        color: mlc.cardBackground,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            // 제목이 위에 바짝 붙지 않도록 top만 살짝 더 (12), 나머지는 타이트(8)
            padding: padding ??
                const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
