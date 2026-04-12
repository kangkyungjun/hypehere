import 'package:flutter/material.dart';

class MarketCalendarEvent {
  final String id;
  final String date;
  final String eventType;
  final String title;
  final String? description;
  final String? ticker;
  final String importance;

  const MarketCalendarEvent({
    required this.id,
    required this.date,
    required this.eventType,
    required this.title,
    this.description,
    this.ticker,
    required this.importance,
  });

  factory MarketCalendarEvent.fromJson(Map<String, dynamic> json) {
    return MarketCalendarEvent(
      id: json['id'] as String,
      date: json['date'] as String,
      eventType: json['event_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      ticker: json['ticker'] as String?,
      importance: json['importance'] as String? ?? 'medium',
    );
  }

  Color get color => switch (eventType) {
    'fomc' || 'fed_speech' => const Color(0xFFE53935),
    'earnings' => const Color(0xFF43A047),
    'economic' => const Color(0xFF1E88E5),
    'options_expiry' => const Color(0xFFFF9800),
    'conference' || 'product_launch' => const Color(0xFF8E24AA),
    'dividend' => const Color(0xFF78909C),
    'shareholder' => const Color(0xFFFDD835),
    _ => const Color(0xFF757575),
  };

  IconData get icon => switch (eventType) {
    'fomc' || 'fed_speech' => Icons.account_balance,
    'earnings' => Icons.bar_chart,
    'economic' => Icons.show_chart,
    'options_expiry' => Icons.timer,
    'conference' => Icons.groups,
    'product_launch' => Icons.rocket_launch,
    'dividend' => Icons.payments,
    'shareholder' => Icons.how_to_vote,
    _ => Icons.event,
  };
}

class EventCalendarData {
  final int year;
  final int month;
  final int totalCount;
  final Map<String, List<MarketCalendarEvent>> byDate;

  const EventCalendarData({
    required this.year,
    required this.month,
    required this.totalCount,
    required this.byDate,
  });

  factory EventCalendarData.fromJson(Map<String, dynamic> json) {
    final byDateJson = json['by_date'] as Map<String, dynamic>? ?? {};
    final byDate = <String, List<MarketCalendarEvent>>{};
    for (final entry in byDateJson.entries) {
      final events = (entry.value as List)
          .map((e) => MarketCalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      byDate[entry.key] = events;
    }

    return EventCalendarData(
      year: json['year'] as int,
      month: json['month'] as int,
      totalCount: json['total_count'] as int? ?? 0,
      byDate: byDate,
    );
  }
}
