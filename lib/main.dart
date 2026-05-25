import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';
import 'theme/app_shadow.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'providers/watchlist_provider.dart';
import 'providers/recent_search_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/coach_mark_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/watchlist/watchlist_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/news/news_combined_screen.dart';
import 'screens/ai_lens/ai_lens_screen.dart';
import 'screens/holdings/holdings_screen.dart';
import 'services/notification_service.dart';
import 'screens/notifications/notification_inbox_screen.dart';
import 'screens/ticker_detail/ticker_detail_screen.dart';
import 'screens/community/post_detail_screen.dart';
import 'models/news_data.dart';
import 'widgets/news/market_news_modal.dart';
import 'widgets/ads/app_open_ad_helper.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load error: $e');
  }

  // Initialize Firebase (timeout: iPad 호환 모드 hang 방지)
  try {
    await Firebase.initializeApp()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Initialize FCM Notification Service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('FCM init error: $e');
  }

  // Initialize RevenueCat (IAP 구독) — fire-and-forget, 내부 재시도 처리
  final subscriptionProvider = SubscriptionProvider();
  subscriptionProvider.initialize();

  // Initialize Google AdMob (timeout: iPad 호환 모드 hang 방지)
  try {
    await MobileAds.instance.initialize()
        .timeout(const Duration(seconds: 10));
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['GADSimulatorID']),
      );
    }
  } catch (e) {
    debugPrint('AdMob init error: $e');
  }

  // Preload App Open Ad
  AppOpenAdHelper.instance.loadAd();

  // Initialize Providers
  final watchlistProvider = WatchlistProvider();
  try {
    await watchlistProvider.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('WatchlistProvider init error: $e');
  }

  final recentSearchProvider = RecentSearchProvider();
  try {
    await recentSearchProvider.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('RecentSearchProvider init error: $e');
  }

  final localeProvider = LocaleProvider();
  try {
    await localeProvider.loadSavedLocale()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('LocaleProvider init error: $e');
  }

  final coachMarkProvider = CoachMarkProvider();
  try {
    await coachMarkProvider.load()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('CoachMarkProvider init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: watchlistProvider),
        ChangeNotifierProvider.value(value: recentSearchProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: coachMarkProvider),
      ],
      child: const MarketLensApp(),
    ),
  );
}

class MarketLensApp extends StatelessWidget {
  const MarketLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'MarketLens',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        // MarketLens brand colors (HypeHere와 다름!)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB), // Deep Trust Blue (brand seed)
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        extensions: const [MarketLensColors.light],

        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,   // Android: 어두운 아이콘
            statusBarBrightness: Brightness.light,      // iOS: 밝은 배경 → 어두운 아이콘
          ),
        ),

        // Bottom navigation theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: MarketLensColors.light.accentBlue,
          unselectedItemColor: MarketLensColors.light.textTertiary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: AppTypography.semiBold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: AppTypography.regular,
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          filled: true,
          fillColor: MarketLensColors.light.sectionBackground,
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB), // Deep Trust Blue (brand seed)
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        extensions: const [MarketLensColors.dark],

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,  // Android: 밝은 아이콘
            statusBarBrightness: Brightness.dark,       // iOS: 어두운 배경 → 밝은 아이콘
          ),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: MarketLensColors.dark.accentBlue,
          unselectedItemColor: MarketLensColors.dark.textTertiary,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedLabelStyle: const TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: AppTypography.semiBold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: AppTypography.regular,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          filled: true,
          fillColor: MarketLensColors.dark.sectionBackground,
        ),
      ),

      themeMode: ThemeMode.system,
      home: UpgradeAlert(
        upgrader: Upgrader(
          messages: _MarketLensUpgraderMessages(
            code: localeProvider.locale?.languageCode ?? 'en',
          ),
          durationUntilAlertAgain: const Duration(days: 1),
        ),
        showIgnore: false,
        showLater: true,
        showReleaseNotes: false,
        dialogStyle: UpgradeDialogStyle.material,
        child: const MainNavigationScreen(),
      ),
    );
  }
}

/// Custom upgrader messages matching MarketLens tone.
class _MarketLensUpgraderMessages extends UpgraderMessages {
  _MarketLensUpgraderMessages({super.code});

  @override
  String? message(UpgraderMessage messageKey) {
    String? custom;
    switch (languageCode) {
      case 'ko': custom = _ko(messageKey);
      case 'en': custom = _en(messageKey);
      case 'ja': custom = _ja(messageKey);
      case 'zh': custom = _zh(messageKey);
      case 'es': custom = _es(messageKey);
    }
    if (custom != null) return custom;
    return super.message(messageKey);
  }

  String? _ko(UpgraderMessage key) => switch (key) {
    UpgraderMessage.title => '새 버전이 출시되었습니다',
    UpgraderMessage.body => '더 나은 MarketLens를 만나보세요.\n최신 기능과 개선 사항이 준비되어 있습니다.',
    UpgraderMessage.prompt => '',
    UpgraderMessage.buttonTitleUpdate => '업데이트하기',
    UpgraderMessage.buttonTitleLater => '나중에',
    UpgraderMessage.buttonTitleIgnore => '무시',
    UpgraderMessage.releaseNotes => '새로운 기능',
  };

  String? _en(UpgraderMessage key) => switch (key) {
    UpgraderMessage.title => 'Update Available',
    UpgraderMessage.body => 'A new version of MarketLens is available\nwith the latest features and improvements.',
    UpgraderMessage.prompt => '',
    UpgraderMessage.buttonTitleUpdate => 'Update Now',
    UpgraderMessage.buttonTitleLater => 'Later',
    UpgraderMessage.buttonTitleIgnore => 'Skip',
    UpgraderMessage.releaseNotes => 'Release Notes',
  };

  String? _ja(UpgraderMessage key) => switch (key) {
    UpgraderMessage.title => '新しいバージョンがあります',
    UpgraderMessage.body => 'MarketLensの最新バージョンが公開されました。\n新機能と改善をお試しください。',
    UpgraderMessage.prompt => '',
    UpgraderMessage.buttonTitleUpdate => 'アップデート',
    UpgraderMessage.buttonTitleLater => '後で',
    _ => null,
  };

  String? _zh(UpgraderMessage key) => switch (key) {
    UpgraderMessage.title => '新版本已发布',
    UpgraderMessage.body => 'MarketLens 新版本已上线，\n包含最新功能和改进。',
    UpgraderMessage.prompt => '',
    UpgraderMessage.buttonTitleUpdate => '立即更新',
    UpgraderMessage.buttonTitleLater => '稍后',
    _ => null,
  };

  String? _es(UpgraderMessage key) => switch (key) {
    UpgraderMessage.title => 'Nueva versión disponible',
    UpgraderMessage.body => 'Una nueva versión de MarketLens está disponible\ncon las últimas funciones y mejoras.',
    UpgraderMessage.prompt => '',
    UpgraderMessage.buttonTitleUpdate => 'Actualizar',
    UpgraderMessage.buttonTitleLater => 'Más tarde',
    _ => null,
  };
}

/// 메인 네비게이션 (5탭 구조)
///
/// Settings는 AppBar 우측 아이콘으로 분리
/// Home → News → AI Analysis → Watchlist → Holdings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  AuthProvider? _authProvider;
  VoidCallback? _authListener;

  // 앱 lifecycle (resume 시 뱃지 갱신)
  late final AppLifecycleListener _lifecycleListener;

  // 속보 토스트 상태
  String? _breakingTitle;
  String? _breakingBody;
  Map<String, dynamic>? _breakingData;
  Timer? _breakingDismissTimer;

  static final String _authBaseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';

  // 5개 탭: Home, News, AI Analysis, Watchlist, Holdings
  final List<Widget> _screens = const [
    DashboardScreen(), // 마켓 (기존 대시보드)
    NewsCombinedScreen(), // 뉴스 (캘린더+뉴스 내부탭)
    AILensScreen(), // AI 렌즈 (AI 시그널 분석)
    WatchlistScreen(), // 관심종목
    HoldingsScreen(), // 보유종목
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();

    // 앱 resume 시 뱃지 카운트 + 구독/권한 자동 동기화
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _fetchUnreadCount();
        // 자동 구독/권한 동기화 (매니저 승급 등 즉시 반영)
        if (_authProvider?.isLoggedIn ?? false) {
          final sub = context.read<SubscriptionProvider>();
          sub.checkStatus();
          _authProvider?.refreshUserInfo();
        }
      },
    );

    // 상태바 아이콘 가시성 보장 (제조사 강제 다크모드 대응)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      );

      // Show App Open Ad on first launch (Gold users excluded)
      final auth = context.read<AuthProvider>();
      if (!auth.shouldHideAds) {
        AppOpenAdHelper.instance.showAdIfAvailable();
      }
    });

    // FCM 포그라운드 수신 시 뱃지 카운트 갱신
    NotificationService().onForegroundMessageReceived = () {
      _fetchUnreadCount();
    };

    // 속보 뉴스 포그라운드 콜백 등록
    NotificationService().onBreakingNewsReceived = (title, body, data) {
      if (mounted) {
        _breakingDismissTimer?.cancel();
        setState(() {
          _breakingTitle = title;
          _breakingBody = body;
          _breakingData = data;
        });
        _breakingDismissTimer = Timer(
          const Duration(seconds: 10),
          _dismissBreakingToast,
        );
      }
    };

    // FCM 알림 탭 시 내비게이션 콜백 등록 (cold start 대기 데이터도 처리)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().onNotificationTap = _handleNotificationNavigation;
    });

    // Auth ↔ Watchlist/Portfolio/Subscription 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      final watchlist = context.read<WatchlistProvider>();
      final portfolio = context.read<PortfolioProvider>();
      final sub = context.read<SubscriptionProvider>();

      // 초기 동기화 (앱 시작 시 auth 상태 확인 완료 후)
      watchlist.switchUser(_authProvider!.currentUser?.id);
      if (_authProvider!.isLoggedIn) {
        portfolio.initialize();
        // logIn 내부에서 미초기화 시 자동 initialize() 호출
        sub.logIn(_authProvider!.currentUser!.id.toString());
      }

      // RevenueCat 실시간 리스너 → role 변경 시 userInfo 갱신
      sub.setupListener(() {
        _authProvider?.refreshUserInfo();
      });

      // 이후 auth 변경 감지
      _authListener = () {
        watchlist.switchUser(_authProvider!.currentUser?.id);
        if (_authProvider!.isLoggedIn) {
          portfolio.initialize();
          sub.logIn(_authProvider!.currentUser!.id.toString());
          _fetchUnreadCount(); // 로그인 직후 뱃지 갱신
        } else {
          portfolio.clear();
          sub.logOut();
          setState(() => _unreadNotificationCount = 0); // 로그아웃 시 뱃지 초기화
        }
      };
      _authProvider!.addListener(_authListener!);
    });
  }

  @override
  void dispose() {
    _breakingDismissTimer?.cancel();
    _lifecycleListener.dispose();
    if (_authListener != null && _authProvider != null) {
      _authProvider!.removeListener(_authListener!);
    }
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_authBaseUrl/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final json = jsonDecode(response.body);
        setState(() {
          _unreadNotificationCount = json['unread_count'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('fetchUnreadCount error: $e');
    }
  }

  /// FCM 알림 탭 시 내비게이션 처리 (type 기반 우선 라우팅)
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = data['type'] as String? ?? '';
    final ticker = data['ticker'] as String?;
    final topTicker = data['top_ticker'] as String?;
    final postId = data['post_id'] as String?;

    // ── 1. 커뮤니티 (post_id) → PostDetailScreen ──
    if (postId != null && postId.isNotEmpty) {
      final id = int.tryParse(postId);
      if (id != null) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: id)));
        _fetchUnreadCount();
        return;
      }
    }

    // ── 2. 뉴스 알림 → 모달 or TickerDetail(news 섹션) ──
    if (type == 'NEWS_BULLISH' || type == 'NEWS_BEARISH' ||
        type == 'BREAKING_NEWS' || type == 'MARKET_NEWS') {
      if (ticker == 'MARKET' || type == 'MARKET_NEWS') {
        // MARKET 뉴스 → News 탭 + 모달 표시
        setState(() => _currentIndex = 1);
        final title = data['title'] as String?;
        if (title != null && title.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              MarketNewsModal.show(context, NewsItem.fromNotification(data));
            }
          });
        }
      } else if (ticker != null && ticker.isNotEmpty) {
        // 종목 뉴스 → TickerDetail 뉴스 섹션 스크롤
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TickerDetailScreen(
                ticker: ticker, initialSection: 'news')));
      }
      _fetchUnreadCount();
      return;
    }

    // ── 3. 호재 급상승 → TickerDetail 뉴스 섹션 ──
    if (type == 'BULLISH_NEWS_SURGE') {
      if (ticker != null && ticker.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TickerDetailScreen(
                ticker: ticker, initialSection: 'news')));
      }
      _fetchUnreadCount();
      return;
    }

    // ── 4. 시그널 (STRONG_BUY/SELL) → TickerDetail ──
    if (type == 'STRONG_BUY' || type == 'STRONG_SELL') {
      if (ticker != null && ticker.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TickerDetailScreen(ticker: ticker)));
      }
      _fetchUnreadCount();
      return;
    }

    // ── 5. 포트폴리오 자문 → TickerDetail ──
    if (type == 'PORTFOLIO_ADVICE') {
      if (ticker != null && ticker.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TickerDetailScreen(ticker: ticker)));
      }
      _fetchUnreadCount();
      return;
    }

    // ── 6. 예약 알림 (top_ticker로 라우팅) ──
    if (type == 'MORNING_BRIEFING' || type == 'CLOSING_REPORT' ||
        type == 'MARKET_OPEN') {
      if (topTicker != null && topTicker.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TickerDetailScreen(ticker: topTicker)));
        _fetchUnreadCount();
        return;
      }
      setState(() => _currentIndex = 0);
      _fetchUnreadCount();
      return;
    }

    // ── 7. 일일 요약 → Dashboard ──
    if (type == 'DAILY_SUMMARY') {
      setState(() => _currentIndex = 0);
      _fetchUnreadCount();
      return;
    }

    // ── 8. 기타 ticker → TickerDetail ──
    if (ticker != null && ticker.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => TickerDetailScreen(ticker: ticker)));
      _fetchUnreadCount();
      return;
    }

    if (topTicker != null && topTicker.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => TickerDetailScreen(ticker: topTicker)));
      _fetchUnreadCount();
      return;
    }

    // ── 9. default → Dashboard ──
    setState(() => _currentIndex = 0);
    _fetchUnreadCount();
  }

  void _dismissBreakingToast() {
    _breakingDismissTimer?.cancel();
    if (mounted) {
      setState(() {
        _breakingTitle = null;
        _breakingBody = null;
        _breakingData = null;
      });
    }
  }

  void _onBreakingToastTap() {
    final ticker = _breakingData?['ticker'] as String?;
    _dismissBreakingToast();
    if (ticker != null && ticker.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TickerDetailScreen(ticker: ticker),
        ),
      );
    }
  }

  Widget _buildBreakingToast() {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onBreakingToastTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: AppShadow.lg(theme.colorScheme.error.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs),
                child: Text('🚨', style: TextStyle(fontSize: AppTypography.headlineLarge)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _breakingTitle ?? '',
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: AppTypography.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_breakingBody != null && _breakingBody!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _breakingBody!,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: _dismissBreakingToast,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 34,
        title: const Text(
          'MarketLens',
          style: TextStyle(fontWeight: AppTypography.bold),
        ),
        actions: [
          // 검색 아이콘
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchHint,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExploreScreen()),
            ),
          ),
          // 알림 아이콘 (벨 + 뱃지)
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotificationCount > 0,
              label: Text(
                _unreadNotificationCount > 99
                    ? '99+'
                    : '$_unreadNotificationCount',
                style: TextStyle(fontSize: AppTypography.micro),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: l10n.notifications,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationInboxScreen(),
                ),
              );
              // Refresh badge after returning from inbox
              _fetchUnreadCount();
            },
          ),
          // Settings 아이콘 (별도 탭 아님!)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // 속보 토스트
          if (_breakingTitle != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBreakingToast(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 5개 탭 고정 표시
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.tabHome,
            tooltip: l10n.tabHomeTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.newspaper_outlined),
            activeIcon: const Icon(Icons.newspaper),
            label: l10n.tabNews,
            tooltip: l10n.tabNewsTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: const Icon(Icons.auto_awesome),
            label: l10n.tabAIAnalysis,
            tooltip: l10n.tabAILensTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.star_border),
            activeIcon: const Icon(Icons.star),
            label: l10n.tabWatchlist,
            tooltip: l10n.tabWatchlistTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.tabHoldings,
            tooltip: l10n.tabHoldingsTooltip,
          ),
        ],
      ),
    );
  }
}
