import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_info.dart';
import '../../providers/recent_search_provider.dart';
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _error = null;
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
          const SizedBox(height: AppSpacing.md),

          // 검색 결과 / 최근 검색
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              ticker.ticker,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(ticker.searchDisplayText),
            trailing: const Icon(Icons.chevron_right),
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
                          fontWeight: FontWeight.bold,
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
