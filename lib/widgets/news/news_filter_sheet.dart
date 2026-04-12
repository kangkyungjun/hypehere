// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_filter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
      backgroundColor: Colors.transparent,
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
  late NewsSourceFilter _sourceFilter;
  late Set<String> _sentimentGrades;
  late Set<String> _sectors;
  late bool _breakingOnly;
  bool _sectorExpanded = false;

  @override
  void initState() {
    super.initState();
    _sourceFilter = widget.initialState.sourceFilter;
    _sentimentGrades = Set.from(widget.initialState.sentimentGrades);
    _sectors = Set.from(widget.initialState.sectors);
    _breakingOnly = widget.initialState.breakingOnly;
  }

  int get _activeCount {
    int count = 0;
    if (_sourceFilter != NewsSourceFilter.all) count++;
    if (_sentimentGrades.isNotEmpty) count++;
    if (_sectors.isNotEmpty) count++;
    if (_breakingOnly) count++;
    return count;
  }

  void _reset() {
    setState(() {
      _sourceFilter = NewsSourceFilter.all;
      _sentimentGrades = {};
      _sectors = {};
      _breakingOnly = false;
    });
  }

  void _apply() {
    Navigator.of(context).pop(NewsFilterState(
      sourceFilter: _sourceFilter,
      sentimentGrades: _sentimentGrades,
      sectors: _sectors,
      breakingOnly: _breakingOnly,
    ));
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7
                 - MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header: Reset + Apply
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(l10n.filterReset),
                ),
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

          const Divider(),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source filter
                  Text(
                    l10n.filterSource,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSourceRadios(l10n, theme),
                  const SizedBox(height: AppSpacing.xl),

                  // Sentiment filter
                  Text(
                    l10n.filterSentiment,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSentimentChips(l10n, theme),
                  const SizedBox(height: AppSpacing.xl),

                  // Breaking only
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.filterBreakingOnly),
                    value: _breakingOnly,
                    onChanged: (v) => setState(() => _breakingOnly = v ?? false),
                  ),

                  // Sector filter (expandable)
                  _buildSectorSection(l10n, theme),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceRadios(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        RadioListTile<NewsSourceFilter>(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.filterAll),
          value: NewsSourceFilter.all,
          groupValue: _sourceFilter,
          onChanged: (v) => setState(() => _sourceFilter = v!),
        ),
        RadioListTile<NewsSourceFilter>(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.filterMyWatchlist),
          subtitle: widget.watchlistTickers.isEmpty
              ? Text(
                  l10n.filterNoWatchlist,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: theme.colorScheme.outline,
                  ),
                )
              : null,
          value: NewsSourceFilter.watchlist,
          groupValue: _sourceFilter,
          onChanged: widget.watchlistTickers.isEmpty
              ? null
              : (v) => setState(() => _sourceFilter = v!),
        ),
        RadioListTile<NewsSourceFilter>(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.filterMarketOnly),
          value: NewsSourceFilter.marketOnly,
          groupValue: _sourceFilter,
          onChanged: (v) => setState(() => _sourceFilter = v!),
        ),
      ],
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
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        l10n.filterSector,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: _sectors.isNotEmpty
          ? Text(
              '${_sectors.length}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      initiallyExpanded: _sectorExpanded,
      onExpansionChanged: (v) => _sectorExpanded = v,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: NewsFilterState.allSectors.map((sector) {
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
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
