import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_filter.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/news/news_filter_sheet.dart';
import '../calendar/event_calendar_screen.dart';
import 'news_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/market_segmented_tabs.dart';

/// Combined News screen with internal tabs: Calendar | News
///
/// Reuses WatchlistScreen's TabBar+TabBarView pattern.
/// - Tab 0: EventCalendarScreen (existing)
/// - Tab 1: NewsListScreen(embedded: true) with filter support
/// - Category chip bar (전체/Biz/World/관심종목) when news tab is active
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

  void _onCategoryChanged(NewsCategory category) {
    setState(() {
      _filterState = _filterState.copyWith(category: category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MarketSegmentedTabs(
                controller: _tabController,
                tabs: [l10n.tabCalendar, l10n.tabNews],
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  _isNewsTab ? AppSpacing.sm : AppSpacing.xl,
                  AppSpacing.xs,
                ),
              ),
            ),
            if (_isNewsTab)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xl),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.mlColors.infoBg.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _openFilterSheet,
                    tooltip: l10n.newsFilter,
                    icon: Badge(
                      isLabelVisible: _filterState.isActive,
                      smallSize: 8,
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: _filterState.isActive
                            ? context.mlColors.accentBlue
                            : context.mlColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Category chip bar (only visible on News tab)
        if (_isNewsTab) _buildCategoryChips(context, l10n),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const EventCalendarScreen(),
              NewsListScreen(embedded: true, filterState: _filterState),
            ],
          ),
        ),
        // Shared banner ad at the bottom of both Calendar/News tabs
        // 하단 여백을 더 줘서 플로팅 탭바(extendBody)에 가리지 않도록
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.xs + 64,
            ),
            child: Center(child: BannerAdWidget()),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context, AppLocalizations l10n) {
    final watchlist = context.watch<WatchlistProvider>().watchlist;
    final options = [
      (NewsCategory.all, l10n.filterAll),
      (NewsCategory.biz, 'Biz'),
      (NewsCategory.world, 'World'),
      (NewsCategory.watchlist, l10n.filterMyWatchlist),
    ];

    final colors = context.mlColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((opt) {
            final isSelected = _filterState.category == opt.$1;
            final isDisabled =
                opt.$1 == NewsCategory.watchlist && watchlist.isEmpty;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: GestureDetector(
                onTap: isDisabled ? null : () => _onCategoryChanged(opt.$1),
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.infoBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      border: Border.all(
                        color: isSelected
                            ? colors.accentBlue.withValues(alpha: 0.28)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.semiBold,
                        color: isSelected
                            ? colors.accentBlue
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
