import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community/comment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onLike;

  const CommentCard({
    super.key,
    required this.comment,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onLike,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLocked = comment.isLocked;
    final showMenu = onEdit != null || onDelete != null || onReport != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.mlColors.subtleBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author + Time + Menu
          Row(
            children: [
              Text(
                comment.author.nickname,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: AppTypography.semiBold,
                  color: isLocked ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                _formatTimeAgo(comment.createdAt, l10n),
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const Spacer(),
              if (showMenu && !isLocked)
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
          // Content
          if (isLocked)
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else
            Text(
              comment.content,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          // Like button (only if not locked)
          if (!isLocked)
            GestureDetector(
              onTap: onLike,
              child: Row(
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: comment.isLiked ? context.mlColors.dangerColor : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${comment.likeCount}',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: comment.isLiked ? context.mlColors.dangerColor : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
