import 'package:flutter/material.dart';
import '../../models/news_data.dart';
import '../../utils/multilingual.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/news/market_news_modal.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Full news list for a specific ticker with infinite scroll.
///
/// - Top section: week/month sentiment stats
/// - Date separators
/// - Timeline layout (dot + vertical line)
/// - Banner ad every 15 items
class TickerNewsListScreen extends StatefulWidget {
  final String ticker;
  final NewsSentimentStats? stats;

  const TickerNewsListScreen({
    super.key,
    required this.ticker,
    this.stats,
  });

  @override
  State<TickerNewsListScreen> createState() => _TickerNewsListScreenState();
}

class _TickerNewsListScreenState extends State<TickerNewsListScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  final ScrollController _scrollController = ScrollController();

  final List<NewsItem> _items = [];
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
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

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.getTickerNews(widget.ticker, limit: _pageSize, offset: 0);
      setState(() {
        _items.clear();
        _items.addAll(data.items);
        _total = data.total;
        _isLoading = false;
      });
    } catch (e) {
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
      final data = await _apiClient.getTickerNews(
        widget.ticker,
        limit: _pageSize,
        offset: _items.length,
      );
      setState(() {
        _items.addAll(data.items);
        _total = data.total;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tickerNews(widget.ticker)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadInitial, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    if (_items.isEmpty && widget.stats == null) {
      return Center(child: Text(l10n.noNewsAvailable));
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _buildListItemCount(),
        itemBuilder: (context, index) => _buildListItem(index),
      ),
    );
  }

  int _buildListItemCount() {
    int count = 0;

    // Stats section at top
    if (widget.stats != null) count++;

    String? lastDateGroup;
    int newsIndex = 0;

    for (int i = 0; i < _items.length; i++) {
      final dateGroup = _items[i].date;
      if (dateGroup != lastDateGroup) {
        count++;
        lastDateGroup = dateGroup;
      }
      count++;
      newsIndex++;
      if (newsIndex % 15 == 0 && i != _items.length - 1) {
        count++;
      }
    }

    if (_isLoadingMore || _items.length < _total) count++;

    return count;
  }

  Widget _buildListItem(int virtualIndex) {
    int currentVirtual = 0;

    // Stats section
    if (widget.stats != null) {
      if (currentVirtual == virtualIndex) {
        return _buildStatsSection(context);
      }
      currentVirtual++;
    }

    String? lastDateGroup;
    int newsCount = 0;

    for (int i = 0; i < _items.length; i++) {
      final dateGroup = _items[i].date;

      if (dateGroup != lastDateGroup) {
        if (currentVirtual == virtualIndex) {
          return _buildDateHeader(context, _items[i]);
        }
        currentVirtual++;
        lastDateGroup = dateGroup;
      }

      if (currentVirtual == virtualIndex) {
        final isLastInGroup = (i == _items.length - 1) ||
            _items[i + 1].date != dateGroup;
        return _buildNewsItem(context, _items[i], isLastInGroup: isLastInGroup);
      }
      currentVirtual++;
      newsCount++;

      if (newsCount % 15 == 0 && i != _items.length - 1) {
        if (currentVirtual == virtualIndex) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: BannerAdWidget(),
          );
        }
        currentVirtual++;
      }
    }

    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.stats!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.mlColors.sectionBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.mlColors.subtleBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatColumn(context, l10n.oneWeek, s.week)),
          Container(width: 1, height: 40, color: context.mlColors.subtleBorder),
          Expanded(child: _buildStatColumn(context, l10n.oneMonth, s.month)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String title, SentimentCounts counts) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatRow(Colors.green, l10n.sentimentBullish, counts.bullish),
        const SizedBox(height: 2),
        _buildStatRow(Colors.grey, l10n.sentimentNeutral, counts.neutral),
        const SizedBox(height: 2),
        _buildStatRow(Colors.red, l10n.sentimentBearish, counts.bearish),
      ],
    );
  }

  Widget _buildStatRow(Color color, String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label  $count',
          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context, NewsItem item) {
    final label = _formatDateLabel(item.date);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
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
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor;

    return InkWell(
      onTap: () => MarketNewsModal.show(context, item),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 6),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: sentiment + time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.sentimentLabelLocalized(AppLocalizations.of(context)),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: dotColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.timeAgoLocalized(AppLocalizations.of(context)),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Row 2: AI summary (localized)
                    Text(
                      item.aiSummary.localize(langCode),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                          fontSize: 10,
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
    );
  }
}
