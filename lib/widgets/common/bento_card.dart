import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Reusable surface card wrapper for dense financial content.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final radius = BorderRadius.circular(AppRadius.card);

    return Container(
      margin: margin,
      child: Material(
        color: mlc.cardBackground,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: mlc.subtleBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
