import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/earnings_data.dart';
import '../../screens/earnings/earnings_calendar_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 대시보드용 이번 주 실적 발표 컴팩트 카드
///
/// "이번 주 실적 N건" + 오늘/내일 발표 종목 미리보기 (최대 3개)
/// "전체보기" 탭 → EarningsCalendarScreen 이동
class EarningsWeekCard extends StatelessWidget {
  final EarningsUpcomingData data;
  final void Function(String ticker)? onTickerTap;

  const EarningsWeekCard({
    super.key,
    required this.data,
    this.onTickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (data.totalCount == 0) return const SizedBox.shrink();

    // Get nearest 3 events from all dates (sorted chronologically)
    final sortedDates = data.byDate.keys.toList()..sort();
    final previewEvents = <EarningsWeekEvent>[];
    for (final date in sortedDates) {
      if (previewEvents.length >= 3) break;
      previewEvents.addAll(data.byDate[date]!);
    }
    final preview = previewEvents.take(3).toList();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, 0),
            child: Row(
              children: [
                Icon(Icons.event_note, size: 20, color: context.mlColors.accentBlue),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.thisWeekEarnings,
                  style: TextStyle(
                    fontSize: AppTypography.headlineSmall,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: context.mlColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    l10n.earningsCount(data.totalCount),
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      fontWeight: FontWeight.bold,
                      color: context.mlColors.accentBlue,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EarningsCalendarScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewAll,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: context.mlColors.accentBlue,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: context.mlColors.accentBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Preview list
          if (preview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...preview.map((event) => _buildPreviewItem(context, event)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
    );
  }

  Widget _buildPreviewItem(BuildContext context, EarningsWeekEvent event) {
    final l10n = AppLocalizations.of(context);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = event.earningsDate == today;

    return InkWell(
      onTap: () => onTickerTap?.call(event.ticker),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Previous surprise badge
            Container(
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: event.surpriseColor(context.mlColors).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.previousEarnings,
                    style: TextStyle(
                      fontSize: AppTypography.chartMicro,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    event.surpriseLabel,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      fontWeight: FontWeight.bold,
                      color: event.surpriseColor(context.mlColors),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Ticker
            Text(
              event.ticker,
              style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name
            Expanded(
              child: Text(
                event.displayNameLocalized(Localizations.localeOf(context).languageCode),
                style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Today badge or date
            if (isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: context.mlColors.lossBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: AppTypography.chartLabel,
                    fontWeight: FontWeight.bold,
                    color: context.mlColors.lossColor,
                  ),
                ),
              )
            else
              Text(
                _formatShortDate(event.earningsDate),
                style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }

  String _formatShortDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '$month/$day';
      }
    } catch (_) {}
    return dateStr;
  }
}
