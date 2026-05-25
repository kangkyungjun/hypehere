import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/notification_item.dart';

void main() {
  group('NotificationItem', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 42,
          'title': 'Price Alert',
          'body': 'AAPL crossed \$200',
          'notification_type': 'price_alert',
          'ticker': 'AAPL',
          'is_read': true,
          'created_at': '2026-04-10T14:30:00Z',
        };

        final item = NotificationItem.fromJson(json);

        expect(item.id, 42);
        expect(item.title, 'Price Alert');
        expect(item.body, 'AAPL crossed \$200');
        expect(item.notificationType, 'price_alert');
        expect(item.ticker, 'AAPL');
        expect(item.isRead, true);
        expect(item.createdAt, DateTime.utc(2026, 4, 10, 14, 30, 0));
      });

      test('ticker defaults to empty string when null', () {
        final json = {
          'id': 1,
          'title': 'Market Open',
          'body': 'Markets are now open',
          'notification_type': 'market',
          'ticker': null,
          'is_read': false,
          'created_at': '2026-04-10T09:30:00Z',
        };

        final item = NotificationItem.fromJson(json);

        expect(item.ticker, '');
      });

      test('isRead defaults to false when null', () {
        final json = {
          'id': 2,
          'title': 'News',
          'body': 'Breaking news',
          'notification_type': 'news',
          'ticker': 'MSFT',
          'is_read': null,
          'created_at': '2026-04-10T12:00:00Z',
        };

        final item = NotificationItem.fromJson(json);

        expect(item.isRead, false);
      });

      test('created_at with UTC suffix is parsed as UTC', () {
        final json = {
          'id': 3,
          'title': 'Test',
          'body': 'Body',
          'notification_type': 'test',
          'ticker': '',
          'is_read': false,
          'created_at': '2026-07-15T08:45:30Z',
        };

        final item = NotificationItem.fromJson(json);

        expect(item.createdAt.isUtc, true);
        expect(item.createdAt.year, 2026);
        expect(item.createdAt.month, 7);
        expect(item.createdAt.day, 15);
        expect(item.createdAt.hour, 8);
        expect(item.createdAt.minute, 45);
        expect(item.createdAt.second, 30);
      });

      test('created_at without UTC suffix is converted to UTC', () {
        final json = {
          'id': 4,
          'title': 'Test',
          'body': 'Body',
          'notification_type': 'test',
          'ticker': '',
          'is_read': false,
          'created_at': '2026-03-20T16:20:10.500',
        };

        final item = NotificationItem.fromJson(json);

        expect(item.createdAt.isUtc, true);
        expect(item.createdAt.year, 2026);
        expect(item.createdAt.month, 3);
        expect(item.createdAt.day, 20);
        expect(item.createdAt.hour, 16);
        expect(item.createdAt.minute, 20);
        expect(item.createdAt.second, 10);
        expect(item.createdAt.millisecond, 500);
      });
    });
  });
}
