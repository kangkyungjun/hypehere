import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/feature_flags.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../watchlist/widgets/portfolio_summary_card.dart';
import '../../models/community/post.dart';
import '../../models/community/comment.dart';
import '../../services/community_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/community/post_card.dart';
import '../community/post_detail_screen.dart';
import '../community/my_posts_screen.dart';
import '../community/my_comments_screen.dart';
import '../community/create_post_screen.dart';
import 'profile_edit_screen.dart';
import '../settings/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/common/bento_card.dart';
import '../../widgets/common/section_header.dart';
import '../../l10n/app_localizations.dart';

/// 사용자 프로필 화면
///
/// - 사용자 정보 표시 (닉네임, 이메일, 가입일)
/// - 내 게시글 미리보기 (최근 5개)
/// - 내 댓글 미리보기 (최근 5개)
/// - 프로필 편집, 로그아웃 버튼
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();

  /// 내 게시글 목록 (최근 5개)
  List<Post>? _myPosts;

  /// 내 댓글 목록 (최근 5개)
  List<Comment>? _myComments;

  /// 총 개수 (서버 count)
  int _myPostsCount = 0;
  int _myCommentsCount = 0;

  /// 로딩 상태
  bool _isLoadingPosts = false;
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _loadMyActivity();
  }

  /// 내 활동 내역 로드
  Future<void> _loadMyActivity() async {
    // [COMMUNITY_FLAG] 커뮤니티 비활성화 시 내 게시글/댓글 로드 자체를 건너뜀.
    if (!FeatureFlags.kCommunityEnabled) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingComments = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingPosts = true;
      _isLoadingComments = true;
    });

    // 내 게시글 로드
    try {
      final result = await _apiClient.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = result.items;
          _myPostsCount = result.count;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Failed to load my posts: $e');
      if (mounted) {
        setState(() {
          _myPosts = [];
          _myPostsCount = 0;
          _isLoadingPosts = false;
        });
      }
    }

    // 내 댓글 로드
    try {
      final result = await _apiClient.getMyComments();
      if (mounted) {
        setState(() {
          _myComments = result.items;
          _myCommentsCount = result.count;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Failed to load my comments: $e');
      if (mounted) {
        setState(() {
          _myComments = [];
          _myCommentsCount = 0;
          _isLoadingComments = false;
        });
      }
    }
  }

  /// 게시글 수정 (PostCard ⋮ 메뉴)
  Future<void> _editPost(Post post) async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(builder: (_) => CreatePostScreen(editPost: post)),
    );

    if (result == true) {
      _loadMyActivity();
    }
  }

  /// 게시글 삭제 (PostCard ⋮ 메뉴)
  Future<void> _deletePost(Post post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _apiClient.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
        _loadMyActivity();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.postDeleteFailed(ErrorLocalizer.getMessage(context, e)),
            ),
          ),
        );
      }
    }
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.logoutConfirmTitle),
          content: Text(l10n.logoutConfirmMessage),
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
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await authProvider.logout();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.logout)));
        Navigator.of(context).pop(); // 프로필 화면 닫기
      }
    }
  }

  /// 날짜 포맷팅 (로케일 기반)
  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final l10n = AppLocalizations.of(context);
          // 로그인 상태 확인
          if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.loginPromptMessage,
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      appPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Text(l10n.login),
                  ),
                ],
              ),
            );
          }

          final user = authProvider.currentUser!;

          return RefreshIndicator(
            onRefresh: _loadMyActivity,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                // 사용자 정보 카드
                _buildUserInfoCard(user),

                const SizedBox(height: AppSpacing.xxl),

                // 투자 수익률 (보유종목 요약과 동일 디자인)
                _buildInvestmentReturnSection(),

                const SizedBox(height: AppSpacing.xxl),

                // 내 게시글 / 내 댓글 섹션
                // [COMMUNITY_FLAG] 커뮤니티 비활성화 시 숨김.
                // 복원: FeatureFlags.kCommunityEnabled = true 로 변경.
                if (FeatureFlags.kCommunityEnabled) ...[
                  // 내 게시글 섹션
                  _buildMyPostsSection(),

                  const SizedBox(height: AppSpacing.xxl),

                  // 내 댓글 섹션
                  _buildMyCommentsSection(),

                  const SizedBox(height: AppSpacing.xxl),
                ],

                // 비밀번호 변경
                _buildChangePasswordTile(),

                const SizedBox(height: AppSpacing.xxl),

                // 로그아웃 / 회원탈퇴
                _buildBottomActions(),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 투자 수익률 섹션 — 보유종목 요약(PortfolioSummaryCard)을 동일 디자인으로 재사용.
  /// 보유 종목이 없으면 안내 문구 카드를 표시.
  Widget _buildInvestmentReturnSection() {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, _) {
        if (portfolio.holdings.isEmpty) {
          return BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.investmentReturn,
                  style: AppTypography.cardTitle.copyWith(
                    color: mlc.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 32,
                        color: mlc.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.noHoldingsYet,
                        style: AppTypography.body.copyWith(
                          color: mlc.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.addFirstHolding,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: mlc.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return PortfolioSummaryCard(
          portfolio: portfolio,
          title: l10n.investmentReturn,
          outerPadding: EdgeInsets.zero,
        );
      },
    );
  }

  /// 사용자 정보 섹션
  Widget _buildUserInfoCard(user) {
    final l10n = AppLocalizations.of(context);
    return BentoCard(
      child: Column(
        children: [
          // 편집 버튼 (우상단)
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  appPageRoute(builder: (_) => ProfileEditScreen(user: user)),
                );
                if (result == true && mounted) {
                  _loadMyActivity();
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: context.mlColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.edit,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: context.mlColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 아바타 + 정보 (가로 배치)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아바타
              CircleAvatar(
                radius: 40,
                backgroundColor: context.mlColors.accentBlue,
                child: Text(
                  user.nickname.isNotEmpty
                      ? user.nickname[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: AppTypography.heroMedium,
                    fontWeight: AppTypography.bold,
                    color: context.mlColors.onPrimary,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.xl),

              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname,
                      style: AppTypography.screenTitle.copyWith(
                        color: context.mlColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        color: context.mlColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.joinDate(_formatDate(user.createdAt)),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: context.mlColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 내 게시글 섹션
  Widget _buildMyPostsSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _myPosts != null
              ? '${l10n.myPosts} (${_formatCount(_myPostsCount)})'
              : l10n.myPosts,
          padding: EdgeInsets.zero,
          trailing: _myPosts != null && _myPosts!.isNotEmpty
              ? Text(
                  l10n.viewAll,
                  style: TextStyle(
                    color: context.mlColors.accentBlue,
                    fontWeight: AppTypography.semiBold,
                  ),
                )
              : null,
          onTrailingTap: _myPosts != null && _myPosts!.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    appPageRoute(builder: (_) => const MyPostsScreen()),
                  );
                }
              : null,
        ),

        const SizedBox(height: AppSpacing.lg),

        // 게시글 목록
        if (_isLoadingPosts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_myPosts == null || _myPosts!.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: context.mlColors.accentBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      size: 32,
                      color: context.mlColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.startWithFirstPost,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.semiBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.writeAPost,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._myPosts!.take(3).map((post) {
            return PostCard(
              post: post,
              onTap: () {
                Navigator.push(
                  context,
                  appPageRoute(
                    builder: (_) => PostDetailScreen(postId: post.id),
                  ),
                );
              },
              onEdit: post.canEdit ? () => _editPost(post) : null,
              onDelete: post.canDelete ? () => _deletePost(post) : null,
            );
          }),
      ],
    );
  }

  /// 내 댓글 섹션
  Widget _buildMyCommentsSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _myComments != null
              ? '${l10n.myComments} (${_formatCount(_myCommentsCount)})'
              : l10n.myComments,
          padding: EdgeInsets.zero,
          trailing: _myComments != null && _myComments!.isNotEmpty
              ? Text(
                  l10n.viewAll,
                  style: TextStyle(
                    color: context.mlColors.accentBlue,
                    fontWeight: AppTypography.semiBold,
                  ),
                )
              : null,
          onTrailingTap: _myComments != null && _myComments!.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    appPageRoute(builder: (_) => const MyCommentsScreen()),
                  );
                }
              : null,
        ),

        const SizedBox(height: AppSpacing.lg),

        // 댓글 목록
        if (_isLoadingComments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_myComments == null || _myComments!.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: context.mlColors.accentBlue.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.comment_outlined,
                      size: 32,
                      color: context.mlColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.writeFirstComment,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.semiBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.noComments,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _myComments!.take(3).map((comment) {
                return ListTile(
                  leading: const Icon(Icons.comment),
                  title: Text(
                    comment.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatDate(comment.createdAt),
                    style: const TextStyle(fontSize: AppTypography.bodySmall),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      appPageRoute(
                        builder: (_) =>
                            PostDetailScreen(postId: comment.postId),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// 개수 포맷 (100개 이상이면 +99)
  String _formatCount(int count) => count > 99 ? '+99' : '$count';

  /// 비밀번호 변경 타일
  Widget _buildChangePasswordTile() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: BentoCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.mlColors.infoBg,
            child: Icon(
              Icons.lock_reset_rounded,
              color: context.mlColors.accentBlue,
            ),
          ),
          title: Text(l10n.changePassword),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              appPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          },
        ),
      ),
    );
  }

  /// 로그아웃 + 회원탈퇴 (하단 액션)
  Widget _buildBottomActions() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleLogout,
            child: Text(
              l10n.logout,
              style: TextStyle(
                color: context.mlColors.dangerColor,
                fontSize: AppTypography.bodyLarge,
                decoration: TextDecoration.underline,
                decorationColor: context.mlColors.dangerColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxxl),
          GestureDetector(
            onTap: _handleDeleteAccount,
            child: Text(
              l10n.deleteAccount,
              style: TextStyle(
                color: context.mlColors.textSecondary,
                fontSize: AppTypography.bodyLarge,
                decoration: TextDecoration.underline,
                decorationColor: context.mlColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 회원탈퇴 처리
  Future<void> _handleDeleteAccount() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context);

    // 1단계: 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteAccount),
          content: Text(l10n.withdrawAccountConfirm),
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
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // 2단계: 사유 입력 다이얼로그
    final reasonController = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteAccount),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.withdrawAccountReasonHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, reasonController.text),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    // null이면 다이얼로그가 뒤로가기로 닫힌 것 → 취소
    if (reason == null) return;

    // 3단계: 탈퇴 요청
    try {
      await authProvider.deleteAccount(
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.withdrawAccountSuccess)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.withdrawAccountFailed)));
      }
    }
  }
}
