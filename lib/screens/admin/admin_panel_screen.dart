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

/// 관리자 패널 (Manager/Master 전용).
///
/// - 20명/페이지 번호형 페이저 (무한스크롤 X)
/// - 상단 권한별 카운트 카드 (Master/Manager/Gold/Regular)
/// - 권한 필터 칩 + 검색
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const int _pageSize = 20;

  final CommunityApiClient _apiClient = CommunityApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;
  int _totalCount = 0;
  String? _roleFilter; // null = 전체

  Map<String, int> _stats = const {
    'total': 0,
    'master': 0,
    'manager': 0,
    'gold': 0,
    'regular': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiClient.getUserStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      // 통계는 보조 정보 — 실패해도 본문 로드 진행
    }
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
    });
    try {
      final query = _searchController.text.trim();
      final result = await _apiClient.getUsers(
        query: query.isNotEmpty ? query : null,
        role: _roleFilter,
        page: page,
        size: _pageSize,
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

  Future<void> _onSearchSubmitted() => _loadUsers(page: 1);

  void _selectRole(String? role) {
    setState(() => _roleFilter = role);
    _loadUsers(page: 1);
  }

  int get _totalPages {
    if (_totalCount == 0) return 1;
    return ((_totalCount - 1) ~/ _pageSize) + 1;
  }

  Future<void> _promoteToGold(int userId, String nickname) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: l10n.promoteToGold,
      content: '$nickname → ${l10n.roleGold}?',
      color: context.mlColors.roleGoldColor,
    );
    if (confirmed != true) return;
    try {
      await _apiClient.promoteToGold(userId);
      _afterRoleChange('$nickname → ${l10n.roleGold}');
    } catch (e) {
      _snackError(e);
    }
  }

  Future<void> _promoteToManager(int userId, String nickname) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: l10n.promoteToManager,
      content: '$nickname → ${l10n.roleManager}?',
      color: context.mlColors.roleManagerColor,
    );
    if (confirmed != true) return;
    try {
      await _apiClient.promoteToManager(userId);
      _afterRoleChange('$nickname → ${l10n.roleManager}');
    } catch (e) {
      _snackError(e);
    }
  }

  Future<void> _demoteToRegular(
      int userId, String nickname, String currentRole) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: l10n.demoteToRegular,
      content: '$nickname → ${l10n.roleRegular}?\n\n${currentRole.toUpperCase()}',
      color: context.mlColors.dangerColor,
    );
    if (confirmed != true) return;
    try {
      await _apiClient.demoteToRegular(userId);
      _afterRoleChange('$nickname → ${l10n.roleRegular}');
    } catch (e) {
      _snackError(e);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String content,
    required Color color,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(
              l10n.confirm,
              style: TextStyle(color: context.mlColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _afterRoleChange(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _loadStats();
    _loadUsers(page: _currentPage);
  }

  void _snackError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorLocalizer.getMessage(context, e)),
        backgroundColor: context.mlColors.dangerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPanel), elevation: 0),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isManagerOrAbove) {
            return _buildLocked(l10n);
          }
          // 시스템 네비바(제스처바/홈인디케이터)에 페이저가 가리지 않도록.
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadStats();
                    await _loadUsers(page: 1);
                  },
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl + bottomInset,
                    ),
                    children: [
                      _buildPermissionCard(authProvider, l10n),
                      const SizedBox(height: AppSpacing.md),
                      _buildStatsCard(),
                      const SizedBox(height: AppSpacing.md),
                      _buildSearchRow(l10n),
                      const SizedBox(height: AppSpacing.md),
                      _buildRoleChips(),
                      const SizedBox(height: AppSpacing.md),
                      if (_errorMessage != null) _buildError(),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_users.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxl,
                          ),
                          child: Center(
                            child: Text(
                              _searchController.text.isNotEmpty
                                  ? l10n.noSearchResults
                                  : l10n.noData,
                              style: TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._users.map((u) => _buildUserCard(u, authProvider)),
                      if (_users.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildPager(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 위젯 빌더 ──

  Widget _buildLocked(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.errManagerRequired,
              style: TextStyle(
                fontSize: AppTypography.headlineLarge,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );

  Widget _buildPermissionCard(AuthProvider auth, AppLocalizations l10n) {
    final mlc = context.mlColors;
    return Card(
      color: mlc.warningBg,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              auth.isMaster
                  ? Icons.admin_panel_settings
                  : Icons.manage_accounts,
              color: auth.isMaster ? mlc.dangerColor : mlc.warningColor,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.roleDisplayName,
                    style: const TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    auth.isMaster
                        ? '${l10n.promoteToGold} · ${l10n.promoteToManager} · ${l10n.demoteToRegular}'
                        : '${l10n.promoteToGold} · ${l10n.demoteToRegular}',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);
    final total = _stats['total'] ?? 0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, size: 18, color: mlc.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '총 가입자',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: mlc.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$total${_unitMyeong(l10n)}',
                  style: const TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _statCell(l10n.roleMaster, _stats['master'] ?? 0,
                    BadgeColors.roleBadge('master', mlc)),
                _statDivider(),
                _statCell(l10n.roleManager, _stats['manager'] ?? 0,
                    BadgeColors.roleBadge('manager', mlc)),
                _statDivider(),
                _statCell(l10n.roleGold, _stats['gold'] ?? 0,
                    BadgeColors.roleBadge('gold', mlc)),
                _statDivider(),
                _statCell(l10n.roleRegular, _stats['regular'] ?? 0,
                    BadgeColors.roleBadge('regular', mlc)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: AppTypography.semiBold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      );

  Widget _buildSearchRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              isDense: true,
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
                        _onSearchSubmitted();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _onSearchSubmitted(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ElevatedButton(
          onPressed: _isLoading ? null : _onSearchSubmitted,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.mlColors.accentBlue,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: AppStroke.medium,
                    color: context.mlColors.onPrimary,
                  ),
                )
              : Text(l10n.tabSearch,
                  style: TextStyle(color: context.mlColors.onPrimary)),
        ),
      ],
    );
  }

  Widget _buildRoleChips() {
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);
    final chips = <(String?, String, int)>[
      (null, '전체', _stats['total'] ?? 0),
      ('master', l10n.roleMaster, _stats['master'] ?? 0),
      ('manager', l10n.roleManager, _stats['manager'] ?? 0),
      ('gold', l10n.roleGold, _stats['gold'] ?? 0),
      ('regular', l10n.roleRegular, _stats['regular'] ?? 0),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final selected = _roleFilter == c.$1;
          final roleColor =
              c.$1 == null ? mlc.accentBlue : BadgeColors.roleBadge(c.$1!, mlc);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text('${c.$2} ${c.$3}'),
              selected: selected,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: selected
                    ? AppTypography.bold
                    : AppTypography.semiBold,
                color: selected ? mlc.onPrimary : roleColor,
              ),
              selectedColor: roleColor,
              backgroundColor: roleColor.withValues(alpha: 0.10),
              side: BorderSide(
                color: roleColor.withValues(alpha: selected ? 0 : 0.3),
              ),
              onSelected: (_) => _selectRole(c.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Card(
          color: context.mlColors.dangerBg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: context.mlColors.dangerColor),
                const SizedBox(width: AppSpacing.md),
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
      );

  /// 번호형 페이저: 1–20 / 8,420   [‹]  1 [2] 3 4 5 … N  [›]
  /// 한 줄 가로 배치 — 좁은 폭에선 페이저만 가로 스크롤.
  Widget _buildPager() {
    final mlc = context.mlColors;
    final start = (_currentPage - 1) * _pageSize + 1;
    final end = (_currentPage * _pageSize).clamp(0, _totalCount);
    final pages = _pageNumbers();

    final pagerChildren = <Widget>[
      _pageButton(
        icon: Icons.chevron_left,
        enabled: _currentPage > 1,
        onTap: () => _loadUsers(page: _currentPage - 1),
      ),
      for (final p in pages) ...[
        const SizedBox(width: AppSpacing.xs),
        if (p == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('…'),
          )
        else
          _pageButton(
            label: '$p',
            selected: p == _currentPage,
            onTap: () => _loadUsers(page: p),
          ),
      ],
      const SizedBox(width: AppSpacing.xs),
      _pageButton(
        icon: Icons.chevron_right,
        enabled: _hasNext,
        onTap: () => _loadUsers(page: _currentPage + 1),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$start–$end / ${_formatNumber(_totalCount)}',
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: mlc.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: pagerChildren,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageButton({
    String? label,
    IconData? icon,
    bool enabled = true,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final mlc = context.mlColors;
    final bg = selected ? mlc.accentBlue : Colors.transparent;
    final fg = selected
        ? mlc.onPrimary
        : (enabled ? mlc.textPrimary : mlc.textTertiary);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected
                ? mlc.accentBlue
                : Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: icon != null
            ? Icon(icon, size: 18, color: fg)
            : Text(
                label!,
                style: TextStyle(
                  color: fg,
                  fontWeight:
                      selected ? AppTypography.bold : AppTypography.semiBold,
                ),
              ),
      ),
    );
  }

  /// 페이저 번호 리스트 — 양 끝(1, total)은 항상, 현재 ±2 보여주고 나머지는 …(null).
  List<int?> _pageNumbers() {
    final total = _totalPages;
    final cur = _currentPage;
    if (total <= 7) {
      return List.generate(total, (i) => i + 1);
    }
    final out = <int?>{1};
    for (var p = cur - 2; p <= cur + 2; p++) {
      if (p > 1 && p < total) out.add(p);
    }
    out.add(total);
    final sorted = out.toList()..sort();
    final result = <int?>[];
    int? prev;
    for (final p in sorted) {
      if (prev != null && p! - prev > 1) result.add(null);
      result.add(p);
      prev = p;
    }
    return result;
  }

  Widget _buildUserCard(Map<String, dynamic> user, AuthProvider auth) {
    final mlc = context.mlColors;
    final l10n = AppLocalizations.of(context);
    final int userId = user['id'];
    final String email = user['email'];
    final String nickname = user['nickname'];
    final String role = user['role'] ?? 'regular';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: mlc.accentBlue,
                  child: Text(
                    nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: mlc.onPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                fontWeight: AppTypography.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildRoleBadge(role, l10n),
                          if (role == 'gold') ...[
                            const SizedBox(width: AppSpacing.xxs),
                            _buildGoldTypeBadge(user['is_iap_gold'] == true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildActionRow(userId, nickname, role, auth, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(
    int userId,
    String nickname,
    String role,
    AuthProvider auth,
    AppLocalizations l10n,
  ) {
    final mlc = context.mlColors;
    final actions = <Widget>[];

    if (auth.canPromoteToGold && role == 'regular') {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _promoteToGold(userId, nickname),
          icon: const Icon(Icons.workspace_premium, size: 18),
          label: Text(l10n.promoteToGold),
          style: OutlinedButton.styleFrom(
            foregroundColor: mlc.roleGoldColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
          ),
        ),
      );
    }
    if (auth.canPromoteToManager && (role == 'regular' || role == 'gold')) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _promoteToManager(userId, nickname),
          icon: const Icon(Icons.manage_accounts, size: 18),
          label: Text(l10n.promoteToManager),
          style: ElevatedButton.styleFrom(
            backgroundColor: mlc.warningColor,
            foregroundColor: mlc.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
          ),
        ),
      );
    }
    final canDemote = (role == 'gold' && auth.canPromoteToGold) ||
        (role == 'manager' && auth.isMaster);
    if (canDemote) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _demoteToRegular(userId, nickname, role),
          icon: const Icon(Icons.arrow_downward, size: 16),
          label: Text(l10n.demoteToRegular),
          style: OutlinedButton.styleFrom(
            foregroundColor: mlc.dangerColor,
            side: BorderSide(color: mlc.dangerColor),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
          ),
        ),
      );
    }
    if (role == 'master') {
      actions.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            l10n.roleMaster,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      );
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: actions,
    );
  }

  Widget _buildGoldTypeBadge(bool isIapGold) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
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

  Widget _buildRoleBadge(String role, AppLocalizations l10n) {
    final badgeColor = BadgeColors.roleBadge(role, context.mlColors);
    String text;
    switch (role) {
      case 'master':
        text = l10n.roleMaster;
        break;
      case 'manager':
        text = l10n.roleManager;
        break;
      case 'gold':
        text = l10n.roleGold;
        break;
      default:
        text = l10n.roleRegular;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.mlColors.onPrimary,
          fontSize: AppTypography.micro,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _unitMyeong(AppLocalizations l10n) {
    // 다국어 단위가 별도로 없으므로 한국어 기본. nItems가 "N건" 형태라 별도 분리.
    return '명';
  }
}
