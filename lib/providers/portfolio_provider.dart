import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/portfolio_data.dart';
import '../services/portfolio_api_client.dart';

/// Server-backed portfolio state management.
///
/// Replaces local-only WatchlistProvider with server-synced data.
/// Handles migration from SharedPreferences → server on first use.
///
/// Data flow:
///   Flutter ↔ FastAPI (server) ↔ Mac mini (AI brain)
class PortfolioProvider with ChangeNotifier {
  static const String _migrationKey = 'portfolio_server_migrated';

  final PortfolioApiClient _apiClient;

  List<PortfolioHolding> _holdings = [];
  List<WatchlistItem> _watchlist = [];
  List<PortfolioTransaction> _transactions = [];
  List<PortfolioAdvice> _advice = [];
  PortfolioSummary? _summary;
  List<UserAlert> _alerts = [];
  ExchangeRate? _exchangeRate;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  /// When portfolio data (prices, holdings) was last fetched from server.
  DateTime? _lastRefreshedAt;

  /// Incremented on portfolio changes (add/update/delete/sell).
  /// Used by PortfolioAICard to detect changes and re-lock ad content.
  int _portfolioVersion = 0;

  PortfolioProvider({PortfolioApiClient? apiClient})
      : _apiClient = apiClient ?? PortfolioApiClient();

  // Getters
  List<PortfolioHolding> get holdings => List.unmodifiable(_holdings);
  List<WatchlistItem> get watchlist => List.unmodifiable(_watchlist);
  List<PortfolioTransaction> get transactions => List.unmodifiable(_transactions);
  List<PortfolioAdvice> get advice => List.unmodifiable(_advice);
  PortfolioSummary? get summary => _summary;
  List<UserAlert> get alerts => List.unmodifiable(_alerts);
  ExchangeRate? get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  int get portfolioVersion => _portfolioVersion;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  /// Watchlist ticker list (for compatibility with existing code)
  List<String> get watchlistTickers =>
      _watchlist.map((w) => w.ticker).toList();

  /// All tracked tickers (holdings + watchlist)
  List<String> get allTickers {
    final set = <String>{};
    for (final h in _holdings) {
      set.add(h.ticker);
    }
    for (final w in _watchlist) {
      set.add(w.ticker);
    }
    return set.toList();
  }

  /// Check if ticker is in watchlist
  bool isInWatchlist(String ticker) =>
      _watchlist.any((w) => w.ticker == ticker.toUpperCase());

  /// Check if ticker is in holdings
  bool isInHoldings(String ticker) =>
      _holdings.any((h) => h.ticker == ticker.toUpperCase());

  /// Total portfolio value
  double get totalValue =>
      _holdings.fold(0, (sum, h) => sum + h.currentValue);

  /// Total cost basis
  double get totalCost =>
      _holdings.fold(0, (sum, h) => sum + h.costBasis);

  /// Total P&L
  double get totalPnl => totalValue - totalCost;

  /// Total P&L %
  double get totalPnlPct => totalCost > 0 ? (totalPnl / totalCost) * 100 : 0;

  /// Unread alerts count
  int get unreadAlertCount =>
      _alerts.where((a) => !a.isRead).length;

  /// Realized P&L from summary
  double get realizedPnl => _summary?.realizedPnl ?? 0;

  /// Get transactions for a specific ticker
  List<PortfolioTransaction> getTransactionsForTicker(String ticker) =>
      _transactions.where((t) => t.ticker == ticker.toUpperCase()).toList();

  // ============================================================
  // Initialization & Migration
  // ============================================================

  /// Initialize provider: load from server + migrate local data if needed.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if we need to migrate local watchlist to server
      await _migrateLocalDataIfNeeded();

      // Load all data from server
      await refresh();

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('PortfolioProvider init error: $e');
      _isInitialized = true; // Mark as initialized even on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrate local SharedPreferences data to server (one-time).
  Future<void> _migrateLocalDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migrationKey) ?? false;
    if (alreadyMigrated) return;

    try {
      // Read local watchlist (per-user key pattern from WatchlistProvider)
      final lastUserId = prefs.getInt('marketlens_last_user_id');
      final wKey = lastUserId != null
          ? 'marketlens_watchlist_$lastUserId'
          : 'marketlens_watchlist_guest';
      final wJson = prefs.getString(wKey);

      if (wJson != null) {
        final localTickers = (jsonDecode(wJson) as List).cast<String>();
        if (localTickers.isNotEmpty) {
          await _apiClient.syncWatchlist(localTickers);
          debugPrint(
              'Migrated ${localTickers.length} watchlist items to server');
        }
      }

      // Read local portfolio entries and sync as holdings
      final pKey = lastUserId != null
          ? 'marketlens_portfolio_$lastUserId'
          : 'marketlens_portfolio_guest';
      final pJson = prefs.getString(pKey);

      if (pJson != null) {
        final localPortfolio = jsonDecode(pJson) as Map<String, dynamic>;
        for (final entry in localPortfolio.entries) {
          final data = entry.value as Map<String, dynamic>;
          final shares = (data['shares'] as num?)?.toDouble();
          final avgPrice = (data['avg_price'] as num?)?.toDouble();
          if (shares != null && avgPrice != null && shares > 0) {
            await _apiClient.addOrUpdateHolding(
              ticker: entry.key,
              shares: shares,
              avgPrice: avgPrice,
              notes: data['notes'] as String?,
            );
          }
        }
        debugPrint(
            'Migrated ${localPortfolio.length} portfolio entries to server');
      }

      // Mark migration complete
      await prefs.setBool(_migrationKey, true);
    } catch (e) {
      debugPrint('Migration error (will retry next launch): $e');
      // Don't mark as migrated — retry on next launch
    }
  }

  /// Refresh all data from server.
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel fetch: core + AI data together
      final results = await Future.wait([
        _apiClient.getHoldings(),
        _apiClient.getWatchlist(),
        _apiClient.getAlerts(limit: 20),
      ]);

      _holdings = results[0] as List<PortfolioHolding>;
      _watchlist = results[1] as List<WatchlistItem>;
      _alerts = results[2] as List<UserAlert>;

      // Await AI data so UI has complete state on first render
      await _refreshAIData();

      _lastRefreshedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      debugPrint('PortfolioProvider refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh advice + summary + exchange rate in parallel.
  ///
  /// CHANGE (2026-06) — AI generation moved from auto to button-triggered:
  /// Previously, calling this on app init / pull-refresh / every holding
  /// add·update·delete·sell caused the server (Mac mini brain) to regenerate
  /// the costly GPT portfolio analysis automatically. That unit cost no longer
  /// matches revenue, so AI *generation* is now user-triggered via
  /// [requestAnalysisUpdate] (rewarded-ad gated in PortfolioAICard).
  ///
  /// These calls are intentionally KEPT so numeric data (value/PnL/advice/FX)
  /// still refreshes — they now rely on the server returning the *cached*
  /// analysis from `GET /summary` (no regeneration). To restore the old
  /// auto-regeneration behavior, either call [requestAnalysisUpdate] from the
  /// CRUD handlers below, or re-enable regen-on-GET server-side.
  Future<void> _refreshAIData() async {
    await Future.wait([
      loadAdvice(),
      loadSummary(),
      loadExchangeRate(),
    ]);
  }

  /// Whether a user-triggered AI analysis update is in flight.
  bool _isUpdatingAnalysis = false;
  bool get isUpdatingAnalysis => _isUpdatingAnalysis;

  /// Representative purchase date for a holding (yyyy-MM-dd), sent in
  /// trigger_data so the Mac mini doesn't reset buy_date to today.
  /// Prefers the earliest BUY transaction for the ticker, else the holding's
  /// createdAt. Returns null only when nothing is known (backend defaults).
  String? _buyDateFor(PortfolioHolding h) {
    DateTime? d;
    final buys = _transactions
        .where((t) => t.ticker == h.ticker.toUpperCase() && t.type == 'BUY')
        .toList();
    if (buys.isNotEmpty) {
      d = buys.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    }
    d ??= h.createdAt;
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// User-triggered ("AI 분석 업데이트" button) portfolio AI regeneration.
  ///
  /// See [_refreshAIData] for why this replaced the previous auto-regeneration.
  /// The refresh is ASYNCHRONOUS: we POST a PENDING queue record (with the
  /// current holdings so the Mac mini analyzes the up-to-date portfolio), then
  /// poll [getSummary] with backoff until the analysis actually changes (the
  /// poller's round-trip is ~15–40s+). Returns `true` if the new analysis was
  /// observed, `false` on timeout (delayed — it will appear on a later fetch).
  Future<bool> requestAnalysisUpdate() async {
    _isUpdatingAnalysis = true;
    _error = null;
    notifyListeners();

    // Baseline to detect when the regenerated analysis has landed.
    final baselineSummary = _summary?.aiSummary;
    final baselineDate = _summary?.date;

    try {
      final holdings = _holdings.map((h) {
        final buyDate = _buyDateFor(h);
        return <String, dynamic>{
          'ticker': h.ticker,
          'shares': h.shares,
          'avg_price': h.avgPrice,
          // buy_date prevents the Mac mini upsert from resetting the purchase
          // date to today (which would corrupt holding-period narration).
          if (buyDate != null) 'buy_date': buyDate,
        };
      }).toList();
      final signature = (_holdings
              .map((h) => '${h.ticker}:${h.shares ?? 0}:${h.avgPrice ?? 0}')
              .toList()
            ..sort())
          .join('|');

      await _apiClient.requestAnalysisRefresh(
        holdings: holdings,
        signature: signature,
      );

      // Backoff poll (~50s total) until the cached summary changes.
      const delays = [2, 3, 4, 5, 5, 5, 6, 6, 7, 7];
      for (final d in delays) {
        await Future.delayed(Duration(seconds: d));
        await loadSummary(); // GET cached summary; updates _summary + notifies
        final cur = _summary;
        final changed = cur != null &&
            ((baselineSummary == null &&
                    (cur.aiSummary?.isNotEmpty ?? false)) ||
                (cur.aiSummary != baselineSummary) ||
                (baselineDate != null && cur.date.isAfter(baselineDate)));
        if (changed) {
          _lastRefreshedAt = DateTime.now();
          return true;
        }
      }
      return false; // delayed — result not yet visible
    } catch (e) {
      _error = e.toString();
      debugPrint('requestAnalysisUpdate error: $e');
      rethrow;
    } finally {
      _isUpdatingAnalysis = false;
      notifyListeners();
    }
  }

  // ============================================================
  // Holdings CRUD
  // ============================================================

  Future<void> addOrUpdateHolding({
    required String ticker,
    required double shares,
    required double avgPrice,
    String? notes,
  }) async {
    try {
      final result = await _apiClient.addOrUpdateHolding(
        ticker: ticker,
        shares: shares,
        avgPrice: avgPrice,
        notes: notes,
      );

      // If instant advice was returned, add/update it in _advice list
      if (result.instantAdvice != null) {
        _advice.removeWhere((a) => a.ticker == result.ticker);
        _advice.insert(0, result.instantAdvice!);
      }

      // Refresh holdings to get enriched data (current price, score)
      _portfolioVersion++;
      _holdings = await _apiClient.getHoldings();
      _lastRefreshedAt = DateTime.now();
      notifyListeners();

      // Refresh AI data so advice + summary reflect the change
      _refreshAIData();
    } catch (e) {
      debugPrint('Add holding error: $e');
      rethrow;
    }
  }

  Future<void> deleteHolding(String ticker) async {
    try {
      await _apiClient.deleteHolding(ticker);
      _portfolioVersion++;
      _holdings.removeWhere((h) => h.ticker == ticker.toUpperCase());
      _advice.removeWhere((a) => a.ticker == ticker.toUpperCase());
      notifyListeners();

      // Refresh AI data so summary reflects the removal
      _refreshAIData();
    } catch (e) {
      debugPrint('Delete holding error: $e');
      rethrow;
    }
  }

  /// Sell shares: record SELL transaction + update/delete holding.
  Future<void> sellHolding({
    required String ticker,
    required double shares,
    required double price,
    required DateTime date,
    required double currentShares,
  }) async {
    try {
      // 1) Record SELL transaction
      await addTransaction(
        ticker: ticker,
        type: 'SELL',
        shares: shares,
        price: price,
        date: date,
      );
      _portfolioVersion++;

      // 2) Update or delete holding
      final remaining = currentShares - shares;
      if (remaining <= 0) {
        await _apiClient.deleteHolding(ticker);
        _holdings.removeWhere((h) => h.ticker == ticker.toUpperCase());
      } else {
        // Keep existing avg price, update shares
        final existing = _holdings.cast<PortfolioHolding?>().firstWhere(
          (h) => h!.ticker == ticker.toUpperCase(),
          orElse: () => null,
        );
        await _apiClient.addOrUpdateHolding(
          ticker: ticker,
          shares: remaining,
          avgPrice: existing?.avgPrice ?? 0,
        );
        _holdings = await _apiClient.getHoldings();
      }

      notifyListeners();

      // Refresh AI data to reflect realized P&L + advice changes
      _refreshAIData();
    } catch (e) {
      debugPrint('Sell holding error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Watchlist CRUD
  // ============================================================

  Future<void> addToWatchlist(String ticker, {String? notes}) async {
    final t = ticker.toUpperCase();
    if (isInWatchlist(t)) return;

    try {
      await _apiClient.addWatchlistItem(t, notes: notes);
      // Optimistic update
      _watchlist.add(WatchlistItem(ticker: t, notes: notes));
      notifyListeners();
    } catch (e) {
      debugPrint('Add watchlist error: $e');
      rethrow;
    }
  }

  Future<void> removeFromWatchlist(String ticker) async {
    final t = ticker.toUpperCase();
    try {
      await _apiClient.removeWatchlistItem(t);
      _watchlist.removeWhere((w) => w.ticker == t);
      notifyListeners();
    } catch (e) {
      debugPrint('Remove watchlist error: $e');
      rethrow;
    }
  }

  Future<void> toggleWatchlist(String ticker) async {
    if (isInWatchlist(ticker)) {
      await removeFromWatchlist(ticker);
    } else {
      await addToWatchlist(ticker);
    }
  }

  // ============================================================
  // Transactions
  // ============================================================

  Future<void> addTransaction({
    required String ticker,
    required String type,
    required double shares,
    required double price,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final txn = await _apiClient.addTransaction(
        ticker: ticker,
        type: type,
        shares: shares,
        price: price,
        date: date,
        notes: notes,
      );
      _transactions.insert(0, txn);
      notifyListeners();
    } catch (e) {
      debugPrint('Add transaction error: $e');
      rethrow;
    }
  }

  Future<void> loadTransactions({String? ticker, int limit = 50}) async {
    try {
      _transactions =
          await _apiClient.getTransactions(ticker: ticker, limit: limit);
      notifyListeners();
    } catch (e) {
      debugPrint('Load transactions error: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _apiClient.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete transaction error: $e');
      rethrow;
    }
  }

  // ============================================================
  // AI Advice & Summary
  // ============================================================

  Future<void> loadAdvice({DateTime? date}) async {
    try {
      _advice = await _apiClient.getAdvice(date: date);
      notifyListeners();
    } catch (e) {
      debugPrint('Load advice error: $e');
    }
  }

  Future<void> loadSummary({DateTime? date}) async {
    try {
      _summary = await _apiClient.getSummary(date: date);
      notifyListeners();
    } catch (e) {
      debugPrint('Load summary error: $e');
    }
  }

  // ============================================================
  // Alerts
  // ============================================================

  Future<void> loadAlerts({bool unreadOnly = false}) async {
    try {
      _alerts = await _apiClient.getAlerts(unreadOnly: unreadOnly);
      notifyListeners();
    } catch (e) {
      debugPrint('Load alerts error: $e');
    }
  }

  Future<void> markAlertRead(int alertId) async {
    try {
      await _apiClient.markAlertRead(alertId);
      final idx = _alerts.indexWhere((a) => a.id == alertId);
      if (idx >= 0) {
        // Create updated alert (immutable pattern)
        final old = _alerts[idx];
        _alerts[idx] = UserAlert(
          id: old.id,
          ticker: old.ticker,
          alertType: old.alertType,
          title: old.title,
          message: old.message,
          priority: old.priority,
          data: old.data,
          isRead: true,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark alert read error: $e');
    }
  }

  Future<void> markAllAlertsRead() async {
    try {
      await _apiClient.markAllAlertsRead();
      await loadAlerts();
    } catch (e) {
      debugPrint('Mark all alerts read error: $e');
    }
  }

  // ============================================================
  // Exchange Rate
  // ============================================================

  Future<void> loadExchangeRate() async {
    try {
      _exchangeRate = await _apiClient.getExchangeRate();
      notifyListeners();
    } catch (e) {
      debugPrint('Load exchange rate error: $e');
    }
  }

  // ============================================================
  // Cleanup
  // ============================================================

  /// Clear all data (on logout)
  void clear() {
    _holdings = [];
    _watchlist = [];
    _transactions = [];
    _advice = [];
    _summary = null;
    _alerts = [];
    _exchangeRate = null;
    _portfolioVersion = 0;
    _lastRefreshedAt = null;
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}
