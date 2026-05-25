import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/community/comment.dart';
import '../../services/community_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'post_detail_screen.dart';
import '../../l10n/app_localizations.dart';

/// 내 댓글 목록 화면
///
/// - 로그인한 사용자의 모든 댓글 표시
/// - 댓글이 달린 게시글 정보 함께 표시
/// - 클릭 시 해당 게시글 상세로 이동
class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();

  /// 내 댓글 목록
  List<Comment> _comments = [];

  /// 로딩 상태
  bool _isLoading = false;

  /// 에러 메시지
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyComments();
  }

  /// 내 댓글 로드
  Future<void> _loadMyComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.getMyComments();
      final comments = result.items;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// 게시글 상세로 이동 (댓글이 달린 게시글)
  void _navigateToPostDetail(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    ).then((_) {
      // 상세 화면에서 돌아올 때 목록 새로고침
      _loadMyComments();
    });
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myComments),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyComments,
        child: _buildBody(),
      ),
    );
  }

  /// 본문 영역 (로딩/에러/빈 상태/댓글 목록)
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _loadMyComments,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // 댓글 없음
    if (_comments.isEmpty) {
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
                  Icons.comment_outlined,
                  size: 48,
                  color: context.mlColors.accentBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 제목
              Text(
                l10n.writeFirstCommentPrompt,
                style: TextStyle(
                  fontSize: AppTypography.displayMedium,
                  fontWeight: AppTypography.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 설명
              Text(
                l10n.startConversationPrompt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                icon: const Icon(Icons.forum),
                label: Text(l10n.browsePosts),
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

    // 댓글 목록
    return ListView.builder(
      itemCount: _comments.length,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentCard(comment);
      },
    );
  }

  /// 댓글 카드 위젯
  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: () => _navigateToPostDetail(comment.postId),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 댓글 내용
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: AppTypography.headlineSmall,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.lg),

              // 하단 정보 (날짜, 좋아요 수)
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDate(comment.createdAt),
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  Icon(
                    Icons.favorite,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${comment.likeCount}',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // 게시글로 이동 아이콘
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
