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
      // 기본 외곽 여백을 타이트하게(기존 T8/B12 → T4/B4, 좌우 16→12)
      margin:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.infoBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: colors.subtleBorder.withValues(alpha: 0.55),
          ),
        ),
        labelColor: colors.accentBlue,
        unselectedLabelColor: colors.textSecondary,
        // 격리 규칙: 칩·탭 라벨은 `chipLabel`(12)만 쓴다. `bodySmall`을 직접
        // 쓰면 읽기 스케일이 바뀔 때 고정높이 `Tab(height: 32)`가 같이 흔들린다.
        labelStyle: const TextStyle(
          fontSize: AppTypography.chipLabelSize,
          fontWeight: AppTypography.bold,
          height: 1.2,
        ),
        // 비선택을 w500으로 내려 선택(w700)과 2단을 확보한다.
        // w700 ↔ w600은 눈이 구분하지 못한다.
        unselectedLabelStyle: const TextStyle(
          fontSize: AppTypography.chipLabelSize,
          fontWeight: AppTypography.medium,
          height: 1.2,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: tabs.map((tab) => Tab(height: 32, text: tab)).toList(),
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
