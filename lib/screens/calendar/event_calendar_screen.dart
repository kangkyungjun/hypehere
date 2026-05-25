import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/market_event.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/rewarded_ad_helper.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../ticker_detail/ticker_detail_screen.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  static const _prefKeyAdUnlock = 'calendar_ad_unlock_until';

  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  late int _year;
  late int _month;
  DateTime? _selectedDate;
  EventCalendarData? _calendarData;
  bool _isLoading = false;
  String? _error;
  DateTime? _adUnlockExpiry;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadAdUnlock();
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
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(event.icon, color: event.colorOf(context.mlColors), size: 24),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(fontSize: AppTypography.headlineMedium, fontWeight: AppTypography.bold),
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
                      color: event.colorOf(context.mlColors).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      _eventTypeLabel(event.eventType, l10n),
                      style: TextStyle(fontSize: AppTypography.caption, color: event.colorOf(context.mlColors), fontWeight: AppTypography.semiBold),
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
                        style: TextStyle(fontSize: AppTypography.micro, color: context.mlColors.lossColor, fontWeight: AppTypography.bold),
                      ),
                    ),
                  ],
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  event.description!,
                  style: TextStyle(fontSize: AppTypography.bodyLarge, color: context.mlColors.textPrimary, height: 1.5),
                ),
              ],
              if (event.ticker != null && event.ticker!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
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

  // ── Premium gating helpers ──

  Future<void> _loadAdUnlock() async {
    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final millis = prefs.getInt(_prefKeyAdUnlock);
    if (millis != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(millis);
      if (expiry.isAfter(DateTime.now())) {
        setState(() => _adUnlockExpiry = expiry);
      }
    }
    // Preload ad for non-Gold users
    if (!auth.shouldHideAds) {
      RewardedAdHelper.instance.preloadAd();
    }
  }

  bool _isCalendarUnlocked() {
    final auth = context.read<AuthProvider>();
    if (auth.shouldHideAds) return true;
    return _adUnlockExpiry != null && _adUnlockExpiry!.isAfter(DateTime.now());
  }

  DateTime _cutoffDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 14));
  }

  bool _isEventLocked(MarketCalendarEvent event) {
    final eventDate = DateTime.tryParse(event.date);
    if (eventDate == null) return false;
    return eventDate.isAfter(_cutoffDate());
  }

  Future<void> _onWatchCalendarAd() async {
    final l10n = AppLocalizations.of(context);
    RewardedAdHelper.instance.showAd(
      onRewarded: () async {
        final expiry = DateTime.now().add(const Duration(hours: 6));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefKeyAdUnlock, expiry.millisecondsSinceEpoch);
        if (mounted) {
          setState(() => _adUnlockExpiry = expiry);
        }
      },
      onFailed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.adNotReady)),
          );
        }
      },
    );
  }

  Widget _buildLockedSection(
    List<MarketCalendarEvent> lockedEvents,
    AppLocalizations l10n,
  ) {
    final newsEvents = lockedEvents.where((e) => !_economicTypes.contains(e.eventType)).toList();
    final econEvents = lockedEvents.where((e) => _economicTypes.contains(e.eventType)).toList();

    return Stack(
      children: [
        // Blurred content
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: IgnorePointer(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildEventColumn(
                        l10n.calendarNewsAnnouncements,
                        Icons.campaign,
                        context.mlColors.eventEarningsColor,
                        newsEvents,
                        l10n,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
            ),
          ),
        ),
        // CTA overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 28, color: context.mlColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.calendarPremiumEvents(lockedEvents.length),
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.bold,
                    color: context.mlColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.calendarUnlockWithAd,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: context.mlColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _onWatchCalendarAd,
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: Text(l10n.watchAd),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: AppTypography.bodySmall),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => GoldUpgradeSheet.show(context, source: 'calendar'),
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: Text(l10n.upgradeToGold),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: AppTypography.bodySmall),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
          // Banner ad between calendar and event list
          const Center(child: BannerAdWidget()),
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
      children: [
        // Left: year/month text + count badge + today badge
        Expanded(
          child: GestureDetector(
            onTap: isCurrentMonth ? null : _goToToday,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _monthName(_month, lang),
                  style: TextStyle(fontSize: AppTypography.bodyLarge, fontWeight: AppTypography.bold, color: context.mlColors.textSecondary),
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
                      l10n.nEvents(_calendarData!.totalCount),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
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
        ),
        // Right: calendar picker + prev/next arrows
        IconButton(
          tooltip: l10n.tooltipSelectMonth,
          icon: const Icon(Icons.calendar_month, size: 22),
          onPressed: () => _showYearMonthPicker(lang, l10n),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: l10n.tooltipPreviousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: _goToPreviousMonth,
          visualDensity: VisualDensity.compact,
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

  void _showYearMonthPicker(String lang, AppLocalizations l10n) {
    final now = DateTime.now();
    final minYear = now.year - 5;
    final maxYear = now.year + 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (modalContext) {
        int pickerYear = _year;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final shortMonths = _shortMonthNames(lang);

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xxl,
                right: AppSpacing.xxl,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year selector row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: pickerYear > minYear
                            ? () => setModalState(() => pickerYear--)
                            : null,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '$pickerYear',
                        style: const TextStyle(
                          fontSize: AppTypography.headlineLarge,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: pickerYear < maxYear
                            ? () => setModalState(() => pickerYear++)
                            : null,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Month grid (4 columns x 3 rows)
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.0,
                    children: List.generate(12, (index) {
                      final m = index + 1;
                      final isSelected = pickerYear == _year && m == _month;
                      final isTodayMonth = pickerYear == now.year && m == now.month;
                      final primary = Theme.of(context).colorScheme.primary;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _year = pickerYear;
                            _month = m;
                            _selectedDate = null;
                            _calendarData = null;
                          });
                          Navigator.pop(modalContext);
                          _loadCalendar();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? primary : null,
                            border: (!isSelected && isTodayMonth)
                                ? Border.all(color: primary, width: 1.5)
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            shortMonths[m],
                            style: TextStyle(
                              fontSize: AppTypography.bodyLarge,
                              fontWeight: (isSelected || isTodayMonth)
                                  ? AppTypography.bold
                                  : AppTypography.regular,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  // "Go to today" button - only when not viewing current month
                  if (!(pickerYear == now.year && _month == now.month)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _goToToday();
                        },
                        child: Text(l10n.today),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _shortMonthNames(String lang) {
    return switch (lang) {
      'ko' => ['', '1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
      'zh' => ['', '1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
      'ja' => ['', '1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
      'es' => ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      _ => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    };
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
                        ? context.mlColors.sundayColor
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
                            fontWeight: isToday || isSelected ? AppTypography.bold : AppTypography.regular,
                            color: isToday
                                ? Theme.of(context).colorScheme.onPrimary
                                : col == 0
                                    ? context.mlColors.sundayColor
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
                        const SizedBox(height: AppSpacing.xs),
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

    // Premium gating: split into free / locked events
    final isUnlocked = _isCalendarUnlocked();
    final freeEvents = isUnlocked ? allEvents : allEvents.where((e) => !_isEventLocked(e)).toList();
    final lockedEvents = isUnlocked ? <MarketCalendarEvent>[] : allEvents.where((e) => _isEventLocked(e)).toList();

    // Split free events into two categories
    final newsEvents = freeEvents.where((e) => !_economicTypes.contains(e.eventType)).toList();
    final econEvents = freeEvents.where((e) => _economicTypes.contains(e.eventType)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerDate != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(headerDate, style: TextStyle(fontSize: AppTypography.bodyLarge, fontWeight: AppTypography.bold, color: context.mlColors.textSecondary)),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.nEvents(allEvents.length),
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary)),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(l10n.nEvents(allEvents.length),
                    style: TextStyle(fontSize: AppTypography.bodySmall, color: context.mlColors.textSecondary, fontWeight: AppTypography.medium)),
                if (isUnlocked && _adUnlockExpiry != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.calendarUnlockedUntil(
                      '${_adUnlockExpiry!.hour.toString().padLeft(2, '0')}:${_adUnlockExpiry!.minute.toString().padLeft(2, '0')}',
                    ),
                    style: TextStyle(fontSize: AppTypography.micro, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ],
            ),
          ),
        // Free events two-column layout
        if (freeEvents.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - News/Announcements
                Expanded(
                  child: _buildEventColumn(
                    l10n.calendarNewsAnnouncements,
                    Icons.campaign,
                    context.mlColors.eventEarningsColor,
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
        // Locked events with blur + CTA
        if (lockedEvents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildLockedSection(lockedEvents, l10n),
        ],
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
              decoration: BoxDecoration(color: event.colorOf(context.mlColors), shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Text(
                        event.date.substring(5),
                        style: TextStyle(fontSize: AppTypography.chartLabel, color: context.mlColors.textTertiary),
                      ),
                      if (event.ticker != null) ...[
                        const SizedBox(width: AppSpacing.xxs),
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
                        const SizedBox(width: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: context.mlColors.lossColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xxs),
                          ),
                          child: Text(
                            '!',
                            style: TextStyle(fontSize: AppTypography.chartMicro, color: context.mlColors.lossColor, fontWeight: AppTypography.bold),
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
