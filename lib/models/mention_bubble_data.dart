/// Data model for the 24h news mention bubble chart.
class TickerMention {
  final String ticker;
  final int mentionCount;
  final String? nameKo;
  final String? sector;
  final String dominantSentiment; // bullish/bearish/neutral
  final double avgSentimentScore;

  TickerMention({
    required this.ticker,
    required this.mentionCount,
    this.nameKo,
    this.sector,
    this.dominantSentiment = 'neutral',
    this.avgSentimentScore = 0.0,
  });

  factory TickerMention.fromJson(Map<String, dynamic> json) {
    return TickerMention(
      ticker: json['ticker'] as String,
      mentionCount: json['mention_count'] as int,
      nameKo: json['name_ko'] as String?,
      sector: json['sector'] as String?,
      dominantSentiment: json['dominant_sentiment'] as String? ?? 'neutral',
      avgSentimentScore: (json['avg_sentiment_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MentionBubbleData {
  final List<TickerMention> items;
  final int periodHours;

  MentionBubbleData({required this.items, required this.periodHours});

  factory MentionBubbleData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.map((e) => TickerMention.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MentionBubbleData(
      items: itemsList,
      periodHours: json['period_hours'] as int? ?? 24,
    );
  }
}
