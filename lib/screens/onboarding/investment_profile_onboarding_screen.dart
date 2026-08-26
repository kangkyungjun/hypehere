import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/investment_profile.dart';
import '../../providers/investment_profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 투자 프로필 온보딩 5단계 위저드
///
/// - P1: 투자 성향 (보수적/균형/공격적)
/// - P2: 투자 기간 (단기/중기/장기)
/// - P3: 리스크 허용도 (슬라이더 1-5)
/// - P4: 목표 수익률 (5%/10%/20%/유연)
/// - P5: 최대 손실 허용 (-5%/-10%/-20%/-40%/무제한)
///
/// Navigator.pop(true) on completion/skip.
class InvestmentProfileOnboardingScreen extends StatefulWidget {
  /// If true, show current profile values as defaults (edit mode).
  final bool isEditing;

  const InvestmentProfileOnboardingScreen({super.key, this.isEditing = false});

  @override
  State<InvestmentProfileOnboardingScreen> createState() =>
      _InvestmentProfileOnboardingScreenState();
}

class _InvestmentProfileOnboardingScreenState
    extends State<InvestmentProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  /// Edit-mode initial load state. While true, the form is hidden behind a
  /// loading indicator so we never prefill with defaults before the real
  /// profile is fetched.
  bool _isLoadingProfile = false;

  /// Edit-mode load failure. When true we block saving and show a retry view,
  /// preventing the real server profile from being overwritten with defaults.
  bool _loadFailed = false;

  // Selections
  String _investmentStyle = 'balanced';
  String _timeHorizon = 'medium';
  double _riskTolerance = 3;
  int _targetReturn = 10;
  int _maxLossTolerance = -20;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final provider = context.read<InvestmentProfileProvider>();
      final profile = provider.profile;
      if (profile != null) {
        _applyProfile(profile);
      } else {
        // Cache is empty (e.g. app-start fetch failed). Re-fetch before
        // prefilling so we don't show defaults that could overwrite the
        // user's real profile on save.
        _isLoadingProfile = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadProfileForEdit();
        });
      }
    }
  }

  void _applyProfile(InvestmentProfile profile) {
    _investmentStyle = profile.investmentStyle;
    _timeHorizon = profile.timeHorizon;
    _riskTolerance = profile.riskTolerance.toDouble();
    _targetReturn = profile.targetReturn;
    _maxLossTolerance = profile.maxLossTolerance;
  }

  Future<void> _loadProfileForEdit() async {
    setState(() {
      _isLoadingProfile = true;
      _loadFailed = false;
    });

    final provider = context.read<InvestmentProfileProvider>();
    await provider.fetchProfile();
    if (!mounted) return;

    final profile = provider.profile;
    setState(() {
      if (profile != null) {
        _applyProfile(profile);
        _loadFailed = false;
      } else {
        // Either the server has no profile yet (unexpected in edit mode) or
        // the fetch failed. Block saving to avoid clobbering real data.
        _loadFailed = true;
      }
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    setState(() => _isSaving = true);

    final profile = InvestmentProfile(
      investmentStyle: _investmentStyle,
      timeHorizon: _timeHorizon,
      riskTolerance: _riskTolerance.round(),
      targetReturn: _targetReturn,
      maxLossTolerance: _maxLossTolerance,
    );

    final provider = context.read<InvestmentProfileProvider>();
    final success = await provider.saveProfile(profile);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.investmentProfileSaveFailed)),
        );
      }
    }
  }

  Future<void> _skipAndClose() async {
    setState(() => _isSaving = true);

    final provider = context.read<InvestmentProfileProvider>();
    await provider.saveProfile(InvestmentProfile.defaultProfile());

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _saveAndClose();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.investmentProfileTitle),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevPage,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
        actions: [
          if (!widget.isEditing && !_isLoadingProfile && !_loadFailed)
            TextButton(
              onPressed: _isSaving ? null : _skipAndClose,
              child: Text(l10n.skip),
            ),
        ],
      ),
      body: _buildBody(l10n, colors),
    );
  }

  Widget _buildBody(AppLocalizations l10n, MarketLensColors colors) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return _buildLoadErrorView(l10n, colors);
    }
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(colors),
        // Pages
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildStylePage(l10n, colors),
              _buildTimeHorizonPage(l10n, colors),
              _buildRiskTolerancePage(l10n, colors),
              _buildTargetReturnPage(l10n, colors),
              _buildMaxLossPage(l10n, colors),
            ],
          ),
        ),
        // Bottom button
        _buildBottomButton(l10n, colors),
      ],
    );
  }

  Widget _buildLoadErrorView(AppLocalizations l10n, MarketLensColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.investmentProfileLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loadProfileForEdit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(MarketLensColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? AppSpacing.xs : 0),
              decoration: BoxDecoration(
                color: isActive ? colors.accentBlue : colors.subtleBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations l10n, MarketLensColors colors) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _isSaving ? null : _nextPage,
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentPage < 4
                          ? l10n.next
                          : l10n.investmentProfileComplete,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── P1: Investment Style ──

  Widget _buildStylePage(AppLocalizations l10n, MarketLensColors colors) {
    return _buildPageLayout(
      title: l10n.investmentStyleTitle,
      subtitle: l10n.investmentStyleSubtitle,
      child: Column(
        children: [
          _buildOptionCard(
            icon: Icons.shield_outlined,
            title: l10n.investmentStyleConservative,
            subtitle: l10n.investmentStyleConservativeDesc,
            isSelected: _investmentStyle == 'conservative',
            onTap: () => setState(() => _investmentStyle = 'conservative'),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildOptionCard(
            icon: Icons.balance_outlined,
            title: l10n.investmentStyleBalanced,
            subtitle: l10n.investmentStyleBalancedDesc,
            isSelected: _investmentStyle == 'balanced',
            onTap: () => setState(() => _investmentStyle = 'balanced'),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildOptionCard(
            icon: Icons.trending_up_rounded,
            title: l10n.investmentStyleAggressive,
            subtitle: l10n.investmentStyleAggressiveDesc,
            isSelected: _investmentStyle == 'aggressive',
            onTap: () => setState(() => _investmentStyle = 'aggressive'),
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── P2: Time Horizon ──

  Widget _buildTimeHorizonPage(AppLocalizations l10n, MarketLensColors colors) {
    return _buildPageLayout(
      title: l10n.timeHorizonTitle,
      subtitle: l10n.timeHorizonSubtitle,
      child: Column(
        children: [
          _buildOptionCard(
            icon: Icons.flash_on_rounded,
            title: l10n.timeHorizonShort,
            subtitle: l10n.timeHorizonShortDesc,
            isSelected: _timeHorizon == 'short',
            onTap: () => setState(() => _timeHorizon = 'short'),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildOptionCard(
            icon: Icons.hourglass_bottom_rounded,
            title: l10n.timeHorizonMedium,
            subtitle: l10n.timeHorizonMediumDesc,
            isSelected: _timeHorizon == 'medium',
            onTap: () => setState(() => _timeHorizon = 'medium'),
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildOptionCard(
            icon: Icons.savings_rounded,
            title: l10n.timeHorizonLong,
            subtitle: l10n.timeHorizonLongDesc,
            isSelected: _timeHorizon == 'long',
            onTap: () => setState(() => _timeHorizon = 'long'),
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── P3: Risk Tolerance ──

  Widget _buildRiskTolerancePage(
      AppLocalizations l10n, MarketLensColors colors) {
    final labels = [
      l10n.riskLevel1,
      l10n.riskLevel2,
      l10n.riskLevel3,
      l10n.riskLevel4,
      l10n.riskLevel5,
    ];

    return _buildPageLayout(
      title: l10n.riskToleranceTitle,
      subtitle: l10n.riskToleranceSubtitle,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_riskTolerance.round()}',
              style: TextStyle(
                fontSize: AppTypography.heroSmall,
                fontWeight: AppTypography.bold,
                color: colors.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            labels[_riskTolerance.round() - 1],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.semiBold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Slider(
            value: _riskTolerance,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: colors.accentBlue,
            onChanged: (v) => setState(() => _riskTolerance = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l10n.riskLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.medium,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    l10n.riskHigh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.medium,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── P4: Target Return ──

  Widget _buildTargetReturnPage(
      AppLocalizations l10n, MarketLensColors colors) {
    final options = [
      (value: 5, label: '5%', desc: l10n.targetReturn5Desc),
      (value: 10, label: '10%', desc: l10n.targetReturn10Desc),
      (value: 20, label: '20%', desc: l10n.targetReturn20Desc),
      (value: 0, label: l10n.targetReturnFlexible, desc: l10n.targetReturnFlexibleDesc),
    ];

    return _buildPageLayout(
      title: l10n.targetReturnTitle,
      subtitle: l10n.targetReturnSubtitle,
      child: Column(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildOptionCard(
              icon: Icons.trending_up,
              title: opt.label,
              subtitle: opt.desc,
              isSelected: _targetReturn == opt.value,
              onTap: () => setState(() => _targetReturn = opt.value),
              colors: colors,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── P5: Max Loss Tolerance ──

  Widget _buildMaxLossPage(AppLocalizations l10n, MarketLensColors colors) {
    final options = [
      (value: -5, label: '-5%', desc: l10n.maxLoss5Desc),
      (value: -10, label: '-10%', desc: l10n.maxLoss10Desc),
      (value: -20, label: '-20%', desc: l10n.maxLoss20Desc),
      (value: -40, label: '-40%', desc: l10n.maxLoss40Desc),
      (value: -100, label: l10n.maxLossUnlimited, desc: l10n.maxLossUnlimitedDesc),
    ];

    return _buildPageLayout(
      title: l10n.maxLossTitle,
      subtitle: l10n.maxLossSubtitle,
      child: Column(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildOptionCard(
              icon: Icons.shield_outlined,
              title: opt.label,
              subtitle: opt.desc,
              isSelected: _maxLossTolerance == opt.value,
              onTap: () => setState(() => _maxLossTolerance = opt.value),
              colors: colors,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared Builders ──

  Widget _buildPageLayout({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colors = context.mlColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.displayMedium,
              fontWeight: AppTypography.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required MarketLensColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.infoBg.withValues(alpha: 0.6)
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? colors.accentBlue
                : colors.subtleBorder.withValues(alpha: 0.72),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentBlue.withValues(alpha: 0.15)
                    : colors.subtleBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.accentBlue : colors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.semiBold,
                      color: isSelected
                          ? colors.accentBlue
                          : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.accentBlue, size: 24),
          ],
        ),
      ),
    );
  }
}
