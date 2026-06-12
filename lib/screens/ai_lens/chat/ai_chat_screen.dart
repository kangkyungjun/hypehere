import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/ads/banner_ad_widget.dart';
import '../../../widgets/ads/rewarded_ad_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../watchlist/widgets/login_required_banner.dart';
import 'chat_bubble.dart';

/// AI 멀티턴 채팅 화면 (AI Lens 탭0).
///
/// 전송 → 백오프 폴링으로 응답 수신(ChatProvider). 서버(FastAPI:8001)가 정본.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    RewardedAdHelper.instance.preloadAd(); // 쿼터 리필용 미리 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      chat.loadConversations(); // 이전 대화 목록 (실패는 조용히)
      chat.loadQuota(); // 일일 무료 쿼터
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(ChatProvider chat, bool isAdFree) async {
    if (_controller.text.trim().isEmpty || chat.isSending) return;
    // B: 무료 쿼터 소진 시 보상형 광고로 리필 (이번 전송은 보류)
    if (!isAdFree && chat.quotaExhausted) {
      _showRefillAd(chat);
      return;
    }
    final text = _controller.text;
    _controller.clear();
    final lang = Localizations.localeOf(context).languageCode;
    if (!isAdFree) await chat.consumeQuota();
    _scrollToBottom();
    await chat.sendMessage(text, lang: lang);
    _scrollToBottom();
  }

  /// 보상형 광고 시청 → 무료 횟수 +5. 광고 못 불러와도 막지 않음(정책).
  void _showRefillAd(ChatProvider chat) {
    RewardedAdHelper.instance.showAd(
      onRewarded: () => chat.grantQuotaBonus(5),
      onFailed: () => chat.grantQuotaBonus(5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LoginRequiredBanner(),
        ),
      );
    }

    final chat = context.watch<ChatProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final isAdFree = auth.shouldHideAds || sub.isGoldActive;
    final showThinking = chat.isSending;
    final count = chat.messages.length + (showThinking ? 1 : 0);

    return Column(
      children: [
        _header(l10n, mlc, chat),
        Expanded(
          child: (chat.isEmpty && !showThinking)
              ? _emptyState(l10n, mlc)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  itemCount: count,
                  itemBuilder: (ctx, i) {
                    if (showThinking && i == count - 1) {
                      return _thinkingBubble(l10n, mlc);
                    }
                    return ChatBubble(message: chat.messages[i]);
                  },
                ),
        ),
        if (chat.error != null && !chat.isSending) _errorBar(l10n, mlc),
        if (!isAdFree) _adAndQuota(context, l10n, mlc, chat),
        _inputBar(context, l10n, mlc, chat, isAdFree),
      ],
    );
  }

  /// A+D 광고 배너 + B 무료 쿼터 표시/리필 (광고 비대상 유저에게만).
  Widget _adAndQuota(BuildContext context, AppLocalizations l10n,
      MarketLensColors mlc, ChatProvider chat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A+D: 하단 배너 (응답 대기 중에도 노출되어 대기 시간 수익화)
        const Center(child: BannerAdWidget()),
        // B: 남은 무료 횟수 표시, 소진 시 보상형 광고 리필 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 0),
          child: Row(
            children: [
              if (chat.quotaExhausted)
                TextButton.icon(
                  onPressed: () => _showRefillAd(chat),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.play_circle_outline_rounded,
                      size: 16, color: mlc.accentBlue),
                  label: Text(l10n.watchAd,
                      style:
                          AppTypography.label.copyWith(color: mlc.accentBlue)),
                )
              else
                Text(
                  '${l10n.aiChatFreeToday} '
                  '${chat.quotaRemaining}/${ChatProvider.freeLimit}',
                  style: AppTypography.label.copyWith(color: mlc.textTertiary),
                ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(
      AppLocalizations l10n, MarketLensColors mlc, ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xxs, AppSpacing.sm, AppSpacing.xxs),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: mlc.subtleBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton.icon(
            onPressed: () => _openHistory(context, l10n, mlc, chat),
            icon: Icon(Icons.history_rounded,
                size: 18, color: mlc.textSecondary),
            label: Text(l10n.aiChatHistory,
                style: AppTypography.label.copyWith(color: mlc.textSecondary)),
          ),
          TextButton.icon(
            onPressed: chat.isSending ? null : () => chat.startNew(),
            icon: Icon(Icons.add_rounded, size: 18, color: mlc.accentBlue),
            label: Text(l10n.aiChatNew,
                style: AppTypography.label.copyWith(color: mlc.accentBlue)),
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context, AppLocalizations l10n,
      MarketLensColors mlc, ChatProvider chat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final convos = chat.conversations;
        return SafeArea(
          child: convos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text(l10n.aiChatNoHistory,
                        style: AppTypography.body
                            .copyWith(color: mlc.textSecondary)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: convos.length,
                  itemBuilder: (c, i) {
                    final cv = convos[i];
                    return ListTile(
                      leading: Icon(Icons.chat_bubble_outline_rounded,
                          size: 20, color: mlc.textTertiary),
                      title: Text(
                        cv.title ?? cv.lastMessage ?? cv.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body
                            .copyWith(color: mlc.textPrimary),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        chat.loadConversation(cv.id);
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _thinkingBubble(AppLocalizations l10n, MarketLensColors mlc) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: mlc.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card(Colors.black),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: mlc.accentBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.aiChatThinking,
                style: AppTypography.body.copyWith(color: mlc.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n, MarketLensColors mlc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: mlc.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: mlc.accentBlue, size: 30),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.aiChatEmptyTitle,
                style:
                    AppTypography.sectionTitle.copyWith(color: mlc.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.aiChatEmptySubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: mlc.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _errorBar(AppLocalizations l10n, MarketLensColors mlc) {
    return Container(
      width: double.infinity,
      color: mlc.dangerBg,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Text(l10n.aiChatErrorRetry,
          style: AppTypography.label.copyWith(color: mlc.dangerColor)),
    );
  }

  Widget _inputBar(BuildContext context, AppLocalizations l10n,
      MarketLensColors mlc, ChatProvider chat, bool isAdFree) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    // 키보드가 없을 때만 플로팅 탭바 클리어런스를 더한다.
    final bottomClear = keyboard > 0
        ? AppSpacing.sm
        : MediaQuery.of(context).viewPadding.bottom + 64;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottomClear),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        border: Border(
            top: BorderSide(color: mlc.subtleBorder.withValues(alpha: 0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(chat, isAdFree),
              style: AppTypography.body.copyWith(color: mlc.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.aiChatHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide(color: mlc.subtleBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  borderSide: BorderSide(color: mlc.subtleBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: chat.isSending ? mlc.neutralColor : mlc.accentBlue,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.full),
              onTap: chat.isSending ? null : () => _send(chat, isAdFree),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.arrow_upward_rounded,
                    color: mlc.onPrimary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
