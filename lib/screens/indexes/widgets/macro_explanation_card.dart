import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/macro_explanation_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 거시 지표(VIX 등) 상세 화면의 차트 아래 끼우는 AI 변동성 설명 카드.
///   - 진입 시 자동 로드(로컬 캐시 우선 → 서버 캐시 → 큐 폴링)
///   - 🔄 누르면 force=true 로 강제 재요청
///   - SelectionArea로 텍스트 long-press 복사 가능
///
/// 게이트 콜백:
///   - [onAutoRefresh]: 자동 로드에서 캐시 miss → 서버 호출 직전. 호출자가
///     쿼터 차감/광고 게이트 수행. [GateResult.allow]면 진행, [GateResult.needAd]면
///     카드 자리에 "광고 보고 분석 받기" CTA만 표시 + 카드는 호출자에게 광고 시청
///     완료 후 [retryAutoLoad]를 호출하라고 안내.
///   - [onForceRefresh]: 🔄 직전. 쿼터 게이트 + (소진이면 그 자리 광고 다이얼로그).
///     false 반환 시 차단.
class MacroExplanationCard extends StatefulWidget {
  const MacroExplanationCard({
    super.key,
    required this.indicatorCode,
    required this.lang,
    required this.recentValues,
    this.onAutoRefresh,
    this.onWatchAdForAuto,
    this.onForceRefresh,
  });

  /// 'VIX' 등 대문자 권장. 내부에서 toUpperCase.
  final String indicatorCode;

  /// 'ko' | 'en' — 그 외는 서버가 en 폴백.
  final String lang;

  /// 오름차순 (오래된 → 최신) 시점 리스트. 각 원소: {date: 'YYYY-MM-DD', value: 18.5}.
  final List<Map<String, Object>> recentValues;

  /// 자동 로드(캐시 miss 시) 직전 호출. 호출자가 쿼터/광고 게이트.
  final Future<MacroAutoGateResult> Function()? onAutoRefresh;

  /// CTA 탭 시 호출 — 호출자가 광고 다이얼로그 + 보상 처리. true면 카드가 자동 재시도.
  final Future<bool> Function()? onWatchAdForAuto;

  /// 🔄 강제 재요청 직전 호출. false 반환 시 차단.
  final Future<bool> Function()? onForceRefresh;

  @override
  State<MacroExplanationCard> createState() => _MacroExplanationCardState();
}

class _MacroExplanationCardState extends State<MacroExplanationCard> {
  final MacroExplanationService _svc = MacroExplanationService();
  bool _loading = true;
  bool _refreshing = false;
  bool _needsAdForAuto = false; // 자동 로드 쿼터 소진 — CTA 표시
  MacroExplanation? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(force: false));
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Future<void> _load({required bool force}) async {
    if (!mounted) return;
    setState(() {
      if (force) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = null;
      _needsAdForAuto = false;
    });

    try {
      // 1) 로컬 캐시 우선 (force일 때는 스킵)
      if (!force) {
        final cached = await _svc.readLocalCache(
          widget.indicatorCode,
          widget.lang,
        );
        if (cached != null && cached.content != null && !cached.isError) {
          if (!mounted) return;
          setState(() {
            _result = cached;
            _loading = false;
            _refreshing = false;
          });
          return;
        }
      }

      // 2) 자동 로드(force=false) 게이트 — 캐시 miss 시 호출자에게 쿼터 차감 위임.
      //    - allow: 진행
      //    - needAd: 카드 자리에 CTA(광고 보고 받기) 표시 후 종료. 사용자 탭으로 _retryAutoLoadAfterAd
      //    - block: 폴백 안내(보통 onForceRefresh 쪽 경로)
      if (!force && widget.onAutoRefresh != null) {
        final gate = await widget.onAutoRefresh!();
        if (!mounted) return;
        switch (gate) {
          case MacroAutoGateResult.allow:
            break;
          case MacroAutoGateResult.needAd:
            setState(() {
              _loading = false;
              _refreshing = false;
              _needsAdForAuto = true;
            });
            return;
          case MacroAutoGateResult.block:
            setState(() {
              _loading = false;
              _refreshing = false;
              _errorMessage = 'blocked';
            });
            return;
        }
      }

      // 3) 서버 요청 (server-side 캐시 hit → 즉시 done / miss → pending+request_id)
      final first = await _svc.request(
        indicatorCode: widget.indicatorCode,
        lang: widget.lang,
        recentValues: widget.recentValues,
        force: force,
      );

      if (first.status == 'done' || first.status == 'error') {
        if (!mounted) return;
        setState(() {
          _result = first;
          _loading = false;
          _refreshing = false;
        });
        return;
      }

      // 4) pending → 폴링
      final polled = await _svc.poll(first.requestId!);
      if (!mounted) return;
      setState(() {
        _result = polled;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// CTA 탭 → 호출자에게 광고 다이얼로그 + 보상 위임 → 성공 시 자동 재로드.
  Future<void> _onCtaTap() async {
    if (_refreshing || _loading) return;
    final cb = widget.onWatchAdForAuto;
    if (cb == null) return;
    setState(() => _refreshing = true);
    final ok = await cb();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (ok) {
      await _load(force: false);
    }
  }

  Future<void> _onForceRefresh() async {
    if (_refreshing || _loading) return;
    final gate = widget.onForceRefresh;
    if (gate != null) {
      final allowed = await gate();
      if (!allowed) return;
    }
    await _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final l = AppLocalizations.of(context);
    final isLoading = _loading || _refreshing;
    final hasContent = _result?.content != null && _result!.content!.isNotEmpty;
    final showCta = !isLoading && _needsAdForAuto && !hasContent;
    final hasError = !isLoading && !showCta &&
        (_errorMessage != null || _result == null || _result!.isError || !hasContent);

    return SelectionArea(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: mlc.infoBg.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:
              Border.all(color: mlc.subtleBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: mlc.accentBlue),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l.macroAiCardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: mlc.accentBlue,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l.macroAiCardRetry,
                  onPressed: isLoading ? null : _onForceRefresh,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: _refreshing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: mlc.accentBlue,
                          ),
                        )
                      : Icon(Icons.refresh, color: mlc.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              _loadingBody(l, mlc)
            else if (showCta)
              _ctaBody(l, mlc)
            else if (hasError)
              _errorBody(l, mlc)
            else
              _contentBody(mlc),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.macroAiCardCadence,
              style: AppTypography.label.copyWith(color: mlc.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody(AppLocalizations l, MarketLensColors mlc) {
    return Row(
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
          l.macroAiCardLoading,
          style: AppTypography.body.copyWith(color: mlc.textSecondary),
        ),
      ],
    );
  }

  Widget _errorBody(AppLocalizations l, MarketLensColors mlc) {
    return Text(
      l.macroAiCardError,
      style: AppTypography.body.copyWith(color: mlc.textSecondary, height: 1.5),
    );
  }

  Widget _contentBody(MarketLensColors mlc) {
    return Text(
      _result!.content!,
      style: AppTypography.body.copyWith(color: mlc.textPrimary, height: 1.5),
    );
  }

  Widget _ctaBody(AppLocalizations l, MarketLensColors mlc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.macroAiCardWatchAdCta,
          style:
              AppTypography.body.copyWith(color: mlc.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: mlc.accentBlue.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: _refreshing ? null : _onCtaTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 16, color: mlc.accentBlue),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.macroAiCardWatchAdAction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: mlc.accentBlue,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 자동 로드 게이트 결과. 호출자(macro_history_screen)가 반환.
enum MacroAutoGateResult {
  /// 차감 OK, 서버 호출 진행.
  allow,

  /// 쿼터 소진 — 카드 자리에 광고 CTA 표시. 사용자가 탭하면 광고 시청 후 다시 시도.
  needAd,

  /// 차단 (예: 광고 시청 거부 + 폴백). 카드는 에러 상태로 표시.
  block,
}
