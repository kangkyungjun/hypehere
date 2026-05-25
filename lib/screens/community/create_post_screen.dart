import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/community/post.dart';
import '../../models/ticker_info.dart';
import '../../services/analytics_api_client.dart';
import '../../services/community_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// 새 게시글 작성 / 수정 화면
///
/// - 티커 검색 기반 Picker + 자유 게시글 지원
/// - prefilledTicker가 있으면 Ticker 필드 잠금 (데이터 무결성)
/// - editPost가 있으면 수정 모드 (기존 데이터 프리필)
/// - 작성/수정 성공 시 pop(true) 반환하여 목록 새로고침 유도
class CreatePostScreen extends StatefulWidget {
  /// 미리 채워질 Ticker (종목 전용 게시판에서 넘어올 때)
  ///
  /// null이 아니면 Ticker가 잠금 상태로 수정 불가
  final String? prefilledTicker;

  /// 수정할 게시글 (null이면 새 작성, 있으면 수정 모드)
  final Post? editPost;

  const CreatePostScreen({super.key, this.prefilledTicker, this.editPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();
  final AnalyticsApiClient _analyticsApi = AnalyticsApiClient();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final TextEditingController _searchController = TextEditingController();

  /// 수정 모드 여부
  late final bool _isEditMode;

  /// Ticker 필드 잠금 여부
  late final bool _isTickerLocked;

  /// 선택된 티커 (null이면 자유 게시글)
  TickerInfo? _selectedTicker;

  /// 검색 결과 목록
  List<TickerInfo> _searchResults = [];

  /// 검색 중 로딩 상태
  bool _isSearching = false;

  /// 검색 필드 활성 상태
  bool _showSearchResults = false;

  /// 제출 중 상태
  bool _isSubmitting = false;

  /// 디바운스 타이머
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editPost != null;
    _isTickerLocked = widget.prefilledTicker != null;

    if (_isEditMode) {
      final post = widget.editPost!;
      _titleController = TextEditingController(text: post.title);
      _contentController = TextEditingController(text: post.content);
      if (post.ticker.isNotEmpty) {
        _selectedTicker = TickerInfo(ticker: post.ticker);
      }
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      if (widget.prefilledTicker != null) {
        _selectedTicker = TickerInfo(ticker: widget.prefilledTicker!);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 티커 검색 (300ms 디바운스)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _analyticsApi.searchTickers(query.trim());
        if (mounted && _searchController.text.trim() == query.trim()) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  /// 검색 결과에서 티커 선택
  void _selectTicker(TickerInfo ticker) {
    setState(() {
      _selectedTicker = ticker;
      _searchResults = [];
      _showSearchResults = false;
      _searchController.clear();
    });
    // 키보드 닫기
    FocusScope.of(context).unfocus();
  }

  /// 선택된 티커 해제
  void _clearTicker() {
    setState(() {
      _selectedTicker = null;
    });
  }

  /// 게시글 작성/수정 제출
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ticker = _selectedTicker?.ticker ?? '';
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (_isEditMode) {
        await _apiClient.updatePost(
          widget.editPost!.id,
          title: title,
          content: content,
          ticker: ticker,
        );
      } else {
        await _apiClient.createPost(
          title: title,
          content: content,
          ticker: ticker,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? l10n.postUpdated : l10n.postCreated),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editPostTitle : l10n.newPost),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              l10n.done,
              style: const TextStyle(
                fontSize: AppTypography.headlineMedium,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showSearchResults = false);
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              _buildTickerField(),
              const SizedBox(height: AppSpacing.xl),
              _buildTitleField(),
              const SizedBox(height: AppSpacing.xl),
              _buildContentField(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 티커 선택 필드 (검색 기반 Picker)
  Widget _buildTickerField() {
    // prefilledTicker 잠금 상태
    if (_isTickerLocked) {
      return _buildLockedTicker();
    }

    // 선택된 티커가 있으면 Chip 표시
    if (_selectedTicker != null) {
      return _buildSelectedTicker();
    }

    // 검색 입력 필드
    return _buildTickerSearch();
  }

  /// 잠금 상태 티커 표시 (종목 전용 게시판)
  Widget _buildLockedTicker() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.mlColors.chartGridLine,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.mlColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.mlColors.accentBlue,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              widget.prefilledTicker!,
              style: TextStyle(
                color: context.mlColors.onPrimary,
                fontSize: AppTypography.bodyLarge,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            l10n.tickerOnlyBoard,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.lock,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  /// 선택 완료된 티커 Chip 표시
  Widget _buildSelectedTicker() {
    final l10n = AppLocalizations.of(context);
    final ticker = _selectedTicker!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectTicker,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: AppTypography.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.mlColors.sectionBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.mlColors.subtleBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.mlColors.accentBlue,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  ticker.ticker,
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  _tickerSubtitle(ticker),
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _clearTicker,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.mlColors.subtleBorder,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: context.mlColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 티커 검색 입력 필드 + 결과 리스트
  Widget _buildTickerSearch() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onTap: () {
            if (_searchController.text.trim().isNotEmpty) {
              setState(() => _showSearchResults = true);
            }
          },
          decoration: InputDecoration(
            labelText: l10n.tickerSearchLabel,
            hintText: l10n.tickerSearchHintCreate,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: AppStroke.medium,
                      ),
                    ),
                  )
                : (_searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: l10n.tooltipClearSearch,
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null),
            filled: true,
            fillColor: context.mlColors.sectionBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
        // 안내 문구
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            left: AppSpacing.xs,
          ),
          child: Text(
            l10n.tickerNotSelectedHint,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        // 검색 결과 리스트
        if (_showSearchResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: context.mlColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.mlColors.subtleBorder.withValues(alpha: 0.68),
                width: 0.8,
              ),
              boxShadow: AppShadow.sm(context.mlColors.overlayDim),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: context.mlColors.chartGridLine.withValues(alpha: 0.72),
              ),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return _buildSearchResultItem(item);
              },
            ),
          ),
        // 검색 중 + 결과 없음
        if (_showSearchResults &&
            !_isSearching &&
            _searchResults.isEmpty &&
            _searchController.text.trim().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: context.mlColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: context.mlColors.subtleBorder.withValues(alpha: 0.68),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                l10n.noTickerSearchResults,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 검색 결과 항목 위젯
  Widget _buildSearchResultItem(TickerInfo item) {
    return InkWell(
      onTap: () => _selectTicker(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            // 티커 심볼
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.mlColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                item.ticker,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: AppTypography.bold,
                  color: context.mlColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 이름 + 카테고리
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tickerSubtitle(item),
                    style: const TextStyle(fontSize: AppTypography.bodyMedium),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 카테고리 태그
            if (item.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: context.mlColors.chartGridLine,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  item.category!,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 티커 부가 텍스트 (name / nameKo)
  String _tickerSubtitle(TickerInfo ticker) {
    if (ticker.name == null) return '';
    if (ticker.nameKo != null) {
      return '${ticker.name!} / ${ticker.nameKo!}';
    }
    return ticker.name!;
  }

  /// 제목 입력 필드
  Widget _buildTitleField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: l10n.postTitle,
        hintText: l10n.postTitleHint,
        filled: true,
        fillColor: context.mlColors.sectionBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        counterText: '',
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.postTitleRequired;
        }
        if (value.trim().length < 2) {
          return l10n.postTitleTooShort;
        }
        return null;
      },
    );
  }

  /// 내용 입력 필드
  Widget _buildContentField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _contentController,
      decoration: InputDecoration(
        labelText: l10n.postContent,
        hintText: l10n.postContentHint,
        filled: true,
        fillColor: context.mlColors.sectionBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignLabelWithHint: true,
      ),
      maxLines: 10,
      minLines: 5,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.postContentRequired;
        }
        if (value.trim().length < 5) {
          return l10n.postContentTooShort;
        }
        return null;
      },
    );
  }

  /// 게시하기 버튼
  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context);
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitPost,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: context.mlColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: _isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: AppStroke.medium,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.mlColors.onPrimary,
                ),
              ),
            )
          : Text(
              _isEditMode ? l10n.updatePostButton : l10n.submitPost,
              style: const TextStyle(
                fontSize: AppTypography.headlineMedium,
                fontWeight: AppTypography.bold,
              ),
            ),
    );
  }
}
