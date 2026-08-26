import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 채팅 메시지 렌더 — GPT/제미나이 스타일.
///
/// - user: 오른쪽 정렬 말풍선(accent 채움 + 흰 글자)
/// - assistant: 말풍선 없이 **화면 전체 폭**으로 텍스트 표시(선택/복사 가능)
///   + 하단에 [복사]·[공유] 액션. 공유/복사는 **질문 + 답변을 묶어서** 처리한다.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.question});

  final ChatMessage message;

  /// assistant 메시지의 경우, 그 답변에 대응하는 사용자 질문(공유/복사에 포함).
  final String? question;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;

    // 사용자 질문: 말풍선 유지
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: mlc.accentBlue,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.card(Colors.black),
          ),
          child: Text(
            message.content,
            style: AppTypography.body.copyWith(
              fontSize: AppTypography.headlineMedium,
              height: 1.55,
              color: mlc.onPrimary,
            ),
          ),
        ),
      );
    }

    // AI 답변: 말풍선 없이 전체 폭 사용 + 복사/공유 액션.
    // 단, isError(맥미니 폴백) 인 경우 에러 톤으로 표시하고 액션 숨김.
    final l10n = AppLocalizations.of(context);
    final isErr = message.isError;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 마커(아이콘만 — 다국어 부담 없음). 에러 시 경고 아이콘으로 교체.
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Icon(
              isErr
                  ? Icons.error_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 16,
              color: isErr ? mlc.dangerColor : mlc.accentBlue,
            ),
          ),
          SelectableText(
            message.content,
            style: AppTypography.body.copyWith(
              fontSize: AppTypography.headlineMedium,
              color: isErr ? mlc.dangerColor : mlc.textPrimary,
              height: 1.55,
            ),
          ),
          // 정상 답변일 때만 복사 / 공유 노출.
          if (!isErr)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  _actionButton(
                    mlc,
                    Icons.copy_rounded,
                    l10n.aiChatCopy,
                    () => _copy(context, l10n),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _actionButton(
                    mlc,
                    Icons.ios_share,
                    l10n.aiChatShare,
                    () => _share(context, l10n),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
    MarketLensColors mlc,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: mlc.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// 질문 + 답변 + 푸터를 묶은 공유/복사용 텍스트.
  String _shareText(AppLocalizations l10n) {
    final answer = message.content.trim();
    final q = question?.trim();
    final buf = StringBuffer();
    if (q != null && q.isNotEmpty) {
      buf.writeln('${l10n.aiChatShareQ}) $q');
      buf.writeln();
    }
    buf.writeln('${l10n.aiChatShareA}) $answer');
    buf.writeln();
    buf.write(l10n.aiChatShareFooter);
    return buf.toString();
  }

  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _shareText(l10n)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.aiChatCopied),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _share(BuildContext context, AppLocalizations l10n) async {
    // iPad 공유 팝오버 기준점(없으면 크래시) — 탭한 위젯 영역으로 지정.
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.share(_shareText(l10n), sharePositionOrigin: origin);
  }
}
