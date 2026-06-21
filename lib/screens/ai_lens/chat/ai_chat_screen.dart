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
import '../../../data/chat_suggestions.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_personalization.dart';
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

  // ── 접속 인사 + 추천(예시) 질문 ──
  /// 빈 화면에서 보여줄 랜덤 추천 질문 5개(관심도 가중).
  List<ChatSuggestion> _suggestions = const [];

  /// 이번 접속에서 노출할 인사말(2시간 쿨다운 통과 시에만 non-null).
  ({String ko, String en})? _greeting;

  /// 카테고리별 관심도(추천 가중치 + 맞춤 콘텐츠 신호).
  Map<String, int> _interest = const {};

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
      _initSuggestions(); // 인사말 + 추천 질문
    });
  }

  /// 관심도 로드 → 추천 질문 5개 추출 + (쿨다운 통과 시) 인사말 준비.
  Future<void> _initSuggestions() async {
    final interest = await ChatPersonalization.loadInterest();
    final greet = await ChatPersonalization.shouldGreet();
    if (greet) await ChatPersonalization.markGreeted();
    if (!mounted) return;
    setState(() {
      _interest = interest;
      _suggestions = ChatSuggestions.pick(5, interest: interest);
      _greeting = greet ? ChatSuggestions.pickGreeting() : null;
    });
  }

  /// 추천 질문을 다른 5개로 교체(셔플).
  void _reshuffle() {
    setState(() => _suggestions = ChatSuggestions.pick(5, interest: _interest));
  }

  /// [i]번 assistant 답변에 대응하는 질문 = 바로 앞쪽 가장 가까운 user 메시지.
  String? _questionFor(List<ChatMessage> msgs, int i) {
    for (int j = i - 1; j >= 0; j--) {
      if (msgs[j].isUser) return msgs[j].content;
    }
    return null;
  }

  @override
  void dispose() {
    // 화면 이탈 시 남아있는 키보드 내림
    FocusManager.instance.primaryFocus?.unfocus();
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
    final text = _controller.text;
    if (text.trim().isEmpty || chat.isSending) return;
    // B: 무료 쿼터 소진 시 보상형 광고로 리필 (입력 보존을 위해 clear 전에 체크)
    if (!isAdFree && chat.quotaExhausted) {
      _showRefillAd(chat);
      return;
    }
    _controller.clear();
    await _submitText(text, chat, isAdFree);
  }

  /// 입력창/추천칩 공통 전송 코어. [category]는 칩 탭에서만 전달.
  Future<void> _submitText(
    String text,
    ChatProvider chat,
    bool isAdFree, {
    String? category,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || chat.isSending) return;
    if (!isAdFree && chat.quotaExhausted) {
      _showRefillAd(chat);
      return;
    }
    // 전송하면 키보드를 내려 화면을 확보(엔터/전송/추천칩 공통).
    FocusScope.of(context).unfocus();
    final lang = Localizations.localeOf(context).languageCode;
    if (!isAdFree) await chat.consumeQuota();
    _scrollToBottom();
    await chat.sendMessage(trimmed, lang: lang, category: category);
    _scrollToBottom();
  }

  /// 추천 질문 탭 → 관심도 기록(맞춤 신호) 후 해당 질문 전송.
  /// 칩의 카테고리를 함께 보내 맥미니가 컨텍스트 주입을 분기할 수 있게 한다.
  Future<void> _onSuggestionTap(
    ChatSuggestion s,
    ChatProvider chat,
    bool isAdFree,
  ) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final interest = await ChatPersonalization.recordTap(s);
    if (!mounted) return;
    setState(() => _interest = interest);
    await _submitText(s.text(isKo), chat, isAdFree, category: s.category);
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
              ? _emptyState(l10n, mlc, chat, isAdFree)
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
                    final msg = chat.messages[i];
                    return ChatBubble(
                      message: msg,
                      // AI 답변엔 대응 질문을 함께 넘겨 공유/복사에 포함
                      question: msg.isAssistant
                          ? _questionFor(chat.messages, i)
                          : null,
                    );
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
  Widget _adAndQuota(
    BuildContext context,
    AppLocalizations l10n,
    MarketLensColors mlc,
    ChatProvider chat,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A+D: 하단 배너 (응답 대기 중에도 노출되어 대기 시간 수익화)
        const Center(child: BannerAdWidget()),
        // B: 남은 무료 횟수 표시, 소진 시 보상형 광고 리필 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              if (chat.quotaExhausted)
                TextButton.icon(
                  onPressed: () => _showRefillAd(chat),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 16,
                    color: mlc.accentBlue,
                  ),
                  label: Text(
                    l10n.watchAd,
                    style: AppTypography.label.copyWith(color: mlc.accentBlue),
                  ),
                )
              else
                Text(
                  '${l10n.aiChatFreeRemaining} '
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
    AppLocalizations l10n,
    MarketLensColors mlc,
    ChatProvider chat,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
        AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: mlc.subtleBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton.icon(
            onPressed: () => _openHistory(context, l10n, mlc, chat),
            icon: Icon(
              Icons.history_rounded,
              size: 18,
              color: mlc.textSecondary,
            ),
            label: Text(
              l10n.aiChatHistory,
              style: AppTypography.label.copyWith(color: mlc.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: chat.isSending ? null : () => chat.startNew(),
            icon: Icon(Icons.add_rounded, size: 18, color: mlc.accentBlue),
            label: Text(
              l10n.aiChatNew,
              style: AppTypography.label.copyWith(color: mlc.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory(
    BuildContext context,
    AppLocalizations l10n,
    MarketLensColors mlc,
    ChatProvider chat,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final convos = chat.conversations;
        return SafeArea(
          child: convos.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      l10n.aiChatNoHistory,
                      style: AppTypography.body.copyWith(
                        color: mlc.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: convos.length,
                  itemBuilder: (c, i) {
                    final cv = convos[i];
                    return ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: mlc.textTertiary,
                      ),
                      title: Text(
                        cv.title ?? cv.lastMessage ?? cv.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: mlc.textPrimary,
                        ),
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
                strokeWidth: 2,
                color: mlc.accentBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.aiChatThinking,
              style: AppTypography.body.copyWith(color: mlc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    AppLocalizations l10n,
    MarketLensColors mlc,
    ChatProvider chat,
    bool isAdFree,
  ) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: mlc.infoBg,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: mlc.accentBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 접속 인사("대화를 걸어주는" 멘트) — 2시간 쿨다운 통과 시에만.
          // 그 외엔 기존 빈 상태 타이틀/서브타이틀.
          if (_greeting != null)
            _greetingCard(mlc, isKo)
          else ...[
            Text(
              l10n.aiChatEmptyTitle,
              style: AppTypography.sectionTitle.copyWith(
                color: mlc.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.aiChatEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: mlc.textSecondary),
            ),
          ],

          // 추천(예시) 질문 — 랜덤 5개, 탭 시 바로 전송.
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(
                  l10n.aiChatSuggestionsTitle,
                  style: AppTypography.label.copyWith(color: mlc.textTertiary),
                ),
                const Spacer(),
                InkWell(
                  onTap: _reshuffle,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: mlc.accentBlue,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          l10n.aiChatShuffle,
                          style: AppTypography.label.copyWith(
                            color: mlc.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _suggestions
                  .map((s) => _suggestionChip(s, isKo, chat, isAdFree, mlc))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 접속 인사 카드(AI가 먼저 말을 거는 느낌의 어시스턴트 톤).
  Widget _greetingCard(MarketLensColors mlc, bool isKo) {
    final g = _greeting!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mlc.infoBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: mlc.subtleBorder.withValues(alpha: 0.5)),
      ),
      child: Text(
        isKo ? g.ko : g.en,
        style: AppTypography.body.copyWith(color: mlc.textPrimary, height: 1.5),
      ),
    );
  }

  /// 추천 질문 칩.
  Widget _suggestionChip(
    ChatSuggestion s,
    bool isKo,
    ChatProvider chat,
    bool isAdFree,
    MarketLensColors mlc,
  ) {
    return Material(
      color: mlc.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: chat.isSending
            ? null
            : () => _onSuggestionTap(s, chat, isAdFree),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: mlc.subtleBorder),
          ),
          child: Text(
            s.text(isKo),
            style: AppTypography.label.copyWith(color: mlc.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _errorBar(AppLocalizations l10n, MarketLensColors mlc) {
    return Container(
      width: double.infinity,
      color: mlc.dangerBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        l10n.aiChatErrorRetry,
        style: AppTypography.label.copyWith(color: mlc.dangerColor),
      ),
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

  Widget _inputBar(
    BuildContext context,
    AppLocalizations l10n,
    MarketLensColors mlc,
    ChatProvider chat,
    bool isAdFree,
  ) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    // 채팅 페이지에선 main.dart가 하단 풀 탭바를 띄우지 않으므로(왼쪽 원형 버튼으로
    // 펼침), 입력창을 탭바 위로 올릴 필요 없이 자연 높이로 둔다 = 홈 인디케이터(safe
    // area)만 피하는 정도. 키보드가 뜨면 키보드 위 8px.
    final bottomClear = keyboard > 0
        ? AppSpacing.sm
        : safeBottom + AppSpacing.sm;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottomClear,
      ),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        border: Border(
          top: BorderSide(color: mlc.subtleBorder.withValues(alpha: 0.6)),
        ),
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
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
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
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: mlc.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
