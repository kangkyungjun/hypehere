import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/market_event.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/empty_state_view.dart';
import '../ticker_detail/ticker_detail_screen.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  late int _year;
  late int _month;
  DateTime? _selectedDate;
  EventCalendarData? _calendarData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_calendarData == null && !_isLoading) {
      _loadCalendar();
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lang = Localizations.localeOf(context).languageCode;
      final data = await _apiClient.getEventCalendar(_year, _month, lang);
      if (mounted) {
        setState(() {
          _calendarData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
      _selectedDate = null;
      _calendarData = null;
    });
    _loadCalendar();
  }

  void _goToNextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _selectedDate = null;
      _calendarData = null;
    });
    _loadCalendar();
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _year = now.year;
      _month = now.month;
      _selectedDate = DateTime(now.year, now.month, now.day);
      _calendarData = null;
    });
    _loadCalendar();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<MarketCalendarEvent> _eventsForDate(DateTime date) {
    if (_calendarData == null) return [];
    return _calendarData!.byDate[_dateKey(date)] ?? [];
  }

  /// Highest importance among events on a date
  String? _highestImportance(DateTime date) {
    final events = _eventsForDate(date);
    if (events.isEmpty) return null;
    if (events.any((e) => e.importance == 'high')) return 'high';
    if (events.any((e) => e.importance == 'medium')) return 'medium';
    return 'low';
  }

  Color _dotColor(String importance) {
    return switch (importance) {
      'high' => context.mlColors.lossColor,
      'medium' => context.mlColors.accentBlue,
      _ => context.mlColors.neutralColor,
    };
  }

  String _monthName(int month, String lang) {
    const monthNamesEn = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthNamesKo = [
      '', '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    const monthNamesZh = [
      '', '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    const monthNamesJa = [
      '', '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    const monthNamesEs = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return switch (lang) {
      'ko' => '$_year년 ${monthNamesKo[month]}',
      'zh' => '$_year年${monthNamesZh[month]}',
      'ja' => '$_year年${monthNamesJa[month]}',
      'es' => '${monthNamesEs[month]} $_year',
      _ => '${monthNamesEn[month]} $_year',
    };
  }

  List<String> _weekdayHeaders(String lang) {
    return switch (lang) {
      'ko' => ['일', '월', '화', '수', '목', '금', '토'],
      'zh' => ['日', '一', '二', '三', '四', '五', '六'],
      'ja' => ['日', '月', '火', '水', '木', '金', '土'],
      'es' => ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'],
      _ => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    };
  }

  String _eventTypeLabel(String eventType, AppLocalizations l10n) {
    return switch (eventType) {
      'fomc' => l10n.eventTypeFomc,
      'fed_speech' => l10n.eventTypeFedSpeech,
      'earnings' => l10n.eventTypeEarnings,
      'economic' => l10n.eventTypeEconomic,
      'options_expiry' => l10n.eventTypeOptionsExpiry,
      'conference' => l10n.eventTypeConference,
      'dividend' => l10n.eventTypeDividend,
      'product_launch' => l10n.eventTypeProductLaunch,
      'shareholder' => l10n.eventTypeShareholder,
      _ => eventType,
    };
  }

  void _onEventTap(MarketCalendarEvent event) {
    if (event.eventType == 'earnings' && event.ticker != null && event.ticker!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TickerDetailScreen(ticker: event.ticker!),
        ),
      );
    } else if (event.description != null && event.description!.isNotEmpty) {
      _showEventDetail(event);
    }
  }

  void _showEventDetail(MarketCalendarEvent event) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            top: AppSpacing.xxl,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(event.icon, color: event.color, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(fontSize: AppTypography.headlineMedium, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      _eventTypeLabel(event.eventType, l10n),
                      style: TextStyle(fontSize: AppTypography.caption, color: event.color, fontWeight: AppTypography.semiBold),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    event.date,
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary),
                  ),
                  if (event.importance == 'high') ...[
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.mlColors.lossColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'HIGH',
                        style: TextStyle(fontSize: AppTypography.micro, color: context.mlColors.lossColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  event.description!,
                  style: TextStyle(fontSize: AppTypography.bodyLarge, color: context.mlColors.textPrimary, height: 1.5),
                ),
              ],
              if (event.ticker != null && event.ticker!.isNotEmpty) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TickerDetailScreen(ticker: event.ticker!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(event.ticker!),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return RefreshIndicator(
      onRefresh: _loadCalendar,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom + 70,
        ),
        children: [
          // Month navigation
          _buildMonthNavigation(lang, l10n, today),
          const SizedBox(height: AppSpacing.md),
          // Calendar grid
          _buildCalendarGrid(lang, today),
          const SizedBox(height: AppSpacing.lg),
          // Event list for selected date
          _buildEventList(l10n),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(String lang, AppLocalizations l10n, DateTime today) {
    final isCurrentMonth = _year == today.year && _month == today.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: l10n.tooltipPreviousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: _goToPreviousMonth,
          visualDensity: VisualDensity.compact,
        ),
        GestureDetector(
          onTap: isCurrentMonth ? null : _goToToday,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _monthName(_month, lang),
                style: const TextStyle(fontSize: AppTypography.headlineLarge, fontWeight: FontWeight.bold),
              ),
              if (_calendarData != null && _calendarData!.totalCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.mlColors.subtleBorder,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    '${_calendarData!.totalCount}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: context.mlColors.textSecondary,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ],
              if (!isCurrentMonth) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    l10n.today,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.tooltipNextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: _goToNextMonth,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(String lang, DateTime today) {
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    final headers = _weekdayHeaders(lang);

    return Column(
      children: [
        // Weekday headers
        Row(
          children: headers.map((h) {
            final isSunday = h == headers[0];
            final isSaturday = h == headers[6];
            return Expanded(
              child: Center(
                child: Text(
                  h,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: isSunday
                        ? const Color(0xFFE53935)
                        : isSaturday
                            ? context.mlColors.accentBlue
                            : context.mlColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Day cells
        ..._buildWeekRows(startWeekday, daysInMonth, today),
      ],
    );
  }

  List<Widget> _buildWeekRows(int startWeekday, int daysInMonth, DateTime today) {
    final rows = <Widget>[];
    int dayCounter = 1;

    // Calculate total cells needed
    final totalCells = startWeekday + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    for (int row = 0; row < totalRows; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startWeekday || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 44)));
        } else {
          final day = dayCounter;
          final date = DateTime(_year, _month, day);
          final isToday = date == today;
          final isSelected = _selectedDate != null && date == _selectedDate;
          final importance = _highestImportance(date);

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: isToday
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: AppTypography.bodyMedium,
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Theme.of(context).colorScheme.onPrimary
                                : col == 0
                                    ? const Color(0xFFE53935)
                                    : col == 6
                                        ? context.mlColors.accentBlue
                                        : null,
                          ),
                        ),
                      ),
                      if (importance != null)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _dotColor(importance),
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }

  static const _economicTypes = {'economic', 'fomc', 'fed_speech'};

  Widget _buildEventList(AppLocalizations l10n) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 40, color: context.mlColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(color: context.mlColors.textSecondary, fontSize: AppTypography.bodyMedium)),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: _loadCalendar, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // Collect events to display
    List<MarketCalendarEvent> allEvents;
    String? headerDate;

    if (_selectedDate == null) {
      final totalCount = _calendarData?.totalCount ?? 0;
      if (totalCount == 0) {
        return EmptyStateView(
          icon: Icons.event_busy,
          message: l10n.noEventsThisMonth,
        );
      }
      final sortedDates = _calendarData!.byDate.keys.toList()..sort();
      allEvents = sortedDates.expand((d) => _calendarData!.byDate[d]!).toList();
    } else {
      allEvents = _eventsForDate(_selectedDate!);
      headerDate = _dateKey(_selectedDate!);
    }

    if (allEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available, size: 40, color: context.mlColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.noEventsSelectedDay,
                style: TextStyle(color: context.mlColors.textSecondary, fontSize: AppTypography.bodyLarge),
              ),
            ],
          ),
        ),
      );
    }

    // Split into two categories
    final newsEvents = allEvents.where((e) => !_economicTypes.contains(e.eventType)).toList();
    final econEvents = allEvents.where((e) => _economicTypes.contains(e.eventType)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerDate != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(headerDate, style: const TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold)),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.nEvents(allEvents.length),
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Text(l10n.nEvents(allEvents.length),
                style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary, fontWeight: AppTypography.medium)),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - News/Announcements
              Expanded(
                child: _buildEventColumn(
                  l10n.calendarNewsAnnouncements,
                  Icons.campaign,
                  const Color(0xFF43A047),
                  newsEvents,
                  l10n,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right column - US Economic Indicators
              Expanded(
                child: _buildEventColumn(
                  l10n.calendarEconomicIndicators,
                  Icons.show_chart,
                  context.mlColors.accentBlue,
                  econEvents,
                  l10n,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventColumn(
    String title,
    IconData icon,
    Color headerColor,
    List<MarketCalendarEvent> events,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.mlColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 13, color: headerColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: AppTypography.caption, fontWeight: AppTypography.bold, color: headerColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${events.length}',
                  style: TextStyle(fontSize: AppTypography.micro, color: headerColor, fontWeight: AppTypography.semiBold),
                ),
              ],
            ),
          ),
          // Event items
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text('—', style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textTertiary)),
              ),
            )
          else
            ...events.map((event) => _buildCompactEventItem(event, l10n)),
        ],
      ),
    );
  }

  Widget _buildCompactEventItem(MarketCalendarEvent event, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _onEventTap(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color dot
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: event.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: AppTypography.caption, fontWeight: AppTypography.medium, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        event.date.substring(5),
                        style: TextStyle(fontSize: AppTypography.chartLabel, color: context.mlColors.textTertiary),
                      ),
                      if (event.ticker != null) ...[
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            event.ticker!,
                            style: TextStyle(
                              fontSize: AppTypography.chartLabel,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: AppTypography.medium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (event.importance == 'high') ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: context.mlColors.lossColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xxs),
                          ),
                          child: Text(
                            '!',
                            style: TextStyle(fontSize: AppTypography.chartMicro, color: context.mlColors.lossColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
