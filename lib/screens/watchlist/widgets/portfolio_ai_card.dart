import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/multilingual.dart';

/// Card displaying full portfolio AI analysis and recommendations.
///
/// Groups [ai_recommendations] by type (PORTFOLIO_OVERVIEW, TECHNICAL_INSIGHT,
/// MARKET_INTELLIGENCE, ACTION_SUMMARY) with bold section headers and thin
/// dividers for readability. Unknown types fall into the generic section.
class PortfolioAICard extends StatelessWidget {
  final PortfolioSummary? summary;

  const PortfolioAICard({super.key, this.summary});

  /// Ordered type keys and their ARB label getters.
  static const _typeOrder = [
    'PORTFOLIO_OVERVIEW',
    'TECHNICAL_INSIGHT',
    'MARKET_INTELLIGENCE',
    'ACTION_SUMMARY',
  ];

  String _sectionTitle(String type, AppLocalizations l10n) {
    switch (type) {
      case 'PORTFOLIO_OVERVIEW':
        return l10n.recPortfolioOverview;
      case 'TECHNICAL_INSIGHT':
        return l10n.recTechnicalInsight;
      case 'MARKET_INTELLIGENCE':
        return l10n.recMarketIntelligence;
      case 'ACTION_SUMMARY':
        return l10n.recActionSummary;
      default:
        return l10n.aiRecommendations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langCode = effectiveLanguageCode(context);
    final hasAI = summary?.aiSummary != null && summary!.aiSummary!.isNotEmpty;

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
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.portfolioAIAnalysis,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (hasAI) ...[
                // AI summary text
                Text(
                  localizePacked(summary!.aiSummary!, langCode),
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurface, height: 1.4),
                ),

                // Grouped recommendations by type
                if (summary!.aiRecommendations != null && summary!.aiRecommendations!.isNotEmpty)
                  ..._buildGroupedRecommendations(theme, l10n, langCode),

                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.dailyUpdate,
                      style: TextStyle(fontSize: AppTypography.micro, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Groups recommendations by type and renders each section.
  List<Widget> _buildGroupedRecommendations(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
  ) {
    final recs = summary!.aiRecommendations!;

    // Group by type
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final rec in recs) {
      final type = (rec['type'] as String?) ?? '';
      grouped.putIfAbsent(type, () => []).add(rec);
    }

    // If no known types found, fall back to flat list (backward compat)
    final hasKnownTypes = grouped.keys.any((t) => _typeOrder.contains(t));
    if (!hasKnownTypes) {
      return _buildFlatRecommendations(theme, l10n, langCode, recs);
    }

    final widgets = <Widget>[];

    // Render in defined order
    for (final type in _typeOrder) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;
      widgets.addAll(_buildSection(theme, l10n, langCode, type, items));
    }

    // Render unknown types at the end
    for (final entry in grouped.entries) {
      if (_typeOrder.contains(entry.key)) continue;
      if (entry.value.isEmpty) continue;
      widgets.addAll(_buildSection(theme, l10n, langCode, entry.key, entry.value));
    }

    return widgets;
  }

  /// Renders a single recommendation section: bold underlined header + messages.
  List<Widget> _buildSection(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    String type,
    List<Map<String, dynamic>> items,
  ) {
    return [
      const SizedBox(height: 10),
      // Section header with underline
      Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          _sectionTitle(type, l10n),
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: AppTypography.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      // Messages
      ...items.map((rec) {
        final message = localizePacked(
          rec['message'] as String? ?? '',
          langCode,
        );
        final priority = (rec['priority'] as String? ?? '').toUpperCase();
        final isHigh = priority == 'HIGH';
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '  \u2022  ',
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    height: 1.4,
                    fontWeight: isHigh ? AppTypography.semiBold : FontWeight.normal,
                    color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  /// Flat bullet list for backward compatibility (no type grouping).
  List<Widget> _buildFlatRecommendations(
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
    List<Map<String, dynamic>> recs,
  ) {
    return [
      const SizedBox(height: AppSpacing.md),
      Text(
        l10n.aiRecommendations,
        style: TextStyle(
          fontSize: AppTypography.bodySmall,
          fontWeight: AppTypography.semiBold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ...recs.map((rec) {
        final message = localizePacked(rec['message'] as String? ?? '', langCode);
        final priority = (rec['priority'] as String? ?? '').toUpperCase();
        final isHigh = priority == 'HIGH';
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('  \u2022  ', style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
              )),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: isHigh ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }
}
