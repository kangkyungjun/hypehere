// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/community/post.dart';
import '../../models/community/comment.dart';
import '../../services/community_api_client.dart';
import '../../providers/auth_provider.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/common/bento_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/community/comment_card.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import 'create_post_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../utils/badge_colors.dart';
import '../../l10n/app_localizations.dart';

/// 게시글 상세 화면
///
/// - 단일 게시글 내용 + 댓글 목록 표시
/// - 좋아요/댓글 작성 기능 (비회원은 로그인 유도)
/// - 낙관적 UI 업데이트로 반응성 향상
/// - 게시글/댓글 수정/삭제 기능
class PostDetailScreen extends StatefulWidget {
  /// 조회할 게시글 ID
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// 게시글 정보
  Post? _post;

  /// 댓글 목록
  List<Comment> _comments = [];

  /// 로딩 상태
  bool _isLoading = false;

  /// 댓글 제출 중 상태
  bool _isSubmittingComment = false;

  /// 에러 메시지
  String? _errorMessage;

  /// 댓글 페이지네이션 상태
  int _commentPage = 1;
  bool _hasNextComments = false;
  bool _isLoadingMoreComments = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 하단 접근 시 댓글 추가 로드
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  /// 게시글 + 댓글 첫 페이지 로드
  Future<void> _loadPostAndComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _commentPage = 1;
      _hasNextComments = false;
    });

    try {
      final post = await _apiClient.getPost(widget.postId);
      final commentResult = await _apiClient.getComments(
        widget.postId,
        page: 1,
      );

      setState(() {
        _post = post;
        _comments = commentResult.items;
        _hasNextComments = commentResult.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// 댓글 추가 페이지 로드
  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasNextComments) return;

    setState(() {
      _isLoadingMoreComments = true;
    });

    try {
      final result = await _apiClient.getComments(
        widget.postId,
        page: _commentPage + 1,
      );
      setState(() {
        _commentPage++;
        _comments.addAll(result.items);
        _hasNextComments = result.hasNext;
        _isLoadingMoreComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreComments = false;
      });
    }
  }

  /// 좋아요 토글 (낙관적 UI 업데이트)
  Future<void> _toggleLike() async {
    if (_post == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 비회원이면 로그인 유도
    if (!authProvider.isLoggedIn) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const SignupPromptDialog(),
      );

      if (result == 'login') {
        if (!mounted) return;
        final success = await Navigator.push<bool>(
          context,
          appPageRoute(builder: (_) => const LoginScreen()),
        );

        if (success == true) {
          // 로그인 성공 후 재시도
          _toggleLike();
        }
      } else if (result == 'signup') {
        if (!mounted) return;
        final success = await Navigator.push<bool>(
          context,
          appPageRoute(builder: (_) => const SignupScreen()),
        );

        if (success == true) {
          // 회원가입 성공 후 재시도
          _toggleLike();
        }
      }
      return;
    }

    // 낙관적 UI 업데이트
    final originalPost = _post!;
    setState(() {
      _post = _post!.copyWith(
        isLiked: !_post!.isLiked,
        likeCount: _post!.isLiked ? _post!.likeCount - 1 : _post!.likeCount + 1,
      );
    });

    try {
      if (originalPost.isLiked) {
        await _apiClient.unlikePost(widget.postId);
      } else {
        await _apiClient.likePost(widget.postId);
      }
    } catch (e) {
      // 에러 발생 시 롤백
      setState(() {
        _post = originalPost;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 댓글 작성 처리
  Future<void> _submitComment() async {
    if (_post == null) return;

    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commentRequired)),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 비회원이면 로그인 유도
    if (!authProvider.isLoggedIn) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => const SignupPromptDialog(),
      );

      if (result == 'login') {
        if (!mounted) return;
        final success = await Navigator.push<bool>(
          context,
          appPageRoute(builder: (_) => const LoginScreen()),
        );

        if (success == true) {
          // 로그인 성공 후 재시도
          _submitComment();
        }
      } else if (result == 'signup') {
        if (!mounted) return;
        final success = await Navigator.push<bool>(
          context,
          appPageRoute(builder: (_) => const SignupScreen()),
        );

        if (success == true) {
          // 회원가입 성공 후 재시도
          _submitComment();
        }
      }
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final newComment = await _apiClient.createComment(
        postId: widget.postId,
        content: content,
      );

      // 댓글 목록에 추가 + 입력란 초기화
      setState(() {
        _comments.add(newComment);
        _post = _post!.copyWith(commentCount: _post!.commentCount + 1);
        _commentController.clear();
        _isSubmittingComment = false;
      });

      // 새 댓글로 스크롤
      Future.delayed(AppDuration.fastest, () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDuration.normal,
          curve: AppDuration.standard,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).commentCreated)),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 게시글 삭제
  Future<void> _deletePost() async {
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
            style: TextButton.styleFrom(
              foregroundColor: context.mlColors.dangerColor,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.deletePost(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 게시글 수정 화면으로 이동
  Future<void> _editPost() async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(builder: (_) => CreatePostScreen(editPost: _post)),
    );

    if (result == true) {
      _loadPostAndComments();
    }
  }

  /// 댓글 좋아요 토글 (낙관적 UI)
  Future<void> _toggleCommentLike(Comment comment) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    // 낙관적 UI 업데이트
    final index = _comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    final original = _comments[index];
    setState(() {
      _comments[index] = original.copyWith(
        isLiked: !original.isLiked,
        likeCount: original.isLiked
            ? original.likeCount - 1
            : original.likeCount + 1,
      );
    });

    try {
      if (original.isLiked) {
        await _apiClient.unlikeComment(widget.postId, comment.id);
      } else {
        await _apiClient.likeComment(widget.postId, comment.id);
      }
    } catch (e) {
      // 롤백
      setState(() {
        _comments[index] = original;
      });
    }
  }

  /// 댓글 삭제
  Future<void> _deleteComment(Comment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteComment),
        content: Text(l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.mlColors.dangerColor,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.deleteComment(widget.postId, comment.id);
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
        _post = _post!.copyWith(commentCount: _post!.commentCount - 1);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.commentDeleted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 댓글 수정
  Future<void> _editComment(Comment comment) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: comment.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editComment),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.commentPlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: Text(l10n.edit),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result == comment.content) return;

    try {
      final updated = await _apiClient.updateComment(
        widget.postId,
        comment.id,
        content: result,
      );
      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = updated;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.commentUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 신고 사유 선택 다이얼로그
  Future<Map<String, String>?> _showReportDialog() async {
    final l10n = AppLocalizations.of(context);
    String? selectedType;
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final reportTypes = {
              'abuse': l10n.reportAbuse,
              'spam': l10n.reportSpam,
              'inappropriate': l10n.reportInappropriate,
              'harassment': l10n.reportHarassment,
              'other': l10n.reportOther,
            };

            return AlertDialog(
              title: Text(l10n.reportTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reportTypes.entries.map(
                      (entry) => RadioListTile<String>(
                        title: Text(entry.value),
                        value: entry.key,
                        groupValue: selectedType,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (selectedType == 'other') ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.reportDescription,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: selectedType != null
                      ? () {
                          Navigator.pop(context, {
                            'reportType': selectedType!,
                            'description': descriptionController.text.trim(),
                          });
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: context.mlColors.reportColor,
                  ),
                  child: Text(l10n.reportSubmit),
                ),
              ],
            );
          },
        );
      },
    );
    descriptionController.dispose();
    return result;
  }

  /// 게시글 신고
  Future<void> _reportPost() async {
    final result = await _showReportDialog();
    if (result == null) return;

    try {
      await _apiClient.reportPost(
        widget.postId,
        reportType: result['reportType']!,
        description: result['description'] ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).reportSubmitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 댓글 신고
  Future<void> _reportComment(Comment comment) async {
    final result = await _showReportDialog();
    if (result == null) return;

    try {
      await _apiClient.reportComment(
        widget.postId,
        comment.id,
        reportType: result['reportType']!,
        description: result['description'] ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).reportSubmitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// Ticker 배지 색상 (PostCard와 동일)
  Color _getTickerColor(String ticker) => BadgeColors.tickerBadge(ticker);

  /// 시간 표시 형식
  String _formatTimeAgo(DateTime dateTime) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    } else if (difference.inHours < 1) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).postDetail),
        actions: [
          if (_post != null)
            Builder(
              builder: (context) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final isOwnPost =
                    authProvider.currentUser?.id == _post!.author.id;
                final canReport = authProvider.isLoggedIn && !isOwnPost;
                final showMenu =
                    _post!.canEdit || _post!.canDelete || canReport;
                if (!showMenu) return const SizedBox.shrink();
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPost();
                    } else if (value == 'delete') {
                      _deletePost();
                    } else if (value == 'report') {
                      _reportPost();
                    }
                  },
                  itemBuilder: (context) => [
                    if (_post!.canEdit)
                      PopupMenuItem(
                        value: 'edit',
                        height: 24,
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.xl,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: AppSpacing.md),
                            Text(AppLocalizations.of(context).edit),
                          ],
                        ),
                      ),
                    if (_post!.canDelete)
                      PopupMenuItem(
                        value: 'delete',
                        height: 24,
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.xl,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: context.mlColors.dangerColor,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppLocalizations.of(context).delete,
                              style: TextStyle(
                                color: context.mlColors.dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (canReport)
                      PopupMenuItem(
                        value: 'report',
                        height: 24,
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.xl,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 20,
                              color: context.mlColors.reportColor,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              AppLocalizations.of(context).report,
                              style: TextStyle(
                                color: context.mlColors.reportColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _post == null
          ? _buildErrorView()
          : Column(
              children: [
                // 게시글 + 댓글 영역 (스크롤 가능)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPostAndComments,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPostHeader(),
                          _buildPostContent(),
                          _buildPostActions(),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: BannerAdWidget(),
                          ),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 댓글 입력란 (하단 고정)
                _buildCommentInput(),
              ],
            ),
    );
  }

  /// 에러 화면
  Widget _buildErrorView() {
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
            _errorMessage ?? AppLocalizations.of(context).cannotLoadPosts,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: _loadPostAndComments,
            child: Text(AppLocalizations.of(context).tryAgain),
          ),
        ],
      ),
    );
  }

  /// 게시글 헤더 (Ticker 배지 + 제목 + 작성자 + 시간)
  Widget _buildPostHeader() {
    final ticker = _post!.ticker;
    final displayTicker = ticker.isEmpty
        ? AppLocalizations.of(context).freePost
        : ticker;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _getTickerColor(ticker),
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                displayTicker,
                style: TextStyle(
                  color: context.mlColors.onPrimary,
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _post!.title,
              style: AppTypography.screenTitle.copyWith(
                color: context.mlColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  _post!.author.nickname,
                  style: AppTypography.bodyStrong.copyWith(
                    color: context.mlColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatTimeAgo(_post!.createdAt),
                  style: AppTypography.label.copyWith(
                    color: context.mlColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 게시글 본문
  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: BentoCard(
        child: SizedBox(
          width: double.infinity,
          child: Text(
            _post!.content,
            style: AppTypography.body.copyWith(
              color: context.mlColors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }

  /// 게시글 액션 (좋아요/댓글 버튼)
  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: BentoCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _post!.isLiked ? Icons.favorite : Icons.favorite_border,
                color: _post!.isLiked
                    ? context.mlColors.dangerColor
                    : context.mlColors.textTertiary,
              ),
              onPressed: _toggleLike,
            ),
            Text(
              '${_post!.likeCount}',
              style: AppTypography.bodyStrong.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Icon(Icons.comment_outlined, color: context.mlColors.textTertiary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${_post!.commentCount}',
              style: AppTypography.bodyStrong.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 댓글 섹션
  Widget _buildCommentsSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 비회원: 댓글 차단 + 회원가입 유도 UI
        if (!authProvider.isLoggedIn) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: AppLocalizations.of(
                    context,
                  ).commentsCount(_post?.commentCount ?? 0),
                ),
                const SizedBox(height: AppSpacing.md),
                BentoCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 44,
                        color: context.mlColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppLocalizations.of(context).loginToViewComments,
                        style: AppTypography.sectionTitle.copyWith(
                          color: context.mlColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppLocalizations.of(context).loginPromptComments,
                        style: AppTypography.body.copyWith(
                          color: context.mlColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                appPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context).login),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                appPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context).signup),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 로그인 사용자: 정상 댓글 표시
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: AppLocalizations.of(
                  context,
                ).commentsCount(_comments.length),
              ),
              const SizedBox(height: AppSpacing.md),

              // 댓글 목록
              if (_comments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: Text(
                      AppLocalizations.of(context).writeFirstComment,
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                )
              else
                ..._buildCommentsWithAds(),

              // 댓글 추가 로딩 인디케이터
              if (_isLoadingMoreComments || _hasNextComments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 댓글 목록에 10개마다 배너 광고 삽입
  List<Widget> _buildCommentsWithAds() {
    final widgets = <Widget>[];
    for (var i = 0; i < _comments.length; i++) {
      final comment = _comments[i];
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isOwnComment = authProvider.currentUser?.id == comment.author.id;
      final canReportComment = authProvider.isLoggedIn && !isOwnComment;
      widgets.add(
        CommentCard(
          comment: comment,
          onEdit: comment.canEdit ? () => _editComment(comment) : null,
          onDelete: comment.canDelete ? () => _deleteComment(comment) : null,
          onReport: canReportComment ? () => _reportComment(comment) : null,
          onLike: () => _toggleCommentLike(comment),
        ),
      );
      // 10개마다 광고 삽입 (마지막 댓글 뒤에는 미삽입)
      if ((i + 1) % 10 == 0 && i + 1 < _comments.length) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: BannerAdWidget(),
          ),
        );
      }
    }
    return widgets;
  }

  /// 댓글 입력란 (하단 고정, SafeArea 적용)
  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.mlColors.cardBackground,
          border: Border(top: BorderSide(color: context.mlColors.subtleBorder)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // 입력 필드
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).commentHint,
                  filled: true,
                  fillColor: context.mlColors.sectionBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    borderSide: BorderSide(
                      color: context.mlColors.subtleBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    borderSide: BorderSide(
                      color: context.mlColors.subtleBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    borderSide: BorderSide(color: context.mlColors.accentBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: 1,
                enabled: !_isSubmittingComment,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // 전송 버튼
            IconButton(
              icon: _isSubmittingComment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: AppStroke.medium,
                      ),
                    )
                  : Icon(Icons.send, color: context.mlColors.accentBlue),
              onPressed: _isSubmittingComment ? null : _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}
