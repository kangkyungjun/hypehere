import 'package:flutter/material.dart';
import '../../../models/community/post.dart';
import '../../../services/community_api_client.dart';
import '../../../widgets/community/post_card.dart';
import '../../community/community_feed_screen.dart';
import '../../community/post_detail_screen.dart';
import '../../community/create_post_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/error_localizer.dart';
import '../../../l10n/app_localizations.dart';

class TickerCommunitySection extends StatefulWidget {
  final String ticker;

  const TickerCommunitySection({
    super.key,
    required this.ticker,
  });

  @override
  State<TickerCommunitySection> createState() => TickerCommunitySectionState();
}

class TickerCommunitySectionState extends State<TickerCommunitySection> {
  final CommunityApiClient _communityApiClient = CommunityApiClient();
  Future<({List<Post> items, int count, bool hasNext})>? _communityFuture;

  @override
  void initState() {
    super.initState();
    _communityFuture = _communityApiClient.getPosts(ticker: widget.ticker);
  }

  void refresh() {
    setState(() {
      _communityFuture = _communityApiClient.getPosts(ticker: widget.ticker);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md(context.mlColors.overlayDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (타이틀 + 게시글 수 + 전체보기 버튼)
          FutureBuilder<({List<Post> items, int count, bool hasNext})>(
            future: _communityFuture,
            builder: (context, snapshot) {
              final postCount = snapshot.data?.count ?? 0;
              return Row(
                children: [
                  Text(
                    l10n.liveTalk,
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  if (postCount > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        l10n.totalPosts(postCount),
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: AppTypography.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: _navigateToCommunity,
                    child: Row(
                      children: [
                        Text(
                          l10n.viewAll,
                          style: TextStyle(fontSize: AppTypography.bodyLarge),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // 글쓰기 인라인 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToCreatePost(),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.writePost),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 게시글 미리보기 (최신 3개)
          FutureBuilder<({List<Post> items, int count, bool hasNext})>(
            future: _communityFuture,
            builder: (context, snapshot) {
              // 로딩 중
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // 에러 발생
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      l10n.cannotLoadPosts,
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              // 데이터 없음 — CTA로 첫 글 작성 유도
              if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.noPostsInTicker,
                          style: TextStyle(
                            fontSize: AppTypography.bodyLarge,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => _navigateToCreatePost(),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(l10n.beFirstToPost),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 최신 3개만 표시
              final posts = snapshot.data!.items.take(3).toList();

              return Column(
                children: posts.map((post) {
                  return PostCard(
                    post: post,
                    compact: true,
                    onTap: () => _navigateToPostDetail(post.id),
                    onEdit: post.canEdit ? () => _editCommunityPost(post) : null,
                    onDelete: post.canDelete ? () => _deleteCommunityPost(post) : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 게시글 수정 (PostCard 메뉴)
  Future<void> _editCommunityPost(Post post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(editPost: post),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _communityFuture = _communityApiClient.getPosts(ticker: widget.ticker);
      });
    }
  }

  /// 게시글 삭제 (PostCard 메뉴)
  Future<void> _deleteCommunityPost(Post post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePost),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.mlColors.dangerColor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _communityApiClient.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.postDeleted)),
        );
        setState(() {
          _communityFuture = _communityApiClient.getPosts(ticker: widget.ticker);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 글쓰기 화면으로 이동
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(prefilledTicker: widget.ticker),
      ),
    );
    if (result == true && mounted) {
      setState(() {
        _communityFuture = _communityApiClient.getPosts(ticker: widget.ticker);
      });
    }
  }

  /// 종목 전용 게시판으로 이동
  void _navigateToCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityFeedScreen(
          initialTicker: widget.ticker,
        ),
      ),
    );
  }

  /// 게시글 상세로 이동
  void _navigateToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }
}
