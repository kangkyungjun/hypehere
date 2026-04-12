import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ticker_info.dart';

/// Recent Search Provider - 최근 검색 관리
///
/// SharedPreferences로 로컬 저장 (TickerInfo 객체 저장)
class RecentSearchProvider with ChangeNotifier {
  static const String _recentSearchKey = 'marketlens_recent_search';
  static const int _maxRecentSearches = 10;

  List<TickerInfo> _recentSearches = [];
  bool _isInitialized = false;

  /// Get recent searches
  List<TickerInfo> get recentSearches => List.unmodifiable(_recentSearches);

  /// Check if provider is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize provider from SharedPreferences
  ///
  /// 기존 String 데이터와 새로운 TickerInfo 데이터 모두 지원 (하위 호환성)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getString(_recentSearchKey);

      if (searchesJson != null) {
        final List<dynamic> decoded = jsonDecode(searchesJson);

        // 새로운 형식 (TickerInfo 객체)인지 확인
        if (decoded.isNotEmpty && decoded.first is Map) {
          // TickerInfo 객체로 변환
          _recentSearches = decoded
              .map((item) => TickerInfo.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          // 기존 형식 (String)을 TickerInfo로 마이그레이션
          _recentSearches = decoded
              .cast<String>()
              .map((ticker) => TickerInfo(
                    ticker: ticker,
                    name: null,
                    nameKo: null,
                  ))
              .toList();

          // 새로운 형식으로 저장
          await _save();
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing RecentSearchProvider: $e');
      _isInitialized = true;
    }
  }

  /// Add ticker to recent searches (TickerInfo 객체 저장)
  Future<void> addSearch(TickerInfo ticker) async {
    if (ticker.ticker.trim().isEmpty) return;

    // 중복 제거 (같은 ticker가 있으면 제거하고 최상단에 추가)
    _recentSearches.removeWhere((t) => t.ticker == ticker.ticker);

    // Add to beginning
    _recentSearches.insert(0, ticker);

    // Keep only max items
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }

    await _save();
    notifyListeners();
  }

  /// Remove ticker from recent searches
  Future<void> removeSearch(String ticker) async {
    final initialLength = _recentSearches.length;
    _recentSearches.removeWhere((t) => t.ticker == ticker);

    // 실제로 제거된 경우에만 저장
    if (_recentSearches.length != initialLength) {
      await _save();
      notifyListeners();
    }
  }

  /// Clear all recent searches
  Future<void> clearAll() async {
    _recentSearches.clear();
    await _save();
    notifyListeners();
  }

  /// Save to SharedPreferences (TickerInfo 객체를 JSON으로 직렬화)
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _recentSearches.map((ticker) => ticker.toJson()).toList();
      await prefs.setString(_recentSearchKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving recent searches: $e');
    }
  }
}
