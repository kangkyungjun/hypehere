import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/community_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/common/bento_card.dart';

/// 차단한 사용자 관리 화면 — 목록 조회 및 차단 해제
/// (Apple Guideline 1.2 (d) — 사용자 차단 기능의 관리 UI)
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final CommunityApiClient _apiClient = CommunityApiClient();

  List<Map<String, dynamic>> _blocked = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _apiClient.getBlockedUsers();
      if (!mounted) return;
      setState(() {
        _blocked = users;
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

  Future<void> _unblock(Map<String, dynamic> user) async {
    final l10n = AppLocalizations.of(context);
    final id = user['id'] as int;
    try {
      await _apiClient.unblockUser(id);
      if (!mounted) return;
      setState(() {
        _blocked.removeWhere((u) => u['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userUnblocked)),
      );
    } catch (e) {
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
      backgroundColor: context.mlColors.sectionBackground,
      appBar: AppBar(title: Text(l10n.blockedUsers)),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: context.mlColors.dangerColor),
            const SizedBox(height: AppSpacing.lg),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.mlColors.textSecondary,
                )),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(onPressed: _load, child: Text(l10n.tryAgain)),
          ],
        ),
      );
    }

    if (_blocked.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block,
                size: 56, color: context.mlColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.noBlockedUsers,
                style: AppTypography.body.copyWith(
                  color: context.mlColors.textSecondary,
                )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        itemCount: _blocked.length,
        itemBuilder: (context, index) {
          final user = _blocked[index];
          final nickname = (user['nickname'] ?? '') as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: BentoCard(
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 22, color: context.mlColors.textTertiary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      nickname,
                      style: AppTypography.bodyStrong.copyWith(
                        color: context.mlColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _unblock(user),
                    child: Text(l10n.unblock),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
