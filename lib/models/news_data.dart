import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Parse server timestamp (always UTC) and keep as UTC DateTime.
/// Compare with DateTime.now().toUtc() for correct relative time anywhere.
DateTime _parseAsUtc(String s) {
  final parsed = DateTime.parse(s);
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year, parsed.month, parsed.day,
    parsed.hour, parsed.minute, parsed.second, parsed.millisecond,
  );
}

/// GICS sector → short abbreviation mapping
const _sectorAbbreviations = {
  'Technology': 'Tech',
  'Information Technology': 'Tech',
  'Healthcare': 'Health',
  'Health Care': 'Health',
  'Consumer Cyclical': 'Cyclical',
  'Consumer Defensive': 'Defensive',
  'Consumer Discretionary': 'Discret.',
  'Consumer Staples': 'Staples',
  'Communication Services': 'Comm',
  'Financial Services': 'Finance',
  'Financials': 'Finance',
  'Industrials': 'Indust.',
  'Energy': 'Energy',
  'Utilities': 'Util.',
  'Real Estate': 'RE',
  'Basic Materials': 'Materials',
  'Materials': 'Materials',
};

/// Single news item from MarketLens AI news API
class NewsItem {
  final String date;
  final String ticker;
  final String title;
  final String? source;
  final String? sourceUrl;
  final DateTime publishedAt;
  final String aiSummary;
  final String sentimentGrade;
  final String sentimentLabel;
  final Map<String, dynamic>? futureEvent;
  final String? tickerNameKo;
  final bool isBreaking;
  final bool isHotTopic;
  final String? hotTopicCategory;
  final int? hotTopicPriority;
  final String? sector;

  NewsItem({
    required this.date,
    required this.ticker,
    required this.title,
    this.source,
    this.sourceUrl,
    required this.publishedAt,
    required this.aiSummary,
    required this.sentimentGrade,
    required this.sentimentLabel,
    this.futureEvent,
    this.tickerNameKo,
    this.isBreaking = false,
    this.isHotTopic = false,
    this.hotTopicCategory,
    this.hotTopicPriority,
    this.sector,
  });

  /// Abbreviated sector name for compact display
  String? get sectorShort {
    if (sector == null) return null;
    return _sectorAbbreviations[sector!] ?? sector!;
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      date: json['date'] as String,
      ticker: json['ticker'] as String,
      title: json['title'] as String,
      source: json['source'] as String?,
      sourceUrl: json['source_url'] as String?,
      publishedAt: _parseAsUtc(json['published_at'] as String),
      aiSummary: json['ai_summary'] as String,
      sentimentGrade: json['sentiment_grade'] as String,
      sentimentLabel: json['sentiment_label'] as String,
      futureEvent: json['future_event'] as Map<String, dynamic>?,
      tickerNameKo: json['ticker_name_ko'] as String?,
      isBreaking: json['is_breaking'] as bool? ?? false,
      isHotTopic: json['is_hot_topic'] as bool? ?? false,
      hotTopicCategory: json['hot_topic_category'] as String?,
      hotTopicPriority: json['hot_topic_priority'] as int?,
      sector: json['sector'] as String?,
    );
  }

  /// FCM 알림 data에서 최소한의 뉴스 아이템 생성 (모달 표시용)
  factory NewsItem.fromNotification(Map<String, dynamic> data) {
    final sentiment = data['sentiment'] as String? ?? 'neutral';
    return NewsItem(
      date: data['date'] as String? ??
          DateTime.now().toUtc().toIso8601String().substring(0, 10),
      ticker: data['ticker'] as String? ?? 'MARKET',
      title: data['title'] as String? ?? '',
      sourceUrl: data['source_url'] as String?,
      publishedAt: DateTime.now().toUtc(),
      aiSummary: data['ai_summary'] as String? ?? '',
      sentimentGrade: sentiment,
      sentimentLabel: sentiment,
      isBreaking: data['type'] == 'BREAKING_NEWS',
    );
  }

  /// Sentiment dot color: bullish=green, bearish=red, neutral=grey
  Color sentimentColor(MarketLensColors colors) {
    switch (sentimentGrade) {
      case 'bullish':
        return colors.gainColor;
      case 'bearish':
        return colors.lossColor;
      default:
        return colors.neutralColor;
    }
  }

  /// Localized sentiment label (replaces API's Korean sentimentLabel)
  String sentimentLabelLocalized(AppLocalizations l10n) {
    switch (sentimentGrade) {
      case 'bullish':
        return l10n.sentimentBullish;
      case 'bearish':
        return l10n.sentimentBearish;
      default:
        return l10n.sentimentNeutral;
    }
  }

  /// Localized relative time string
  String timeAgoLocalized(AppLocalizations l10n) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(publishedAt);

    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays == 1) return l10n.timeYesterday;
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return date;
  }
}

/// Sentiment count for a period
class SentimentCounts {
  final int bullish;
  final int neutral;
  final int bearish;

  SentimentCounts({this.bullish = 0, this.neutral = 0, this.bearish = 0});

  factory SentimentCounts.fromJson(Map<String, dynamic> json) {
    return SentimentCounts(
      bullish: json['bullish'] as int? ?? 0,
      neutral: json['neutral'] as int? ?? 0,
      bearish: json['bearish'] as int? ?? 0,
    );
  }
}

/// Week/month sentiment stats from charts API
class NewsSentimentStats {
  final SentimentCounts week;
  final SentimentCounts month;

  NewsSentimentStats({required this.week, required this.month});

  factory NewsSentimentStats.fromJson(Map<String, dynamic> json) {
    return NewsSentimentStats(
      week: json['week'] != null
          ? SentimentCounts.fromJson(json['week'] as Map<String, dynamic>)
          : SentimentCounts(),
      month: json['month'] != null
          ? SentimentCounts.fromJson(json['month'] as Map<String, dynamic>)
          : SentimentCounts(),
    );
  }
}

/// Paginated news list response
class NewsListData {
  final List<NewsItem> items;
  final int total;

  NewsListData({required this.items, required this.total});

  factory NewsListData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return NewsListData(
      items: itemsList,
      total: json['total'] as int? ?? 0,
    );
  }
}
