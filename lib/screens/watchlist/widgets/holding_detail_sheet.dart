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

    if (tickerAdvice.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.noAnalysisYet,
                style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    final advice = tickerAdvice.first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.aiAdvice, style: TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold, color: theme.colorScheme.primary)),
              ],
            ),
            if (advice.summary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizePacked(advice.summary!, langCode),
                style: TextStyle(fontSize: AppTypography.bodyMedium, height: 1.4, color: theme.colorScheme.onSurface),
              ),
            ],
            if (advice.targetAction != null && advice.targetAction!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.recommendedAction}: ',
                      style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.bold, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Expanded(
                      child: Text(
                        localizePacked(advice.targetAction!, langCode),
                        style: TextStyle(fontSize: AppTypography.bodySmall, fontWeight: AppTypography.semiBold, height: 1.3, color: theme.colorScheme.onSurface),
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
        // Drag handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),
        ),

        // Header: ticker (tap→detail) + price + signal
        Row(
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
                        Text(h.ticker, style: TextStyle(fontSize: AppTypography.displayMedium, fontWeight: AppTypography.bold, color: theme.colorScheme.primary)),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.open_in_new, size: 14, color: theme.colorScheme.primary),
                      ],
                    ),
                    Text(displayName, style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (h.currentPrice != null)
                  Text('\$${h.currentPrice!.toStringAsFixed(2)}', style: const TextStyle(fontSize: AppTypography.headlineMedium, fontWeight: AppTypography.semiBold, fontFeatures: AppTypography.tabularFigures))
                else
                  Text('—', style: TextStyle(fontSize: AppTypography.headlineMedium, color: theme.colorScheme.outline)),
                Text(
                  '${(h.changePct ?? 0) >= 0 ? '+' : ''}${(h.changePct ?? 0).toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: (h.changePct ?? 0) >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor, fontFeatures: AppTypography.tabularFigures),
                ),
              ],
            ),
            if (h.signal != null && _signalLabel(context, h.signal).isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: _signalColor(context, h.signal),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  _signalLabel(context, h.signal),
                  style: TextStyle(color: context.mlColors.onPrimary, fontSize: AppTypography.caption, fontWeight: AppTypography.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Holding status card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.holdingStatus, style: TextStyle(fontSize: AppTypography.bodyMedium, fontWeight: AppTypography.semiBold, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _InfoItem(label: l10n.shares, value: h.shares?.toStringAsFixed(h.shares == h.shares?.truncateToDouble() ? 0 : 2) ?? '—'),
                    _InfoItem(label: l10n.avgPriceLabel, value: '\$${h.avgPrice?.toStringAsFixed(2) ?? '—'}'),
                    _InfoItem(label: l10n.currentValueLabel, value: h.currentPrice != null ? '\$${h.currentValue.toStringAsFixed(2)}' : '—'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${l10n.unrealizedPnl}: ',
                      style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${h.pnl >= 0 ? '+' : ''}\$${h.pnl.toStringAsFixed(2)} (${h.pnlPct >= 0 ? '+' : ''}${h.pnlPct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.semiBold,
                        color: h.pnl >= 0 ? context.mlColors.gainColor : context.mlColors.lossColor,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

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
            child: Text('—', style: TextStyle(color: theme.colorScheme.outline)),
          )
        else ...[
          ...displayTxn.map((txn) => TransactionRow(txn: txn, avgPrice: h.avgPrice ?? 0)),
          if (hasMoreTxn && !_showAllTxn)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TextButton(
                onPressed: () => setState(() => _showAllTxn = true),
                child: Text(
                  l10n.viewAllTransactions(_transactions.length),
                  style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.primary),
                ),
              ),
            )
          else if (_showAllTxn && hasMoreTxn)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllTxn = false),
                icon: Icon(Icons.keyboard_arrow_up, size: 16, color: theme.colorScheme.primary),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ko' ? '줄이기' : 'Show less',
                  style: TextStyle(fontSize: AppTypography.bodySmall, color: theme.colorScheme.primary),
                ),
              ),
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

/// 보유 상세의 라벨+값 셀. 라벨이 `colorScheme.outline`(11px, 회색 배경 위
/// 4.11:1로 AA 미달)이라 앱에서 가장 흐린 라벨이었다 — 프리미티브가 통일한다.
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MlKeyValueRow(
        label: label,
        value: value,
        layout: MlKvLayout.stack,
        dense: true,
      ),
    );
  }
}
