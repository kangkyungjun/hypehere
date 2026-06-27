import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/webview_screen.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/recent_search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/auth_service.dart';
import '../../config/feature_flags.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../admin/active_users_dashboard_screen.dart';
import '../admin/management_records_screen.dart';
import '../ai_lens/chat/chat_storage_settings_screen.dart';
import '../community/community_feed_screen.dart';
import 'blocked_users_screen.dart';
import '../onboarding/investment_profile_onboarding_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../utils/badge_colors.dart';
import '../../providers/coach_mark_provider.dart';
import '../../widgets/common/bento_card.dart';
import '../../widgets/common/section_header.dart';

/// Settings Screen - 앱 설정
///
/// ⚠️ 별도 탭 아님: AppBar 우측 아이콘에서 접근
/// - 간단한 설정만 제공 (도구형 앱)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearRecentSearches(
    BuildContext context,
    RecentSearchProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.clearRecentSearches),
          content: Text(l10n.clearRecentSearchesConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await provider.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recentSearchesCleared),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearWatchlist(
    BuildContext context,
    WatchlistProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.clearWatchlist),
          content: Text(l10n.clearWatchlistConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: context.mlColors.dangerColor,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await provider.clearWatchlist();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.watchlistCleared),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteAllData),
          content: Text(l10n.deleteAllDataConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: context.mlColors.dangerColor,
              ),
              child: Text(l10n.deleteAllButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reinitialize providers
      if (!context.mounted) return;

      final watchlistProvider = context.read<WatchlistProvider>();
      final recentSearchProvider = context.read<RecentSearchProvider>();

      await watchlistProvider.initialize();
      await recentSearchProvider.initialize();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.allDataDeleted),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showAboutDialog(
      context: context,
      applicationName: 'MarketLens',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.analytics,
        size: 48,
        color: context.mlColors.accentBlue,
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.appDescription),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '© 2026 MarketLens',
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      appPageRoute(
        builder: (_) => WebViewScreen(
          title: l10n.privacyPolicy,
          url: 'https://www.hypehere.net/marketlens/privacy/?lang=$lang',
        ),
      ),
    );
  }

  void _openTermsOfService(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Navigator.push(
      context,
      appPageRoute(
        builder: (_) => WebViewScreen(
          title: l10n.termsOfService,
          url: 'https://www.hypehere.net/marketlens/terms/?lang=$lang',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          // Account Section
          _buildAccountSection(context),

          // Investment Profile Section (로그인 상태에서만)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isLoggedIn) return const SizedBox.shrink();
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.investmentProfileSection),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.pie_chart_outline_rounded,
                        iconColor: context.mlColors.accentBlue,
                        title: l10n.investmentProfileTitle,
                        subtitle: l10n.investmentProfileEditSubtitle,
                        onTap: () {
                          Navigator.push(
                            context,
                            appPageRoute(
                              builder: (_) =>
                                  const InvestmentProfileOnboardingScreen(
                                      isEditing: true),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Admin Panel Section (Manager 이상만 표시)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final l10n = AppLocalizations.of(context);
              if (authProvider.isManagerOrAbove) {
                return Column(
                  children: [
                    _buildSectionHeader(context, l10n.admin),
                    _buildSettingsCard(
                      context,
                      children: [
                        _buildSettingsTile(
                          context,
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: context.mlColors.warningColor,
                          title: l10n.adminPanel,
                          subtitle: l10n.adminPanelSubtitle,
                          onTap: () => _navigateToAdminPanel(context),
                        ),
                        // Master 전용 — 활성 사용자(DAU/WAU). 매니저에겐 렌더 안 됨.
                        if (authProvider.isMaster)
                          _buildSettingsTile(
                            context,
                            icon: Icons.insights_rounded,
                            iconColor: context.mlColors.accentBlue,
                            title: '활성 사용자 (DAU/WAU)',
                            subtitle: 'Master 전용 · 일·주 활성 사용자',
                            onTap: () => Navigator.push(
                              context,
                              appPageRoute(
                                builder: (_) =>
                                    const ActiveUsersDashboardScreen(),
                              ),
                            ),
                          ),
                        // Master 전용 — 경영·운영 관리(지출·수익·자산·계획)
                        if (authProvider.isMaster)
                          _buildSettingsTile(
                            context,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: context.mlColors.gainColor,
                            title: '경영·운영 관리',
                            subtitle: 'Master 전용 · 수익·지출·자산·계획 기록',
                            onTap: () => Navigator.push(
                              context,
                              appPageRoute(
                                builder: (_) =>
                                    const ManagementRecordsScreen(),
                              ),
                            ),
                          ),
                        _buildSettingsTile(
                          context,
                          icon: Icons.campaign_rounded,
                          iconColor: context.mlColors.accentBlue,
                          title: l10n.sendPushNotification,
                          subtitle: l10n.sendPushNotificationSubtitle,
                          onTap: () => _showBroadcastPushDialog(context),
                        ),
                        SwitchListTile(
                          secondary: Icon(
                            authProvider.adsEnabled
                                ? Icons.ads_click
                                : Icons.block,
                            color: authProvider.adsEnabled
                                ? context.mlColors.gainColor
                                : context.mlColors.neutralColor,
                          ),
                          title: Text(l10n.showAds),
                          subtitle: Text(
                            authProvider.adsEnabled
                                ? l10n.adsEnabledDescription
                                : l10n.adsDisabledDescription,
                          ),
                          value: authProvider.adsEnabled,
                          onChanged: authProvider.setAdsEnabled,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Subscription Section
          // [SUBSCRIPTION_VISIBILITY_FLAG] 구독(Gold) 섹션 숨김 처리.
          // 복원: FeatureFlags.kShowSubscriptionInSettings = true (config/feature_flags.dart)
          if (FeatureFlags.kShowSubscriptionInSettings)
            _buildSubscriptionSection(context),

          // Language Section
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final l10n = AppLocalizations.of(context);
              final currentLocale = localeProvider.locale;
              String currentLanguageLabel;
              if (currentLocale == null) {
                currentLanguageLabel = l10n.systemDefault;
              } else if (currentLocale.languageCode == 'ko') {
                currentLanguageLabel = l10n.languageKorean;
              } else if (currentLocale.languageCode == 'zh') {
                currentLanguageLabel = l10n.languageChinese;
              } else if (currentLocale.languageCode == 'ja') {
                currentLanguageLabel = l10n.languageJapanese;
              } else if (currentLocale.languageCode == 'es') {
                currentLanguageLabel = l10n.languageSpanish;
              } else {
                currentLanguageLabel = l10n.languageEnglish;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.languageSettings),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: currentLanguageLabel,
                        onTap: () =>
                            _showLanguageBottomSheet(context, localeProvider),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Community Section
          // [COMMUNITY_FLAG] 커뮤니티 비활성화 시 섹션 전체 숨김.
          // 복원: FeatureFlags.kCommunityEnabled = true 로 변경.
          Builder(
            builder: (context) {
              if (!FeatureFlags.kCommunityEnabled) {
                return const SizedBox.shrink();
              }
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.tabCommunity),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.forum_rounded,
                        title: l10n.tabCommunity,
                        onTap: () {
                          Navigator.push(
                            context,
                            appPageRoute(
                              builder: (_) => const CommunityFeedScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.block,
                        title: l10n.blockedUsers,
                        onTap: () {
                          Navigator.push(
                            context,
                            appPageRoute(
                              builder: (_) => const BlockedUsersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Data Management Section
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.dataManagement),
                  _buildSettingsCard(
                    context,
                    children: [
                      Consumer<RecentSearchProvider>(
                        builder: (context, recentSearchProvider, child) {
                          final searchCount =
                              recentSearchProvider.recentSearches.length;
                          return _buildSettingsTile(
                            context,
                            icon: Icons.history_rounded,
                            title: l10n.clearRecentSearches,
                            subtitle: l10n.nSearchRecords(searchCount),
                            onTap: () => _clearRecentSearches(
                              context,
                              recentSearchProvider,
                            ),
                          );
                        },
                      ),
                      Consumer<WatchlistProvider>(
                        builder: (context, watchlistProvider, child) {
                          final watchlistCount =
                              watchlistProvider.watchlist.length;
                          return _buildSettingsTile(
                            context,
                            icon: Icons.bookmark_rounded,
                            title: l10n.clearWatchlist,
                            subtitle: l10n.nTickers(watchlistCount),
                            onTap: () =>
                                _clearWatchlist(context, watchlistProvider),
                          );
                        },
                      ),
                      Consumer<CoachMarkProvider>(
                        builder: (context, coachMark, child) {
                          return _buildSettingsTile(
                            context,
                            icon: Icons.school_outlined,
                            title: l10n.resetTutorials,
                            subtitle: l10n.resetTutorialsDesc,
                            onTap: () async {
                              await coachMark.resetAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.tutorialsReset)),
                                );
                              }
                            },
                          );
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.chat_outlined,
                        title: l10n.aiChatStorageSettings,
                        subtitle: l10n.aiChatStorageSettingsSubtitle,
                        onTap: () => Navigator.push(
                          context,
                          appPageRoute(
                            builder: (_) => const ChatStorageSettingsScreen(),
                          ),
                        ),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.delete_sweep_rounded,
                        iconColor: context.mlColors.dangerColor,
                        title: l10n.deleteAllData,
                        subtitle: l10n.removeAllLocalData,
                        titleColor: context.mlColors.dangerColor,
                        onTap: () => _clearAllData(context),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // App Info Section
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.info),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: l10n.aboutMarketLens,
                        subtitle: l10n.version('1.0.0'),
                        onTap: () => _showAbout(context),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Footer
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'MarketLens',
                      style: TextStyle(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.aiStockAnalysis,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Privacy Policy & Terms of Service Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _openPrivacyPolicy(context),
                          child: Text(
                            l10n.privacyPolicy,
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openTermsOfService(context),
                          child: Text(
                            l10n.termsOfService,
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'marketlens.service@gmail.com',
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Subscription Section
  Widget _buildSubscriptionSection(BuildContext context) {
    return Consumer2<AuthProvider, SubscriptionProvider>(
      builder: (context, auth, sub, child) {
        final l10n = AppLocalizations.of(context);

        // 비로그인 또는 Manager/Master → 표시 안 함
        if (!auth.isLoggedIn || auth.isManagerOrAbove) {
          return const SizedBox.shrink();
        }

        // Hybrid check: server role OR client-side RevenueCat status (webhook 지연 대비)
        if (auth.isGoldOrAbove || sub.isGoldActive) {
          // Gold 유저: 구독 상태 + 구독 관리 + 구매 복원
          final formattedDate = sub.expirationDate != null
              ? '${sub.expirationDate!.year}-${sub.expirationDate!.month.toString().padLeft(2, '0')}-${sub.expirationDate!.day.toString().padLeft(2, '0')}'
              : '';
          final subtitleText = sub.isOnTrial && formattedDate.isNotEmpty
              ? l10n.trialEndsOn(formattedDate)
              : formattedDate.isNotEmpty
              ? l10n.subscriptionExpires(formattedDate)
              : '';
          final badgeText = sub.isOnTrial
              ? l10n.onFreeTrial
              : l10n.subscriptionActive;
          final badgeColor = sub.isOnTrial
              ? Colors.orange.shade600
              : Colors.green.shade600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.subscription),
              _buildSettingsCard(
                context,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber.shade700,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.goldMembershipTitle,
                            style: AppTypography.bodyStrong.copyWith(
                              color: context.mlColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(
                              AppRadius.badge,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: context.mlColors.onPrimary,
                              fontSize: AppTypography.micro,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: subtitleText.isNotEmpty
                        ? Text(subtitleText)
                        : null,
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.settings_rounded,
                    title: l10n.manageSubscription,
                    onTap: () => sub.openManagement(),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.restore_rounded,
                    title: l10n.restorePurchaseTitle,
                    subtitle: l10n.restorePurchaseDescription,
                    onTap: () async {
                      final success = await sub.restorePurchases();
                      if (!context.mounted) return;
                      if (success) {
                        await auth.refreshUserInfo();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.purchaseRestored)),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.purchaseRestoreFailed)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        }

        // [GOLD_PURCHASE_FLAG] Regular 유저 구독 섹션
        // 복원: kGoldPurchaseEnabled = true → 기존 업그레이드 유도 UI 자동 복원.
        if (!FeatureFlags.kGoldPurchaseEnabled) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.subscription),
              _buildSettingsCard(
                context,
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.workspace_premium_rounded,
                    iconColor: Colors.amber.shade700,
                    title: l10n.goldMembershipTitle,
                    subtitle: l10n.goldComingSoon,
                  ),
                ],
              ),
            ],
          );
        }

        // Regular 유저: 업그레이드 유도 + 구매 복원
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, l10n.subscription),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.workspace_premium_rounded,
                  iconColor: Colors.amber.shade700,
                  title: l10n.upgradeToGold,
                  subtitle: l10n.goldBenefitNoAds,
                  onTap: () =>
                      GoldUpgradeSheet.show(context, source: 'settings'),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.restore_rounded,
                  title: l10n.restorePurchaseTitle,
                  subtitle: l10n.restorePurchaseDescription,
                  onTap: () async {
                    final success = await sub.restorePurchases();
                    if (!context.mounted) return;
                    if (success) {
                      await auth.refreshUserInfo();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.purchaseRestored)),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.purchaseRestoreFailed)),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Account Section
  Widget _buildAccountSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final l10n = AppLocalizations.of(context);
        if (authProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isLoggedIn && authProvider.currentUser != null) {
          // 로그인 상태: 사용자 카드 → 프로필 페이지로 이동
          final user = authProvider.currentUser!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.account),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: BentoCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      appPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: context.mlColors.accentBlue,
                        child: Text(
                          user.nickname.isNotEmpty
                              ? user.nickname[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: context.mlColors.onPrimary,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.nickname,
                                    style: AppTypography.cardTitle.copyWith(
                                      color: context.mlColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _buildRoleBadge(context, user.role),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              user.email,
                              style: AppTypography.label.copyWith(
                                color: context.mlColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.chevron_right,
                        color: context.mlColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // 비로그인 상태: 로그인 유도
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, l10n.account),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.mlColors.infoBg.withValues(
                            alpha: 0.58,
                          ),
                          child: Icon(
                            Icons.login_rounded,
                            color: context.mlColors.accentBlue,
                          ),
                        ),
                        title: Text(l10n.login),
                        subtitle: Text(l10n.loginSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToLogin(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.mlColors.infoBg.withValues(
                            alpha: 0.58,
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: context.mlColors.accentBlue,
                          ),
                        ),
                        title: Text(l10n.signup),
                        subtitle: Text(l10n.signupSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateToSignup(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  /// 로그인 화면으로 이동
  Future<void> _navigateToLogin(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(builder: (_) => const LoginScreen()),
    );

    // 로그인 성공 시 AuthProvider 자동 업데이트됨
    if (result == true && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.welcome),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 회원가입 화면으로 이동
  Future<void> _navigateToSignup(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(builder: (_) => const SignupScreen()),
    );

    // 회원가입 성공 시 AuthProvider 자동 업데이트됨
    if (result == true && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountCreated),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 관리자 패널로 이동 (Manager 이상 전용)
  void _navigateToAdminPanel(BuildContext context) {
    Navigator.push(
      context,
      appPageRoute(builder: (_) => const AdminPanelScreen()),
    );
  }

  /// 푸시 알림 브로드캐스트 다이얼로그 (Manager+ 전용)
  void _showBroadcastPushDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.sendPushNotification),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: l10n.pushTitle,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: bodyController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.pushBody,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();
                          if (title.isEmpty || body.isEmpty) return;

                          setState(() => isSending = true);
                          try {
                            final result = await AuthService().broadcastPush(
                              title: title,
                              body: body,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              final sent = result['sent'] ?? 0;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.pushSentResult(sent)),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isSending = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.pushSendFailed)),
                              );
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: AppStroke.medium,
                          ),
                        )
                      : Text(l10n.send),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Language selection bottom sheet
  void _showLanguageBottomSheet(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = localeProvider.locale;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.languageSettings,
                  style: const TextStyle(
                    fontSize: AppTypography.headlineLarge,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildLanguageOption(
                context: context,
                label: l10n.languageKorean,
                flag: '\u{1F1F0}\u{1F1F7}',
                isSelected: currentLocale?.languageCode == 'ko',
                onTap: () {
                  localeProvider.setLocale(const Locale('ko'));
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              _buildLanguageOption(
                context: context,
                label: l10n.languageEnglish,
                flag: '\u{1F1FA}\u{1F1F8}',
                isSelected: currentLocale?.languageCode == 'en',
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              _buildLanguageOption(
                context: context,
                label: l10n.languageChinese,
                flag: '\u{1F1E8}\u{1F1F3}',
                isSelected: currentLocale?.languageCode == 'zh',
                onTap: () {
                  localeProvider.setLocale(const Locale('zh'));
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              _buildLanguageOption(
                context: context,
                label: l10n.languageJapanese,
                flag: '\u{1F1EF}\u{1F1F5}',
                isSelected: currentLocale?.languageCode == 'ja',
                onTap: () {
                  localeProvider.setLocale(const Locale('ja'));
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              _buildLanguageOption(
                context: context,
                label: l10n.languageSpanish,
                flag: '\u{1F1EA}\u{1F1F8}',
                isSelected: currentLocale?.languageCode == 'es',
                onTap: () {
                  localeProvider.setLocale(const Locale('es'));
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              _buildLanguageOption(
                context: context,
                label: l10n.systemDefault,
                flag: '\u{1F4F1}',
                isSelected: currentLocale == null,
                onTap: () {
                  localeProvider.clearLocale();
                  Navigator.pop(context);
                  _showLanguageChangedSnackBar(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(
        flag,
        style: TextStyle(fontSize: AppTypography.displayLarge),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: context.mlColors.accentBlue)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: BentoCard(
        padding: EdgeInsets.zero,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final mlc = context.mlColors;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? mlc.accentBlue).withValues(alpha: 0.10),
        child: Icon(icon, color: iconColor ?? mlc.accentBlue, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyStrong.copyWith(
          color: titleColor ?? mlc.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: titleColor ?? mlc.textTertiary,
      ),
      onTap: onTap,
    );
  }

  void _showLanguageChangedSnackBar(BuildContext context) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.languageChanged),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Section header
  Widget _buildSectionHeader(BuildContext context, String title) {
    return SectionHeader(
      title: title,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
    );
  }

  /// MarketLens 역할 배지
  Widget _buildRoleBadge(BuildContext context, String role) {
    final badgeColor = BadgeColors.roleBadge(role, context.mlColors);
    String badgeText;

    switch (role) {
      case 'master':
        badgeText = 'Master';
        break;
      case 'manager':
        badgeText = 'Manager';
        break;
      case 'gold':
        badgeText = 'Gold';
        break;
      case 'regular':
      default:
        badgeText = 'Regular';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: context.mlColors.onPrimary,
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
