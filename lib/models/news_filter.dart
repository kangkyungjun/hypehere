/// News source filter mode
enum NewsSourceFilter { all, watchlist, marketOnly }

/// Immutable filter state for news list
class NewsFilterState {
  final NewsSourceFilter sourceFilter;
  final Set<String> sentimentGrades; // {bullish, bearish, neutral}
  final Set<String> sectors;
  final bool breakingOnly;

  const NewsFilterState({
    this.sourceFilter = NewsSourceFilter.all,
    this.sentimentGrades = const {},
    this.sectors = const {},
    this.breakingOnly = false,
  });

  /// Whether any filter is active (non-default)
  bool get isActive =>
      sourceFilter != NewsSourceFilter.all ||
      sentimentGrades.isNotEmpty ||
      sectors.isNotEmpty ||
      breakingOnly;

  /// Count of active filter categories
  int get activeCount {
    int count = 0;
    if (sourceFilter != NewsSourceFilter.all) count++;
    if (sentimentGrades.isNotEmpty) count++;
    if (sectors.isNotEmpty) count++;
    if (breakingOnly) count++;
    return count;
  }

  NewsFilterState copyWith({
    NewsSourceFilter? sourceFilter,
    Set<String>? sentimentGrades,
    Set<String>? sectors,
    bool? breakingOnly,
  }) {
    return NewsFilterState(
      sourceFilter: sourceFilter ?? this.sourceFilter,
      sentimentGrades: sentimentGrades ?? this.sentimentGrades,
      sectors: sectors ?? this.sectors,
      breakingOnly: breakingOnly ?? this.breakingOnly,
    );
  }

  /// Reset to default state
  static const NewsFilterState defaultState = NewsFilterState();

  /// All available GICS sector values
  static const List<String> allSectors = [
    'Technology',
    'Healthcare',
    'Energy',
    'Consumer Cyclical',
    'Consumer Defensive',
    'Communication Services',
    'Financials',
    'Industrials',
    'Utilities',
    'Real Estate',
    'Basic Materials',
  ];
}
