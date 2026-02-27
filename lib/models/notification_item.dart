import '../l10n/app_localizations.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final String ticker;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.ticker,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      notificationType: json['notification_type'] as String,
      ticker: json['ticker'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: _parseAsUtc(json['created_at'] as String),
    );
  }

  String timeAgoLocalized(AppLocalizations l10n) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays == 1) return l10n.timeYesterday;
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return '${createdAt.month}/${createdAt.day}';
  }

  static DateTime _parseAsUtc(String s) {
    final parsed = DateTime.parse(s);
    if (parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second, parsed.millisecond,
    );
  }
}
