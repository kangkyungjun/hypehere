import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'theme/app_duration.dart';
import 'theme/app_typography.dart';
import 'providers/watchlist_provider.dart';
import 'providers/recent_search_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/portfolio_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/watchlist/watchlist_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/news/news_combined_screen.dart';
import 'screens/ai_lens/ai_lens_screen.dart';
import 'screens/holdings/holdings_screen.dart';
import 'models/indices_data.dart';
import 'services/analytics_api_client.dart';
import 'services/notification_service.dart';
import 'screens/notifications/notification_inbox_screen.dart';
import 'screens/ticker_detail/ticker_detail_screen.dart';
import 'screens/community/post_detail_screen.dart';

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

  // Initialize Google AdMob (timeout: iPad 호환 모드 hang 방지)
  try {
    await MobileAds.instance.initialize()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('AdMob init error: $e');
  }

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: watchlistProvider),
        ChangeNotifierProvider.value(value: recentSearchProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
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
          seedColor: const Color(0xFF1E88E5), // Professional blue (seed — not a display color)
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
          unselectedItemColor: MarketLensColors.light.neutralColor,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
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
          seedColor: const Color(0xFF1E88E5), // seed — same brand blue
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
          unselectedItemColor: Color(0xFF9E9E9E), // intentional grey 500 for both themes
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
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
      home: const MainNavigationScreen(),
    );
  }
}

/// 메인 네비게이션 (5탭 구조)
///
/// ⚠️ Settings는 AppBar 우측 아이콘으로 분리
/// 📊 Market → 📰 News → 🤖 AI Lens → ⭐ Watchlist → 💼 Holdings
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showIndicesBar = true;
  MarketIndicesData? _indicesData;
  int _unreadNotificationCount = 0;
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
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

  // 5개 탭: Market, News, AI Lens, Watchlist, Holdings
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
    _loadIndices();
    _fetchUnreadCount();

    // 앱 resume 시 뱃지 카운트 갱신
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _fetchUnreadCount();
        _loadIndices();
      },
    );

    // 상태바 아이콘 가시성 보장 (제조사 강제 다크모드 대응)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      );
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

    // Auth ↔ Watchlist/Portfolio 동기화: 로그인/로그아웃 시 유저별 데이터 전환
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      final watchlist = context.read<WatchlistProvider>();
      final portfolio = context.read<PortfolioProvider>();

      // 초기 동기화 (앱 시작 시 auth 상태 확인 완료 후)
      watchlist.switchUser(_authProvider!.currentUser?.id);
      if (_authProvider!.isLoggedIn) {
        portfolio.initialize();
      }

      // 이후 auth 변경 감지
      _authListener = () {
        watchlist.switchUser(_authProvider!.currentUser?.id);
        if (_authProvider!.isLoggedIn) {
          portfolio.initialize();
          _fetchUnreadCount(); // 로그인 직후 뱃지 갱신
        } else {
          portfolio.clear();
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
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadIndices() async {
    try {
      final data = await _apiClient.getMarketIndices();
      if (mounted) {
        setState(() => _indicesData = data);
      }
    } catch (_) {}
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

  /// FCM 알림 탭 시 내비게이션 처리
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = data['type'] as String? ?? '';
    final ticker = data['ticker'] as String?;
    final topTicker = data['top_ticker'] as String?;
    final postId = data['post_id'] as String?;

    // 커뮤니티 알림 (post_id 있음) → PostDetailScreen
    if (postId != null && postId.isNotEmpty) {
      final id = int.tryParse(postId);
      if (id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: id)),
        );
        _fetchUnreadCount();
        return;
      }
    }

    // MARKET 뉴스 알림 → News 탭 (index 1)
    if (ticker == 'MARKET' || type == 'MARKET_NEWS') {
      setState(() => _currentIndex = 1);
      _fetchUnreadCount();
      return;
    }

    // 종목 관련 알림 → TickerDetailScreen
    if (ticker != null && ticker.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
      );
      _fetchUnreadCount();
      return;
    }

    // 시장 전체 알림 (top_ticker 있음) → TickerDetailScreen
    if (topTicker != null && topTicker.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: topTicker)),
      );
      _fetchUnreadCount();
      return;
    }

    // 그 외 (MORNING_BRIEFING 등) → Dashboard 탭
    setState(() => _currentIndex = 0);
    _loadIndices();
    _fetchUnreadCount();
  }

  /// 지수 이름 축약
  String _shortName(String code) {
    switch (code) {
      case 'SPY':
        return 'S&P';
      case 'QQQ':
        return 'NAS';
      case 'DIA':
        return 'DOW';
      default:
        return code;
    }
  }

  /// 숫자 콤마 포맷
  String _formatClose(double value) {
    if (value >= 1000) {
      final intPart = value.toInt();
      final str = intPart.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return value.toStringAsFixed(2);
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
            boxShadow: [
              AppShadow.lg(theme.colorScheme.error.withValues(alpha: 0.15)),
            ],
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
                        fontWeight: FontWeight.bold,
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

  /// AppBar bottom: indices bar only
  PreferredSize _buildAppBarBottom(bool hasIndices) {
    final indicesHeight = (hasIndices && _showIndicesBar) ? 30.0 : 0.0;

    return PreferredSize(
      preferredSize: Size.fromHeight(indicesHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIndices)
            AnimatedContainer(
              duration: AppDuration.fast,
              height: _showIndicesBar ? 30 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: _buildCompactIndicesRow(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactIndicesRow() {
    if (_indicesData == null || _indicesData!.indices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _indicesData!.indices.map((idx) {
          final isPositive = idx.changePct >= 0;
          final mlc = context.mlColors;
          final changeColor = idx.changePct > 0
              ? mlc.gainColor
              : idx.changePct < 0
                  ? mlc.lossColor
                  : mlc.neutralColor;
          final arrow = idx.changePct > 0 ? '▲' : idx.changePct < 0 ? '▼' : '─';
          final sign = isPositive ? '+' : '';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _shortName(idx.code),
                style: TextStyle(fontSize: AppTypography.caption, fontWeight: AppTypography.medium),
              ),
              const SizedBox(width: 3),
              Text(
                _formatClose(idx.close),
                style: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '$arrow$sign${idx.changePct.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: AppTypography.micro, color: changeColor, fontWeight: AppTypography.semiBold),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasIndices = _indicesData != null && _indicesData!.indices.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 34,
        title: const Text(
          'MarketLens',
          style: TextStyle(fontWeight: FontWeight.bold),
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
            icon: const Icon(Icons.more_vert),
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
        bottom: _buildAppBarBottom(hasIndices),
      ),
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse && _showIndicesBar) {
                setState(() => _showIndicesBar = false);
              } else if (notification.direction == ScrollDirection.forward && !_showIndicesBar) {
                setState(() => _showIndicesBar = true);
              }
              return false;
            },
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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
            icon: const Icon(Icons.show_chart_outlined),
            activeIcon: const Icon(Icons.show_chart),
            label: l10n.tabMarket,
            tooltip: l10n.tabMarketTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_outlined),
            activeIcon: const Icon(Icons.article),
            label: l10n.tabNews,
            tooltip: l10n.tabNewsTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: const Icon(Icons.auto_awesome),
            label: l10n.tabAILens,
            tooltip: l10n.tabAILensTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_outline),
            activeIcon: const Icon(Icons.bookmark),
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
