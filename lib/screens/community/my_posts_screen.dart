import 'package:flutter/material.dart';
import '../../models/community/post.dart';
import '../../services/community_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/community/post_card.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../../l10n/app_localizations.dart';

/// 내 게시글 목록 화면
///
/// - 로그인한 사용자의 모든 게시글 표시
/// - PostCard 위젯 재사용
/// - 무한 스크롤 지원 (향후 구현)
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();

  /// 내 게시글 목록
  List<Post> _posts = [];

  /// 로딩 상태
  bool _isLoading = false;

  /// 에러 메시지
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  /// 내 게시글 로드
  Future<void> _loadMyPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.getMyPosts();
      final posts = result.items;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// 게시글 수정 (PostCard ⋮ 메뉴)
  Future<void> _editPost(Post post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(editPost: post),
      ),
    );

    if (result == true) {
      _loadMyPosts();
    }
  }

  /// 게시글 삭제 (PostCard ⋮ 메뉴)
  Future<void> _deletePost(Post post) async {
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
      await _apiClient.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.postDeleted)),
        );
        _loadMyPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 게시글 상세로 이동
  void _navigateToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    ).then((_) {
      // 상세 화면에서 돌아올 때 목록 새로고침
      _loadMyPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPosts),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyPosts,
        child: _buildBody(),
      ),
    );
  }

  /// 본문 영역 (로딩/에러/빈 상태/게시글 목록)
  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    // 로딩 중
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 발생
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.mlColors.dangerColor,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.cannotLoadPosts,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _loadMyPosts,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // 게시글 없음
    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 브랜드 컬러 CircleAvatar with Icon
              CircleAvatar(
                radius: 48,
                backgroundColor: context.mlColors.accentBlue.withValues(alpha: 0.1),
                child: Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: context.mlColors.accentBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 제목
              Text(
                l10n.startWithFirstPost,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: context.mlColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 설명
              Text(
                l10n.shareThoughtsPrompt,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.mlColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // CTA 버튼
              ElevatedButton.icon(
                onPressed: () {
                  // Community 탭으로 이동 (index 2)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.edit),
                label: Text(l10n.writeAPost),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.mlColors.accentBlue,
                  foregroundColor: context.mlColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 게시글 목록
    return ListView.builder(
      itemCount: _posts.length,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return PostCard(
          post: post,
          onTap: () => _navigateToPostDetail(post.id),
          onEdit: post.canEdit ? () => _editPost(post) : null,
          onDelete: post.canDelete ? () => _deletePost(post) : null,
        );
      },
    );
  }
}
