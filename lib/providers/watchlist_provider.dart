import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';
import '../services/portfolio_api_client.dart';

/// Provider for managing user's watchlist/portfolio
///
/// Per-user storage: each account has its own watchlist/portfolio
/// stored under user-specific SharedPreferences keys.
class WatchlistProvider with ChangeNotifier {
  static const String _lastUserKey = 'marketlens_last_user_id';

  int? _currentUserId;
  List<String> _watchlist = [];
  Map<String, PortfolioEntry> _portfolio = {};
  bool _isInitialized = false;
  PortfolioApiClient? _apiClient;
  bool _isLoggedIn = false;

  /// Get watchlist tickers
  List<String> get watchlist => List.unmodifiable(_watchlist);

  /// Get portfolio entries
  Map<String, PortfolioEntry> get portfolio =>
      Map.unmodifiable(_portfolio);

  /// Check if provider is initialized
  bool get isInitialized => _isInitialized;

  /// Get portfolio tickers
  List<String> get portfolioTickers => _portfolio.keys.toList();

  /// Per-user storage keys
  String _watchlistKeyFor(int? userId) => userId != null
      ? 'marketlens_watchlist_$userId'
      : 'marketlens_watchlist_guest';

  String _portfolioKeyFor(int? userId) => userId != null
      ? 'marketlens_portfolio_$userId'
      : 'marketlens_portfolio_guest';

  String get _watchlistKey => _watchlistKeyFor(_currentUserId);
  String get _portfolioKey => _portfolioKeyFor(_currentUserId);

  /// Initialize provider from SharedPreferences
  ///
  /// Loads last active user's data for immediate display,
  /// or legacy data on first run after update.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Try last active user's data first (instant display on app restart)
      final lastUserId = prefs.getInt(_lastUserKey);
      if (lastUserId != null) {
        _currentUserId = lastUserId;
        _loadFromPrefs(prefs, lastUserId);
      } else {
        // Legacy: load from old static key (first run after update)
        final wJson = prefs.getString('marketlens_watchlist');
        if (wJson != null) {
          _watchlist = (jsonDecode(wJson) as List).cast<String>();
        }
        final pJson = prefs.getString('marketlens_portfolio');
        if (pJson != null) {
          _portfolio = (jsonDecode(pJson) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, PortfolioEntry.fromJson(v)));
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing WatchlistProvider: $e');
      _isInitialized = true;
    }
  }

  /// Load watchlist/portfolio from SharedPreferences for a specific user
  void _loadFromPrefs(SharedPreferences prefs, int? userId) {
    final wJson = prefs.getString(_watchlistKeyFor(userId));
    if (wJson != null) {
      _watchlist = (jsonDecode(wJson) as List).cast<String>();
    }
    final pJson = prefs.getString(_portfolioKeyFor(userId));
    if (pJson != null) {
      _portfolio = (jsonDecode(pJson) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, PortfolioEntry.fromJson(v)));
    }
  }

  /// Switch to a different user's watchlist/portfolio
  ///
  /// Called on login/logout to load the correct user's data.
  /// Handles one-time migration from legacy (non-user-specific) keys.
  /// When logged in, fetches watchlist from server for cross-device sync.
  Future<void> switchUser(int? userId) async {
    if (_currentUserId == userId) return;

    final prefs = await SharedPreferences.getInstance();

    // Save current user's data before switching (real users only)
    if (_currentUserId != null && _isInitialized) {
      await prefs.setString(_watchlistKey, jsonEncode(_watchlist));
      await prefs.setString(
        _portfolioKey,
        jsonEncode(_portfolio.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }

    _currentUserId = userId;
    _watchlist = [];
    _portfolio = {};
    _isLoggedIn = userId != null;

    // Track last active user for fast loading on next app start
    if (userId != null) {
      await prefs.setInt(_lastUserKey, userId);
    } else {
      await prefs.remove(_lastUserKey);
      _apiClient = null;
    }

    if (userId != null) {
      // Load local data first (instant display)
      final wJson = prefs.getString(_watchlistKey);
      final pJson = prefs.getString(_portfolioKey);

      if (wJson != null) {
        _watchlist = (jsonDecode(wJson) as List).cast<String>();
      } else {
        // One-time migration from legacy key
        final legacyW = prefs.getString('marketlens_watchlist');
        if (legacyW != null) {
          _watchlist = (jsonDecode(legacyW) as List).cast<String>();
          await prefs.setString(_watchlistKey, legacyW);
          await prefs.remove('marketlens_watchlist');
        }
      }

      if (pJson != null) {
        _portfolio = (jsonDecode(pJson) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, PortfolioEntry.fromJson(v)));
      } else {
        final legacyP = prefs.getString('marketlens_portfolio');
        if (legacyP != null) {
          _portfolio = (jsonDecode(legacyP) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, PortfolioEntry.fromJson(v)));
          await prefs.setString(_portfolioKey, legacyP);
          await prefs.remove('marketlens_portfolio');
        }
      }

      // Fetch watchlist from server for cross-device sync
      _apiClient = PortfolioApiClient();
      try {
        final serverItems = await _apiClient!.getWatchlist();
        _watchlist = serverItems.map((w) => w.ticker).toList();
        await _saveWatchlist();
        notifyListeners();
      } catch (e) {
        debugPrint('Server watchlist fetch failed, using local: $e');
      }
    }
    // else: logged out → empty watchlist/portfolio

    NotificationService().syncWatchlistSubscriptions(_watchlist).catchError((e) {
      debugPrint('syncWatchlistSubscriptions failed: $e');
    });
    notifyListeners();
  }

  // ==========================================
  // Watchlist Management
  // ==========================================

  /// Add ticker to watchlist
  Future<void> addToWatchlist(String ticker) async {
    ticker = ticker.toUpperCase();
    if (_watchlist.contains(ticker)) return;

    _watchlist.add(ticker);
    await _saveWatchlist();
    notifyListeners();

    if (_isLoggedIn && _apiClient != null) {
      try {
        await _apiClient!.addWatchlistItem(ticker);
      } catch (e) {
        debugPrint('Server add watchlist failed: $e');
      }
    }
  }

  /// Remove ticker from watchlist
  Future<void> removeFromWatchlist(String ticker) async {
    ticker = ticker.toUpperCase();
    if (!_watchlist.contains(ticker)) return;

    _watchlist.remove(ticker);
    await _saveWatchlist();
    notifyListeners();

    if (_isLoggedIn && _apiClient != null) {
      try {
        await _apiClient!.removeWatchlistItem(ticker);
      } catch (e) {
        debugPrint('Server remove watchlist failed: $e');
      }
    }
  }

  /// Check if ticker is in watchlist
  bool isInWatchlist(String ticker) {
    return _watchlist.contains(ticker.toUpperCase());
  }

  /// Toggle ticker in watchlist
  Future<void> toggleWatchlist(String ticker) async {
    if (isInWatchlist(ticker)) {
      await removeFromWatchlist(ticker);
    } else {
      await addToWatchlist(ticker);
    }
  }

  /// Clear all watchlist entries
  Future<void> clearWatchlist() async {
    final oldTickers = List<String>.from(_watchlist);
    _watchlist.clear();
    await _saveWatchlist();
    notifyListeners();

    if (_isLoggedIn && _apiClient != null) {
      for (final ticker in oldTickers) {
        try {
          await _apiClient!.removeWatchlistItem(ticker);
        } catch (e) {
          debugPrint('Server clear watchlist item failed: $e');
        }
      }
    }
  }

  // ==========================================
  // Portfolio Management
  // ==========================================

  /// Add ticker to portfolio with position details
  Future<void> addToPortfolio({
    required String ticker,
    required double shares,
    required double avgPrice,
    String? notes,
  }) async {
    ticker = ticker.toUpperCase();

    _portfolio[ticker] = PortfolioEntry(
      ticker: ticker,
      shares: shares,
      avgPrice: avgPrice,
      notes: notes,
      addedAt: DateTime.now(),
    );

    await _savePortfolio();
    notifyListeners();
  }

  /// Update portfolio entry
  Future<void> updatePortfolioEntry({
    required String ticker,
    double? shares,
    double? avgPrice,
    String? notes,
  }) async {
    ticker = ticker.toUpperCase();
    final entry = _portfolio[ticker];
    if (entry == null) return;

    _portfolio[ticker] = PortfolioEntry(
      ticker: ticker,
      shares: shares ?? entry.shares,
      avgPrice: avgPrice ?? entry.avgPrice,
      notes: notes ?? entry.notes,
      addedAt: entry.addedAt,
    );

    await _savePortfolio();
    notifyListeners();
  }

  /// Remove ticker from portfolio
  Future<void> removeFromPortfolio(String ticker) async {
    ticker = ticker.toUpperCase();
    if (!_portfolio.containsKey(ticker)) return;

    _portfolio.remove(ticker);
    await _savePortfolio();
    notifyListeners();
  }

  /// Check if ticker is in portfolio
  bool isInPortfolio(String ticker) {
    return _portfolio.containsKey(ticker.toUpperCase());
  }

  /// Get portfolio entry
  PortfolioEntry? getPortfolioEntry(String ticker) {
    return _portfolio[ticker.toUpperCase()];
  }

  /// Clear all portfolio entries
  Future<void> clearPortfolio() async {
    _portfolio.clear();
    await _savePortfolio();
    notifyListeners();
  }

  /// Calculate total portfolio value
  double calculateTotalValue(Map<String, double> currentPrices) {
    double total = 0;
    for (final entry in _portfolio.values) {
      final currentPrice = currentPrices[entry.ticker];
      if (currentPrice != null) {
        total += entry.shares * currentPrice;
      }
    }
    return total;
  }

  /// Calculate total cost basis
  double get totalCostBasis {
    return _portfolio.values
        .fold(0, (sum, entry) => sum + (entry.shares * entry.avgPrice));
  }

  /// Calculate unrealized gain/loss
  double calculateUnrealizedGainLoss(Map<String, double> currentPrices) {
    return calculateTotalValue(currentPrices) - totalCostBasis;
  }

  // ==========================================
  // Persistence
  // ==========================================

  Future<void> _saveWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_watchlistKey, jsonEncode(_watchlist));
      // FCM 구독 동기화
      NotificationService().syncWatchlistSubscriptions(_watchlist).catchError((e) {
        debugPrint('syncWatchlistSubscriptions failed: $e');
      });
    } catch (e) {
      debugPrint('Error saving watchlist: $e');
    }
  }

  Future<void> _savePortfolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final portfolioJson = _portfolio.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_portfolioKey, jsonEncode(portfolioJson));
    } catch (e) {
      debugPrint('Error saving portfolio: $e');
    }
  }

  /// Export data for backup
  Map<String, dynamic> exportData() {
    return {
      'watchlist': _watchlist,
      'portfolio': _portfolio.map((k, v) => MapEntry(k, v.toJson())),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('watchlist')) {
        _watchlist = (data['watchlist'] as List).cast<String>();
      }
      if (data.containsKey('portfolio')) {
        final portfolioData = data['portfolio'] as Map<String, dynamic>;
        _portfolio = portfolioData.map(
          (key, value) => MapEntry(key, PortfolioEntry.fromJson(value)),
        );
      }

      await _saveWatchlist();
      await _savePortfolio();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }
}

/// Portfolio entry model
class PortfolioEntry {
  final String ticker;
  final double shares;
  final double avgPrice;
  final String? notes;
  final DateTime addedAt;

  PortfolioEntry({
    required this.ticker,
    required this.shares,
    required this.avgPrice,
    this.notes,
    required this.addedAt,
  });

  factory PortfolioEntry.fromJson(Map<String, dynamic> json) {
    return PortfolioEntry(
      ticker: json['ticker'] as String,
      shares: (json['shares'] as num).toDouble(),
      avgPrice: (json['avg_price'] as num).toDouble(),
      notes: json['notes'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'shares': shares,
      'avg_price': avgPrice,
      'notes': notes,
      'added_at': addedAt.toIso8601String(),
    };
  }

  /// Calculate cost basis
  double get costBasis => shares * avgPrice;

  /// Calculate gain/loss with current price
  double calculateGainLoss(double currentPrice) {
    return (currentPrice - avgPrice) * shares;
  }

  /// Calculate gain/loss percentage
  double calculateGainLossPercent(double currentPrice) {
    if (avgPrice == 0) return 0;
    return ((currentPrice - avgPrice) / avgPrice) * 100;
  }

  /// Calculate current value
  double calculateCurrentValue(double currentPrice) {
    return shares * currentPrice;
  }
}
