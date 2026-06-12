import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 채팅 말풍선 — 앱 카드 톤과 통일(테두리 없이 soft-shadow).
///
/// user: accent 채움 + 흰 글자 / assistant: 흰 카드 + soft-shadow.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isUser ? mlc.accentBlue : mlc.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card(Colors.black),
        ),
        child: Text(
          message.content,
          style: AppTypography.body
              .copyWith(color: isUser ? mlc.onPrimary : mlc.textPrimary),
        ),
      ),
    );
  }
}
