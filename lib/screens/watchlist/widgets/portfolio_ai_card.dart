import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/multilingual.dart';
import '../../../widgets/ads/rewarded_ad_helper.dart';
import '../../../config/feature_flags.dart';
import '../../../widgets/common/gold_upgrade_sheet.dart';

String _formatSummaryTime(DateTime dt, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(dt.year, dt.month, dt.day);
  final timeStr = DateFormat('HH:mm').format(dt);

  if (dateDay == today) {
    return '${l10n.today} $timeStr';
  } else if (dateDay == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} $timeStr';
  } else {
    return DateFormat('M/d HH:mm').format(dt);
  }
}

/// Card displaying full portfolio AI analysis and recommendations.
///
/// Groups [ai_recommendations] into 3 card sections:
///   1. PORTFOLIO_OVERVIEW — AI summary + overview items
///   2. MARKET_INTELLIGENCE — sub-grouped by COMPANY_CLASSIFICATION,
///      ANALYST_SUMMARY, MARKET_SUMMARY, UPCOMING_EVENTS
///   3. ACTION_SUMMARY — color-coded by BUY (🟢), HOLD (🟡), SELL (🔴)
///
/// Legacy TECHNICAL_INSIGHT items are merged into MARKET_INTELLIGENCE > ANALYST_SUMMARY.
/// Items without sub_type render as flat lists (backward compatible).
///
/// Free users see blurred content with dual CTA ("Watch Ad" + "Gold Upgrade").
/// Gold+ users always see full content without blur.
/// Content-based locking with persistence:
///   - Unlocked content is saved to SharedPreferences
///   - If current content matches saved → auto-unlocked (already seen)
///   - If new content arrives → blur with X button to view previous analysis
class PortfolioAICard extends StatefulWidget {
  final PortfolioSummary? summary;
  final bool isAdFree;

  const PortfolioAICard({
    super.key,
    this.summary,
    required this.isAdFree,
  });

  @override
  State<PortfolioAICard> createState() => _PortfolioAICardState();
}

class _PortfolioAICardState extends State<PortfolioAICard> {
  static const _prefKeySummary = 'portfolio_ai_last_summary';
  static const _prefKeyRecs = 'portfolio_ai_last_recommendations';
  // Anti-abuse: signature + date of the last *generated* analysis, used to
  // decide whether a new update would differ (and thus whether to allow a
  // rewarded-ad-gated regeneration).
  static const _prefKeySignature = 'portfolio_ai_last_signature';
  static const _prefKeyAnalysisDate = 'portfolio_ai_last_analysis_date';

  /// In-session unlock: set after watching ad in current session.
  String? _sessionUnlockedSummary;

  /// Persisted previous content loaded from SharedPreferences.
  String? _savedAiSummary;
  List<Map<String, dynamic>>? _savedRecommendations;

  /// Portfolio signature + calendar day of the last generated analysis.
  String? _savedSignature;
  String? _savedAnalysisDate;

  /// When true, shows the previous (saved) content instead of blur.
  bool _showingPrevious = false;

  /// Set when a button-triggered refresh was paid for (ad watched) but the
  /// regeneration didn't land within the polling window. The analysis is
  /// auto-unlocked + persisted once it arrives on a later fetch (didUpdateWidget).
  bool _pendingUnlock = false;
  String? _pendingBaselineSummary;

  bool get _isUnlocked {
    if (widget.isAdFree) return true;
    final current = widget.summary?.aiSummary;
    if (current == null || current.isEmpty) return true;
    // Session unlock OR persistent match (already seen)
    return _sessionUnlockedSummary == current || _savedAiSummary == current;
  }

  /// Whether we have saved previous content different from current.
  bool get _hasPreviousContent =>
      _savedAiSummary != null &&
      _savedAiSummary!.isNotEmpty &&
      _savedAiSummary != widget.summary?.aiSummary;

  /// Ordered major section types (3 card sections).
  static const _typeOrder = [
    'PORTFOLIO_OVERVIEW',
    'MARKET_INTELLIGENCE',
    'ACTION_SUMMARY',
  ];

  /// Sub-type order within MARKET_INTELLIGENCE.
  static const _marketIntelSubTypes = [
    'COMPANY_CLASSIFICATION',
    'ANALYST_SUMMARY',
    'MARKET_SUMMARY',
    'UPCOMING_EVENTS',
  ];

  /// Sub-type order within ACTION_SUMMARY.
  static const _actionSubTypes = ['BUY', 'HOLD', 'SELL'];

  @override
  void initState() {
    super.initState();
    _loadSavedContent();
    RewardedAdHelper.instance.preloadAd();
  }

  @override
  void didUpdateWidget(covariant PortfolioAICard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset "showing previous" when content changes
    if (oldWidget.summary?.aiSummary != widget.summary?.aiSummary) {
      _showingPrevious = false;
    }
    // A paid-but-delayed refresh has now landed → auto-unlock + persist so the
    // user sees the analysis they already watched an ad for (no re-blur).
    final current = widget.summary?.aiSummary;
    if (_pendingUnlock &&
        current != null &&
        current.isNotEmpty &&
        current != _pendingBaselineSummary) {
      _pendingUnlock = false;
      _sessionUnlockedSummary = current;
      _persistGenerated(widget.summary);
    }
    if (!widget.isAdFree && !_isUnlocked) {
      RewardedAdHelper.instance.preloadAd();
    }
  }

  Future<void> _loadSavedContent() async {
    final prefs = await SharedPreferences.getInstance();
    final summary = prefs.getString(_prefKeySummary);
    final recsJson = prefs.getString(_prefKeyRecs);
    final signature = prefs.getString(_prefKeySignature);
    final analysisDate = prefs.getString(_prefKeyAnalysisDate);
    if (!mounted) return;
    setState(() {
      _savedAiSummary = summary;
      _savedSignature = signature;
      _savedAnalysisDate = analysisDate;
      if (recsJson != null) {
        try {
          _savedRecommendations =
              (jsonDecode(recsJson) as List).cast<Map<String, dynamic>>();
        } catch (_) {
          _savedRecommendations = null;
        }
      }
    });
  }

  Future<void> _persistCurrentContent() async {
    final summary = widget.summary?.aiSummary;
    final recs = widget.summary?.aiRecommendations;
    if (summary == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySummary, summary);
    if (recs != null) {
      await prefs.setString(_prefKeyRecs, jsonEncode(recs));
    } else {
      await prefs.remove(_prefKeyRecs);
    }

    if (!mounted) return;
    setState(() {
      _savedAiSummary = summary;
      _savedRecommendations = recs;
      _showingPrevious = false;
    });
  }

  // ─── Button-triggered AI update (replaces the old auto-regeneration) ──────
  //
  // CHANGE (2026-06): The portfolio analysis no longer regenerates automatically
  // (see PortfolioProvider._refreshAIData). The user now presses "AI 분석
  // 업데이트" to request a fresh analysis (rewarded-ad gated). To avoid users
  // burning rewarded ads on an identical result, the button is only meaningful
  // when the portfolio changed OR a new calendar day started since the last
  // generated analysis.

  String _todayYmd() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Order-independent signature of the current holdings (ticker/shares/avgPrice).
  String _currentSignature() {
    final holdings = context.read<PortfolioProvider>().holdings;
    final parts = holdings
        .map((h) => '${h.ticker}:${h.shares ?? 0}:${h.avgPrice ?? 0}')
        .toList()
      ..sort();
    return parts.join('|');
  }

  /// A new analysis would differ only if holdings changed or the day rolled over.
  bool get _canUpdate {
    if (_savedSignature == null || _savedAnalysisDate == null) return true;
    if (_currentSignature() != _savedSignature) return true;
    if (_todayYmd() != _savedAnalysisDate) return true;
    return false;
  }

  void _onUpdatePressed() {
    final l10n = AppLocalizations.of(context);
    // Anti-abuse: nothing changed → don't show an ad, just inform the user.
    if (!_canUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiNoChangeToAnalyze)),
      );
      return;
    }
    if (widget.isAdFree) {
      _runUpdate();
      return;
    }
    RewardedAdHelper.instance.showAd(
      onRewarded: _runUpdate,
      // 광고를 불러오지 못하면(노필 등) 막지 않고 무료로 업데이트 진행
      onFailed: _runUpdate,
    );
  }

  Future<void> _runUpdate() async {
    final provider = context.read<PortfolioProvider>();
    final l10n = AppLocalizations.of(context);
    // Capture baseline so we can auto-unlock if the (paid) analysis lands later.
    _pendingBaselineSummary = widget.summary?.aiSummary;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiUpdateInProgressHint)),
      );
    }
    try {
      final applied = await provider.requestAnalysisUpdate();
      if (!mounted) return;
      if (applied) {
        setState(() {
          _sessionUnlockedSummary = provider.summary?.aiSummary;
          _pendingUnlock = false;
        });
        await _persistGenerated(provider.summary);
      } else {
        // Timed out: the regeneration is still in flight. Auto-unlock when the
        // new analysis arrives on a later fetch (see didUpdateWidget).
        setState(() => _pendingUnlock = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiUpdateDelayed)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signalLoadFailed)),
        );
      }
    }
  }

  /// Persist a freshly generated analysis + its signature/date.
  Future<void> _persistGenerated(PortfolioSummary? s) async {
    final summary = s?.aiSummary;
    if (summary == null) return;
    final recs = s?.aiRecommendations;
    final sig = _currentSignature();
    final today = _todayYmd();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySummary, summary);
    if (recs != null) {
      await prefs.setString(_prefKeyRecs, jsonEncode(recs));
    } else {
      await prefs.remove(_prefKeyRecs);
    }
    await prefs.setString(_prefKeySignature, sig);
    await prefs.setString(_prefKeyAnalysisDate, today);

    if (!mounted) return;
    setState(() {
      _savedAiSummary = summary;
      _savedRecommendations = recs;
      _savedSignature = sig;
      _savedAnalysisDate = today;
      _showingPrevious = false;
    });
  }

  /// Primary "AI 분석 업데이트" button + no-change reason line.
  Widget _buildUpdateButton(ThemeData theme, AppLocalizations l10n) {
    final updating = context.watch<PortfolioProvider>().isUpdatingAnalysis;
    final canUpdate = _canUpdate;

    final Widget label = updating
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.aiUpdating),
            ],
          )
        : Text(l10n.aiUpdateButton);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: updating ? null : _onUpdatePressed,
          icon: updating
              ? const SizedBox.shrink()
              : Icon(
                  canUpdate
                      ? Icons.auto_awesome_rounded
                      : Icons.check_circle_outline,
                  size: 18,
                ),
          label: label,
          style: FilledButton.styleFrom(
            // Visually de-emphasize when there is nothing new to analyze.
            backgroundColor: canUpdate
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: canUpdate
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.outline,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        if (!canUpdate) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.aiNoChangeToAnalyze,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _onWatchAd() {
    // 광고 시청 완료(onRewarded) 또는 광고를 못 불러온 경우(onFailed) 모두
    // 동일하게 무료로 블러를 해제한다. (광고 노필 환경에서도 막히지 않도록)
    void unlock() {
      if (mounted) {
        setState(() {
          _sessionUnlockedSummary = widget.summary?.aiSummary;
        });
        _persistCurrentContent();
      }
    }

    RewardedAdHelper.instance.showAd(
      onRewarded: unlock,
      onFailed: unlock,
    );
  }

  String _sectionTitle(String type, AppLocalizations l10n) {
    switch (type) {
      case 'PORTFOLIO_OVERVIEW':
        return '1. ${l10n.recPortfolioOverview}';
      case 'MARKET_INTELLIGENCE':
        return '2. ${l10n.recMarketIntelligence}';
      case 'ACTION_SUMMARY':
        return '3. ${l10n.recActionSummary}';
      default:
        return l10n.aiRecommendations;
    }
  }

  String _subTypeTitle(String type, String subType, AppLocalizations l10n) {
    if (type == 'MARKET_INTELLIGENCE') {
      switch (subType) {
        case 'COMPANY_CLASSIFICATION':
          return l10n.recCompanyClassification;
        case 'ANALYST_SUMMARY':
          return l10n.recAnalystSummary;
        case 'MARKET_SUMMARY':
          return l10n.recMarketSummary;
        case 'UPCOMING_EVENTS':
          return l10n.recUpcomingEvents;
      }
    } else if (type == 'ACTION_SUMMARY') {
      switch (subType) {
        case 'BUY':
          return l10n.recBuyRecommend;
        case 'HOLD':
          return l10n.recHoldRecommend;
        case 'SELL':
          return l10n.recSellRecommend;
      }
    }
    return subType;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langCode = effectiveLanguageCode(context);
    final hasAI = widget.summary?.aiSummary != null && widget.summary!.aiSummary!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.portfolioAIAnalysis,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (hasAI) ...[
                if (_isUnlocked) ...[
                  _buildAIContent(
                    theme, l10n, langCode,
                    aiSummary: widget.summary!.aiSummary!,
                    recommendations: widget.summary!.aiRecommendations,
                  ),
                ] else if (_showingPrevious && _hasPreviousContent) ...[
                  _buildPreviousContentView(theme, l10n, langCode),
                ] else ...[
                  _buildBlurredContent(theme, l10n, langCode),
                ],
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.analysisWaiting,
                      style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ],
              // Button-triggered AI analysis update (rewarded-ad gated)
              _buildUpdateButton(theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the previous (saved) content with an info banner.
  Widget _buildPreviousContentView(ThemeData theme, AppLocalizations l10n, String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner: "Previous analysis" + button to view new (locked)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.history, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.viewingPreviousAnalysis,
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showingPrevious = false),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(Icons.close, size: 16, color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Previous AI content
        _buildAIContent(
          theme, l10n, langCode,
          aiSummary: _savedAiSummary!,
          recommendations: _savedRecommendations,
        ),
      ],
    );
  }

  Widget _buildAIContent(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode, {
    required String aiSummary,
    List<Map<String, dynamic>>? recommendations,
  }) {
    final mlColors = context.mlColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendations != null && recommendations.isNotEmpty)
          ..._buildGroupedRecommendations(theme, l10n, langCode, recommendations, aiSummary)
        else
          _buildColoredText(
            localizePacked(aiSummary, langCode),
            TextStyle(fontSize: AppTypography.bodyLarge, color: theme.colorScheme.onSurface, height: 1.5),
            mlColors,
          ),

        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.schedule, size: 12, color: theme.colorScheme.outline),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                l10n.aiAnalysisOnDemandHint,
                style: TextStyle(fontSize: AppTypography.micro, color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
        if (widget.summary?.date != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: Text(
              l10n.lastUpdateTime(_formatSummaryTime(widget.summary!.date, l10n)),
              style: TextStyle(fontSize: AppTypography.micro, color: theme.colorScheme.outline),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBlurredContent(ThemeData theme, AppLocalizations l10n, String langCode) {
    // Both children are non-positioned so Stack takes max(blur, overlay) height.
    // This prevents overflow when the overlay is taller than the blurred content.
    return Stack(
      alignment: Alignment.center,
      children: [
        // Blurred AI content (background layer)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: IgnorePointer(
              child: _buildAIContent(
                theme, l10n, langCode,
                aiSummary: widget.summary!.aiSummary!,
                recommendations: widget.summary!.aiRecommendations,
              ),
            ),
          ),
        ),
        // Lock overlay with CTA buttons (foreground layer)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // consume taps on empty area
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 32, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.newAiAnalysisAvailable,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                // Dual CTA: Watch Ad + Gold Upgrade
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _onWatchAd,
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: Text(l10n.watchAd, style: const TextStyle(fontSize: AppTypography.bodySmall)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    // [GOLD_PURCHASE_FLAG] 구매 비활성화 시 업그레이드 버튼 숨김
                    if (FeatureFlags.kGoldPurchaseEnabled)
                      OutlinedButton.icon(
                        onPressed: () => GoldUpgradeSheet.show(context, source: 'ai_card'),
                        icon: Icon(Icons.workspace_premium, size: 16, color: Colors.amber.shade700),
                        label: Text(l10n.upgradeToGold, style: const TextStyle(fontSize: AppTypography.bodySmall)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade700,
                          side: BorderSide(color: Colors.amber.shade700),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.xs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                // X button: show previous analysis (if available)
                if (_hasPreviousContent) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => setState(() => _showingPrevious = true),
                    icon: Icon(Icons.close, size: 16, color: theme.colorScheme.outline),
                    label: Text(
                      l10n.viewingPreviousAnalysis,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Groups recommendations by type and renders each as a card section.
  ///
  /// Merges legacy TECHNICAL_INSIGHT → MARKET_INTELLIGENCE (sub_type: ANALYST_SUMMARY).
  /// Renders 3 major card sections with sub-type grouping where available.
  List<Widget> _buildGroupedRecommendations(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    List<Map<String, dynamic>> recs,
    String aiSummary,
  ) {
    // Normalize: merge TECHNICAL_INSIGHT → MARKET_INTELLIGENCE
    final normalizedRecs = recs.map((rec) {
      final type = (rec['type'] as String?) ?? '';
      if (type == 'TECHNICAL_INSIGHT') {
        return {
          ...rec,
          'type': 'MARKET_INTELLIGENCE',
          'sub_type': rec['sub_type'] ?? 'ANALYST_SUMMARY',
        };
      }
      return rec;
    }).toList();

    // Group by type
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final rec in normalizedRecs) {
      final type = (rec['type'] as String?) ?? '';
      grouped.putIfAbsent(type, () => []).add(rec);
    }

    // If no known types found, fall back to flat list (backward compat)
    final hasKnownTypes = grouped.keys.any((t) => _typeOrder.contains(t));
    if (!hasKnownTypes) {
      return _buildFlatRecommendations(theme, l10n, langCode, recs);
    }

    final widgets = <Widget>[];

    // Render each major section as a card
    for (final type in _typeOrder) {
      final items = grouped[type];
      if (type == 'PORTFOLIO_OVERVIEW') {
        // Always render (AI summary goes here even if no items)
        widgets.add(_buildSectionCard(
          theme, l10n, langCode, type,
          aiSummary: aiSummary,
          items: items ?? [],
        ));
      } else if (items != null && items.isNotEmpty) {
        widgets.add(_buildSectionCard(
          theme, l10n, langCode, type,
          items: items,
        ));
      }
    }

    // Unknown types at the end
    for (final entry in grouped.entries) {
      if (_typeOrder.contains(entry.key)) continue;
      if (entry.value.isEmpty) continue;
      widgets.add(_buildSectionCard(
        theme, l10n, langCode, entry.key,
        items: entry.value,
      ));
    }

    return widgets;
  }

  /// Splits a pipe-separated message into individual items grouped by ticker.
  ///
  /// Input:  "EPAM: desc1 | EPAM: desc2 | MSFT: desc3"
  /// Output: ["EPAM: desc1. desc2", "MSFT: desc3"]
  static final _tickerPrefix = RegExp(r'^([A-Z]{1,5}):\s*');

  List<String> _groupByTicker(String message) {
    final parts = message.split(RegExp(r'\s*\|\s*'));
    if (parts.length <= 1) return [message];

    // LinkedHashMap preserves insertion order
    final grouped = <String, List<String>>{};
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final match = _tickerPrefix.firstMatch(trimmed);
      if (match != null) {
        final ticker = match.group(1)!;
        final desc = trimmed.substring(match.end).trim();
        grouped.putIfAbsent(ticker, () => []).add(desc);
      } else {
        // No ticker prefix — append to last group or create standalone
        if (grouped.isNotEmpty) {
          grouped.values.last.add(trimmed);
        } else {
          grouped.putIfAbsent('', () => []).add(trimmed);
        }
      }
    }

    return grouped.entries.map((e) {
      final ticker = e.key;
      final descs = e.value.join('. ');
      return ticker.isNotEmpty ? '$ticker: $descs' : descs;
    }).toList();
  }

  /// Renders a major section as a card container with header and content.
  Widget _buildSectionCard(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    String type, {
    String? aiSummary,
    required List<Map<String, dynamic>> items,
  }) {
    final mlColors = context.mlColors;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            _sectionTitle(type, l10n),
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // AI summary text (only in PORTFOLIO_OVERVIEW)
          if (aiSummary != null) ...[
            _buildColoredText(
              localizePacked(aiSummary, langCode),
              TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
              mlColors,
            ),
            if (items.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ],

          // Section content with sub-type grouping
          if (type == 'MARKET_INTELLIGENCE')
            ..._buildMarketIntelligenceContent(theme, l10n, langCode, items)
          else if (type == 'ACTION_SUMMARY')
            ..._buildActionSummaryContent(theme, l10n, langCode, items)
          else
            ..._buildFlatItems(theme, langCode, items),
        ],
      ),
    );
  }

  /// Renders MARKET_INTELLIGENCE content with sub-type grouping (a/b/c/d).
  List<Widget> _buildMarketIntelligenceContent(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    List<Map<String, dynamic>> items,
  ) {
    final hasSubTypes = items.any((r) => r['sub_type'] != null);
    if (!hasSubTypes) {
      return _buildFlatItems(theme, langCode, items);
    }

    final subGrouped = <String, List<Map<String, dynamic>>>{};
    for (final rec in items) {
      final subType = (rec['sub_type'] as String?) ?? '';
      subGrouped.putIfAbsent(subType, () => []).add(rec);
    }

    final widgets = <Widget>[];
    const letters = ['a', 'b', 'c', 'd', 'e', 'f'];
    int letterIdx = 0;

    for (final subType in _marketIntelSubTypes) {
      final subItems = subGrouped[subType];
      if (subItems == null || subItems.isEmpty) continue;
      if (letterIdx > 0) widgets.add(const SizedBox(height: AppSpacing.xs));
      widgets.addAll(_buildSubSection(
        theme, langCode,
        '${letters[letterIdx]}. ${_subTypeTitle('MARKET_INTELLIGENCE', subType, l10n)}',
        subItems,
      ));
      letterIdx++;
    }

    // Unknown sub_types
    for (final entry in subGrouped.entries) {
      if (_marketIntelSubTypes.contains(entry.key) || entry.key.isEmpty) continue;
      if (letterIdx > 0) widgets.add(const SizedBox(height: AppSpacing.xs));
      widgets.addAll(_buildSubSection(
        theme, langCode,
        '${letters[letterIdx % letters.length]}. ${entry.key}',
        entry.value,
      ));
      letterIdx++;
    }

    // Items without sub_type
    final noSubType = subGrouped[''];
    if (noSubType != null && noSubType.isNotEmpty) {
      widgets.addAll(_buildFlatItems(theme, langCode, noSubType));
    }

    return widgets;
  }

  /// Renders ACTION_SUMMARY content with color-coded sub-sections (BUY/HOLD/SELL).
  List<Widget> _buildActionSummaryContent(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    List<Map<String, dynamic>> items,
  ) {
    final hasSubTypes = items.any((r) => r['sub_type'] != null);
    if (!hasSubTypes) {
      return _buildFlatItems(theme, langCode, items);
    }

    final subGrouped = <String, List<Map<String, dynamic>>>{};
    for (final rec in items) {
      final subType = (rec['sub_type'] as String?) ?? '';
      subGrouped.putIfAbsent(subType, () => []).add(rec);
    }

    final widgets = <Widget>[];
    const letters = ['a', 'b', 'c'];
    int letterIdx = 0;

    final mlc = context.mlColors;
    final indicators = {
      'BUY': ('\uD83D\uDFE2', mlc.scoreBuyColor),   // 🟢
      'HOLD': ('\uD83D\uDFE1', mlc.scoreHoldColor),  // 🟡
      'SELL': ('\uD83D\uDD34', mlc.scoreSellColor),   // 🔴
    };

    for (final subType in _actionSubTypes) {
      final subItems = subGrouped[subType];
      if (subItems == null || subItems.isEmpty) continue;
      final indicator = indicators[subType];
      if (letterIdx > 0) widgets.add(const SizedBox(height: AppSpacing.xs));
      widgets.addAll(_buildActionSubSection(
        theme, langCode,
        indicator?.$1 ?? '',
        '${letters[letterIdx]}. ${_subTypeTitle('ACTION_SUMMARY', subType, l10n)}',
        subItems,
        indicator?.$2,
      ));
      letterIdx++;
    }

    // Items without sub_type
    final noSubType = subGrouped[''];
    if (noSubType != null && noSubType.isNotEmpty) {
      widgets.addAll(_buildFlatItems(theme, langCode, noSubType));
    }

    return widgets;
  }

  /// Renders a sub-section with a lettered title and bullet items.
  List<Widget> _buildSubSection(
    ThemeData theme,
    String langCode,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          title,
          style: TextStyle(
            fontSize: AppTypography.bodyMedium,
            fontWeight: AppTypography.semiBold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ..._buildFlatItems(theme, langCode, items),
    ];
  }

  /// Renders an action sub-section with emoji indicator and accent color.
  List<Widget> _buildActionSubSection(
    ThemeData theme,
    String langCode,
    String emoji,
    String title,
    List<Map<String, dynamic>> items,
    Color? accentColor,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: AppTypography.bodyLarge)),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: AppTypography.semiBold,
                  color: accentColor ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ..._buildFlatItems(theme, langCode, items),
    ];
  }

  /// Renders a flat list of bullet items from recommendation records.
  List<Widget> _buildFlatItems(
    ThemeData theme,
    String langCode,
    List<Map<String, dynamic>> items,
  ) {
    final mlColors = context.mlColors;
    return items.expand((rec) {
      final message = localizePacked(rec['message'] as String? ?? '', langCode);
      final priority = (rec['priority'] as String? ?? '').toUpperCase();
      final isHigh = priority == 'HIGH';
      final grouped = _groupByTicker(message);

      return grouped.map((line) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                isHigh ? ' \u25B6 ' : ' \u2022 ',
                style: TextStyle(
                  fontSize: isHigh ? AppTypography.bodySmall : AppTypography.bodyMedium,
                  color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: _buildColoredText(
                line,
                TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  height: 1.5,
                  fontWeight: isHigh ? AppTypography.semiBold : AppTypography.regular,
                  color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurface,
                ),
                mlColors,
              ),
            ),
          ],
        ),
      ));
    }).toList();
  }

  /// Flat bullet list for backward compatibility (no type grouping).
  List<Widget> _buildFlatRecommendations(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    List<Map<String, dynamic>> recs,
  ) {
    final mlColors = context.mlColors;
    return [
      const SizedBox(height: AppSpacing.md),
      Text(
        l10n.aiRecommendations,
        style: TextStyle(
          fontSize: AppTypography.bodyLarge,
          fontWeight: AppTypography.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ...recs.expand((rec) {
        final message = localizePacked(rec['message'] as String? ?? '', langCode);
        final priority = (rec['priority'] as String? ?? '').toUpperCase();
        final isHigh = priority == 'HIGH';
        final grouped = _groupByTicker(message);

        return grouped.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  isHigh ? ' \u25B6 ' : ' \u2022 ',
                  style: TextStyle(
                    fontSize: isHigh ? AppTypography.bodySmall : AppTypography.bodyMedium,
                    color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: _buildColoredText(
                  line,
                  TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    height: 1.5,
                    fontWeight: isHigh ? AppTypography.semiBold : AppTypography.regular,
                    color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                  mlColors,
                ),
              ),
            ],
          ),
        ));
      }),
    ];
  }

  /// Regex for percentage patterns: +12.3%, -5%, 12.3% etc.
  static final _pctPattern = RegExp(r'([+\-]?\d+\.?\d*)\s*%');

  /// Builds a RichText widget that colorizes percentage values.
  /// Positive → gainColor, negative → lossColor, unsigned → default.
  Widget _buildColoredText(String text, TextStyle baseStyle, MarketLensColors mlColors) {
    final matches = _pctPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final m in matches) {
      // Text before match
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      // The matched percentage
      final numStr = m.group(1)!;
      final value = double.tryParse(numStr);
      Color? color;
      if (value != null) {
        if (value > 0 || numStr.startsWith('+')) {
          color = mlColors.gainColor;
        } else if (value < 0) {
          color = mlColors.lossColor;
        }
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: TextStyle(
          color: color,
          fontWeight: AppTypography.semiBold,
        ),
      ));
      lastEnd = m.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
