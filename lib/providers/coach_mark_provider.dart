import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages coach mark (tutorial overlay) visibility state using SharedPreferences.
///
/// Each screen has a key indicating whether the coach mark has been shown.
/// On first app launch (or after reset), all coach marks are visible.
class CoachMarkProvider extends ChangeNotifier {
  static const _prefix = 'coach_mark_seen_';

  /// Known coach mark keys
  static const keyDashboardTreemap = 'dashboard_treemap';
  static const keyAiLens = 'ai_lens';
  static const keyWatchlist = 'watchlist';
  static const keyHoldings = 'holdings';
  static const keyTickerScore = 'ticker_score';
  static const keyMacroGauge = 'macro_gauge';

  static const allKeys = [
    keyDashboardTreemap,
    keyAiLens,
    keyWatchlist,
    keyHoldings,
    keyTickerScore,
    keyMacroGauge,
  ];

  final Set<String> _seen = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Load seen state from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _seen.clear();
    for (final key in allKeys) {
      if (prefs.getBool('$_prefix$key') == true) {
        _seen.add(key);
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Whether the coach mark for [key] should be shown (not yet seen)
  bool shouldShow(String key) => _loaded && !_seen.contains(key);

  /// Mark a coach mark as seen
  Future<void> markSeen(String key) async {
    if (_seen.contains(key)) return;
    _seen.add(key);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', true);
  }

  /// Reset all coach marks so they show again
  Future<void> resetAll() async {
    _seen.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    for (final key in allKeys) {
      await prefs.remove('$_prefix$key');
    }
  }
}
