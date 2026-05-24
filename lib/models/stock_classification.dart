import 'package:flutter/material.dart';

/// Peter Lynch 6-category stock classification
class StockClassification {
  final String category;
  final String categoryKo;
  final String categoryEn;
  final double confidence;
  final String? reasonKo;
  final String? reasonEn;
  final Map<String, dynamic>? metrics;

  StockClassification({
    required this.category,
    required this.categoryKo,
    required this.categoryEn,
    this.confidence = 0.0,
    this.reasonKo,
    this.reasonEn,
    this.metrics,
  });

  factory StockClassification.fromJson(Map<String, dynamic> json) {
    return StockClassification(
      category: json['category'] as String,
      categoryKo: json['category_ko'] as String,
      categoryEn: json['category_en'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasonKo: json['reason_ko'] as String?,
      reasonEn: json['reason_en'] as String?,
      metrics: json['metrics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'category_ko': categoryKo,
      'category_en': categoryEn,
      'confidence': confidence,
      'reason_ko': reasonKo,
      'reason_en': reasonEn,
      'metrics': metrics,
    };
  }

  /// Get localized category name based on language code
  String localizedName(String langCode) {
    if (langCode == 'ko') return categoryKo;
    return categoryEn;
  }

  /// Badge color by category
  Color get color {
    switch (category) {
      case 'FAST_GROWER':
        return const Color(0xFF4CAF50); // green
      case 'STALWART':
        return const Color(0xFF2196F3); // blue
      case 'SLOW_GROWER':
        return const Color(0xFF9E9E9E); // grey
      case 'CYCLICAL':
        return const Color(0xFFFF9800); // orange
      case 'TURNAROUND':
        return const Color(0xFF9C27B0); // purple
      case 'ASSET_PLAY':
        return const Color(0xFF795548); // brown
      default:
        return const Color(0xFF607D8B); // blue-grey
    }
  }

  /// Icon by category
  IconData get icon {
    switch (category) {
      case 'FAST_GROWER':
        return Icons.trending_up;
      case 'STALWART':
        return Icons.shield_outlined;
      case 'SLOW_GROWER':
        return Icons.speed;
      case 'CYCLICAL':
        return Icons.autorenew;
      case 'TURNAROUND':
        return Icons.refresh;
      case 'ASSET_PLAY':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  /// All 6 categories for filter chips
  static const List<Map<String, String>> allCategories = [
    {'code': 'FAST_GROWER', 'ko': '고성장주', 'en': 'Fast Grower'},
    {'code': 'STALWART', 'ko': '대형우량주', 'en': 'Stalwart'},
    {'code': 'SLOW_GROWER', 'ko': '저성장주', 'en': 'Slow Grower'},
    {'code': 'CYCLICAL', 'ko': '경기순환주', 'en': 'Cyclical'},
    {'code': 'TURNAROUND', 'ko': '턴어라운드', 'en': 'Turnaround'},
    {'code': 'ASSET_PLAY', 'ko': '자산주', 'en': 'Asset Play'},
  ];
}
