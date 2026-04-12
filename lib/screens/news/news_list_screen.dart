import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_data.dart';
import '../../models/news_filter.dart';
import '../../utils/multilingual.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/news/market_news_modal.dart';
import '../../widgets/news/hot_topic_toast.dart';
import '../../widgets/news/mention_bubble_card.dart';
import '../../models/mention_bubble_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/watchlist_provider.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/empty_state_view.dart';

/// Full news list screen with infinite scroll and date grouping.
///
/// - Date separators ("오늘 2/21 금", "어제 2/20 목")
/// - Timeline layout (dot + vertical line)
/// - Banner ad every 15 news items
/// - Tap item → TickerDetailScreen
/// - Filter support via [filterState]
/// - Hot topic toast overlay
class NewsListScreen extends StatefulWidget {
  final bool embedded;
  final NewsFilterState filterState;

  const NewsListScreen({
    super.key,
    this.embedded = false,
    this.filterState = const NewsFilterState(),
  });

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  final ScrollController _scrollController = ScrollController();

  final List<NewsItem> _items = [];
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // Hot topics
  List<NewsItem> _hotTopics = [];
  bool _hotTopicDismissed = false;

  // Mention bubble
  MentionBubbleData? _mentionBubble;

  // Track current filter to detect changes
  late NewsFilterState _currentFilter;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filterState;
    _scrollController.addListener(_onScroll);
    _loadInitial();
    _loadHotTopics();
    _loadMentionBubble();
  }

  @override
  void didUpdateWidget(NewsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when filter changes
    if (widget.filterState != _currentFilter) {
      _currentFilter = widget.filterState;
      _items.clear();
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Build API filter parameters from current filter state
  ({String? tickers, String? sentiment, String? sectors, bool? isBreaking})
      _buildFilterParams() {
    final f = widget.filterState;
    String? tickers;
    String? sentiment;
    String? sectors;
    bool? isBreaking;

    // Source filter
    if (f.sourceFilter == NewsSourceFilter.watchlist) {
      final wl = context.read<WatchlistProvider>().watchlist;
      if (wl.isNotEmpty) {
        tickers = wl.join(',');
      }
    } else if (f.sourceFilter == NewsSourceFilter.marketOnly) {
      tickers = 'MARKET';
    }

    // Sentiment filter
    if (f.sentimentGrades.isNotEmpty) {
      sentiment = f.sentimentGrades.join(',');
    }

    // Sector filter
    if (f.sectors.isNotEmpty) {
      sectors = f.sectors.join(',');
    }

    // Breaking only
    if (f.breakingOnly) {
      isBreaking = true;
    }

    return (
      tickers: tickers,
      sentiment: sentiment,
      sectors: sectors,
      isBreaking: isBreaking,
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = _buildFilterParams();
      final data = await _apiClient.getNewsList(
        limit: _pageSize,
        offset: 0,
        tickers: params.tickers,
        sentiment: params.sentiment,
        sectors: params.sectors,
        isBreaking: params.isBreaking,
      );
      if (!mounted) return;
      setState(() {
        _items.clear();
        _items.addAll(data.items);
        _total = data.total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _items.length >= _total) return;

    setState(() => _isLoadingMore = true);

    try {
      final params = _buildFilterParams();
      final data = await _apiClient.getNewsList(
        limit: _pageSize,
        offset: _items.length,
        tickers: params.tickers,
        sentiment: params.sentiment,
        sectors: params.sectors,
        isBreaking: params.isBreaking,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(data.items);
        _total = data.total;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadHotTopics() async {
    try {
      final data = await _apiClient.getHotTopics(limit: 5);
      if (data.items.isNotEmpty && mounted) {
        setState(() => _hotTopics = data.items);
      }
    } catch (_) {
      // Silently fail — toast is optional
    }
  }

  Future<void> _loadMentionBubble() async {
    try {
      final data = await _apiClient.getMentionBubble();
      if (data.items.isNotEmpty && mounted) {
        setState(() => _mentionBubble = data);
      }
    } catch (_) {
      // Silently fail — bubble is optional
    }
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketNews),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: _loadInitial,
        retryLabel: l10n.retry,
      );
    }

    if (_items.isEmpty) {
      return EmptyStateView(
        icon: Icons.article_outlined,
        message: l10n.noNewsAvailable,
      );
    }

    final showToast = _hotTopics.isNotEmpty && !_hotTopicDismissed;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadInitial(), _loadHotTopics(), _loadMentionBubble()]);
        _hotTopicDismissed = false;
      },
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              showToast ? 120 : AppSpacing.xl, // Extra top padding when toast visible
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            itemCount: _buildListItemCount(),
            itemBuilder: (context, index) => _buildListItem(index),
          ),
          if (showToast)
            HotTopicToast(
              hotTopics: _hotTopics,
              onDismiss: () => setState(() => _hotTopicDismissed = true),
            ),
        ],
      ),
    );
  }

  bool get _hasBubble => _mentionBubble != null && _mentionBubble!.items.isNotEmpty;

  /// Calculate total item count including bubble card, date headers, and ads
  int _buildListItemCount() {
    int count = _hasBubble ? 1 : 0; // bubble card slot
    String? lastDateGroup;
    int newsIndex = 0;

    for (int i = 0; i < _items.length; i++) {
      final dateGroup = _getDateGroup(_items[i]);
      if (dateGroup != lastDateGroup) {
        count++; // date header
        lastDateGroup = dateGroup;
      }
      count++; // news item
      newsIndex++;

      // Ad banner every 15 news items
      if (newsIndex % 15 == 0 && i != _items.length - 1) {
        count++;
      }
    }

    // Loading indicator at bottom
    if (_isLoadingMore || _items.length < _total) {
      count++;
    }

    return count;
  }

  /// Build item at virtual index (handles bubble, headers, news, ads)
  Widget _buildListItem(int virtualIndex) {
    // Bubble card at index 0
    if (_hasBubble && virtualIndex == 0) {
      return MentionBubbleCard(data: _mentionBubble!);
    }

    // Offset for the bubble card
    final adjusted = _hasBubble ? virtualIndex - 1 : virtualIndex;

    int currentVirtual = 0;
    String? lastDateGroup;
    int newsCount = 0;

    for (int i = 0; i < _items.length; i++) {
      final dateGroup = _getDateGroup(_items[i]);

      // Date header
      if (dateGroup != lastDateGroup) {
        if (currentVirtual == adjusted) {
          return _buildDateHeader(context, _items[i]);
        }
        currentVirtual++;
        lastDateGroup = dateGroup;
      }

      // News item
      if (currentVirtual == adjusted) {
        final isLastInGroup = (i == _items.length - 1) ||
            _getDateGroup(_items[i + 1]) != dateGroup;
        return _buildNewsItem(context, _items[i], isLastInGroup: isLastInGroup);
      }
      currentVirtual++;
      newsCount++;

      // Ad banner every 15 news items
      if (newsCount % 15 == 0 && i != _items.length - 1) {
        if (currentVirtual == adjusted) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: BannerAdWidget(),
          );
        }
        currentVirtual++;
      }
    }

    // Loading indicator
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  String _getDateGroup(NewsItem item) => item.date;

  Widget _buildDateHeader(BuildContext context, NewsItem item) {
    final label = _formatDateLabel(item.date);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.bodyMedium,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatDateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = today.difference(target).inDays;

      final l10n = AppLocalizations.of(context);
      final weekdays = [l10n.weekdayMon, l10n.weekdayTue, l10n.weekdayWed, l10n.weekdayThu, l10n.weekdayFri, l10n.weekdaySat, l10n.weekdaySun];
      final dayLabel = weekdays[date.weekday - 1];
      final formatted = '${date.month}/${date.day} $dayLabel';

      if (diff == 0) return '${l10n.today} · $formatted';
      if (diff == 1) return '${l10n.yesterday} · $formatted';
      if (diff == 2) return '${l10n.dayBeforeYesterday} · $formatted';
      return formatted;
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildNewsItem(BuildContext context, NewsItem item, {required bool isLastInGroup}) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor(context.mlColors);

    final isMarket = MarketNewsModal.isMarketNews(item);

    return InkWell(
      onTap: () => isMarket
          ? MarketNewsModal.show(context, item)
          : _onTickerTap(item.ticker),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLastInGroup)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: context.mlColors.chartGridLine,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: ticker + sentiment + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: isMarket
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              isMarket
                                  ? l10n.marketNews
                                  : (langCode == 'ko' && item.tickerNameKo != null)
                                      ? '${item.ticker} ${item.tickerNameKo}'
                                      : item.ticker,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                fontWeight: FontWeight.bold,
                                color: isMarket
                                    ? context.mlColors.textSecondary
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Breaking badge
                          if (item.isBreaking) ...[
                            const Text('\u{1F6A8}', style: TextStyle(fontSize: AppTypography.bodySmall)),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              item.sentimentLabelLocalized(l10n),
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Sector abbreviation (grey)
                          if (item.sectorShort != null) ...[
                            Text(
                              item.sectorShort!,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            item.timeAgoLocalized(l10n),
                            style: TextStyle(
                              fontSize: AppTypography.micro,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Row 2: AI summary (localized)
                      Text(
                        item.aiSummary.localize(langCode),
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: AppTypography.semiBold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Row 3: source
                      if (item.source != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.source!,
                          style: TextStyle(
                            fontSize: AppTypography.micro,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
