import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';

/// Card displaying full portfolio AI analysis and recommendations.
class PortfolioAICard extends StatelessWidget {
  final PortfolioSummary? summary;

  const PortfolioAICard({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasAI = summary?.aiSummary != null && summary!.aiSummary!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.portfolioAIAnalysis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (hasAI) ...[
                Text(
                  summary!.aiSummary!,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, height: 1.4),
                ),
                if (summary!.aiRecommendations != null && summary!.aiRecommendations!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.aiRecommendations,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...summary!.aiRecommendations!.map((rec) {
                    final action = rec['action'] as String? ?? '';
                    final ticker = rec['ticker'] as String? ?? '';
                    final reason = rec['reason'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('  •  ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          Expanded(
                            child: Text(
                              ticker.isNotEmpty ? '$ticker $action: $reason' : '$action: $reason',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      l10n.dailyUpdate,
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      l10n.analysisWaiting,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
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
}
