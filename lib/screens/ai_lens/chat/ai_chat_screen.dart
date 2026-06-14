import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/chat_nav_signals.dart';
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

  // ───────────────────────────────────────────────────────────────────────
  // 대화 관리 UI(헤더의 "이전 대화"·"새 대화") 노출 플래그. 현재 OFF로 가려둠.
  //
  // [가린 이유 — 2026-06-14] 서버 대화 이력(analytics.chat_messages)에 AI 답변이
  //   저장되지 않아, "이전 대화"를 열어도 사용자 질문만 보이고 답변은 비어 있음.
  //   원인은 맥미니 분석엔진이 답변을 신규 경로 /internal/ingest/chat-message가
  //   아니라 옛 ai-messages 경로로 보내 chat_messages에 assistant 턴이 안 쌓이는 것.
  //   답변 없는 이력/새 대화 분리는 사용자에게 혼란만 주므로 기능을 잠시 숨긴다.
  //
  // [되살리는 법] 맥미니가 chat-message로 답변을 저장하도록 수정되면 이 값만 true로.
  //   헤더·이력 시트·관련 Provider 메서드는 그대로 보존되어 있어 즉시 복구된다.
  //
  // [완전 제거 시] 끝내 안 쓰기로 확정되면 다음을 함께 삭제:
  //   - 이 화면: _header(), _openHistory(), 본 플래그, build()의 헤더 분기,
  //     initState()의 loadConversations() 호출
  //   - ChatProvider: startNew(), loadConversation(), loadConversations(),
  //     _conversations 필드 / conversations getter
  //   - ChatApiClient.getConversations() (다른 참조가 없을 때)
  // 비-const 인스턴스 필드로 두어 dead_code 경고 없이 분기를 유지한다.
  // ───────────────────────────────────────────────────────────────────────
  final bool _showConversationControls = false;

  @override
  void initState() {
    super.initState();
    RewardedAdHelper.instance.preloadAd(); // 쿼터 리필용 미리 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      // 이전 대화 목록 (실패는 조용히). 대화 관리 UI를 숨긴 동안엔 불필요한
      // 네트워크 호출이라 함께 가린다. _showConversationControls 참고.
      if (_showConversationControls) chat.loadConversations();
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
        // 대화 관리 UI(이전 대화·새 대화)는 현재 가려둠 — _showConversationControls 참고.
        if (_showConversationControls) _header(l10n, mlc, chat),
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

  /// 입력창 왼쪽 인라인 원형 버튼 — 하단 풀 탭바를 펼쳤다 접는다.
  /// 탭바에서 다시 채팅으로 돌아올 때도 같은 버튼(펼침 상태=X 아이콘)으로 접는다.
  Widget _navToggleButton(MarketLensColors mlc) {
    return ValueListenableBuilder<bool>(
      valueListenable: chatNavExpanded,
      builder: (context, expanded, _) {
        return Material(
          color: mlc.infoBg.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => chatNavExpanded.value = !expanded,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                expanded ? Icons.close_rounded : Icons.apps_rounded,
                color: mlc.accentBlue,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputBar(BuildContext context, AppLocalizations l10n,
      MarketLensColors mlc, ChatProvider chat, bool isAdFree) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    // 채팅 페이지에선 main.dart가 하단 풀 탭바를 띄우지 않으므로(왼쪽 원형 버튼으로
    // 펼침), 입력창을 탭바 위로 올릴 필요 없이 자연 높이로 둔다 = 홈 인디케이터(safe
    // area)만 피하는 정도. 키보드가 뜨면 키보드 위 8px.
    final bottomClear =
        keyboard > 0 ? AppSpacing.sm : safeBottom + AppSpacing.sm;
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
          // 접이식 내비 토글(탭바 ⇄ 채팅 입력). 펼침이면 X, 접힘이면 메뉴 아이콘.
          _navToggleButton(mlc),
          const SizedBox(width: AppSpacing.sm),
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
