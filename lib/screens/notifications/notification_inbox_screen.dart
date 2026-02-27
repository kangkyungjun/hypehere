import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_item.dart';
import '../ticker_detail/ticker_detail_screen.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['notifications'] as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _notifications = list;
          _isLoading = false;
        });

        // Mark all as read on enter
        _markAllRead(token);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'HTTP ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _error = 'Timeout';
      });
    } on SocketException {
      setState(() {
        _isLoading = false;
        _error = 'Network error';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markAllRead(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  String _iconForType(String type) {
    switch (type) {
      case 'STRONG_BUY':
        return '\u{1F4C8}'; // 📈
      case 'STRONG_SELL':
        return '\u{1F4C9}'; // 📉
      case 'NEWS_BULLISH':
      case 'NEWS_BEARISH':
      case 'BULLISH_NEWS_SURGE':
        return '\u{1F4F0}'; // 📰
      case 'COMMENT_ON_MY_POST':
      case 'COMMENT_ON_THREAD':
        return '\u{1F4AC}'; // 💬
      case 'HOT_POST':
        return '\u{1F525}'; // 🔥
      case 'NEW_POST':
        return '\u{1F4DD}'; // 📝
      case 'DAILY_SUMMARY':
        return '\u{1F4CA}'; // 📊
      default:
        return '\u{1F514}'; // 🔔
    }
  }

  void _onTapNotification(NotificationItem item) {
    if (item.ticker.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TickerDetailScreen(ticker: item.ticker),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchNotifications,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState(l10n, theme)
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(
                          indent: 16,
                          endIndent: 16,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(
                            _notifications[index],
                            l10n,
                            theme,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '\u{1F515}', // 🔕
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noNotifications,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.notificationsRetentionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: item.ticker.isNotEmpty ? () => _onTapNotification(item) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _iconForType(item.notificationType),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timeAgoLocalized(l10n),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
