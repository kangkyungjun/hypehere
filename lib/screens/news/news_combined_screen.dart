import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_filter.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/news/news_filter_sheet.dart';
import '../calendar/event_calendar_screen.dart';
import 'news_list_screen.dart';
import '../../theme/app_spacing.dart';

/// Combined News screen with internal tabs: Calendar | News
///
/// Reuses WatchlistScreen's TabBar+TabBarView pattern.
/// - Tab 0: EventCalendarScreen (existing)
/// - Tab 1: NewsListScreen(embedded: true) with filter support
class NewsCombinedScreen extends StatefulWidget {
  const NewsCombinedScreen({super.key});

  @override
  State<NewsCombinedScreen> createState() => _NewsCombinedScreenState();
}

class _NewsCombinedScreenState extends State<NewsCombinedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  NewsFilterState _filterState = const NewsFilterState();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isNewsTab => _tabController.index == 1;

  void _openFilterSheet() async {
    final watchlist = context.read<WatchlistProvider>().watchlist;
    final result = await NewsFilterSheet.show(
      context,
      currentState: _filterState,
      watchlistTickers: watchlist,
    );
    if (result != null) {
      setState(() => _filterState = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Material(
          color: theme.colorScheme.surface,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.tabCalendar),
                  Tab(text: l10n.tabNews),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
              ),
              // Filter button (only visible on News tab)
              if (_isNewsTab)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: IconButton(
                    icon: Badge(
                      isLabelVisible: _filterState.isActive,
                      smallSize: 8,
                      child: Icon(
                        Icons.tune,
                        size: 20,
                        color: _filterState.isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: _openFilterSheet,
                    tooltip: l10n.newsFilter,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const EventCalendarScreen(),
              NewsListScreen(
                embedded: true,
                filterState: _filterState,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
