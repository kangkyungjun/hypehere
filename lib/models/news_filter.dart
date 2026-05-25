/// News category filter mode
enum NewsCategory { all, biz, world, watchlist }

/// Immutable filter state for news list
class NewsFilterState {
  final NewsCategory category;
  final Set<String> sentimentGrades; // {bullish, bearish, neutral}
  final Set<String> sectors;
  final bool breakingOnly;

  const NewsFilterState({
    this.category = NewsCategory.all,
    this.sentimentGrades = const {},
    this.sectors = const {},
    this.breakingOnly = false,
  });

  /// Whether any filter is active (non-default)
  bool get isActive =>
      category != NewsCategory.all ||
      sentimentGrades.isNotEmpty ||
      sectors.isNotEmpty ||
      breakingOnly;

  /// Count of active filter categories
  int get activeCount {
    int count = 0;
    if (category != NewsCategory.all) count++;
    if (sentimentGrades.isNotEmpty) count++;
    if (sectors.isNotEmpty) count++;
    if (breakingOnly) count++;
    return count;
  }

  NewsFilterState copyWith({
    NewsCategory? category,
    Set<String>? sentimentGrades,
    Set<String>? sectors,
    bool? breakingOnly,
  }) {
    return NewsFilterState(
      category: category ?? this.category,
      sentimentGrades: sentimentGrades ?? this.sentimentGrades,
      sectors: sectors ?? this.sectors,
      breakingOnly: breakingOnly ?? this.breakingOnly,
    );
  }

  /// Reset to default state
  static const NewsFilterState defaultState = NewsFilterState();

  /// Fallback GICS sector values (used when API unavailable)
  static const List<String> fallbackSectors = [
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
