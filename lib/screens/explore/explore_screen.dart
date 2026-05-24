import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_info.dart';
import '../../models/stock_classification.dart';
import '../../providers/recent_search_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/app_colors.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/error_state_view.dart';
/// Explore Screen - 검색/탐색 (도구형 검색)
///
/// ⚠️ HypeHere 검색과 다름: 종목 중심, 빠른 진입
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  Timer? _debounce;

  List<TickerInfo> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  // Classification filter
  String? _selectedClassification;
  List<Map<String, dynamic>> _classificationResults = [];
  bool _isLoadingClassification = false;
  int _classificationDisplayCount = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce 처리 (300ms)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await _apiClient.searchTickers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  void _onTickerTap(TickerInfo ticker) {
    // 최근 검색에 추가 (전체 TickerInfo 객체 저장)
    context.read<RecentSearchProvider>().addSearch(ticker);

    // Ticker Detail로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker.ticker),
      ),
    );
  }

  void _onRecentSearchTap(TickerInfo ticker) {
    _searchController.text = ticker.ticker;
    _performSearch(ticker.ticker);
  }

  Future<void> _onClassificationTap(String category) async {
    if (_selectedClassification == category) {
      setState(() {
        _selectedClassification = null;
        _classificationResults = [];
      });
      return;
    }
    setState(() {
      _selectedClassification = category;
      _isLoadingClassification = true;
      _classificationResults = [];
      _classificationDisplayCount = 20;
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
    });
    try {
      final results = await _apiClient.getStocksByClassification(category);
      if (!mounted) return;
      setState(() {
        _classificationResults = results;
        _isLoadingClassification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingClassification = false;
        _error = ErrorLocalizer.getMessage(context, e);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _error = null;
      _selectedClassification = null;
      _classificationResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: l10n.tooltipClearSearch,
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearSearch,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          style: const TextStyle(fontSize: AppTypography.bodyLarge),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
      ),
      body: Column(
        children: [

          // 광고 배너
          const BannerAdWidget(),

          // Classification filter chips
          _buildClassificationChips(),
          const SizedBox(height: AppSpacing.sm),

          // 검색 결과 / 최근 검색 / 분류 결과
          Expanded(
            child: _selectedClassification != null
                ? _buildClassificationContent()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationChips() {
    final langCode = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: StockClassification.allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = StockClassification.allCategories[index];
          final code = cat['code']!;
          final label = langCode == 'ko' ? cat['ko']! : cat['en']!;
          final isSelected = _selectedClassification == code;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => _onClassificationTap(code),
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildClassificationContent() {
    if (_isLoadingClassification) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_classificationResults.isEmpty) {
      return Center(
        child: Text(
          Localizations.localeOf(context).languageCode == 'ko'
              ? '해당 분류 종목이 없습니다'
              : 'No stocks in this category',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    // Sort by trading_value descending (client-side fallback)
    final sorted = List<Map<String, dynamic>>.from(_classificationResults)
      ..sort((a, b) {
        final aVal = (a['trading_value'] as num?)?.toDouble() ?? 0;
        final bVal = (b['trading_value'] as num?)?.toDouble() ?? 0;
        return bVal.compareTo(aVal);
      });

    final displayItems = sorted.take(_classificationDisplayCount).toList();
    final hasMore = sorted.length > _classificationDisplayCount;

    return ListView.builder(
      itemCount: displayItems.length + (hasMore ? 1 : 0),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemBuilder: (context, index) {
        // "Load more" button at the end
        if (index == displayItems.length) {
          final remaining = sorted.length - _classificationDisplayCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: OutlinedButton(
                onPressed: () => setState(() => _classificationDisplayCount += 20),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ko'
                      ? '더보기 ($remaining)'
                      : 'Show more ($remaining)',
                ),
              ),
            ),
          );
        }

        final item = displayItems[index];
        final ticker = item['ticker'] as String;
        final name = item['name'] as String?;
        final nameKo = item['name_ko'] as String?;
        final score = item['score'] as num?;
        final changePct = item['change_pct'] as num?;
        final langCode = Localizations.localeOf(context).languageCode;
        final displayName = (langCode == 'ko' && nameKo != null) ? nameKo : (name ?? ticker);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(ticker[0], style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
          title: Text(ticker, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(score.toStringAsFixed(0), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onTertiaryContainer)),
                ),
              if (changePct != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: changePct >= 0
                        ? context.mlColors.gainColor
                        : context.mlColors.lossColor,
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 상태
    if (_error != null) {
      return ErrorStateView(
        message: l10n.searchFailed,
        detail: _error!,
        onRetry: () => _performSearch(_searchController.text),
        retryLabel: l10n.retry,
      );
    }

    // 검색 후 빈 결과
    if (_hasSearched && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.noSearchResults,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.tryDifferentSearch,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // 검색 결과 표시
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final ticker = _searchResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                ticker.ticker.substring(0, 1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            title: Text(
              ticker.ticker,
              style: const TextStyle(fontWeight: AppTypography.bold),
            ),
            subtitle: Text(ticker.searchDisplayText),
            trailing: Consumer<WatchlistProvider>(
              builder: (context, wp, _) {
                final isIn = wp.isInWatchlist(ticker.ticker);
                return IconButton(
                  icon: Icon(
                    isIn ? Icons.bookmark : Icons.bookmark_border,
                    color: isIn
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  onPressed: () {
                    wp.toggleWatchlist(ticker.ticker);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isIn
                            ? '${ticker.ticker} ${l10n.removedFromWatchlist}'
                            : '${ticker.ticker} ${l10n.addedToWatchlist}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
            onTap: () => _onTickerTap(ticker),
          );
        },
      );
    }

    // 초기 상태: 최근 검색 표시
    return Consumer<RecentSearchProvider>(
      builder: (context, recentSearchProvider, child) {
        final recentSearches = recentSearchProvider.recentSearches;

        if (recentSearches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.tickerSearch,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.enterTickerAbove,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                // Bookmark guide card
                _buildBookmarkGuide(context, l10n),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentSearches,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      recentSearchProvider.clearAll();
                    },
                    child: Text(l10n.clearAll),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: recentSearches.length,
                itemBuilder: (context, index) {
                  final ticker = recentSearches[index];

                  // 2줄 표시: 1줄(ticker), 2줄(English / Korean)
                  String? subtitleText;
                  if (ticker.name != null || ticker.nameKo != null) {
                    final names = [
                      if (ticker.name != null) ticker.name,
                      if (ticker.nameKo != null) ticker.nameKo,
                    ];
                    subtitleText = names.join(' / ');
                  }

                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      ticker.ticker,
                      style: const TextStyle(fontWeight: AppTypography.bold),
                    ),
                    subtitle: subtitleText != null
                        ? Text(
                            subtitleText,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: AppTypography.bodySmall,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      tooltip: l10n.tooltipRemove,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        recentSearchProvider.removeSearch(ticker.ticker);
                      },
                    ),
                    onTap: () => _onRecentSearchTap(ticker),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookmarkGuide(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.mlColors.subtleBorder),
      ),
      child: Column(
        children: [
          Text(
            l10n.bookmarkGuide,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 28,
                color: theme.colorScheme.outline,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ),
              Icon(
                Icons.bookmark,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
