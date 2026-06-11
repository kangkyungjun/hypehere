import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';
import 'market_news_modal.dart';

/// Collapsible "Today's Key News" card: a numbered 1..5 list of the
/// highest-priority recent news. The header chevron folds/unfolds the
/// whole list; tapping a row opens the shared [MarketNewsModal].
class KeyNewsCard extends StatefulWidget {
  final List<NewsItem> items;

  const KeyNewsCard({super.key, required this.items});

  @override
  State<KeyNewsCard> createState() => _KeyNewsCardState();
}

class _KeyNewsCardState extends State<KeyNewsCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final mlc = context.mlColors;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (tap to collapse/expand)
            InkWell(
              onTap: () => setState(() => _collapsed = !_collapsed),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      '❗',
                      style: TextStyle(fontSize: AppTypography.bodyMedium),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.keyNewsTitle,
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.bold,
                        color: mlc.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _collapsed ? 0.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 22,
                        color: mlc.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body (animated collapse)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _collapsed
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < widget.items.length; i++)
                          _buildRow(context, i, widget.items[i], langCode, mlc),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    int index,
    NewsItem item,
    String langCode,
    MarketLensColors mlc,
  ) {
    return InkWell(
      onTap: () => MarketNewsModal.show(context, item),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: AppTypography.bold,
                  color: mlc.accentBlue,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.aiSummary.localize(langCode),
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: mlc.textPrimary,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 18, color: mlc.textTertiary),
          ],
        ),
      ),
    );
  }
}
