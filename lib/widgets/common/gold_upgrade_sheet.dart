import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/feature_flags.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import 'modal_handle_bar.dart';

/// Gold 업그레이드 바텀시트 — RevenueCat IAP 구매 UI
class GoldUpgradeSheet extends StatefulWidget {
  final String source; // 'holdings_limit' | 'ai_card' (analytics용)

  const GoldUpgradeSheet({super.key, required this.source});

  // [GOLD_PURCHASE_FLAG] 골드 구매 비활성화 시 Coming Soon 스낵바 표시.
  // 복원: FeatureFlags.kGoldPurchaseEnabled = true 로 변경하면 이 분기 자동 비활성화.
  static Future<void> show(BuildContext context, {required String source}) {
    if (!FeatureFlags.kGoldPurchaseEnabled) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goldComingSoon)),
      );
      return Future.value();
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.mlColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (_) => GoldUpgradeSheet(source: source),
    );
  }

  @override
  State<GoldUpgradeSheet> createState() => _GoldUpgradeSheetState();
}

class _GoldUpgradeSheetState extends State<GoldUpgradeSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sub = context.read<SubscriptionProvider>();
      // 미초기화 시 즉시 초기화 트리거
      if (!sub.isInitialized && !sub.isInitializing) {
        sub.initialize();
      }
      // 가격 정보 미리 가져오기
      sub.fetchPriceString();
    });
  }

  Future<void> _handlePurchase() async {
    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    final l10n = AppLocalizations.of(context);

    // 이미 Gold+ → 안내
    if (auth.isGoldOrAbove || sub.isGoldActive) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // 비로그인 시 로그인 유도
    if (!auth.isLoggedIn) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.loginRequired),
            content: Text(l10n.loginRequiredForPurchase),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // 시트 닫기
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(l10n.login),
              ),
            ],
          ),
        );
      }
      return;
    }

    final result = await sub.purchaseGold();
    if (!mounted) return;

    switch (result) {
      case PurchaseResult.success:
        // Sync with backend if logged in
        if (auth.isLoggedIn) {
          await auth.refreshUserInfo();
        }
        if (mounted) Navigator.pop(context);
      case PurchaseResult.cancelled:
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.purchaseCancelled)));
        }
      case PurchaseResult.notInitialized:
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.purchaseStoreUnavailable),
              content: Text(l10n.purchaseFailed),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    sub.initialize();
                  },
                  child: Text(l10n.purchaseRetry),
                ),
              ],
            ),
          );
        }
      case PurchaseResult.storeProblem:
        // StoreKit 연결 문제 (iPad 호환 모드, 결제 비활성 등)
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.purchaseStoreUnavailable),
              content: Text(l10n.purchaseStoreProblem),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirm),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handlePurchase();
                  },
                  child: Text(l10n.purchaseRetry),
                ),
              ],
            ),
          );
        }
      case PurchaseResult.noOffering:
      case PurchaseResult.noPackage:
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.purchaseTemporarilyUnavailable),
              content: Text(l10n.purchaseFailed),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          );
        }
      case PurchaseResult.error:
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.purchaseStoreUnavailable),
              content: Text(l10n.purchaseStoreProblem),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.confirm),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handlePurchase();
                  },
                  child: Text(l10n.purchaseRetry),
                ),
              ],
            ),
          );
        }
    }
  }

  Future<void> _handleRestore() async {
    final sub = context.read<SubscriptionProvider>();
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    final success = await sub.restorePurchases();
    if (!mounted) return;

    if (success) {
      await auth.refreshUserInfo();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.purchaseRestored)));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.purchaseRestoreFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final sub = context.watch<SubscriptionProvider>();
    final auth = context.watch<AuthProvider>();

    // 체험 가능 여부 = RevenueCat 체험 가능 AND 서버에서 체험 미사용
    final canTrial =
        sub.isTrialAvailable && !(auth.currentUser?.hasUsedTrial ?? false);

    final priceText = canTrial
        ? l10n.freeTrialInfo(sub.priceString ?? '\$4.99')
        : sub.priceString != null
        ? l10n.goldMonthlyPrice(sub.priceString!)
        : l10n.goldMonthlyPrice('\$4.99');

    final isAlreadyGold = auth.isGoldOrAbove || sub.isGoldActive;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalHandleBar(),

            // Title
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: mlc.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 30,
                color: mlc.accentBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.goldMembershipTitle,
              style: TextStyle(
                fontSize: AppTypography.headlineLarge,
                fontWeight: AppTypography.bold,
                color: mlc.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Benefits
            _benefitRow(Icons.all_inclusive, l10n.goldBenefitUnlimitedHoldings),
            const SizedBox(height: AppSpacing.md),
            _benefitRow(Icons.smart_toy, l10n.goldBenefitAIUnlimited),
            const SizedBox(height: AppSpacing.md),
            _benefitRow(Icons.block, l10n.goldBenefitNoAds),
            const SizedBox(height: AppSpacing.xl),

            // Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: mlc.infoBg.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                priceText,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.bold,
                  color: mlc.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Purchase button — 초기화 상태별 분기
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _resolveButtonAction(sub, isAlreadyGold),
                style: FilledButton.styleFrom(
                  backgroundColor: mlc.accentBlue,
                  foregroundColor: mlc.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: _buildButtonChild(sub, isAlreadyGold, canTrial, l10n),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Restore button
            TextButton(
              onPressed: sub.isLoading ? null : _handleRestore,
              child: Text(
                l10n.restorePurchases,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: mlc.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Payment account warning
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: mlc.cardBackground,
                border: Border.all(
                  color: mlc.subtleBorder.withValues(alpha: 0.62),
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                l10n.subscriptionPaymentAccountWarning,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  color: mlc.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Terms
            Text(
              Platform.isIOS
                  ? l10n.subscriptionTermsIos
                  : l10n.subscriptionTermsAndroid,
              style: TextStyle(
                fontSize: AppTypography.micro,
                color: mlc.textTertiary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Legal links (Terms of Service & Privacy Policy)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _openUrl(
                    'https://www.hypehere.net/marketlens/terms/?lang=${Localizations.localeOf(context).languageCode}',
                  ),
                  child: Text(
                    l10n.termsOfService,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      color: mlc.accentBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: mlc.accentBlue,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    '|',
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      color: mlc.textTertiary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openUrl(
                    'https://www.hypehere.net/marketlens/privacy/?lang=${Localizations.localeOf(context).languageCode}',
                  ),
                  child: Text(
                    l10n.privacyPolicy,
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      color: mlc.accentBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: mlc.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// 버튼 onPressed 콜백 결정
  VoidCallback? _resolveButtonAction(
    SubscriptionProvider sub,
    bool isAlreadyGold,
  ) {
    if (isAlreadyGold || sub.isLoading) return null;
    if (sub.isInitializing) return null; // 초기화 중 — 비활성
    if (!sub.isInitialized && sub.initError != null) {
      return () => sub.initialize(); // 초기화 실패 — "Try Again"
    }
    return _handlePurchase; // 정상 — 구매 진행
  }

  /// 버튼 내부 위젯 결정
  Widget _buildButtonChild(
    SubscriptionProvider sub,
    bool isAlreadyGold,
    bool canTrial,
    AppLocalizations l10n,
  ) {
    if (sub.isLoading || sub.isInitializing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: AppStroke.medium,
              color: Colors.white,
            ),
          ),
          if (sub.isInitializing) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              l10n.purchaseInitializing,
              style: const TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ],
      );
    }
    if (!sub.isInitialized && sub.initError != null) {
      return Text(
        l10n.purchaseRetry,
        style: const TextStyle(
          fontSize: AppTypography.bodyLarge,
          fontWeight: AppTypography.bold,
        ),
      );
    }
    return Text(
      isAlreadyGold
          ? l10n.subscriptionActive
          : canTrial
          ? l10n.freeTrialStart
          : l10n.subscribeNow,
      style: const TextStyle(
        fontSize: AppTypography.bodyLarge,
        fontWeight: AppTypography.bold,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _benefitRow(IconData icon, String text) {
    final mlc = context.mlColors;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: mlc.infoBg,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Icon(icon, size: 16, color: mlc.accentBlue),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: mlc.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
