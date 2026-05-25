import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/portfolio_data.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PortfolioHolding
  // ---------------------------------------------------------------------------
  group('PortfolioHolding', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'ticker': 'AAPL',
          'shares': 10,
          'avg_price': 150.5,
          'name': 'Apple Inc.',
          'name_ko': '애플',
          'current_price': 175.25,
          'change_pct': 2.3,
          'score': 85.0,
          'signal': 'BUY',
          'created_at': '2026-01-15T10:00:00',
          'updated_at': '2026-04-10T14:30:00',
          'notes': 'Long-term hold',
        };

        final holding = PortfolioHolding.fromJson(json);

        expect(holding.ticker, 'AAPL');
        expect(holding.shares, 10.0);
        expect(holding.avgPrice, 150.5);
        expect(holding.name, 'Apple Inc.');
        expect(holding.nameKo, '애플');
        expect(holding.currentPrice, 175.25);
        expect(holding.changePct, 2.3);
        expect(holding.score, 85.0);
        expect(holding.signal, 'BUY');
        expect(holding.createdAt, DateTime(2026, 1, 15, 10, 0, 0));
        expect(holding.updatedAt, DateTime(2026, 4, 10, 14, 30, 0));
        expect(holding.notes, 'Long-term hold');
        expect(holding.instantAdvice, isNull);
      });

      test('parses with nested instant_advice', () {
        final json = {
          'ticker': 'TSLA',
          'shares': 5,
          'avg_price': 200.0,
          'instant_advice': {
            'ticker': 'TSLA',
            'date': '2026-04-10',
            'signal': 'HOLD',
            'confidence': 0.72,
            'summary': 'Maintain position',
            'reasons': {
              'bullish': ['Strong revenue growth'],
              'bearish': ['High valuation'],
            },
            'target_action': 'HOLD',
          },
        };

        final holding = PortfolioHolding.fromJson(json);

        expect(holding.ticker, 'TSLA');
        expect(holding.instantAdvice, isNotNull);
        expect(holding.instantAdvice!.ticker, 'TSLA');
        expect(holding.instantAdvice!.signal, 'HOLD');
        expect(holding.instantAdvice!.confidence, 0.72);
        expect(holding.instantAdvice!.summary, 'Maintain position');
        expect(holding.instantAdvice!.bullishReasons, ['Strong revenue growth']);
        expect(holding.instantAdvice!.bearishReasons, ['High valuation']);
      });

      test('handles null optional fields', () {
        final json = {'ticker': 'GOOG'};

        final holding = PortfolioHolding.fromJson(json);

        expect(holding.ticker, 'GOOG');
        expect(holding.shares, isNull);
        expect(holding.avgPrice, isNull);
        expect(holding.notes, isNull);
        expect(holding.createdAt, isNull);
        expect(holding.updatedAt, isNull);
        expect(holding.name, isNull);
        expect(holding.nameKo, isNull);
        expect(holding.currentPrice, isNull);
        expect(holding.changePct, isNull);
        expect(holding.score, isNull);
        expect(holding.signal, isNull);
        expect(holding.instantAdvice, isNull);
      });

      test('parses integer num values as doubles', () {
        final json = {
          'ticker': 'MSFT',
          'shares': 20,
          'avg_price': 300,
          'current_price': 350,
          'change_pct': 5,
          'score': 90,
        };

        final holding = PortfolioHolding.fromJson(json);

        expect(holding.shares, 20.0);
        expect(holding.shares, isA<double>());
        expect(holding.avgPrice, 300.0);
        expect(holding.currentPrice, 350.0);
        expect(holding.changePct, 5.0);
        expect(holding.score, 90.0);
      });
    });

    group('computed properties', () {
      test('costBasis = shares * avgPrice', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 150.0,
        );
        expect(holding.costBasis, 1500.0);
      });

      test('costBasis returns 0 when shares is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          avgPrice: 150.0,
        );
        expect(holding.costBasis, 0.0);
      });

      test('costBasis returns 0 when avgPrice is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
        );
        expect(holding.costBasis, 0.0);
      });

      test('costBasis returns 0 when both null', () {
        final holding = PortfolioHolding(ticker: 'AAPL');
        expect(holding.costBasis, 0.0);
      });

      test('currentValue = shares * currentPrice', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          currentPrice: 175.0,
        );
        expect(holding.currentValue, 1750.0);
      });

      test('currentValue returns 0 when shares is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          currentPrice: 175.0,
        );
        expect(holding.currentValue, 0.0);
      });

      test('currentValue returns 0 when currentPrice is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
        );
        expect(holding.currentValue, 0.0);
      });

      test('pnl = currentValue - costBasis', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 150.0,
          currentPrice: 175.0,
        );
        expect(holding.pnl, 250.0); // 1750 - 1500
      });

      test('pnl returns 0 when currentPrice is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 150.0,
        );
        expect(holding.pnl, 0.0);
      });

      test('pnl handles negative P&L (loss)', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 200.0,
          currentPrice: 150.0,
        );
        expect(holding.pnl, -500.0); // 1500 - 2000
      });

      test('pnlPct = (pnl / costBasis) * 100', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 100.0,
          currentPrice: 150.0,
        );
        // pnl = 1500 - 1000 = 500; pnlPct = (500 / 1000) * 100 = 50.0
        expect(holding.pnlPct, 50.0);
      });

      test('pnlPct returns 0 when costBasis is 0', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          currentPrice: 175.0,
        );
        expect(holding.pnlPct, 0.0);
      });

      test('pnlPct returns 0 when currentPrice is null', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 150.0,
        );
        expect(holding.pnlPct, 0.0);
      });

      test('pnlPct handles negative percentage (loss)', () {
        final holding = PortfolioHolding(
          ticker: 'AAPL',
          shares: 10,
          avgPrice: 200.0,
          currentPrice: 150.0,
        );
        // pnl = 1500 - 2000 = -500; pnlPct = (-500 / 2000) * 100 = -25.0
        expect(holding.pnlPct, -25.0);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // WatchlistItem
  // ---------------------------------------------------------------------------
  group('WatchlistItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'ticker': 'NVDA',
        'notes': 'AI play',
        'created_at': '2026-03-01T08:00:00',
        'name': 'NVIDIA Corporation',
        'name_ko': '엔비디아',
        'current_price': 950.0,
        'change_pct': 3.5,
        'score': 92.0,
        'signal': 'BUY',
      };

      final item = WatchlistItem.fromJson(json);

      expect(item.ticker, 'NVDA');
      expect(item.notes, 'AI play');
      expect(item.createdAt, DateTime(2026, 3, 1, 8, 0, 0));
      expect(item.name, 'NVIDIA Corporation');
      expect(item.nameKo, '엔비디아');
      expect(item.currentPrice, 950.0);
      expect(item.changePct, 3.5);
      expect(item.score, 92.0);
      expect(item.signal, 'BUY');
    });

    test('fromJson handles null optional fields', () {
      final json = {'ticker': 'AMD'};

      final item = WatchlistItem.fromJson(json);

      expect(item.ticker, 'AMD');
      expect(item.notes, isNull);
      expect(item.createdAt, isNull);
      expect(item.name, isNull);
      expect(item.nameKo, isNull);
      expect(item.currentPrice, isNull);
      expect(item.changePct, isNull);
      expect(item.score, isNull);
      expect(item.signal, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PortfolioTransaction
  // ---------------------------------------------------------------------------
  group('PortfolioTransaction', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 42,
          'ticker': 'AAPL',
          'type': 'BUY',
          'shares': 10.0,
          'price': 150.5,
          'date': '2026-03-15',
          'notes': 'Initial purchase',
          'created_at': '2026-03-15T09:30:00',
          'realized_pnl': 0.0,
        };

        final tx = PortfolioTransaction.fromJson(json);

        expect(tx.id, 42);
        expect(tx.ticker, 'AAPL');
        expect(tx.type, 'BUY');
        expect(tx.shares, 10.0);
        expect(tx.price, 150.5);
        expect(tx.date, DateTime(2026, 3, 15));
        expect(tx.notes, 'Initial purchase');
        expect(tx.createdAt, DateTime(2026, 3, 15, 9, 30, 0));
        expect(tx.realizedPnl, 0.0);
      });

      test('parses SELL type with realized P&L', () {
        final json = {
          'id': 43,
          'ticker': 'TSLA',
          'type': 'SELL',
          'shares': 5,
          'price': 250,
          'date': '2026-04-01',
          'realized_pnl': 125.50,
        };

        final tx = PortfolioTransaction.fromJson(json);

        expect(tx.type, 'SELL');
        expect(tx.realizedPnl, 125.50);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 1,
          'ticker': 'GOOG',
          'type': 'BUY',
          'shares': 2,
          'price': 170.0,
          'date': '2026-01-01',
        };

        final tx = PortfolioTransaction.fromJson(json);

        expect(tx.notes, isNull);
        expect(tx.createdAt, isNull);
        expect(tx.realizedPnl, isNull);
      });

      test('parses integer num values as doubles', () {
        final json = {
          'id': 10,
          'ticker': 'META',
          'type': 'BUY',
          'shares': 3,
          'price': 500,
          'date': '2026-02-20',
        };

        final tx = PortfolioTransaction.fromJson(json);

        expect(tx.shares, 3.0);
        expect(tx.shares, isA<double>());
        expect(tx.price, 500.0);
        expect(tx.price, isA<double>());
      });
    });

    test('totalValue = shares * price', () {
      final tx = PortfolioTransaction(
        id: 1,
        ticker: 'AAPL',
        type: 'BUY',
        shares: 10,
        price: 150.0,
        date: DateTime(2026, 3, 15),
      );
      expect(tx.totalValue, 1500.0);
    });

    test('totalValue with fractional shares', () {
      final tx = PortfolioTransaction(
        id: 2,
        ticker: 'AMZN',
        type: 'BUY',
        shares: 0.5,
        price: 200.0,
        date: DateTime(2026, 3, 15),
      );
      expect(tx.totalValue, 100.0);
    });
  });

  // ---------------------------------------------------------------------------
  // PortfolioAdvice
  // ---------------------------------------------------------------------------
  group('PortfolioAdvice', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'ticker': 'AAPL',
          'date': '2026-04-10',
          'signal': 'BUY',
          'confidence': 0.85,
          'summary': 'Strong buy signal based on momentum',
          'reasons': {
            'bullish': ['Revenue beat expectations', 'iPhone demand strong'],
            'bearish': ['China risks'],
          },
          'target_action': 'BUY',
          'name': 'Apple Inc.',
          'name_ko': '애플',
          'current_price': 175.25,
          'score': 88.0,
        };

        final advice = PortfolioAdvice.fromJson(json);

        expect(advice.ticker, 'AAPL');
        expect(advice.date, DateTime(2026, 4, 10));
        expect(advice.signal, 'BUY');
        expect(advice.confidence, 0.85);
        expect(advice.summary, 'Strong buy signal based on momentum');
        expect(advice.reasons, isNotNull);
        expect(advice.targetAction, 'BUY');
        expect(advice.name, 'Apple Inc.');
        expect(advice.nameKo, '애플');
        expect(advice.currentPrice, 175.25);
        expect(advice.score, 88.0);
      });

      test('handles null optional fields', () {
        final json = {
          'ticker': 'MSFT',
          'date': '2026-04-10',
        };

        final advice = PortfolioAdvice.fromJson(json);

        expect(advice.ticker, 'MSFT');
        expect(advice.date, DateTime(2026, 4, 10));
        expect(advice.signal, isNull);
        expect(advice.confidence, isNull);
        expect(advice.summary, isNull);
        expect(advice.reasons, isNull);
        expect(advice.targetAction, isNull);
        expect(advice.name, isNull);
        expect(advice.nameKo, isNull);
        expect(advice.currentPrice, isNull);
        expect(advice.score, isNull);
      });
    });

    group('bullishReasons', () {
      test('extracts bullish reasons from reasons map', () {
        final advice = PortfolioAdvice(
          ticker: 'AAPL',
          date: DateTime(2026, 4, 10),
          reasons: {
            'bullish': ['Strong earnings', 'Market momentum'],
            'bearish': ['Valuation concerns'],
          },
        );

        expect(advice.bullishReasons, ['Strong earnings', 'Market momentum']);
      });

      test('returns empty list when reasons is null', () {
        final advice = PortfolioAdvice(
          ticker: 'AAPL',
          date: DateTime(2026, 4, 10),
        );
        expect(advice.bullishReasons, isEmpty);
      });

      test('returns empty list when bullish key is missing', () {
        final advice = PortfolioAdvice(
          ticker: 'AAPL',
          date: DateTime(2026, 4, 10),
          reasons: {'bearish': ['Some risk']},
        );
        expect(advice.bullishReasons, isEmpty);
      });

      test('returns empty list when bullish value is null', () {
        final advice = PortfolioAdvice(
          ticker: 'AAPL',
          date: DateTime(2026, 4, 10),
          reasons: {'bullish': null},
        );
        expect(advice.bullishReasons, isEmpty);
      });
    });

    group('bearishReasons', () {
      test('extracts bearish reasons from reasons map', () {
        final advice = PortfolioAdvice(
          ticker: 'TSLA',
          date: DateTime(2026, 4, 10),
          reasons: {
            'bullish': ['Growth potential'],
            'bearish': ['High PE ratio', 'Competition increasing'],
          },
        );

        expect(
          advice.bearishReasons,
          ['High PE ratio', 'Competition increasing'],
        );
      });

      test('returns empty list when reasons is null', () {
        final advice = PortfolioAdvice(
          ticker: 'TSLA',
          date: DateTime(2026, 4, 10),
        );
        expect(advice.bearishReasons, isEmpty);
      });

      test('returns empty list when bearish key is missing', () {
        final advice = PortfolioAdvice(
          ticker: 'TSLA',
          date: DateTime(2026, 4, 10),
          reasons: {'bullish': ['Some strength']},
        );
        expect(advice.bearishReasons, isEmpty);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // PortfolioSummary
  // ---------------------------------------------------------------------------
  group('PortfolioSummary', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'date': '2026-04-10',
        'total_value': 50000.0,
        'total_cost': 40000.0,
        'total_pnl': 10000.0,
        'total_pnl_pct': 25.0,
        'day_pnl': 500.0,
        'day_pnl_pct': 1.0,
        'holdings_detail': [
          {'ticker': 'AAPL', 'value': 25000.0},
          {'ticker': 'TSLA', 'value': 25000.0},
        ],
        'ai_summary': 'Portfolio is performing well',
        'ai_recommendations': [
          {'action': 'BUY', 'ticker': 'NVDA'},
        ],
        'realized_pnl': 2500.0,
        'periods': {
          '1M': {'pnl': 3000.0, 'pnl_pct': 6.5},
          '3M': {'pnl': 8000.0, 'pnl_pct': 18.2},
        },
        'trade_history': [
          {'ticker': 'AAPL', 'type': 'BUY', 'shares': 10},
        ],
      };

      final summary = PortfolioSummary.fromJson(json);

      expect(summary.date, DateTime(2026, 4, 10));
      expect(summary.totalValue, 50000.0);
      expect(summary.totalCost, 40000.0);
      expect(summary.totalPnl, 10000.0);
      expect(summary.totalPnlPct, 25.0);
      expect(summary.dayPnl, 500.0);
      expect(summary.dayPnlPct, 1.0);
      expect(summary.holdingsDetail, hasLength(2));
      expect(summary.holdingsDetail![0]['ticker'], 'AAPL');
      expect(summary.aiSummary, 'Portfolio is performing well');
      expect(summary.aiRecommendations, hasLength(1));
      expect(summary.aiRecommendations![0]['action'], 'BUY');
      expect(summary.realizedPnl, 2500.0);
      expect(summary.periods, isNotNull);
      expect(summary.periods!['1M'], isNotNull);
      expect(summary.tradeHistory, hasLength(1));
      expect(summary.tradeHistory![0]['ticker'], 'AAPL');
    });

    test('fromJson handles null optional fields', () {
      final json = {'date': '2026-04-10'};

      final summary = PortfolioSummary.fromJson(json);

      expect(summary.date, DateTime(2026, 4, 10));
      expect(summary.totalValue, isNull);
      expect(summary.totalCost, isNull);
      expect(summary.totalPnl, isNull);
      expect(summary.totalPnlPct, isNull);
      expect(summary.dayPnl, isNull);
      expect(summary.dayPnlPct, isNull);
      expect(summary.holdingsDetail, isNull);
      expect(summary.aiSummary, isNull);
      expect(summary.aiRecommendations, isNull);
      expect(summary.realizedPnl, isNull);
      expect(summary.periods, isNull);
      expect(summary.tradeHistory, isNull);
    });

    test('fromJson parses integer num values as doubles', () {
      final json = {
        'date': '2026-04-10',
        'total_value': 50000,
        'total_cost': 40000,
        'total_pnl': 10000,
        'total_pnl_pct': 25,
        'day_pnl': 500,
        'day_pnl_pct': 1,
        'realized_pnl': 2500,
      };

      final summary = PortfolioSummary.fromJson(json);

      expect(summary.totalValue, 50000.0);
      expect(summary.totalValue, isA<double>());
      expect(summary.totalCost, 40000.0);
      expect(summary.realizedPnl, 2500.0);
    });
  });

  // ---------------------------------------------------------------------------
  // UserAlert
  // ---------------------------------------------------------------------------
  group('UserAlert', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 100,
        'ticker': 'AAPL',
        'alert_type': 'PRICE_TARGET',
        'title': 'AAPL hit target price',
        'message': 'Apple reached \$180',
        'priority': 'high',
        'data': {'target_price': 180.0, 'current_price': 180.5},
        'is_read': true,
        'created_at': '2026-04-10T12:00:00',
      };

      final alert = UserAlert.fromJson(json);

      expect(alert.id, 100);
      expect(alert.ticker, 'AAPL');
      expect(alert.alertType, 'PRICE_TARGET');
      expect(alert.title, 'AAPL hit target price');
      expect(alert.message, 'Apple reached \$180');
      expect(alert.priority, 'high');
      expect(alert.data, isNotNull);
      expect(alert.data!['target_price'], 180.0);
      expect(alert.isRead, true);
      expect(alert.createdAt, DateTime(2026, 4, 10, 12, 0, 0));
    });

    test('isRead defaults to false when missing from JSON', () {
      final json = {
        'id': 101,
        'alert_type': 'SCORE_CHANGE',
        'title': 'Score changed',
      };

      final alert = UserAlert.fromJson(json);

      expect(alert.isRead, false);
    });

    test('isRead defaults to false when null in JSON', () {
      final json = {
        'id': 102,
        'alert_type': 'SCORE_CHANGE',
        'title': 'Score changed',
        'is_read': null,
      };

      final alert = UserAlert.fromJson(json);

      expect(alert.isRead, false);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 103,
        'alert_type': 'NEWS',
        'title': 'Breaking news',
      };

      final alert = UserAlert.fromJson(json);

      expect(alert.id, 103);
      expect(alert.ticker, isNull);
      expect(alert.message, isNull);
      expect(alert.priority, isNull);
      expect(alert.data, isNull);
      expect(alert.createdAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ExchangeRate
  // ---------------------------------------------------------------------------
  group('ExchangeRate', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'date': '2026-04-10',
        'usd_krw': 1350.25,
      };

      final rate = ExchangeRate.fromJson(json);

      expect(rate.date, DateTime(2026, 4, 10));
      expect(rate.usdKrw, 1350.25);
    });

    test('fromJson parses integer usd_krw as double', () {
      final json = {
        'date': '2026-04-10',
        'usd_krw': 1350,
      };

      final rate = ExchangeRate.fromJson(json);

      expect(rate.usdKrw, 1350.0);
      expect(rate.usdKrw, isA<double>());
    });
  });
}
