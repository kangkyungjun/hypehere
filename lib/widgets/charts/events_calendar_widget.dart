import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'earnings_chart_widget.dart';
import '../common/ml_expandable_card.dart';

/// Upcoming Events card widget (earnings date, dividends, estimates)
///
/// Shows D-Day countdown with 5-level urgency color coding:
/// - imminent (D-0 or past): Red with pulse animation
/// - urgent (D-1~3): Red
/// - soon (D-4~7): Orange
/// - upcoming (D-8~14): Yellow/Amber
/// - scheduled (D-15+): Green
///
/// Tapping the card opens a modal bottom sheet with:
/// - Full schedule details
/// - Recent earnings list (up to 4 quarters)
/// - Earnings history bar chart
class EventsCalendarWidget extends StatefulWidget {
  final TickerCalendar calendar;
  final List<EarningsHistoryEntry>? earningsHistory;

  const EventsCalendarWidget({
    super.key,
    required this.calendar,
    this.earningsHistory,
  });

  @override
  State<EventsCalendarWidget> createState() => _EventsCalendarWidgetState();
}

class _EventsCalendarWidgetState extends State<EventsCalendarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDuration.slowest,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Only animate for imminent urgency
    if (widget.calendar.urgency == 'imminent') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EventsCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.calendar.urgency == 'imminent') {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calendar = widget.calendar;

    // Nothing meaningful to show
    if (calendar.nextEarningsDate == null &&
        calendar.exDividendDate == null &&
        calendar.dividendDate == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showDetailModal(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with chevron
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.keyEvents,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: context.mlColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Next Earnings Date
            if (calendar.nextEarningsDate != null) ...[
              _buildEarningsRow(calendar),

              // Earnings estimate
              if (calendar.earningsEstimate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                  child: Text(
                    _formatEstimate(calendar.earningsEstimate!),
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary),
                  ),
                ),
              ],

              // Revenue estimate
              if (calendar.revenueEstimate != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                  child: Text(
                    _formatRevenueEstimate(calendar.revenueEstimate!),
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
            ],

            // Ex-Dividend Date
            if (calendar.exDividendDate != null)
              _buildEventRow(
                icon: Icons.payments_outlined,
                label: l10n.exDividendDate,
                date: calendar.exDividendDate!,
              ),

            // Dividend Date
            if (calendar.dividendDate != null) ...[
              if (calendar.exDividendDate != null) const SizedBox(height: AppSpacing.md),
              _buildEventRow(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.dividendPayDate,
                date: calendar.dividendDate!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal
  // ---------------------------------------------------------------------------

  void _showDetailModal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calendar = widget.calendar;
    final earnings = widget.earningsHistory;

    // Filter reported earnings (up to 4 most recent quarters)
    final recentEarnings = earnings
            ?.where((e) => e.reportedEps != null)
            .toList() ??
        [];
    // Keep last 4 quarters max
    final displayEarnings = recentEarnings.length > 4
        ? recentEarnings.sublist(recentEarnings.length - 4)
        : recentEarnings;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg + MediaQuery.of(ctx).viewPadding.bottom,
            ),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.mlColors.textTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                l10n.eventDetails,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Upcoming Schedule ---
              _buildSectionLabel(ctx, l10n.upcomingEvents),
              const SizedBox(height: AppSpacing.lg),

              // Earnings
              if (calendar.nextEarningsDate != null) ...[
                _buildModalEarningsRow(ctx, calendar),
                if (calendar.earningsEstimate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                    child: Text(
                      _formatEstimate(calendar.earningsEstimate!),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: ctx.mlColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (calendar.revenueEstimate != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xxxl),
                    child: Text(
                      _formatRevenueEstimate(calendar.revenueEstimate!),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: ctx.mlColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],

              // Ex-dividend
              if (calendar.exDividendDate != null) ...[
                _buildModalEventRow(
                  ctx,
                  icon: Icons.payments_outlined,
                  label: l10n.exDividendDate,
                  date: calendar.exDividendDate!,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Dividend pay
              if (calendar.dividendDate != null)
                _buildModalEventRow(
                  ctx,
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.dividendPayDate,
                  date: calendar.dividendDate!,
                ),

              // --- Recent Earnings ---
              if (displayEarnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _buildSectionLabel(ctx, l10n.recentEarningsQuarters(displayEarnings.length)),
                const SizedBox(height: AppSpacing.lg),
                ...displayEarnings.reversed.map(
                  (e) => _buildRecentEarningsRow(ctx, e),
                ),
              ],

              // --- Earnings History Chart ---
              if (earnings != null && earnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _buildSectionLabel(ctx, l10n.earningsHistoryChart),
                const SizedBox(height: AppSpacing.lg),
                EarningsChartWidget(
                  earningsHistory: earnings,
                  margin: EdgeInsets.zero,
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal helper widgets
  // ---------------------------------------------------------------------------

  /// 두 파일에 한 글자도 다르지 않게 복붙돼 있던 헬퍼 — 프리미티브로 수렴.
  Widget _buildSectionLabel(BuildContext ctx, String text) =>
      MlCardSectionLabel(text);

  Widget _buildModalEarningsRow(BuildContext ctx, TickerCalendar calendar) {
    String dateDisplay = calendar.nextEarningsDate!;
    if (calendar.nextEarningsDateEnd != null &&
        calendar.nextEarningsDateEnd != calendar.nextEarningsDate) {
      final start = _formatShortDate(calendar.nextEarningsDate!);
      final end = _formatShortDate(calendar.nextEarningsDateEnd!);
      dateDisplay = '$start ~ $end';
    } else {
      dateDisplay = _formatShortDate(calendar.nextEarningsDate!);
    }

    final dDay = calendar.dDay ?? calendar.earningsDaysRemaining;

    return Row(
      children: [
        Icon(Icons.bar_chart, size: 18, color: ctx.mlColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          AppLocalizations.of(ctx).nextEarningsDate,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium),
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildConfirmedIcon(calendar.earningsConfirmed),
        const Spacer(),
        Text(
          dateDisplay,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold),
        ),
        if (dDay != null) ...[
          const SizedBox(width: AppSpacing.md),
          _buildUrgencyBadge(dDay, calendar.urgency),
        ],
      ],
    );
  }

  Widget _buildModalEventRow(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String date,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ctx.mlColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium),
        ),
        const Spacer(),
        Text(
          _formatShortDate(date),
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold),
        ),
      ],
    );
  }

  Widget _buildRecentEarningsRow(BuildContext ctx, EarningsHistoryEntry entry) {
    final dateParts = entry.date.split('-');
    String dateLabel = entry.date;
    if (dateParts.length >= 2) {
      dateLabel = '${dateParts[0]}-${dateParts[1]}';
    }

    final beat = entry.isBeat;
    final surpriseColor = beat ? ctx.mlColors.gainColor : ctx.mlColors.lossColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + actual EPS
          Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: AppTypography.semiBold,
                  color: ctx.mlColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'EPS \$${entry.reportedEps!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          // Estimate + surprise %
          Row(
            children: [
              Text(
                AppLocalizations.of(ctx).epsEstimateValue((entry.epsEstimate ?? 0).toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: ctx.mlColors.textSecondary,
                ),
              ),
              if (entry.surprisePct != null) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${entry.surprisePct! >= 0 ? '+' : ''}${entry.surprisePct!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.bold,
                    color: surpriseColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  beat ? '\u{1F7E2}' : '\u{1F534}',
                  style: const TextStyle(fontSize: AppTypography.micro),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: Theme.of(ctx).dividerColor.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card helper widgets (existing)
  // ---------------------------------------------------------------------------

  /// Build earnings row with D-Day badge, confirmed status, and date range
  Widget _buildEarningsRow(TickerCalendar calendar) {
    // Build date display string
    String dateDisplay = calendar.nextEarningsDate!;
    if (calendar.nextEarningsDateEnd != null &&
        calendar.nextEarningsDateEnd != calendar.nextEarningsDate) {
      // Show date range: "2/15 ~ 2/17"
      final start = _formatShortDate(calendar.nextEarningsDate!);
      final end = _formatShortDate(calendar.nextEarningsDateEnd!);
      dateDisplay = '$start ~ $end';
    } else {
      dateDisplay = _formatShortDate(calendar.nextEarningsDate!);
    }

    // Use d_day from server, fall back to earningsDaysRemaining
    final dDay = calendar.dDay ?? calendar.earningsDaysRemaining;

    return Row(
      children: [
        Icon(Icons.bar_chart, size: 18, color: context.mlColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          AppLocalizations.of(context).nextEarningsDate,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium),
        ),

        // Confirmed/tentative indicator
        const SizedBox(width: AppSpacing.xs),
        _buildConfirmedIcon(calendar.earningsConfirmed),

        const Spacer(),
        Text(
          dateDisplay,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold),
        ),
        if (dDay != null) ...[
          const SizedBox(width: AppSpacing.md),
          _buildUrgencyBadge(dDay, calendar.urgency),
        ],
      ],
    );
  }

  /// Build confirmed/tentative indicator icon
  Widget _buildConfirmedIcon(bool? confirmed) {
    if (confirmed == true) {
      return Tooltip(
        message: AppLocalizations.of(context).earningsConfirmed,
        child: Icon(Icons.check_circle, size: 14, color: context.mlColors.gainColor),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 14, color: context.mlColors.warningColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '(TBD)',
            style: TextStyle(fontSize: AppTypography.micro, color: context.mlColors.warningColor),
          ),
        ],
      );
    }
  }

  /// Build 5-level urgency D-Day badge
  Widget _buildUrgencyBadge(int days, String? urgency) {
    final (bgColor, textColor) = _getUrgencyColors(urgency ?? _fallbackUrgency(days));

    final String label = days <= 0 ? 'D-Day' : 'D-$days';

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: AppTypography.bold,
          color: textColor,
        ),
      ),
    );

    // Pulse animation for imminent
    if (urgency == 'imminent' || (urgency == null && days <= 0)) {
      badge = FadeTransition(
        opacity: _pulseAnimation,
        child: badge,
      );
    }

    return badge;
  }

  /// Get colors for urgency level
  (Color, Color) _getUrgencyColors(String urgency) {
    switch (urgency) {
      case 'imminent':
        return (context.mlColors.lossBg, context.mlColors.lossColor);
      case 'urgent':
        return (context.mlColors.lossBg, context.mlColors.lossColor);
      case 'soon':
        return (context.mlColors.warningBg, context.mlColors.warningColor);
      case 'upcoming':
        return (context.mlColors.warningBg, context.mlColors.warningColor);
      case 'scheduled':
      default:
        return (context.mlColors.gainBg, context.mlColors.gainColor);
    }
  }

  /// Fallback urgency computation when server doesn't provide it
  String _fallbackUrgency(int days) {
    if (days <= 0) return 'imminent';
    if (days <= 3) return 'urgent';
    if (days <= 7) return 'soon';
    if (days <= 14) return 'upcoming';
    return 'scheduled';
  }

  Widget _buildEventRow({
    required IconData icon,
    required String label,
    required String date,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.mlColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.medium),
        ),
        const Spacer(),
        Text(
          _formatShortDate(date),
          style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold),
        ),
      ],
    );
  }

  /// Format YYYY-MM-DD to shorter display (M/D)
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

  String _formatEstimate(Map<String, double?> est) {
    final l10n = AppLocalizations.of(context);
    final low = est['low'];
    final high = est['high'];
    final avg = est['avg'];

    if (avg == null) return '';

    final parts = <String>[l10n.epsEstimateLabel];
    if (low != null && high != null) {
      parts.add('\$${low.toStringAsFixed(2)} ~ \$${high.toStringAsFixed(2)}');
      parts.add('(${l10n.averageLabel} \$${avg.toStringAsFixed(2)})');
    } else {
      parts.add('\$${avg.toStringAsFixed(2)}');
    }

    return parts.join(' ');
  }

  String _formatRevenueEstimate(Map<String, double?> est) {
    final avg = est['avg'];
    if (avg == null) return '';

    // Revenue is typically in billions
    String formatRevenue(double val) {
      if (val >= 1e9) return '\$${(val / 1e9).toStringAsFixed(1)}B';
      if (val >= 1e6) return '\$${(val / 1e6).toStringAsFixed(0)}M';
      return '\$${val.toStringAsFixed(0)}';
    }

    final low = est['low'];
    final high = est['high'];

    final l10n = AppLocalizations.of(context);
    if (low != null && high != null) {
      return '${l10n.revenueEstimateLabel} ${formatRevenue(low)} ~ ${formatRevenue(high)} (${l10n.averageLabel} ${formatRevenue(avg)})';
    }
    return '${l10n.revenueEstimateLabel} ${formatRevenue(avg)}';
  }
}
