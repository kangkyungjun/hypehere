import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';

/// Bottom sheet showing instant AI advice after a stock purchase.
class InstantAdviceSheet extends StatelessWidget {
  final PortfolioAdvice advice;

  const InstantAdviceSheet({super.key, required this.advice});

  /// Show the sheet.
  static Future<void> show(BuildContext context, PortfolioAdvice advice) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InstantAdviceSheet(advice: advice),
    );
  }

  Color _signalColor(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY':
      case 'STRONG_BUY':
        return Colors.green;
      case 'SELL':
      case 'STRONG_SELL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _signalLabel(String? signal) {
    switch (signal?.toUpperCase()) {
      case 'BUY':
        return 'BUY';
      case 'STRONG_BUY':
        return 'STRONG BUY';
      case 'SELL':
        return 'SELL';
      case 'STRONG_SELL':
        return 'STRONG SELL';
      case 'HOLD':
        return 'HOLD';
      default:
        return signal ?? 'N/A';
    }
  }

  /// Parse multilingual summary (|||  delimited) — pick current locale.
  String _parseSummary(String? raw, BuildContext context) {
    if (raw == null || raw.isEmpty) return '';
    final parts = raw.split('|||');
    if (parts.length == 1) return raw;

    final lang = Localizations.localeOf(context).languageCode;
    // Convention: en|||ko|||ja|||zh|||es
    const langOrder = ['en', 'ko', 'ja', 'zh', 'es'];
    final idx = langOrder.indexOf(lang);
    if (idx >= 0 && idx < parts.length) return parts[idx].trim();
    return parts.first.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header: ticker + signal pill + confidence
                Row(
                  children: [
                    Text(
                      advice.ticker,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isKo && advice.nameKo != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        advice.nameKo!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else if (advice.name != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        advice.name!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (advice.signal != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _signalColor(advice.signal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _signalLabel(advice.signal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                // Confidence
                if (advice.confidence != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.confidence}: ${(advice.confidence! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Title
                Text(
                  l10n.aiAdviceInstant,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Summary text
                if (advice.summary != null)
                  Text(
                    _parseSummary(advice.summary, context),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                const SizedBox(height: 16),

                // Bullish factors
                if (advice.bullishReasons.isNotEmpty) ...[
                  Text(
                    l10n.bullishFactorsPortfolio,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...advice.bullishReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('+ ', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                _parseSummary(r, context),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],

                // Bearish factors
                if (advice.bearishReasons.isNotEmpty) ...[
                  Text(
                    l10n.bearishFactorsPortfolio,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...advice.bearishReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('- ', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                _parseSummary(r, context),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],

                // Footer
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: theme.colorScheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.detailedAnalysisComingSoon,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
