import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_message.dart';
import '../../../providers/chat_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// AI 채팅 이전 대화 화면.
///
/// **기능:** 대화 목록 표시 → 탭으로 해당 대화 열기. 선택 모드(우측 상단 "선택")
/// 진입 시 체크박스로 여러 대화를 골라 **공유**(평문 합본) 또는 **폰에서 숨김**
/// 처리할 수 있다. 숨김은 서버 정본에는 손대지 않음(학습/개인화 자료 보존).
class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  bool _selecting = false;
  final Set<String> _picked = <String>{};

  void _toggleSelect() {
    setState(() {
      _selecting = !_selecting;
      if (!_selecting) _picked.clear();
    });
  }

  void _tapTile(String id) {
    if (_selecting) {
      setState(() {
        if (_picked.contains(id)) {
          _picked.remove(id);
        } else {
          _picked.add(id);
        }
      });
      return;
    }
    Navigator.pop(context, id);
  }

  Future<void> _hideSelected(ChatProvider chat, AppLocalizations l10n) async {
    if (_picked.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiChatHide),
        content: Text(l10n.aiChatHideConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.mlColors.dangerColor,
            ),
            child: Text(l10n.aiChatHide),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ids = _picked.toList();
    await chat.hideConversationsLocally(ids);
    if (!mounted) return;
    setState(() {
      _picked.clear();
      _selecting = false;
    });
  }

  Future<void> _shareSelected(
    BuildContext context,
    ChatProvider chat,
    AppLocalizations l10n,
  ) async {
    if (_picked.isEmpty) return;
    final blocks = <String>[];
    for (final id in _picked) {
      final msgs = await chat.messagesForExport(id);
      if (msgs.isEmpty) continue;
      blocks.add(_formatConversation(msgs, l10n));
    }
    if (blocks.isEmpty || !context.mounted) return;
    final text = blocks.join('\n\n---\n\n');
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(text, sharePositionOrigin: origin);
  }

  String _formatConversation(List<ChatMessage> msgs, AppLocalizations l10n) {
    final buf = StringBuffer();
    // user/assistant 페어로 출력. 단발 메시지도 그대로 한 줄씩.
    for (final m in msgs) {
      if (m.isUser) {
        buf.writeln('${l10n.aiChatShareQ}) ${m.content.trim()}');
      } else {
        buf.writeln('${l10n.aiChatShareA}) ${m.content.trim()}');
      }
      buf.writeln();
    }
    buf.write(l10n.aiChatShareFooter);
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final chat = context.watch<ChatProvider>();
    final convos = chat.conversations;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selecting
            ? l10n.aiChatSelectedCount(_picked.length)
            : l10n.aiChatHistory),
        actions: [
          if (convos.isNotEmpty)
            TextButton(
              onPressed: _toggleSelect,
              child: Text(
                _selecting ? l10n.cancel : l10n.aiChatSelect,
                style: AppTypography.label.copyWith(color: mlc.accentBlue),
              ),
            ),
        ],
      ),
      body: convos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  l10n.aiChatNoHistory,
                  style: AppTypography.body.copyWith(color: mlc.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: convos.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: mlc.subtleBorder.withValues(alpha: 0.4),
              ),
              itemBuilder: (c, i) {
                final cv = convos[i];
                final picked = _picked.contains(cv.id);
                return ListTile(
                  leading: _selecting
                      ? Icon(
                          picked
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: picked ? mlc.accentBlue : mlc.textTertiary,
                        )
                      : Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: mlc.textTertiary,
                        ),
                  title: Text(
                    cv.title?.isNotEmpty == true
                        ? cv.title!
                        : (cv.lastMessage ?? cv.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(color: mlc.textPrimary),
                  ),
                  subtitle: cv.lastMessage != null && cv.title != cv.lastMessage
                      ? Text(
                          cv.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label.copyWith(
                            color: mlc.textTertiary,
                          ),
                        )
                      : null,
                  onTap: () => _tapTile(cv.id),
                );
              },
            ),
      bottomNavigationBar: _selecting && _picked.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: mlc.cardBackground,
                  border: Border(
                    top: BorderSide(
                      color: mlc.subtleBorder.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _hideSelected(chat, l10n),
                        icon: Icon(
                          Icons.visibility_off_outlined,
                          size: 18,
                          color: mlc.dangerColor,
                        ),
                        label: Text(
                          l10n.aiChatHide,
                          style: AppTypography.label.copyWith(
                            color: mlc.dangerColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: mlc.dangerColor.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _shareSelected(context, chat, l10n),
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: Text(l10n.aiChatShare),
                        style: FilledButton.styleFrom(
                          backgroundColor: mlc.accentBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
