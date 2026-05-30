import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// 백그라운드 메시지 핸들러 (top-level function 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');

  // notification 페이로드가 있는 메시지는 OS가 자동 표시하므로 로컬 알림 생략
  // data-only 메시지만 로컬 알림으로 직접 표시
  if (message.notification != null) return;

  final title = message.data['title'] ?? '';
  final body = message.data['body'] ?? '';
  if (title.isEmpty && body.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final isSubscription =
      message.data['type']?.toString().startsWith('SUBSCRIPTION_') ?? false;
  final channelId =
      isSubscription ? 'marketlens_subscription' : 'marketlens_default';
  final channelName =
      isSubscription ? 'Subscription Alerts' : 'MarketLens 알림';

  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase 미초기화 시 크래시 방지: lazy init (iPad 호환 모드 등)
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();

  static final String _baseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ??
      'http://43.201.45.60:8000/api/accounts';

  String? _currentToken;
  bool _tokenRefreshListenerRegistered = false;

  // Stream subscriptions (cancel on dispose to prevent memory leaks)
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  // 알림 탭 시 라우팅 콜백 (cold start 대기 데이터 포함)
  Function(Map<String, dynamic>)? _onNotificationTap;
  Map<String, dynamic>? _pendingNotificationData;

  set onNotificationTap(Function(Map<String, dynamic>)? callback) {
    _onNotificationTap = callback;
    // cold start: 콜백 할당 전에 쌓인 대기 데이터 즉시 처리
    if (callback != null && _pendingNotificationData != null) {
      callback(_pendingNotificationData!);
      _pendingNotificationData = null;
    }
  }

  // 속보 뉴스 포그라운드 콜백 (토스트 표시용)
  Function(String title, String body, Map<String, dynamic> data)?
  onBreakingNewsReceived;

  // 포그라운드 FCM 수신 콜백 (뱃지 카운트 갱신용)
  VoidCallback? onForegroundMessageReceived;

  /// FCM 초기화 (main.dart에서 호출)
  Future<void> initialize() async {
    // Firebase Messaging 인스턴스 획득 (Firebase 미초기화 시 skip)
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[FCM] Firebase not available, skipping FCM setup: $e');
      return;
    }

    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 로컬 알림 채널 설정 (Android)
    const androidChannel = AndroidNotificationChannel(
      'marketlens_default',
      'MarketLens 알림',
      description: '시그널, 뉴스, 커뮤니티 알림',
      importance: Importance.high,
    );

    const subscriptionChannel = AndroidNotificationChannel(
      'marketlens_subscription',
      'Subscription Alerts',
      description: '구독 결제, 갱신, 만료 알림',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(subscriptionChannel);

    // 로컬 알림 초기화
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 기존 구독 취소 (initialize 중복 호출 방지)
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();

    // 포그라운드 메시지 리스너
    _onMessageSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    // 알림 탭으로 앱 열었을 때
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationOpen,
    );

    // 앱이 종료 상태에서 알림으로 열린 경우
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }

    // iOS foreground: 시스템 자동 표시 비활성화 (onMessage → _localNotifications.show()로 통일)
    // alert/sound를 true로 두면 시스템 표시 + _localNotifications.show() 이중 표시됨
    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  /// 권한 요청 + 토큰 등록 (로그인 후 호출)
  Future<void> requestPermissionAndRegister() async {
    if (_messaging == null ||
        _onMessageSub == null ||
        _onMessageOpenedAppSub == null) {
      await initialize();
    }
    if (_messaging == null) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
    } else {
      debugPrint(
        '[FCM] Permission not granted: ${settings.authorizationStatus}',
      );
    }
  }

  Map<String, dynamic> _payloadFromRemoteMessage(RemoteMessage message) {
    return <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title!,
      if (message.notification?.body != null)
        'body': message.notification!.body!,
      if (message.messageId != null) 'message_id': message.messageId!,
    };
  }

  /// FCM 토큰 서버 등록
  Future<void> _registerToken() async {
    try {
      final token = await _messaging?.getToken();
      if (token == null) return;

      _currentToken = token;
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final platform = Platform.isIOS ? 'ios' : 'android';
      final language = PlatformDispatcher.instance.locale.languageCode;

      final response = await http.post(
        Uri.parse('$_baseUrl/device/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': platform,
          'language': language,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[FCM] Token registration failed: '
          '${response.statusCode} ${response.body}',
        );
        return;
      }

      debugPrint('[FCM] Token registered: ${token.substring(0, 20)}...');

      // 토큰 갱신 리스너 (중복 등록 방지)
      if (!_tokenRefreshListenerRegistered) {
        _tokenRefreshListenerRegistered = true;
        await _onTokenRefreshSub?.cancel();
        _onTokenRefreshSub = _messaging?.onTokenRefresh.listen((
          newToken,
        ) async {
          final oldToken = _currentToken;
          _currentToken = newToken;
          final at = await _storage.read(key: 'auth_token');
          if (at != null) {
            // 이전 토큰 비활성화 (같은 기기에 중복 발송 방지)
            if (oldToken != null && oldToken != newToken) {
              try {
                await http.post(
                  Uri.parse('$_baseUrl/device/deactivate/'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Token $at',
                  },
                  body: jsonEncode({'token': oldToken}),
                );
                debugPrint('[FCM] Old token deactivated on refresh');
              } catch (e) {
                debugPrint('[FCM] Old token deactivation failed: $e');
              }
            }

            // 새 토큰 등록
            final p = Platform.isIOS ? 'ios' : 'android';
            final lang = PlatformDispatcher.instance.locale.languageCode;
            final response = await http.post(
              Uri.parse('$_baseUrl/device/register/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token $at',
              },
              body: jsonEncode({
                'token': newToken,
                'platform': p,
                'language': lang,
              }),
            );
            if (response.statusCode < 200 || response.statusCode >= 300) {
              debugPrint(
                '[FCM] Token refresh registration failed: '
                '${response.statusCode} ${response.body}',
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  /// 로그아웃 시 토큰 비활성화
  Future<void> deactivateToken() async {
    _currentToken ??= await _messaging?.getToken();
    if (_currentToken == null) return;

    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('$_baseUrl/device/deactivate/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({'token': _currentToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[FCM] Token deactivation failed: '
          '${response.statusCode} ${response.body}',
        );
        return;
      }

      debugPrint('[FCM] Token deactivated');
    } catch (e) {
      debugPrint('[FCM] Token deactivation error: $e');
    }
  }

  /// 리소스 정리 (메모리 누수 방지)
  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
    _onTokenRefreshSub = null;
    _tokenRefreshListenerRegistered = false;
  }

  /// Watchlist 구독 동기화
  Future<void> syncWatchlistSubscriptions(List<String> tickers) async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final response = await http.put(
        Uri.parse('$_baseUrl/device/subscriptions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({'tickers': tickers}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[FCM] Subscription sync failed: '
          '${response.statusCode} ${response.body}',
        );
        return;
      }

      debugPrint('[FCM] Subscriptions synced: ${tickers.length} tickers');
    } catch (e) {
      debugPrint('[FCM] Subscription sync error: $e');
    }
  }

  /// 포그라운드 메시지 → 로컬 알림 표시
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // 뱃지 카운트 갱신 콜백 호출
    onForegroundMessageReceived?.call();

    // 속보 뉴스: in-app 토스트로 표시 (시스템 알림 대신)
    final payload = _payloadFromRemoteMessage(message);

    if (payload['type'] == 'BREAKING_NEWS' && onBreakingNewsReceived != null) {
      onBreakingNewsReceived!(
        notification.title ?? '',
        notification.body ?? '',
        payload,
      );
      return;
    }

    // 구독 알림은 별도 채널로 라우팅
    final isSubscription =
        payload['type']?.toString().startsWith('SUBSCRIPTION_') ?? false;
    final androidDetails = isSubscription
        ? const AndroidNotificationDetails(
            'marketlens_subscription',
            'Subscription Alerts',
            importance: Importance.high,
            priority: Priority.high,
          )
        : const AndroidNotificationDetails(
            'marketlens_default',
            'MarketLens 알림',
            importance: Importance.high,
            priority: Priority.high,
          );

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  /// 알림 탭으로 앱 진입 시 라우팅
  void _handleNotificationOpen(RemoteMessage message) {
    final data = _payloadFromRemoteMessage(message);
    if (_onNotificationTap != null) {
      _onNotificationTap!(data);
    } else {
      // cold start: 콜백이 아직 등록 안 됨 → 대기
      _pendingNotificationData = data;
    }
  }

  /// 로컬 알림 탭 핸들러
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        if (_onNotificationTap != null) {
          _onNotificationTap!(data);
        } else {
          _pendingNotificationData = data;
        }
      } catch (_) {}
    }
  }
}
