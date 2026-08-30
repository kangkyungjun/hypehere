import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';
import '../common/ml_expandable_card.dart';
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
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final mlc = context.mlColors;

    // 개편 전: `_collapsed`(다른 곳은 전부 `_expanded`라 **극성이 반대**),
    // chevron 회전 turns도 뒤집혀 있었고, curve 없이 200ms 하드코딩이었다.
    // 프리미티브가 상태·회전·애니메이션·Semantics를 전부 담당한다.
    return MlExpandableCard(
      initiallyExpanded: true,
      tapTarget: MlExpandTapTarget.headerOnly,
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      divider: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      header: Row(
        children: [
          Text('❗', style: TextStyle(fontSize: AppTypography.bodyMedium)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.keyNewsTitle,
              style: AppTypography.bodyStrong.copyWith(
                color: mlc.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      detail: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.items.length; i++)
            _buildRow(context, i, widget.items[i], langCode, mlc),
        ],
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
                  fontSize: AppTypography.bodyLarge,
                  color: mlc.textPrimary,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 18, color: mlc.textSecondary),
          ],
        ),
      ),
    );
  }
}
