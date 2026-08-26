import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/chat_personalization.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// AI 채팅 로컬 저장 설정.
///
/// - 한도 선택(100 / 500 / 1000 / 무제한)
/// - 현재 사용량 표시(대화 수 · 추정 KB)
/// - 폰 로컬 전체 삭제(서버 자료는 보존)
class ChatStorageSettingsScreen extends StatefulWidget {
  const ChatStorageSettingsScreen({super.key});

  @override
  State<ChatStorageSettingsScreen> createState() =>
      _ChatStorageSettingsScreenState();
}

class _ChatStorageSettingsScreenState extends State<ChatStorageSettingsScreen> {
  static const _options = [100, 500, 1000, 0]; // 0 = 무제한

  ({int conversations, int bytes})? _usage;
  bool _busy = false;
  GreetCooldownMode _greetMode = GreetCooldownMode.twoHours;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUsage();
      _loadGreetMode();
    });
  }

  Future<void> _loadGreetMode() async {
    final m = await ChatPersonalization.loadGreetMode();
    if (!mounted) return;
    setState(() => _greetMode = m);
  }

  Future<void> _setGreetMode(GreetCooldownMode m) async {
    setState(() => _greetMode = m);
    await ChatPersonalization.saveGreetMode(m);
  }

  Future<void> _refreshUsage() async {
    final chat = context.read<ChatProvider>();
    final u = await chat.localUsage();
    if (!mounted) return;
    setState(() => _usage = u);
  }

  Future<void> _confirmClear(
    BuildContext context,
    ChatProvider chat,
    AppLocalizations l10n,
  ) async {
    final mlc = context.mlColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiChatClearLocal),
        content: Text(l10n.aiChatClearLocalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: mlc.dangerColor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await chat.clearAllLocal();
    await _refreshUsage();
    if (!context.mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.aiChatLocalCleared)),
    );
  }

  String _formatBytes(int b, AppLocalizations l10n) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) {
      return '${(b / 1024).toStringAsFixed(1)} KB';
    }
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _labelFor(int n, AppLocalizations l10n) =>
      n == 0 ? l10n.aiChatUnlimited : l10n.aiChatNConversations(n);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiChatStorageSettings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          // ── 현재 사용량 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.aiChatStorageUsage,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: mlc.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: mlc.subtleBorder.withValues(alpha: 0.6),
                ),
              ),
              child: _usage == null
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mlc.accentBlue,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        _statCell(
                          mlc,
                          l10n.aiChatNConversations(_usage!.conversations),
                          l10n.aiChatHistory,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _statCell(
                          mlc,
                          _formatBytes(_usage!.bytes, l10n),
                          l10n.aiChatStorageBytes,
                        ),
                      ],
                    ),
            ),
          ),

          // ── AI 인사 빈도 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.aiChatGreetingCooldownTitle,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
          ),
          ..._greetOptions(l10n).map((opt) {
            final selected = _greetMode == opt.mode;
            return ListTile(
              onTap: () => _setGreetMode(opt.mode),
              leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? mlc.accentBlue : mlc.textTertiary,
              ),
              title: Text(
                opt.label,
                style: AppTypography.body.copyWith(
                  color: selected ? mlc.textPrimary : mlc.textSecondary,
                ),
              ),
            );
          }),

          // ── 한도 선택 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.aiChatStorageLimit,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
          ),
          ..._options.map((n) {
            final selected = chat.localLimit == n;
            return ListTile(
              onTap: () => chat.setLocalLimit(n),
              leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? mlc.accentBlue : mlc.textTertiary,
              ),
              title: Text(
                _labelFor(n, l10n),
                style: AppTypography.body.copyWith(
                  color: selected ? mlc.textPrimary : mlc.textSecondary,
                ),
              ),
            );
          }),

          // ── 안내 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Text(
              l10n.aiChatStorageNote,
              style: AppTypography.label.copyWith(color: mlc.textTertiary),
            ),
          ),

          // ── 전체 삭제 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _confirmClear(context, chat, l10n),
              icon: Icon(
                Icons.delete_sweep_rounded,
                size: 20,
                color: mlc.dangerColor,
              ),
              label: Text(
                l10n.aiChatClearLocal,
                style: AppTypography.body.copyWith(color: mlc.dangerColor),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(
                  color: mlc.dangerColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Text(
              l10n.aiChatClearLocalDesc,
              style: AppTypography.label.copyWith(color: mlc.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  List<({GreetCooldownMode mode, String label})> _greetOptions(
      AppLocalizations l10n) {
    return [
      (mode: GreetCooldownMode.off, label: l10n.aiChatGreetingCooldownOff),
      (
        mode: GreetCooldownMode.twoHours,
        label: l10n.aiChatGreetingCooldown2h,
      ),
      (
        mode: GreetCooldownMode.daily,
        label: l10n.aiChatGreetingCooldownDaily,
      ),
    ];
  }

  Widget _statCell(MarketLensColors mlc, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.label.copyWith(color: mlc.textSecondary),
          ),
        ],
      ),
    );
  }
}
