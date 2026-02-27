import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'providers/watchlist_provider.dart';
import 'providers/recent_search_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/watchlist/watchlist_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/compare/compare_screen.dart';
import 'screens/community/community_feed_screen.dart';
import 'screens/news/news_list_screen.dart';
import 'models/indices_data.dart';
import 'services/analytics_api_client.dart';
import 'services/notification_service.dart';
import 'screens/notifications/notification_inbox_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize Google AdMob
  await MobileAds.instance.initialize();

  // Initialize Providers
  final watchlistProvider = WatchlistProvider();
  await watchlistProvider.initialize();

  final recentSearchProvider = RecentSearchProvider();
  await recentSearchProvider.initialize();

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: watchlistProvider),
        ChangeNotifierProvider.value(value: recentSearchProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
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
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
      theme: ThemeData(
        // MarketLens brand colors (HypeHere와 다름!)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Professional blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        extensions: const [MarketLensColors.light],

        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),

        // Bottom navigation theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF1E88E5),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        extensions: const [MarketLensColors.dark],

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF42A5F5),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
        ),
      ),

      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}

/// 메인 네비게이션 (4탭 구조 - 커뮤니티 기능 통합)
///
/// ⚠️ HypeHere 5탭 구조와 다름
/// ⚠️ Settings는 AppBar 우측 아이콘으로 분리
/// 📊 Dashboard → 🔍 Explore → 📰 News → 💬 Community → ⭐ Watchlist
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

  static final String _authBaseUrl =
      dotenv.env['AUTH_API_BASE_URL'] ?? 'http://43.201.45.60:8000/api/accounts';

  // 5개 탭: Dashboard, Explore, News, Community, Watchlist
  final List<Widget> _screens = const [
    DashboardScreen(), // 시장 스냅샷
    ExploreScreen(), // 검색/탐색
    NewsListScreen(embedded: true), // 시장 뉴스 전체보기
    CommunityFeedScreen(), // 통합 게시판 (전체 글)
    WatchlistScreen(), // 관심종목 워크스페이스
  ];

  @override
  void initState() {
    super.initState();
    _loadIndices();
    _fetchUnreadCount();
  }

  @override
  void dispose() {
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
    } catch (_) {}
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

  Widget _buildCompactIndicesRow() {
    if (_indicesData == null || _indicesData!.indices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _indicesData!.indices.map((idx) {
          final isPositive = idx.changePct >= 0;
          final changeColor = idx.changePct > 0
              ? const Color(0xFF4CAF50)
              : idx.changePct < 0
                  ? const Color(0xFFF44336)
                  : Colors.grey;
          final arrow = idx.changePct > 0 ? '▲' : idx.changePct < 0 ? '▼' : '─';
          final sign = isPositive ? '+' : '';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _shortName(idx.code),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 3),
              Text(
                _formatClose(idx.close),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2),
              Text(
                '$arrow$sign${idx.changePct.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 10, color: changeColor, fontWeight: FontWeight.w600),
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
        title: const Text(
          'MarketLens',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // [숨김] 비교하기 기능 — 추후 활성화 시 주석 해제
          // IconButton(
          //   icon: const Icon(Icons.compare_arrows),
          //   tooltip: '종목 비교',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const CompareScreen(),
          //       ),
          //     );
          //   },
          // ),
          // 알림 아이콘 (벨 + 뱃지)
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotificationCount > 0,
              label: Text(
                _unreadNotificationCount > 99
                    ? '99+'
                    : '$_unreadNotificationCount',
                style: const TextStyle(fontSize: 10),
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
        bottom: hasIndices
            ? PreferredSize(
                preferredSize: Size.fromHeight(_showIndicesBar ? 30 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _showIndicesBar ? 30 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: _buildCompactIndicesRow(),
                ),
              )
            : null,
      ),
      body: NotificationListener<UserScrollNotification>(
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
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.tabDashboard,
            tooltip: l10n.tabDashboardTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            activeIcon: const Icon(Icons.search),
            label: l10n.tabSearch,
            tooltip: l10n.tabSearchTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_outlined),
            activeIcon: const Icon(Icons.article),
            label: l10n.tabNews,
            tooltip: l10n.tabNewsTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.forum_outlined),
            activeIcon: const Icon(Icons.forum),
            label: l10n.tabCommunity,
            tooltip: l10n.tabCommunityTooltip,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_outline),
            activeIcon: const Icon(Icons.bookmark),
            label: l10n.tabWatchlist,
            tooltip: l10n.tabWatchlistTooltip,
          ),
        ],
      ),
    );
  }
}
