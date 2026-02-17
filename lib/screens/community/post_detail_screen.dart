import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/community/post.dart';
import '../../models/community/comment.dart';
import '../../services/community_api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/community/comment_card.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// 게시글 상세 화면
///
/// - 단일 게시글 내용 + 댓글 목록 표시
/// - 좋아요/댓글 작성 기능 (비회원은 로그인 유도)
/// - 낙관적 UI 업데이트로 반응성 향상
class PostDetailScreen extends StatefulWidget {
  /// 조회할 게시글 ID
  final int postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

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

  @override
  void initState() {
    super.initState();
    _loadPostAndComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 게시글 + 댓글 로드
  Future<void> _loadPostAndComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await _apiClient.getPost(widget.postId);
      final comments = await _apiClient.getComments(widget.postId);

      setState(() {
        _post = post;
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '게시글을 불러올 수 없습니다: $e';
        _isLoading = false;
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
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );

        if (success == true) {
          // 로그인 성공 후 재시도
          _toggleLike();
        }
      } else if (result == 'signup') {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const SignupScreen(),
          ),
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
          SnackBar(content: Text('좋아요 처리 실패: $e')),
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
        const SnackBar(content: Text('댓글 내용을 입력해주세요')),
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
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );

        if (success == true) {
          // 로그인 성공 후 재시도
          _submitComment();
        }
      } else if (result == 'signup') {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const SignupScreen(),
          ),
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
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    }
  }

  /// Ticker 배지 색상 (PostCard와 동일)
  Color _getTickerColor(String ticker) {
    switch (ticker) {
      case 'TSLA':
        return const Color(0xFF1E88E5); // Blue
      case 'AAPL':
        return const Color(0xFF424242); // Gray
      case 'NVDA':
        return const Color(0xFF76B900); // Green
      default:
        return const Color(0xFF1E88E5);
    }
  }

  /// 시간 표시 형식
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
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
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPostHeader(),
                                _buildPostContent(),
                                _buildPostActions(),
                                const Divider(height: 2, thickness: 2),
                                _buildCommentsSection(),
                              ],
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '게시글을 불러올 수 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPostAndComments,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 게시글 헤더 (Ticker 배지 + 제목 + 작성자 + 시간)
  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticker 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTickerColor(_post!.ticker),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _post!.ticker,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 제목
          Text(
            _post!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // 작성자 + 시간
          Row(
            children: [
              Text(
                _post!.author.nickname,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(_post!.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 게시글 본문
  Widget _buildPostContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        _post!.content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    );
  }

  /// 게시글 액션 (좋아요/댓글 버튼)
  Widget _buildPostActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 좋아요 버튼
          IconButton(
            icon: Icon(
              _post!.isLiked ? Icons.favorite : Icons.favorite_border,
              color: _post!.isLiked ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleLike,
          ),
          Text(
            '${_post!.likeCount}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(width: 16),

          // 댓글 아이콘 (클릭 불가, 표시용)
          Icon(Icons.comment_outlined, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${_post!.commentCount}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 댓글 섹션
  Widget _buildCommentsSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 비회원: 댓글 차단 + 회원가입 유도 UI
        if (!authProvider.isLoggedIn) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 댓글 헤더
                Text(
                  '댓글 ${_post?.commentCount ?? 0}개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 회원가입 유도 카드
                Card(
                  color: const Color(0xFFF5F5F5),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '댓글을 보려면 로그인이 필요해요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '다른 투자자들의 의견을 확인하고\n나만의 분석을 공유해보세요!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text('로그인'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                              ),
                              child: const Text(
                                '회원가입',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 로그인 사용자: 정상 댓글 표시
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 댓글 헤더
              Text(
                '댓글 ${_comments.length}개',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // 댓글 목록
              if (_comments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      '첫 번째 댓글을 남겨보세요!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_comments.length, (index) {
                  final comment = _comments[index];
                  return CommentCard(comment: comment);
                }),
            ],
          ),
        );
      },
    );
  }

  /// 댓글 입력란 (하단 고정, SafeArea 적용)
  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 입력 필드
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 1,
                enabled: !_isSubmittingComment,
              ),
            ),

            const SizedBox(width: 8),

            // 전송 버튼
            IconButton(
              icon: _isSubmittingComment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
              onPressed: _isSubmittingComment ? null : _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}
