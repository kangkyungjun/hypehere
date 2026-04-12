import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/webview_screen.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/recent_search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../community/community_feed_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/badge_colors.dart';

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
          content: Text(
            l10n.clearRecentSearchesConfirm,
          ),
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
          content: Text(
            l10n.clearWatchlistConfirm,
          ),
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
          content: Text(
            l10n.deleteAllDataConfirm,
          ),
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
        Text(
          l10n.appDescription,
        ),
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
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
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
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
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
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Account Section
          _buildAccountSection(context),

          // Admin Panel Section (Manager 이상만 표시)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final l10n = AppLocalizations.of(context);
              if (authProvider.isManagerOrAbove) {
                return Column(
                  children: [
                    const Divider(height: 32),
                    _buildSectionHeader(context, l10n.admin),
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings, color: context.mlColors.warningColor),
                      title: Text(
                        l10n.adminPanel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.adminPanelSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _navigateToAdminPanel(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.campaign, color: context.mlColors.accentBlue),
                      title: Text(
                        l10n.sendPushNotification,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.sendPushNotificationSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showBroadcastPushDialog(context),
                    ),
                    SwitchListTile(
                      secondary: Icon(
                        authProvider.adsEnabled ? Icons.ads_click : Icons.block,
                        color: authProvider.adsEnabled ? context.mlColors.gainColor : context.mlColors.neutralColor,
                      ),
                      title: Text(l10n.showAds),
                      subtitle: Text(authProvider.adsEnabled ? l10n.adsEnabledDescription : l10n.adsDisabledDescription),
                      value: authProvider.adsEnabled,
                      onChanged: (value) {
                        authProvider.setAdsEnabled(value);
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const Divider(height: 32),

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
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    subtitle: Text(currentLanguageLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageBottomSheet(context, localeProvider),
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32),

          // Community Section
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return ListTile(
                leading: const Icon(Icons.forum),
                title: Text(l10n.tabCommunity),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunityFeedScreen(),
                    ),
                  );
                },
              );
            },
          ),

          const Divider(height: 32),

          // Data Management Section
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.dataManagement),
                  Consumer<RecentSearchProvider>(
                    builder: (context, recentSearchProvider, child) {
                      final l10n = AppLocalizations.of(context);
                      final searchCount = recentSearchProvider.recentSearches.length;
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(l10n.clearRecentSearches),
                        subtitle: Text(l10n.nSearchRecords(searchCount)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _clearRecentSearches(context, recentSearchProvider),
                      );
                    },
                  ),
                  Consumer<WatchlistProvider>(
                    builder: (context, watchlistProvider, child) {
                      final l10n = AppLocalizations.of(context);
                      final watchlistCount = watchlistProvider.watchlist.length;
                      return ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: Text(l10n.clearWatchlist),
                        subtitle: Text(l10n.nTickers(watchlistCount)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _clearWatchlist(context, watchlistProvider),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_sweep, color: context.mlColors.dangerColor),
                    title: Text(
                      l10n.deleteAllData,
                      style: TextStyle(color: context.mlColors.dangerColor),
                    ),
                    subtitle: Text(l10n.removeAllLocalData),
                    trailing: Icon(Icons.chevron_right, color: context.mlColors.dangerColor),
                    onTap: () => _clearAllData(context),
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32),

          // App Info Section
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, l10n.info),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.aboutMarketLens),
                    subtitle: Text(l10n.version('1.0.0')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAbout(context),
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
                        fontWeight: FontWeight.bold,
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              Card(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.mlColors.accentBlue,
                    child: Text(
                      user.nickname.isNotEmpty
                          ? user.nickname[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: context.mlColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypography.headlineMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _buildRoleBadge(context, user.role),
                    ],
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
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
              Card(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: Text(l10n.login),
                      subtitle: Text(l10n.loginSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _navigateToLogin(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: Text(l10n.signup),
                      subtitle: Text(l10n.signupSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _navigateToSignup(context),
                    ),
                  ],
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
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
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
      MaterialPageRoute(
        builder: (context) => const SignupScreen(),
      ),
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
      MaterialPageRoute(
        builder: (context) => const AdminPanelScreen(),
      ),
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
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
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
                                SnackBar(content: Text(l10n.pushSentResult(sent))),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
  void _showLanguageBottomSheet(BuildContext context, LocaleProvider localeProvider) {
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
                    fontWeight: FontWeight.bold,
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
      leading: Text(flag, style: TextStyle(fontSize: AppTypography.displayLarge)),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: context.mlColors.accentBlue)
          : null,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTypography.bodyLarge,
          fontWeight: FontWeight.bold,
          color: context.mlColors.accentBlue,
        ),
      ),
    );
  }

  /// MarketLens 역할 배지
  Widget _buildRoleBadge(BuildContext context, String role) {
    final badgeColor = BadgeColors.roleBadge(role);
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: context.mlColors.onPrimary,
          fontSize: AppTypography.micro,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
