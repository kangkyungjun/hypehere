import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';
import 'market_news_modal.dart';

/// Semi-transparent hot topic toast overlay for top of news list.
///
/// Shows up to 3 hot topic headlines with tap-to-detail.
/// Additional items shown as "+N more" count.
class HotTopicToast extends StatelessWidget {
  final List<NewsItem> hotTopics;
  final void Function(int index) onDismissItem;

  const HotTopicToast({
    super.key,
    required this.hotTopics,
    required this.onDismissItem,
  });

  @override
  Widget build(BuildContext context) {
    if (hotTopics.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    final previewItems = hotTopics.take(3).toList();
    final moreCount = hotTopics.length - previewItems.length;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadow.sm(context.mlColors.overlayDim),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fire icon
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    '🔥',
                    style: TextStyle(fontSize: AppTypography.headlineLarge),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Content: up to 3 headlines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < previewItems.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 8,
                            thickness: 0.5,
                            color: theme.colorScheme.onErrorContainer
                                .withValues(alpha: 0.15),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => MarketNewsModal.show(
                                  context,
                                  previewItems[i],
                                ),
                                child: Text(
                                  previewItems[i].aiSummary.localize(langCode),
                                  style: TextStyle(
                                    fontSize: AppTypography.bodySmall,
                                    fontWeight: i == 0
                                        ? AppTypography.semiBold
                                        : AppTypography.regular,
                                    color: theme.colorScheme.onErrorContainer,
                                    height: 1.3,
                                  ),
                                  maxLines: i == 0 ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => onDismissItem(i),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxs),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: theme.colorScheme.onErrorContainer
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (moreCount > 0) ...[
                        Divider(
                          height: 8,
                          thickness: 0.5,
                          color: theme.colorScheme.onErrorContainer.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              MarketNewsModal.show(context, hotTopics.first),
                          child: Text(
                            l10n.hotTopicMore(moreCount),
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              fontWeight: AppTypography.medium,
                              color: theme.colorScheme.onErrorContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
