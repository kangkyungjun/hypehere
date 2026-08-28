import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/feature_flags.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../models/notification_item.dart';
import '../../widgets/common/empty_state_view.dart';
import '../community/post_detail_screen.dart';
import '../ticker_detail/ticker_detail_screen.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ??
      'http://43.201.45.60:8000/api/accounts';

  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  static const _storage = FlutterSecureStorage();

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
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

      final response = await http
          .get(
            Uri.parse('$_baseUrl/notifications/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['notifications'] as List)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _notifications = list;
          _isLoading = false;
        });
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
      await http
          .post(
            Uri.parse('$_baseUrl/notifications/read/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }

  Future<void> _markSingleRead(NotificationItem item) async {
    if (item.isRead) return;
    try {
      final token = await _getAuthToken();
      if (token == null) return;

      await http
          .post(
            Uri.parse('$_baseUrl/notifications/${item.id}/read/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      // 로컬 상태 즉시 갱신
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == item.id);
          if (idx != -1) {
            _notifications[idx] = _notifications[idx].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      debugPrint('markSingleRead error: $e');
    }
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
    // 개별 읽음 처리
    _markSingleRead(item);

    // [COMMUNITY_FLAG] 커뮤니티 비활성화 시 게시글 알림 탭은 무시(딥링크 차단).
    // 복원: FeatureFlags.kCommunityEnabled = true 로 변경.
    if (FeatureFlags.kCommunityEnabled &&
        item.isCommunityNotification &&
        item.postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: item.postId!),
        ),
      );
    } else if (item.ticker.isNotEmpty) {
      final isNews = item.notificationType.toUpperCase().contains('NEWS');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TickerDetailScreen(
            ticker: item.ticker,
            initialSection: isNews ? 'news' : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (hasUnread && _notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final token = await _storage.read(key: 'auth_token');
                if (token != null) {
                  await _markAllRead(token);
                  _fetchNotifications();
                }
              },
              child: Text(l10n.markAllAsRead),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
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
                separatorBuilder: (_, __) =>
                    const Divider(indent: 16, endIndent: 16, height: 1),
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
    return EmptyStateView(
      icon: Icons.notifications_off_outlined,
      message: l10n.noNotifications,
      subtitle: l10n.notificationsRetentionHint,
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final hasTapTarget = item.ticker.isNotEmpty ||
        (item.isCommunityNotification && item.postId != null);

    return InkWell(
      onTap: hasTapTarget ? () => _onTapNotification(item) : null,
      child: Container(
        color: item.isRead
            ? Colors.transparent
            : context.mlColors.infoBg.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미읽음 표시 (파란 점)
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  right: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.mlColors.accentBlue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 8 + AppSpacing.sm),
            Text(
              _iconForType(item.notificationType),
              style: const TextStyle(fontSize: AppTypography.displayMedium),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: AppTypography.headlineSmall,
                            fontWeight: item.isRead
                                ? AppTypography.semiBold
                                : AppTypography.bold,
                            color: context.mlColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          item.timeAgoLocalized(l10n),
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            fontWeight: AppTypography.medium,
                            color: context.mlColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: context.mlColors.textSecondary,
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
