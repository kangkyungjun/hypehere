import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/chat_nav_signals.dart';
import '../../../providers/portfolio_provider.dart';
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
import '../../../utils/app_page_route.dart';
import 'chat_bubble.dart';
import 'chat_history_screen.dart';

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

  // 대화 관리 UI(헤더 "이전 대화"·"새 대화") 노출 플래그.
  // 06-21 is_error 폴백 + 06-27 로컬 캐시(sqflite) 도입으로 이력이 안전하게
  // 누적·표시되므로 ON. 필요 시 false 로 다시 가릴 수 있다.
  final bool _showConversationControls = true;

  // ── 접속 인사 + 추천(예시) 질문 ──
  /// 빈 화면에서 보여줄 랜덤 추천 질문 5개(관심도 가중).
  List<ChatSuggestion> _suggestions = const [];

  /// 이번 접속에서 노출할 인사말(2시간 쿨다운 통과 시에만 non-null).
  ({String ko, String en})? _greeting;

  /// 오늘(로컬 자정 기준) 첫 진입이면 면책 안내 시스템 말풍선을 1회 노출.
  /// 화면을 실제로 연 경우에만 계산·기록되므로 사전 생성되지 않는다.
  bool _showDailyDisclaimer = false;

  /// 카테고리별 관심도(추천 가중치 + 맞춤 콘텐츠 신호).
  Map<String, int> _interest = const {};

  @override
  void initState() {
    super.initState();
    RewardedAdHelper.instance.preloadAd(); // 쿼터 리필용 미리 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      chat.loadQuota(); // 무료 쿼터 + 로컬 한도 설정 로드
      if (_showConversationControls) chat.loadConversations();
      _initSuggestions(); // 인사말 + 추천 질문
    });
  }

  /// 관심도 로드 → 추천 질문 5개 추출 + (쿨다운 통과 시) 인사말 준비.
  /// 인사는 PortfolioProvider의 보유/관심 티커를 반영해 동적 조립(둘 다 없으면 랜덤 폴백).
  Future<void> _initSuggestions() async {
    final interest = await ChatPersonalization.loadInterest();
    final greet = await ChatPersonalization.shouldGreet();
    if (greet) await ChatPersonalization.markGreeted();
    // 면책 안내: 오늘 첫 진입이면 1회 노출(그린 시점에 기록해 재노출 방지).
    final showDisclaimer = await ChatPersonalization.shouldShowDailyDisclaimer();
    if (showDisclaimer) await ChatPersonalization.markDisclaimerShown();
    if (!mounted) return;
    final port = context.read<PortfolioProvider>();
    // 보유 평가액 desc로 우선순위 정렬 (큰 종목 먼저 인사에 노출).
    final sortedHoldings = [...port.holdings]
      ..sort((a, b) => (b.currentValue).compareTo(a.currentValue));
    final holdings = sortedHoldings
        .map((h) => (ticker: h.ticker, changePct: h.changePct))
        .toList();
    final watchlist = port.watchlistTickers
        .map((t) => (ticker: t, changePct: null as double?))
        .toList();
    setState(() {
      _interest = interest;
      _showDailyDisclaimer = showDisclaimer;
      _suggestions = ChatSuggestions.pick(5, interest: interest);
      _greeting = greet
          ? ChatSuggestions.pickGreetingFor(
              holdings: holdings,
              watchlist: watchlist,
            )
          : null;
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
    // 대화가 있을 때는 면책 안내를 리스트 맨 위(헤더)에 시스템 말풍선으로 1개 얹는다.
    final headerCount = _showDailyDisclaimer ? 1 : 0;
    final count = headerCount + chat.messages.length + (showThinking ? 1 : 0);

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
                    if (headerCount == 1 && i == 0) {
                      return _dailyDisclaimerBubble(l10n, mlc);
                    }
                    final mi = i - headerCount;
                    if (showThinking && mi == chat.messages.length) {
                      return _thinkingBubble(l10n, mlc);
                    }
                    final msg = chat.messages[mi];
                    return ChatBubble(
                      message: msg,
                      // AI 답변엔 대응 질문을 함께 넘겨 공유/복사에 포함
                      question: msg.isAssistant
                          ? _questionFor(chat.messages, mi)
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
            onPressed: () => _openHistory(context, chat),
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

  /// 이전 대화 목록 → 선택 모드/공유/숨김 지원하는 전용 화면.
  Future<void> _openHistory(BuildContext context, ChatProvider chat) async {
    // 진입 직전에 목록 한 번 더 머지(서버 + 로컬 캐시).
    chat.loadConversations();
    final picked = await Navigator.push<String?>(
      context,
      appPageRoute(builder: (_) => const ChatHistoryScreen()),
    );
    if (picked == null || !mounted) return;
    await chat.loadConversation(picked);
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
          // 오늘 첫 진입이면 면책 안내를 맨 위에 1회.
          if (_showDailyDisclaimer) _dailyDisclaimerBubble(l10n, mlc),
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

  /// 하루 1회 면책 안내 — 시스템 말풍선(전송·저장 안 하는 뷰 전용).
  /// AI/유저 말풍선과 구분되도록 은은한 회색 톤 + info 아이콘.
  Widget _dailyDisclaimerBubble(AppLocalizations l10n, MarketLensColors mlc) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: mlc.subtleBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: mlc.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.aiChatDailyDisclaimer,
              style: AppTypography.body.copyWith(
                fontSize: AppTypography.bodySmall,
                color: mlc.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 접속 인사 카드(AI가 먼저 말을 거는 느낌). 보유 종목이 있으면 하단에
  /// '내 보유 종목 분석' CTA — 탭 시 보유 티커를 포함한 메시지를
  /// category=portfolio_holdings 로 즉시 전송.
  Widget _greetingCard(MarketLensColors mlc, bool isKo) {
    final g = _greeting!;
    final port = context.watch<PortfolioProvider>();
    final hasHoldings = port.holdings.isNotEmpty;
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mlc.infoBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: mlc.subtleBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? g.ko : g.en,
            style:
                AppTypography.body.copyWith(color: mlc.textPrimary, height: 1.5),
          ),
          if (hasHoldings) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: _analyzeHoldingsCta(mlc, l, isKo),
            ),
          ],
        ],
      ),
    );
  }

  Widget _analyzeHoldingsCta(
      MarketLensColors mlc, AppLocalizations l, bool isKo) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final isAdFree = auth.shouldHideAds || sub.isGoldActive;
    return Material(
      color: mlc.accentBlue.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: chat.isSending
            ? null
            : () => _onAnalyzeHoldingsTap(chat, isAdFree, isKo),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: mlc.accentBlue),
              const SizedBox(width: 6),
              Text(
                l.aiChatAnalyzeMyHoldings,
                style: AppTypography.label.copyWith(
                  color: mlc.accentBlue,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAnalyzeHoldingsTap(
      ChatProvider chat, bool isAdFree, bool isKo) async {
    final port = context.read<PortfolioProvider>();
    // 보유 평가액 desc 상위 8개 — 너무 많으면 메시지가 늘어져 LLM 답변 품질 ↓.
    final sorted = [...port.holdings]
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    final tickers = sorted
        .take(8)
        .map((h) => h.ticker.toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tickers.isEmpty) return;
    final joined = tickers.join(', ');
    final msg = isKo
        ? '내 보유 종목 [$joined] 오늘 흐름과 단기 전망을 한 단락으로 요약해줘.'
        : 'Summarize today\'s moves and short-term outlook for my holdings [$joined] in one paragraph.';
    await _submitText(msg, chat, isAdFree, category: 'portfolio_holdings');
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
