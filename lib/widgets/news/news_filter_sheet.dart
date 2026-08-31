// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_filter.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../common/ml_divider.dart';
import '../common/modal_handle_bar.dart';

/// Bottom sheet for filtering news list.
///
/// Returns updated [NewsFilterState] when user taps "Apply",
/// or null if dismissed without applying.
class NewsFilterSheet extends StatefulWidget {
  final NewsFilterState initialState;
  final List<String> watchlistTickers;

  const NewsFilterSheet({
    super.key,
    required this.initialState,
    required this.watchlistTickers,
  });

  /// Show the filter sheet and return the new state (or null).
  static Future<NewsFilterState?> show(
    BuildContext context, {
    required NewsFilterState currentState,
    required List<String> watchlistTickers,
  }) {
    return showModalBottomSheet<NewsFilterState>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => NewsFilterSheet(
        initialState: currentState,
        watchlistTickers: watchlistTickers,
      ),
    );
  }

  @override
  State<NewsFilterSheet> createState() => _NewsFilterSheetState();
}

class _NewsFilterSheetState extends State<NewsFilterSheet> {
  late NewsCategory _category;
  late Set<String> _sentimentGrades;
  late Set<String> _sectors;
  late bool _breakingOnly;

  List<String> _availableSectors = NewsFilterState.fallbackSectors;
  bool _sectorsLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialState.category;
    _sentimentGrades = Set.from(widget.initialState.sentimentGrades);
    _sectors = Set.from(widget.initialState.sectors);
    _breakingOnly = widget.initialState.breakingOnly;
    _loadSectors();
  }

  Future<void> _loadSectors() async {
    setState(() => _sectorsLoading = true);
    try {
      final sectors = await AnalyticsApiClient().getNewsSectors();
      if (sectors.isNotEmpty && mounted) {
        setState(() => _availableSectors = sectors);
      }
    } catch (_) {
      // fallback already set
    } finally {
      if (mounted) setState(() => _sectorsLoading = false);
    }
  }

  int get _activeCount {
    int count = 0;
    if (_category != NewsCategory.all) count++;
    if (_sentimentGrades.isNotEmpty) count++;
    if (_sectors.isNotEmpty) count++;
    if (_breakingOnly) count++;
    return count;
  }

  void _reset() {
    setState(() {
      _category = NewsCategory.all;
      _sentimentGrades = {};
      _sectors = {};
      _breakingOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      NewsFilterState(
        category: _category,
        sentimentGrades: _sentimentGrades,
        sectors: _sectors,
        breakingOnly: _breakingOnly,
      ),
    );
  }

  /// Localized sector name
  String _sectorLabel(BuildContext context, String sector) {
    final l10n = AppLocalizations.of(context);
    switch (sector) {
      case 'Technology':
        return l10n.sectorTechnology;
      case 'Healthcare':
        return l10n.sectorHealthcare;
      case 'Energy':
        return l10n.sectorEnergy;
      case 'Consumer Cyclical':
        return l10n.sectorCyclical;
      case 'Consumer Defensive':
        return l10n.sectorDefensive;
      case 'Communication Services':
        return l10n.sectorComm;
      case 'Financials':
        return l10n.sectorFinance;
      case 'Industrials':
        return l10n.sectorIndustrials;
      case 'Utilities':
        return l10n.sectorUtilities;
      case 'Real Estate':
        return l10n.sectorRealEstate;
      case 'Basic Materials':
        return l10n.sectorMaterials;
      default:
        return sector;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.mlColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.65 -
            MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalHandleBar(),

          // Header: Reset + Apply
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.newsFilter,
                    style: AppTypography.sectionTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                TextButton(onPressed: _reset, child: Text(l10n.filterReset)),
                const SizedBox(width: AppSpacing.xs),
                FilledButton(
                  onPressed: _apply,
                  child: Text(
                    _activeCount > 0
                        ? '${l10n.filterApply} ($_activeCount)'
                        : l10n.filterApply,
                  ),
                ),
              ],
            ),
          ),

          const MlDivider(),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source filter (horizontal chips)
                  Text(
                    l10n.filterSource,
                    style: AppTypography.cardTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSourceChips(l10n),
                  const SizedBox(height: AppSpacing.md),

                  // Sentiment filter
                  Text(
                    l10n.filterSentiment,
                    style: AppTypography.cardTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSentimentChips(l10n, theme),
                  const SizedBox(height: AppSpacing.md),

                  // Breaking only
                  Container(
                    decoration: BoxDecoration(
                      color: colors.infoBg.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      title: Text(l10n.filterBreakingOnly),
                      value: _breakingOnly,
                      onChanged: (v) =>
                          setState(() => _breakingOnly = v ?? false),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Sector filter (always expanded)
                  _buildSectorSection(l10n, theme),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChips(AppLocalizations l10n) {
    final options = [
      (NewsCategory.all, l10n.filterAll),
      (NewsCategory.biz, 'Biz'),
      (NewsCategory.world, 'World'),
      (NewsCategory.watchlist, l10n.filterMyWatchlist),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      children: options.map((opt) {
        final selected = _category == opt.$1;
        final isDisabled =
            opt.$1 == NewsCategory.watchlist && widget.watchlistTickers.isEmpty;
        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => _category = opt.$1),
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? context.mlColors.infoBg.withValues(alpha: 0.72)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: selected
                      ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: selected
                      ? AppTypography.bold
                      : AppTypography.medium,
                  color: selected
                      ? context.mlColors.accentBlue
                      : context.mlColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSentimentChips(AppLocalizations l10n, ThemeData theme) {
    final options = [
      ('bullish', l10n.sentimentBullish, context.mlColors.gainColor),
      ('bearish', l10n.sentimentBearish, context.mlColors.lossColor),
      ('neutral', l10n.sentimentNeutral, context.mlColors.neutralColor),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final (value, label, color) = opt;
        final selected = _sentimentGrades.contains(value);
        return FilterChip(
          label: Text(label),
          selected: selected,
          selectedColor: color.withValues(alpha: 0.2),
          checkmarkColor: color,
          onSelected: (sel) {
            setState(() {
              if (sel) {
                _sentimentGrades.add(value);
              } else {
                _sentimentGrades.remove(value);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectorSection(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.filterSector,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            if (_sectors.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_sectors.length}',
                style: TextStyle(
                  color: context.mlColors.accentBlue,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_sectorsLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: AppStroke.medium),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _availableSectors.map((sector) {
              final selected = _sectors.contains(sector);
              return FilterChip(
                label: Text(_sectorLabel(context, sector)),
                selected: selected,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _sectors.add(sector);
                    } else {
                      _sectors.remove(sector);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
