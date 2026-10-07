import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_data.dart';
import '../../models/news_filter.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/news/news_article_row.dart';
import '../../widgets/news/mention_bubble_card.dart';
import '../../widgets/news/bull_bear_bar_card.dart';
import '../../widgets/news/key_news_card.dart';
import '../../models/mention_bubble_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/watchlist_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/empty_state_view.dart';

/// Full news list screen with infinite scroll and date grouping.
///
/// - Date separators ("오늘 2/21 금", "어제 2/20 목")
/// - Timeline layout (dot + vertical line)
/// - Banner ad every 15 news items
/// - Tap item → MarketNewsModal (with original-article / go-to-stock actions)
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

  // Hot topics (data loaded for future use; toast display disabled)
  // ignore: unused_field
  List<NewsItem> _hotTopics = [];

  // Mention bubble
  MentionBubbleData? _mentionBubble;

  // 24h bull/bear sentiment counts + AI key news
  SentimentCounts _sentimentCounts = SentimentCounts();
  List<NewsItem> _keyNews = [];

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
    _loadSentimentCounts();
    _loadKeyNews();
  }

  @override
  void didUpdateWidget(NewsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when filter changes (including category)
    if (widget.filterState != _currentFilter) {
      _currentFilter = widget.filterState;
      _items.clear();
      _loadInitial();
      _loadMentionBubble();
      _loadSentimentCounts();
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
  ({
    String? tickers,
    String? sentiment,
    String? sectors,
    bool? isBreaking,
    bool? excludeMarket,
  })
  _buildFilterParams() {
    final f = widget.filterState;
    String? tickers;
    String? sentiment;
    String? sectors;
    bool? isBreaking;
    bool? excludeMarket;

    // Category filter
    switch (f.category) {
      case NewsCategory.all:
        break;
      case NewsCategory.biz:
        excludeMarket = true;
        break;
      case NewsCategory.world:
        tickers = 'MARKET';
        break;
      case NewsCategory.watchlist:
        final wl = context.read<WatchlistProvider>().watchlist;
        if (wl.isNotEmpty) {
          tickers = wl.join(',');
        }
        break;
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
      excludeMarket: excludeMarket,
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
        excludeMarket: params.excludeMarket,
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
        excludeMarket: params.excludeMarket,
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
      final f = widget.filterState;
      String? sectors = f.sectors.isNotEmpty ? f.sectors.join(',') : null;
      String? tickers;

      if (f.category == NewsCategory.watchlist) {
        final wl = context.read<WatchlistProvider>().watchlist;
        if (wl.isNotEmpty) tickers = wl.join(',');
      }

      final data = await _apiClient.getMentionBubble(
        sectors: sectors,
        tickers: tickers,
      );
      if (mounted) {
        setState(() => _mentionBubble = data.items.isNotEmpty ? data : null);
      }
    } catch (_) {
      // Silently fail — bubble is optional
    }
  }

  Future<void> _loadSentimentCounts() async {
    final params = _buildFilterParams();
    final counts = await _apiClient.getRecentSentimentCounts(
      hours: 24,
      tickers: params.tickers,
      sectors: params.sectors,
      excludeMarket: params.excludeMarket,
      // NOT params.sentiment — bar shows the full mix for the category
    );
    if (mounted) setState(() => _sentimentCounts = counts);
  }

  Future<void> _loadKeyNews() async {
    final items = await _apiClient.getKeyNews(hours: 10, limit: 5);
    if (mounted) setState(() => _keyNews = items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.marketNews)),
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

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadInitial(),
          _loadHotTopics(),
          _loadMentionBubble(),
          _loadSentimentCounts(),
          _loadKeyNews(),
        ]);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          // embedded(뉴스 탭)일 때만 플로팅 탭바 클리어런스, 단독은 자체 Scaffold
          widget.embedded
              ? AppLayout.bottomNavClearanceOf(context)
              : AppSpacing.xl,
        ),
        itemCount: _buildListItemCount(),
        itemBuilder: (context, index) => _buildListItem(index),
      ),
    );
  }

  bool get _hasBubble =>
      _mentionBubble != null && _mentionBubble!.items.isNotEmpty;

  bool get _hasBullBear =>
      (_sentimentCounts.bullish +
          _sentimentCounts.neutral +
          _sentimentCounts.bearish) >
      0;

  bool get _hasKeyNews => _keyNews.isNotEmpty;

  /// Header widgets shown above the news timeline. The banner ad is always
  /// present so it appears even when all cards are hidden.
  List<Widget> _headerWidgets() {
    return [
      if (_hasBubble) MentionBubbleCard(data: _mentionBubble!),
      if (_hasBullBear) BullBearBarCard(counts: _sentimentCounts),
      if (_hasKeyNews) KeyNewsCard(items: _keyNews),
      const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Center(child: BannerAdWidget()),
      ),
    ];
  }

  /// Calculate total item count including header widgets, date headers, and ads
  int _buildListItemCount() {
    int count = _headerWidgets().length;
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

  /// Build item at virtual index (handles header widgets, date headers, news, ads)
  Widget _buildListItem(int virtualIndex) {
    final headers = _headerWidgets();
    if (virtualIndex < headers.length) {
      return headers[virtualIndex];
    }

    // Offset past the header widgets
    final adjusted = virtualIndex - headers.length;

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
        // `isLastInGroup`은 타임라인 세로선 전용이었는데 그 선을 지우면서
        // 쓰이지 않게 됐다(날짜 헤더가 같은 정보를 이미 명시한다).
        return NewsArticleRow(item: _items[i]);
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
    // 그룹 라벨이 콘텐츠보다 크면 안 된다. 개편 전에는 날짜가 `cardTitle`(18)로
    // **헤드라인(16)보다 컸다** — 위계가 역전돼 있었다. 레퍼런스의 `🕐 4일 전`은
    // 작고 뮤트다.
    //
    // 위 여백은 `sectionGap`(20), 아래는 `xs`(4). 비대칭이라 헤더가 아래
    // 콘텐츠에 붙어 한 덩어리가 된다 — 대칭(16/8)일 때는 헤더가 위아래
    // 어디에도 속하지 않아 구간이 안 생겼다.
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDensity.sectionGap,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: context.mlColors.textTertiary,
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
      final weekdays = [
        l10n.weekdayMon,
        l10n.weekdayTue,
        l10n.weekdayWed,
        l10n.weekdayThu,
        l10n.weekdayFri,
        l10n.weekdaySat,
        l10n.weekdaySun,
      ];
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

}
