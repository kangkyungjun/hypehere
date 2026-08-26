// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community/post.dart';
import '../../models/ticker_info.dart';
import '../../services/community_api_client.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../utils/app_page_route.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// 커뮤니티 게시판 화면 (Context-Aware)
///
/// - initialTicker가 null이면: 전체 게시판 (모든 종목)
/// - initialTicker가 있으면: 종목 전용 게시판 (필터 ON)
class CommunityFeedScreen extends StatefulWidget {
  /// 초기 필터 종목 (null이면 전체)
  final String? initialTicker;

  const CommunityFeedScreen({super.key, this.initialTicker});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();
  final AnalyticsApiClient _analyticsApiClient = AnalyticsApiClient();
  final ScrollController _scrollController = ScrollController();

  /// 검색 관련
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  /// 현재 필터링 중인 종목 (null이면 전체)
  String? _currentTicker;

  /// 티커 필터 칩에 표시할 목록
  final List<String> _filterTickers = [
    'AAPL',
    'TSLA',
    'NVDA',
    'MSFT',
    'AMZN',
    'META',
    'GOOGL',
  ];

  /// 게시글 목록
  List<Post> _posts = [];

  /// 로딩 상태
  bool _isLoading = false;

  /// 추가 로딩 상태
  bool _isLoadingMore = false;

  /// 에러 메시지
  String? _errorMessage;

  /// 네트워크 에러 플래그 (연결 실패 등)
  bool _isNetworkError = false;

  /// 페이지네이션
  int _currentPage = 1;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _currentTicker = widget.initialTicker;
    // initialTicker가 있으면 필터 목록에 추가
    if (widget.initialTicker != null &&
        !_filterTickers.contains(widget.initialTicker)) {
      _filterTickers.insert(0, widget.initialTicker!);
    }
    _scrollController.addListener(_onScroll);
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _analyticsApiClient.dispose();
    super.dispose();
  }

  /// 스크롤 감지 — 하단 200px 접근 시 다음 페이지 로드
  void _onScroll() {
    if (_searchQuery.isNotEmpty) return; // 검색 모드에서는 페이지네이션 미적용
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  /// 검색어 변경 시 디바운스 처리
  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value.trim();
      });
      _loadPosts();
    });
  }

  /// 검색 클리어
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadPosts();
  }

  /// 게시글 목록 로드 (첫 페이지, 검색/필터 조건에 따라 분기)
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNetworkError = false;
      _currentPage = 1;
      _hasNext = false;
    });

    try {
      if (_searchQuery.isNotEmpty) {
        // 검색 모드 (페이지네이션 미적용)
        final posts = await _apiClient.searchPosts(
          _searchQuery,
          ticker: _currentTicker,
        );
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        // 일반 모드 (페이지네이션 적용)
        final result = await _apiClient.getPosts(
          ticker: _currentTicker,
          page: 1,
        );
        setState(() {
          _posts = result.items;
          _hasNext = result.hasNext;
          _isLoading = false;
        });
      }
    } on SocketException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _isNetworkError = true;
        _errorMessage = l10n.networkError;
      });
    } on TimeoutException {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _isNetworkError = true;
        _errorMessage = l10n.serverTimeout;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _errorMessage = _searchQuery.isNotEmpty
            ? l10n.searchResultsLoadFailed
            : l10n.postsLoadFailed;
      });
    }
  }

  /// 다음 페이지 추가 로드
  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasNext) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _apiClient.getPosts(
        ticker: _currentTicker,
        page: _currentPage + 1,
      );
      setState(() {
        _currentPage++;
        _posts.addAll(result.items);
        _hasNext = result.hasNext;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 티커 필터 선택
  void _selectTicker(String? ticker) {
    setState(() {
      _currentTicker = ticker;
    });
    _loadPosts();
  }

  /// 게시글 수정 (PostCard ⋮ 메뉴)
  Future<void> _editPost(Post post) async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(builder: (_) => CreatePostScreen(editPost: post)),
    );

    if (result == true) {
      _loadPosts();
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
      await _apiClient.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
        _loadPosts();
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

  /// 게시글 신고
  Future<void> _reportPost(Post post) async {
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

    if (result == null) return;

    try {
      await _apiClient.reportPost(
        post.id,
        reportType: result['reportType']!,
        description: result['description'] ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  /// 게시글 작성자 차단 — 차단 즉시 해당 사용자의 게시글을 목록에서 제거
  Future<void> _blockPostAuthor(Post post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUser),
        content: Text(l10n.blockUserConfirm(post.author.nickname)),
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
            child: Text(l10n.blockUser),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _apiClient.blockUser(post.author.id, postId: post.id);
      if (!mounted) return;
      final blockedId = post.author.id;
      setState(() {
        _posts.removeWhere((p) => p.author.id == blockedId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlocked)),
      );
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
      appPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    ).then((_) {
      _loadPosts();
    });
  }

  /// 글쓰기 버튼 클릭 처리
  Future<void> _onCreatePostPressed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
        if (success == true) _navigateToCreatePost();
      } else if (result == 'signup') {
        if (!mounted) return;
        final success = await Navigator.push<bool>(
          context,
          appPageRoute(builder: (_) => const SignupScreen()),
        );
        if (success == true) _navigateToCreatePost();
      }
      return;
    }

    _navigateToCreatePost();
  }

  /// 글쓰기 화면으로 이동
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      appPageRoute(
        builder: (_) => CreatePostScreen(prefilledTicker: _currentTicker),
      ),
    );

    if (result == true) {
      _loadPosts();
    }
  }

  /// 티커 검색 BottomSheet 표시
  void _showTickerSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _TickerSearchSheet(
        analyticsApiClient: _analyticsApiClient,
        defaultTickers: _filterTickers,
        onTickerSelected: (ticker) {
          Navigator.pop(context);
          // 선택한 티커를 필터 목록에 추가 (중복 방지)
          if (!_filterTickers.contains(ticker)) {
            setState(() {
              _filterTickers.add(ticker);
            });
          }
          _selectTicker(ticker);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTickerFilterChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePostPressed,
        tooltip: l10n.writePost,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  /// 검색바 위젯
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.communitySearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: l10n.tooltipClearSearch,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: context.mlColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.badge),
            borderSide: BorderSide(color: context.mlColors.subtleBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.badge),
            borderSide: BorderSide(color: context.mlColors.subtleBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.badge),
            borderSide: BorderSide(
              color: context.mlColors.accentBlue,
              width: 1,
            ),
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// 티커 필터 칩 위젯 (수평 스크롤)
  Widget _buildTickerFilterChips() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
        children: [
          // "전체" 칩
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: ChoiceChip(
              label: Text(l10n.all),
              selected: _currentTicker == null,
              onSelected: (_) => _selectTicker(null),
              selectedColor: context.mlColors.infoBg.withValues(alpha: 0.72),
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: _currentTicker == null
                    ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                    : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              labelStyle: AppTypography.label.copyWith(
                color: _currentTicker == null
                    ? context.mlColors.accentBlue
                    : context.mlColors.textSecondary,
              ),
            ),
          ),
          // 티커 칩들
          ..._filterTickers.map(
            (ticker) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: ChoiceChip(
                label: Text(ticker),
                selected: _currentTicker == ticker,
                onSelected: (_) => _selectTicker(ticker),
                selectedColor: context.mlColors.infoBg.withValues(alpha: 0.72),
                backgroundColor: Colors.transparent,
                side: BorderSide(
                  color: _currentTicker == ticker
                      ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                      : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                labelStyle: AppTypography.label.copyWith(
                  color: _currentTicker == ticker
                      ? context.mlColors.accentBlue
                      : context.mlColors.textSecondary,
                ),
              ),
            ),
          ),
          // ➕ 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: Text(l10n.add),
              onPressed: _showTickerSearchSheet,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: context.mlColors.subtleBorder.withValues(alpha: 0.58),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              labelStyle: AppTypography.label.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 본문 영역 (로딩/에러/빈 상태/게시글 목록)
  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    // 1) 로딩 중
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2) 네트워크 에러
    if (_isNetworkError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: context.mlColors.dangerColor),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _errorMessage ?? l10n.checkNetwork,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: _loadPosts,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    // 3) 서버 에러
    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        detail: l10n.tryAgainLater,
        onRetry: _loadPosts,
        retryLabel: l10n.refresh,
      );
    }

    // 4) 빈 게시글
    if (_posts.isEmpty) {
      final isFiltering = _searchQuery.isNotEmpty || _currentTicker != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltering ? Icons.search_off : Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              isFiltering ? l10n.noSearchResultsCommunity : l10n.noPostsYet,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: context.mlColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isFiltering ? l10n.tryDifferentFilter : l10n.writeFirstPost,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.mlColors.textSecondary,
              ),
            ),
            if (!isFiltering) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: _onCreatePostPressed,
                icon: const Icon(Icons.edit),
                label: Text(l10n.writePost),
              ),
            ],
          ],
        ),
      );
    }

    // 5) 게시글 목록 (10개마다 광고 배너 삽입 + 무한스크롤)
    final adCount = _posts.length ~/ 10;
    final totalItems = _posts.length + adCount + (_hasNext ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalItems,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          // 하단 로딩 인디케이터 (마지막 아이템)
          if (_hasNext && index == totalItems - 1) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final adsBefore = (index + 1) ~/ 11;
          final isAd =
              index > 0 && (index + 1) % 11 == 0 && adsBefore <= adCount;

          if (isAd) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: BannerAdWidget(),
            );
          }

          final postIndex = index - adsBefore;
          if (postIndex >= _posts.length || postIndex < 0) {
            return const SizedBox.shrink();
          }
          final post = _posts[postIndex];
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final isOwnPost = authProvider.currentUser?.id == post.author.id;
          final canReport = authProvider.isLoggedIn && !isOwnPost;
          final canBlock = authProvider.isLoggedIn && !isOwnPost;
          return PostCard(
            post: post,
            onTap: () => _navigateToPostDetail(post.id),
            onEdit: post.canEdit ? () => _editPost(post) : null,
            onDelete: post.canDelete ? () => _deletePost(post) : null,
            onReport: canReport ? () => _reportPost(post) : null,
            onBlock: canBlock ? () => _blockPostAuthor(post) : null,
          );
        },
      ),
    );
  }
}

/// 티커 검색 BottomSheet
class _TickerSearchSheet extends StatefulWidget {
  final AnalyticsApiClient analyticsApiClient;
  final List<String> defaultTickers;
  final ValueChanged<String> onTickerSelected;

  const _TickerSearchSheet({
    required this.analyticsApiClient,
    required this.defaultTickers,
    required this.onTickerSelected,
  });

  @override
  State<_TickerSearchSheet> createState() => _TickerSearchSheetState();
}

class _TickerSearchSheetState extends State<_TickerSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<TickerInfo>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await widget.analyticsApiClient.searchTickers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.mlColors.subtleBorder,
                borderRadius: BorderRadius.circular(AppRadius.xxs),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // 검색바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).tickerSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          tooltip: AppLocalizations.of(
                            context,
                          ).tooltipClearSearch,
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _searchResults = null;
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.mlColors.sectionBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 내용
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults != null
                  ? _buildSearchResults(scrollController)
                  : _buildPopularTickers(scrollController),
            ),
          ],
        );
      },
    );
  }

  /// 인기 티커 그리드
  Widget _buildPopularTickers(ScrollController scrollController) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        Text(
          l10n.popularTickers,
          style: AppTypography.cardTitle.copyWith(
            color: context.mlColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.defaultTickers.map((ticker) {
            return ActionChip(
              label: Text(ticker),
              onPressed: () => widget.onTickerSelected(ticker),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 검색 결과 리스트
  Widget _buildSearchResults(ScrollController scrollController) {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noSearchResultsCommunity,
          style: AppTypography.body.copyWith(
            color: context.mlColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: _searchResults!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ticker = _searchResults![index];
        return ListTile(
          title: Text(
            ticker.ticker,
            style: const TextStyle(fontWeight: AppTypography.semiBold),
          ),
          subtitle: Text(
            ticker.displayName != ticker.ticker
                ? '${ticker.displayName}${ticker.nameKo != null ? ' / ${ticker.nameKo}' : ''}'
                : '',
          ),
          trailing: ticker.category != null
              ? Text(
                  ticker.category!,
                  style: AppTypography.label.copyWith(
                    color: context.mlColors.textSecondary,
                  ),
                )
              : null,
          onTap: () => widget.onTickerSelected(ticker.ticker),
        );
      },
    );
  }
}
