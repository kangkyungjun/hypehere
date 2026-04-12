import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community/post.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/badge_colors.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  /// When true, removes horizontal padding and divider (for embedded use)
  final bool compact;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.compact = false,
  });

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    } else if (difference.inHours < 1) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.timeYesterday;
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }

  Color _getTickerColor(String ticker) => BadgeColors.tickerBadge(ticker);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: compact
                ? const EdgeInsets.only(top: AppSpacing.sm)
                : const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ticker badge + author + time
                Row(
                  children: [
                    // Ticker badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getTickerColor(post.ticker),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        post.ticker.isEmpty ? l10n.freePost : post.ticker,
                        style: TextStyle(
                          color: context.mlColors.onPrimary,
                          fontSize: AppTypography.bodySmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Author
                    Text(
                      post.author.nickname,
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: AppTypography.medium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // Time
                    Text(
                      _formatTimeAgo(post.createdAt, l10n),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    // 수정/삭제/신고 메뉴
                    if (onEdit != null || onDelete != null || onReport != null)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(Icons.more_vert, size: 18, color: Theme.of(context).colorScheme.outline),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'delete') {
                              onDelete?.call();
                            } else if (value == 'report') {
                              onReport?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            if (onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                height: 24,
                                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xl),
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(l10n.edit),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                height: 24,
                                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xl),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: context.mlColors.dangerColor),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(l10n.delete, style: TextStyle(color: context.mlColors.dangerColor)),
                                  ],
                                ),
                              ),
                            if (onReport != null)
                              PopupMenuItem(
                                value: 'report',
                                height: 24,
                                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xl),
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined, size: 18, color: context.mlColors.reportColor),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(l10n.report, style: TextStyle(color: context.mlColors.reportColor)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Title
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                // Content preview
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                // Footer: like count + comment count
                Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: post.isLiked ? context.mlColors.dangerColor : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${post.commentCount}',
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(indent: compact ? 0 : 16, endIndent: compact ? 0 : 16),
        ],
      ),
    );
  }
}
