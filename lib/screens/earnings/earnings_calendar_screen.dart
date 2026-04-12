import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/earnings_data.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../utils/score_mapper.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/empty_state_view.dart';

/// 이번 주 실적 발표 일정 화면
///
/// 날짜별 그룹핑하여 종목 카드 리스트로 표시.
/// Pull-to-refresh 지원. 종목 탭 → TickerDetailScreen.
class EarningsCalendarScreen extends StatefulWidget {
  const EarningsCalendarScreen({super.key});

  @override
  State<EarningsCalendarScreen> createState() => _EarningsCalendarScreenState();
}

class _EarningsCalendarScreenState extends State<EarningsCalendarScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  EarningsUpcomingData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.getUpcomingEarnings(days: 7);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.thisWeekEarnings),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateView(
        message: l10n.cannotLoadData,
        onRetry: _loadData,
        retryLabel: l10n.retry,
      );
    }

    if (_data == null || _data!.totalCount == 0) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          EmptyStateView(
            icon: Icons.event_available,
            message: l10n.noEarningsThisWeek,
            iconSize: 64,
          ),
        ],
      );
    }

    // Sort dates
    final sortedDates = _data!.byDate.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final events = _data!.byDate[dateStr]!;
        return _buildDateSection(dateStr, events);
      },
    );
  }

  Widget _buildDateSection(String dateStr, List<EarningsWeekEvent> events) {
    final dayLabel = _formatDayHeader(dateStr);
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isToday ? context.mlColors.accentBlue.withValues(alpha: 0.1) : context.mlColors.sectionBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isToday ? context.mlColors.accentBlue : context.mlColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: AppTypography.headlineSmall,
                  fontWeight: FontWeight.bold,
                  color: isToday ? context.mlColors.accentBlue : context.mlColors.textPrimary,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: context.mlColors.accentBlue,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'TODAY',
                    style: TextStyle(
                      color: context.mlColors.onPrimary,
                      fontSize: AppTypography.micro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                AppLocalizations.of(context).nItems(events.length),
                style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.textSecondary),
              ),
            ],
          ),
        ),

        // Event cards
        for (int i = 0; i < events.length; i++)
          _buildEventCard(events[i], isLast: i == events.length - 1),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildEventCard(EarningsWeekEvent event, {bool isLast = false}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TickerDetailScreen(ticker: event.ticker),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                // Previous surprise badge
                Container(
                  width: 52,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.surpriseColor(context.mlColors).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.previousEarnings,
                        style: TextStyle(
                          fontSize: AppTypography.chartMicro,
                          color: context.mlColors.textSecondary,
                        ),
                      ),
                      Text(
                        event.surpriseLabel,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.bold,
                          color: event.surpriseColor(context.mlColors),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // Ticker info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.ticker,
                            style: const TextStyle(
                              fontSize: AppTypography.headlineSmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              event.displayNameLocalized(Localizations.localeOf(context).languageCode),
                              style: TextStyle(
                                fontSize: AppTypography.bodySmall,
                                color: context.mlColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildInfoRow(event),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, color: context.mlColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  Widget _buildInfoRow(EarningsWeekEvent event) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    // Score label
    if (event.score != null) {
      final label = ScoreMapper.getScoreLabelLocalized(event.score!, l10n);
      final color = ScoreMapper.getScoreColor(event.score!, context.mlColors);
      chips.add(Text(
        '$label(${event.score!.toStringAsFixed(1)})',
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: color,
          fontWeight: AppTypography.medium,
        ),
      ));
    }

    // EPS estimate
    if (event.epsEstimateAvg != null) {
      if (chips.isNotEmpty) {
        chips.add(Text(
          ' · ',
          style: TextStyle(fontSize: AppTypography.caption, color: context.mlColors.textTertiary),
        ));
      }
      chips.add(Text(
        '${l10n.epsEstimateLabel} \$${event.epsEstimateAvg!.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: AppTypography.caption,
          color: context.mlColors.textSecondary,
        ),
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: chips);
  }

  String _formatDayHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final l10n = AppLocalizations.of(context);
      final weekdays = [
        l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed,
        l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun,
      ];
      final weekday = weekdays[date.weekday - 1];
      return '${date.month}/${date.day} ($weekday)';
    } catch (_) {
      return dateStr;
    }
  }
}
