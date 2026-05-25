import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class MarketSegmentedTabs extends StatelessWidget {
  const MarketSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.padding,
  });

  final TabController controller;
  final List<String> tabs;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;

    return Container(
      margin:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.md,
          ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colors.accentBlue,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: AppTypography.bold,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: AppTypography.semiBold,
          height: 1.2,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: tabs.map((tab) => Tab(height: 36, text: tab)).toList(),
      ),
    );
  }
}

class MarketModalScaffold extends StatelessWidget {
  const MarketModalScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            child,
            if (actions != null) ...[
              const SizedBox(height: AppSpacing.xl),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}
