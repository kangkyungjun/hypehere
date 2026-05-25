/// Ticker metadata model
///
/// Matches the server's TickerMetadata schema
class TickerInfo {
  final String ticker;
  final String? name;
  final String? nameKo;
  final String? category;

  TickerInfo({
    required this.ticker,
    this.name,
    this.nameKo,
    this.category,
  });

  factory TickerInfo.fromJson(Map<String, dynamic> json) {
    return TickerInfo(
      ticker: json['ticker'] as String,
      name: json['name'] as String?,
      nameKo: json['name_ko'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'name': name,
      'name_ko': nameKo,
      'category': category,
    };
  }

  /// Get display name (fallback to ticker if name is null)
  String get displayName => name ?? ticker;

  /// Get display text for search results
  String get searchDisplayText {
    String displayText = ticker;

    if (name != null) {
      displayText += ' - $name';
      if (nameKo != null) {
        displayText += ' / $nameKo';
      }
    }

    if (category != null) {
      displayText += ' ($category)';
    }

    return displayText;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TickerInfo && other.ticker == ticker;
  }

  @override
  int get hashCode => ticker.hashCode;
}
