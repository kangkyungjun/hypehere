import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/badge_colors.dart';
/// 관리자 패널 화면 (Manager/Master 전용)
///
/// 기능:
/// - 진입 시 자동으로 사용자 목록 로드 (무한스크롤)
/// - 사용자 검색 (이메일 또는 닉네임) — 필터 역할
/// - Gold로 승급 (Manager+)
/// - Manager로 승급 (Master만)
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 감지 — 하단 200px 접근 시 다음 페이지 로드
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  /// 첫 페이지 로드 (검색어 변경 시 리셋)
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _users = [];
      _hasNext = false;
      _totalCount = 0;
    });

    try {
      final query = _searchController.text.trim();
      final result = await _apiClient.getUsers(
        query: query.isNotEmpty ? query : null,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _totalCount = result.count;
        _hasNext = result.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// 다음 페이지 추가 로드
  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasNext) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final query = _searchController.text.trim();
      final result = await _apiClient.getUsers(
        query: query.isNotEmpty ? query : null,
        page: _currentPage + 1,
      );
      if (!mounted) return;
      setState(() {
        _currentPage++;
        _users.addAll(result.items);
        _totalCount = result.count;
        _hasNext = result.hasNext;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Gold로 승급
  Future<void> _promoteToGold(int userId, String nickname) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.promoteToGold),
        content: Text('$nickname → ${l10n.roleGold}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.mlColors.roleGoldColor,
            ),
            child: Text(l10n.confirm, style: TextStyle(color: context.mlColors.onPrimary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.promoteToGold(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nickname → ${l10n.roleGold}')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorLocalizer.getMessage(context, e)),
            backgroundColor: context.mlColors.dangerColor,
          ),
        );
      }
    }
  }

  /// Manager로 승급
  Future<void> _promoteToManager(int userId, String nickname) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.promoteToManager),
        content: Text('$nickname → ${l10n.roleManager}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.mlColors.roleManagerColor,
            ),
            child: Text(l10n.confirm, style: TextStyle(color: context.mlColors.onPrimary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.promoteToManager(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nickname → ${l10n.roleManager}')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorLocalizer.getMessage(context, e)),
            backgroundColor: context.mlColors.dangerColor,
          ),
        );
      }
    }
  }

  /// Regular로 강등
  Future<void> _demoteToRegular(int userId, String nickname, String currentRole) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.demoteToRegular),
        content: Text('$nickname → ${l10n.roleRegular}?\n\n${currentRole.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.mlColors.dangerColor,
            ),
            child: Text(l10n.confirm, style: TextStyle(color: context.mlColors.onPrimary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.demoteToRegular(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nickname → ${l10n.roleRegular}')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorLocalizer.getMessage(context, e)),
            backgroundColor: context.mlColors.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPanel),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 권한 체크
          if (!authProvider.isManagerOrAbove) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.errManagerRequired,
                    style: TextStyle(fontSize: AppTypography.headlineLarge, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.errManagerRequired,
                    style: TextStyle(fontSize: AppTypography.bodyLarge, color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 상단 고정 영역 (권한 카드 + 검색)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 권한 정보 카드
                    Card(
                      color: context.mlColors.warningBg,
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Row(
                          children: [
                            Icon(
                              authProvider.isMaster ? Icons.admin_panel_settings : Icons.manage_accounts,
                              color: authProvider.isMaster ? context.mlColors.dangerColor : context.mlColors.warningColor,
                              size: 32,
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.roleDisplayName,
                                    style: const TextStyle(
                                      fontSize: AppTypography.headlineLarge,
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    authProvider.isMaster
                                        ? '${l10n.promoteToGold} + ${l10n.promoteToManager} / ${l10n.demoteToRegular}'
                                        : '${l10n.promoteToGold} / ${l10n.demoteToRegular}',
                                    style: TextStyle(
                                      fontSize: AppTypography.bodyLarge,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 사용자 검색
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: l10n.tooltipClearSearch,
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        _loadUsers();
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _loadUsers(),
                            onChanged: (value) {
                              setState(() {}); // suffixIcon 토글용
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.mlColors.accentBlue,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: AppStroke.medium,
                                    color: context.mlColors.onPrimary,
                                  ),
                                )
                              : Text(l10n.tabSearch, style: TextStyle(color: context.mlColors.onPrimary)),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 카운트 표시
                    if (_totalCount > 0)
                      Text(
                        l10n.nItems(_totalCount),
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          fontWeight: AppTypography.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // 에러 메시지
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Card(
                    color: context.mlColors.dangerBg,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: context.mlColors.dangerColor),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: context.mlColors.dangerColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 사용자 목록 (무한스크롤)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? l10n.noSearchResults
                                  : l10n.noData,
                              style: TextStyle(fontSize: AppTypography.headlineMedium, color: Theme.of(context).colorScheme.outline),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                            itemCount: _users.length + (_hasNext ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _users.length) {
                                // 하단 로딩 인디케이터
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.xl),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildUserCard(_users[index], authProvider);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 사용자 카드 위젯
  Widget _buildUserCard(Map<String, dynamic> user, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context);
    final int userId = user['id'];
    final String email = user['email'];
    final String nickname = user['nickname'];
    final String role = user['role'] ?? 'regular';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.mlColors.accentBlue,
                  child: Text(
                    nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U',
                    style: TextStyle(color: context.mlColors.onPrimary, fontWeight: AppTypography.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              fontSize: AppTypography.headlineMedium,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _buildRoleBadge(role),
                          // IAP 결제 Gold vs 수동 승급 Gold 구분 표시
                          if (role == 'gold') ...[
                            const SizedBox(width: AppSpacing.xs),
                            _buildGoldTypeBadge(user['is_iap_gold'] == true),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        email,
                        style: TextStyle(fontSize: AppTypography.bodySmall, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // 승급 버튼
            Row(
              children: [
                // Gold 승급 버튼 (Manager+, regular 사용자만)
                if (authProvider.canPromoteToGold && role == 'regular')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _promoteToGold(userId, nickname),
                      icon: const Icon(Icons.workspace_premium),
                      label: Text(l10n.promoteToGold),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.mlColors.roleGoldColor,
                      ),
                    ),
                  ),

                if (authProvider.canPromoteToGold && authProvider.canPromoteToManager && role == 'regular')
                  const SizedBox(width: AppSpacing.md),

                // Manager 임명 버튼 (Master만, regular/gold 사용자만)
                if (authProvider.canPromoteToManager && (role == 'regular' || role == 'gold'))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _promoteToManager(userId, nickname),
                      icon: const Icon(Icons.manage_accounts),
                      label: Text(l10n.promoteToManager),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.mlColors.warningColor,
                        foregroundColor: context.mlColors.onPrimary,
                      ),
                    ),
                  ),

                // 이미 최고 권한인 경우
                if (role == 'master')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.roleMaster,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 강등 버튼 (Gold/Manager만 표시)
            if ((role == 'gold' && authProvider.canPromoteToGold) ||
                (role == 'manager' && authProvider.isMaster))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _demoteToRegular(userId, nickname, role),
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: Text(l10n.demoteToRegular),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.mlColors.dangerColor,
                      side: BorderSide(color: context.mlColors.dangerColor),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Gold 유형 배지 (IAP 결제 vs 수동 승급)
  Widget _buildGoldTypeBadge(bool isIapGold) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isIapGold ? Colors.blue.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isIapGold ? Colors.blue.shade300 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Text(
        isIapGold ? 'IAP' : 'Manual',
        style: TextStyle(
          color: isIapGold ? Colors.blue.shade700 : Colors.orange.shade700,
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }

  /// 역할 배지
  Widget _buildRoleBadge(String role) {
    final l10n = AppLocalizations.of(context);
    final badgeColor = BadgeColors.roleBadge(role, context.mlColors);
    String badgeText;

    switch (role) {
      case 'master':
        badgeText = l10n.roleMaster;
        break;
      case 'manager':
        badgeText = l10n.roleManager;
        break;
      case 'gold':
        badgeText = l10n.roleGold;
        break;
      case 'regular':
      default:
        badgeText = l10n.roleRegular;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: context.mlColors.onPrimary,
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}
