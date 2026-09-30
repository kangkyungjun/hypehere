import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/news_data.dart';
import '../../models/news_filter.dart';
import '../../utils/multilingual.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/news/market_news_modal.dart';
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
              ? MediaQuery.of(context).viewPadding.bottom +
                    AppLayout.bottomNavClearance
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
        final isLastInGroup =
            (i == _items.length - 1) ||
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

  Widget _buildNewsItem(
    BuildContext context,
    NewsItem item, {
    required bool isLastInGroup,
  }) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor(context.mlColors);
    final mlc = context.mlColors;

    final isMarket = MarketNewsModal.isMarketNews(item);

    // 메타 4종(감정·출처·섹터·시간)을 한 줄 11px로 합친다.
    // 개편 전에는 이 넷이 전부 13px이었고 그중 둘(티커·감정)은 굵기까지
    // w700으로 같았다 — 한 행에 13px이 다섯 개. 사용자가 말한 "다닥다닥"의
    // 기계적 정체다. 감정 라벨은 **지우지 않는다**: 점 색만 남기면 색맹
    // 사용자에게 단서가 사라진다. pill 배경만 걷고 색 + 텍스트 2중 인코딩을 유지한다.
    final meta = <TextSpan>[
      TextSpan(
        text: item.sentimentLabelLocalized(l10n),
        style: TextStyle(color: dotColor, fontWeight: AppTypography.semiBold),
      ),
      if (item.source != null) TextSpan(text: '  ·  ${item.source!}'),
      if (item.sectorShort != null) TextSpan(text: '  ·  ${item.sectorShort!}'),
      TextSpan(text: '  ·  ${item.timeAgoLocalized(l10n)}'),
    ];

    return InkWell(
      onTap: () => MarketNewsModal.show(context, item),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임라인 점. 세로 연결선은 제거했다 — 같은 날짜 그룹이라는
            // 정보를 바로 위 날짜 헤더가 이미 명시하므로 중복이었고,
            // 32pt(가용폭의 8.6%)를 점 하나에 쓰고 있었다. 12+8 = 20pt로 줄여
            // 헤드라인 가로폭 12pt를 회수한다.
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1행 — 티커가 이 행의 히어로다.
                    //
                    // 레퍼런스 리스트 행에서 유일하게 크고 블루인 것은 가격이다.
                    // 우리 도메인의 대응물은 티커다. pill을 해체하고 18 w700로
                    // 세우면 18/11 = 1.64로 레퍼런스(1.62)와 같은 리듬이 된다.
                    // 블루가 행당 한 곳뿐이라 "블루=탭 가능" 신호도 순수해진다.
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isMarket
                                ? l10n.marketNews
                                : (langCode == 'ko' && item.tickerNameKo != null)
                                    ? '${item.ticker} ${item.tickerNameKo}'
                                    : item.ticker,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppTypography.headlineLarge,
                              fontWeight: AppTypography.bold,
                              color: isMarket
                                  ? mlc.textSecondary
                                  : mlc.accentBlue,
                            ),
                          ),
                        ),
                        if (item.isBreaking) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Text(
                            '\u{1F6A8}',
                            style: TextStyle(fontSize: AppTypography.bodySmall),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // 2행 — 헤드라인(AI 요약).
                    Text(
                      item.aiSummary.localize(langCode),
                      style: AppTypography.bodyStrong.copyWith(
                        fontSize: AppTypography.headlineMedium,
                        height: 1.35,
                        color: mlc.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // 3행 — 메타 한 줄. 별도의 '출처' 행을 없애 21pt 회수.
                    Text.rich(
                      TextSpan(children: meta),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: mlc.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
