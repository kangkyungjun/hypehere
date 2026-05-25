import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/market_event.dart';
import 'package:marketlens/theme/app_colors.dart';

void main() {
  group('MarketCalendarEvent', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 'evt-001',
          'date': '2026-04-15',
          'event_type': 'earnings',
          'title': 'AAPL Q2 Earnings',
          'description': 'Apple quarterly earnings report',
          'ticker': 'AAPL',
          'importance': 'high',
        };

        final event = MarketCalendarEvent.fromJson(json);

        expect(event.id, 'evt-001');
        expect(event.date, '2026-04-15');
        expect(event.eventType, 'earnings');
        expect(event.title, 'AAPL Q2 Earnings');
        expect(event.description, 'Apple quarterly earnings report');
        expect(event.ticker, 'AAPL');
        expect(event.importance, 'high');
      });

      test('description defaults to null when absent', () {
        final json = {
          'id': 'evt-002',
          'date': '2026-04-16',
          'event_type': 'fomc',
          'title': 'FOMC Meeting',
          'ticker': null,
          'importance': 'high',
        };

        final event = MarketCalendarEvent.fromJson(json);

        expect(event.description, isNull);
        expect(event.ticker, isNull);
      });

      test('importance defaults to medium when null', () {
        final json = {
          'id': 'evt-003',
          'date': '2026-04-17',
          'event_type': 'economic',
          'title': 'CPI Report',
          'description': null,
          'ticker': null,
          'importance': null,
        };

        final event = MarketCalendarEvent.fromJson(json);

        expect(event.importance, 'medium');
      });
    });

    group('colorOf', () {
      const mlc = MarketLensColors.light;

      MarketCalendarEvent makeEvent(String eventType) {
        return MarketCalendarEvent.fromJson({
          'id': 'c-1',
          'date': '2026-01-01',
          'event_type': eventType,
          'title': 'Test',
          'importance': 'low',
        });
      }

      test('fomc returns eventFedColor', () {
        expect(makeEvent('fomc').colorOf(mlc), mlc.eventFedColor);
      });

      test('fed_speech returns eventFedColor', () {
        expect(makeEvent('fed_speech').colorOf(mlc), mlc.eventFedColor);
      });

      test('earnings returns eventEarningsColor', () {
        expect(makeEvent('earnings').colorOf(mlc), mlc.eventEarningsColor);
      });

      test('economic returns eventEconomicColor', () {
        expect(makeEvent('economic').colorOf(mlc), mlc.eventEconomicColor);
      });

      test('options_expiry returns eventOptionsColor', () {
        expect(makeEvent('options_expiry').colorOf(mlc), mlc.eventOptionsColor);
      });

      test('conference returns eventConferenceColor', () {
        expect(makeEvent('conference').colorOf(mlc), mlc.eventConferenceColor);
      });

      test('product_launch returns eventConferenceColor', () {
        expect(makeEvent('product_launch').colorOf(mlc), mlc.eventConferenceColor);
      });

      test('dividend returns eventDividendColor', () {
        expect(makeEvent('dividend').colorOf(mlc), mlc.eventDividendColor);
      });

      test('shareholder returns eventShareholderColor', () {
        expect(makeEvent('shareholder').colorOf(mlc), mlc.eventShareholderColor);
      });

      test('unknown event type returns roleRegularColor', () {
        expect(makeEvent('unknown_type').colorOf(mlc), mlc.roleRegularColor);
      });
    });

    group('icon getter', () {
      MarketCalendarEvent makeEvent(String eventType) {
        return MarketCalendarEvent.fromJson({
          'id': 'i-1',
          'date': '2026-01-01',
          'event_type': eventType,
          'title': 'Test',
          'importance': 'low',
        });
      }

      test('fomc returns account_balance', () {
        expect(makeEvent('fomc').icon, Icons.account_balance);
      });

      test('fed_speech returns account_balance', () {
        expect(makeEvent('fed_speech').icon, Icons.account_balance);
      });

      test('earnings returns bar_chart', () {
        expect(makeEvent('earnings').icon, Icons.bar_chart);
      });

      test('economic returns show_chart', () {
        expect(makeEvent('economic').icon, Icons.show_chart);
      });

      test('options_expiry returns timer', () {
        expect(makeEvent('options_expiry').icon, Icons.timer);
      });

      test('conference returns groups', () {
        expect(makeEvent('conference').icon, Icons.groups);
      });

      test('product_launch returns rocket_launch', () {
        expect(makeEvent('product_launch').icon, Icons.rocket_launch);
      });

      test('dividend returns payments', () {
        expect(makeEvent('dividend').icon, Icons.payments);
      });

      test('shareholder returns how_to_vote', () {
        expect(makeEvent('shareholder').icon, Icons.how_to_vote);
      });

      test('unknown event type returns event', () {
        expect(makeEvent('something_else').icon, Icons.event);
      });
    });
  });

  group('EventCalendarData', () {
    group('fromJson', () {
      test('parses year, month, totalCount, and byDate with nested events', () {
        final json = {
          'year': 2026,
          'month': 4,
          'total_count': 2,
          'by_date': {
            '2026-04-15': [
              {
                'id': 'evt-100',
                'date': '2026-04-15',
                'event_type': 'earnings',
                'title': 'AAPL Earnings',
                'description': 'Quarterly report',
                'ticker': 'AAPL',
                'importance': 'high',
              },
            ],
            '2026-04-20': [
              {
                'id': 'evt-101',
                'date': '2026-04-20',
                'event_type': 'fomc',
                'title': 'FOMC Decision',
                'description': null,
                'ticker': null,
                'importance': 'high',
              },
            ],
          },
        };

        final data = EventCalendarData.fromJson(json);

        expect(data.year, 2026);
        expect(data.month, 4);
        expect(data.totalCount, 2);
        expect(data.byDate.length, 2);
        expect(data.byDate['2026-04-15']!.length, 1);
        expect(data.byDate['2026-04-15']!.first.id, 'evt-100');
        expect(data.byDate['2026-04-15']!.first.eventType, 'earnings');
        expect(data.byDate['2026-04-15']!.first.ticker, 'AAPL');
        expect(data.byDate['2026-04-20']!.length, 1);
        expect(data.byDate['2026-04-20']!.first.id, 'evt-101');
        expect(data.byDate['2026-04-20']!.first.eventType, 'fomc');
      });

      test('handles empty byDate map', () {
        final json = {
          'year': 2026,
          'month': 5,
          'total_count': 0,
          'by_date': <String, dynamic>{},
        };

        final data = EventCalendarData.fromJson(json);

        expect(data.year, 2026);
        expect(data.month, 5);
        expect(data.totalCount, 0);
        expect(data.byDate, isEmpty);
      });

      test('handles null byDate', () {
        final json = {
          'year': 2026,
          'month': 6,
          'total_count': null,
          'by_date': null,
        };

        final data = EventCalendarData.fromJson(json);

        expect(data.year, 2026);
        expect(data.month, 6);
        expect(data.totalCount, 0);
        expect(data.byDate, isEmpty);
      });
    });
  });
}
