import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_stroke.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/multilingual.dart';
import 'transaction_row.dart';
import '../../../widgets/common/ml_key_value_row.dart';
import '../../../widgets/common/ml_show_more.dart';
import '../../../widgets/common/bento_card.dart';

/// Actions that can be returned from HoldingDetailSheet.
enum HoldingAction { additionalBuy, sell, edit, delete, viewDetail }

/// Bottom sheet showing holding details, transaction history, and action buttons.
///
/// Returns a [HoldingAction] via Navigator.pop so the caller (HoldingsTab)
/// handles further navigation with a valid context.
class HoldingDetailSheet {
  HoldingDetailSheet._();

  static Future<HoldingAction?> show(BuildContext context, PortfolioHolding holding) {
    return showModalBottomSheet<HoldingAction>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _HoldingDetailContent(
          holding: holding,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _HoldingDetailContent extends StatefulWidget {
  final PortfolioHolding holding;
  final ScrollController scrollController;

  const _HoldingDetailContent({
    required this.holding,
    required this.scrollController,
  });

  @override
  State<_HoldingDetailContent> createState() => _HoldingDetailContentState();
}

class _HoldingDetailContentState extends State<_HoldingDetailContent> {
  List<PortfolioTransaction> _transactions = [];
  bool _loadingTxn = true;
  bool _showAllTxn = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final portfolio = context.read<PortfolioProvider>();
    await portfolio.loadTransactions(ticker: widget.holding.ticker);
    if (mounted) {
      setState(() {
        _transactions = portfolio.getTransactionsForTicker(widget.holding.ticker);
        _loadingTxn = false;
      });
    }
  }

  Color _signalColor(BuildContext context, String? signal) {
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == 'STRONG_BUY' || s.contains('매수')) return context.mlColors.gainColor;
    if (s == 'SELL' || s == 'STRONG_SELL' || s.contains('매도')) return context.mlColors.lossColor;
    return context.mlColors.neutralColor;
  }

  String _signalLabel(BuildContext context, String? signal) {
    final l10n = AppLocalizations.of(context);
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == '매수권고') return l10n.scoreBuy;
    if (s == 'STRONG_BUY' || s == '적극매수') return l10n.scoreStrongBuy;
    if (s == 'SELL' || s == '매도권고') return l10n.scoreSell;
    if (s == 'STRONG_SELL' || s == '적극매도') return l10n.scoreStrongSell;
    if (s == 'HOLD' || s == '관망') return l10n.scoreHold;
    return '';
  }

  Widget _buildInlineAdvice(BuildContext context, ThemeData theme, AppLocalizations l10n, String ticker) {
    final portfolio = context.watch<PortfolioProvider>();
    final adviceList = portfolio.advice;
    final tickerAdvice = adviceList.where((a) => a.ticker == ticker).toList();
    final langCode = effectiveLanguageCode(context);
    final mlc = context.mlColors;

    if (tickerAdvice.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: mlc.textTertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.noAnalysisYet,
                style: TextStyle(fontSize: AppTypography.bodySmall, color: mlc.textTertiary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    final advice = tickerAdvice.first;

    // 흰 카드가 아니라 **틴트 안내 표면**이다. Material `Card`를 쓰면 전역
    // cardTheme(흰색·무테)과 섞여 의도가 흐려지므로 Container로 명시한다.
    return Container(
      decoration: BoxDecoration(
        color: mlc.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDensity.cardPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: mlc.accentBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.aiAdvice, style: TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold, color: mlc.accentBlue)),
              ],
            ),
            if (advice.summary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizePacked(advice.summary!, langCode),
                style: TextStyle(fontSize: AppTypography.bodyMedium, height: 1.4, color: mlc.textPrimary),
              ),
            ],
            if (advice.targetAction != null && advice.targetAction!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: mlc.groupedBackground,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.recommendedAction}: ',
                      style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.bold, color: mlc.textSecondary),
                    ),
                    Expanded(
                      child: Text(
                        localizePacked(advice.targetAction!, langCode),
                        style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.semiBold, height: 1.3, color: mlc.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (advice.bullishReasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.bullishFactorsPortfolio, style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.semiBold, color: context.mlColors.gainColor)),
              const SizedBox(height: AppSpacing.xs),
              ...advice.bullishReasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('+ ', style: TextStyle(color: context.mlColors.gainColor, fontWeight: AppTypography.bold, fontSize: AppTypography.bodySmall)),
                    Expanded(child: Text(localizePacked(r, langCode), style: const TextStyle(fontSize: AppTypography.bodySmall))),
                  ],
                ),
              )),
            ],
            if (advice.bearishReasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.bearishFactorsPortfolio, style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.semiBold, color: context.mlColors.lossColor)),
              const SizedBox(height: AppSpacing.xs),
              ...advice.bearishReasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- ', style: TextStyle(color: context.mlColors.lossColor, fontWeight: AppTypography.bold, fontSize: AppTypography.bodySmall)),
                    Expanded(child: Text(localizePacked(r, langCode), style: const TextStyle(fontSize: AppTypography.bodySmall))),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final h = widget.holding;
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && h.nameKo != null ? h.nameKo! : h.name ?? h.ticker;

    // Transaction display: show 3 or all
    final displayTxn = _showAllTxn ? _transactions : _transactions.take(3).toList();
    final hasMoreTxn = _transactions.length > 3;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl,
          AppSpacing.xxl + MediaQuery.of(context).viewPadding.bottom),
      children: [
        // ── 헤더: 핸들 + 티커 + 시그널 배지 ──
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: mlc.subtleBorder,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context, HoldingAction.viewDetail),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          h.ticker,
                          style: AppTypography.screenTitle.copyWith(
                            color: mlc.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: mlc.accentBlue,
                        ),
                      ],
                    ),
                    Text(
                      displayName,
                      style: AppTypography.body.copyWith(
                        color: mlc.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (h.signal != null && _signalLabel(context, h.signal).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _signalColor(context, h.signal),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  _signalLabel(context, h.signal),
                  style: AppTypography.badgeLabel.copyWith(
                    color: mlc.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDensity.cardGap),

        // ── 현재가 카드 (레퍼런스 ①의 "내차 예상시세" 대응) ──
        //
        // 개편 전: 헤더 오른쪽에 16px로 눌려 있어 이 시트의 히어로가 없었다.
        BentoCard(
          child: Column(
            children: [
              MlKeyValueRow(
                label: l10n.currentPrice,
                value: h.currentPrice != null
                    ? '\$${h.currentPrice!.toStringAsFixed(2)}'
                    : '',
                emphasis: MlKvEmphasis.strong,
              ),
              MlKeyValueRow(
                label: l10n.macroChangeLabel,
                value:
                    '${(h.changePct ?? 0) >= 0 ? '+' : ''}'
                    '${(h.changePct ?? 0).toStringAsFixed(2)}',
                unit: '%',
                emphasis: MlKvEmphasis.directional,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDensity.cardGap),

        // ── 보유 현황 카드 (레퍼런스 ③의 확장형 KV 대응) ──
        //
        // 개편 전: `Card(surfaceContainerHighest α0.4)` — 앱의 유일한 Material
        // Card 표면이라 다른 카드와 회색이 미세하게 달랐다. BentoCard로 통일.
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.holdingStatus,
                style: AppTypography.cardTitle.copyWith(
                  color: mlc.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MlKeyValueRow(
                label: l10n.shares,
                value:
                    h.shares?.toStringAsFixed(
                      h.shares == h.shares?.truncateToDouble() ? 0 : 2,
                    ) ??
                    '',
              ),
              MlKeyValueRow(
                label: l10n.avgPriceLabel,
                value: h.avgPrice != null
                    ? '\$${h.avgPrice!.toStringAsFixed(2)}'
                    : '',
              ),
              MlKeyValueRow(
                label: l10n.currentValueLabel,
                value: h.currentPrice != null
                    ? '\$${h.currentValue.toStringAsFixed(2)}'
                    : '',
                emphasis: MlKvEmphasis.strong,
              ),
              MlKeyValueRow(
                label: l10n.unrealizedPnl,
                value:
                    '${h.pnl >= 0 ? '+' : ''}\$${h.pnl.toStringAsFixed(2)}',
                sub:
                    '(${h.pnlPct >= 0 ? '+' : ''}'
                    '${h.pnlPct.toStringAsFixed(1)}%)',
                subColor: h.pnl >= 0 ? mlc.gainColor : mlc.lossColor,
                emphasis: MlKvEmphasis.directional,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDensity.cardGap),

        // Inline AI advice
        _buildInlineAdvice(context, theme, l10n, h.ticker),
        const SizedBox(height: AppSpacing.lg),

        // Transaction history
        Text(l10n.transactionHistory, style: const TextStyle(fontSize: AppTypography.bodyLarge, fontWeight: AppTypography.semiBold)),
        const SizedBox(height: AppSpacing.sm),
        if (_loadingTxn)
          const Center(child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(strokeWidth: AppStroke.medium),
          ))
        else if (_transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('—', style: TextStyle(color: mlc.textTertiary)),
          )
        else ...[
          ...displayTxn.map((txn) => TransactionRow(txn: txn, avgPrice: h.avgPrice ?? 0)),
          // holdings_tab의 같은 블록과 **복붙**이었다(임계값만 3 vs 5).
          // 프리미티브로 수렴 — 하드코딩 '줄이기'/'Show less'도 l10n으로.
          if (hasMoreTxn)
            MlShowMoreButton(
              expanded: _showAllTxn,
              remaining: _transactions.length - displayTxn.length,
              onPressed: () => setState(() => _showAllTxn = !_showAllTxn),
            ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // Action buttons: 2x2 grid
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.additionalBuy, style: const TextStyle(fontSize: AppTypography.bodyMedium)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                onPressed: () => Navigator.pop(context, HoldingAction.additionalBuy),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.sell, size: 18, color: context.mlColors.dangerColor),
                label: Text(l10n.partialSell, style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.dangerColor)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  side: BorderSide(color: context.mlColors.dangerColor),
                ),
                onPressed: () => Navigator.pop(context, HoldingAction.sell),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: Text(l10n.editHolding, style: const TextStyle(fontSize: AppTypography.bodyMedium)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)),
                onPressed: () => Navigator.pop(context, HoldingAction.edit),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_outline, size: 18, color: context.mlColors.dangerColor),
                label: Text(l10n.deleteHolding, style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.dangerColor)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  side: BorderSide(color: context.mlColors.dangerColor),
                ),
                onPressed: () => Navigator.pop(context, HoldingAction.delete),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

