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

    final borderColor = mlc.subtleBorder.withValues(alpha: emphasized ? 0 : 1);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: emphasized ? AppShadow.sm(Colors.black) : null,
      ),
      child: Material(
        color: mlc.cardBackground,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
