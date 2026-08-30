import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';

String _formatRelativeTime(DateTime dt, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(dt.year, dt.month, dt.day);
  final timeStr = DateFormat('HH:mm').format(dt);

  if (dateDay == today) {
    return '${l10n.today} $timeStr';
  } else if (dateDay == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} $timeStr';
  } else {
    return DateFormat('M/d HH:mm').format(dt);
  }
}

/// Card showing portfolio totals in a 2x2 grid layout.
///
/// Only displayed when logged in AND has holdings.
class PortfolioSummaryCard extends StatelessWidget {
  final PortfolioProvider portfolio;

  /// 카드 타이틀 (기본: 보유 요약). 프로필 등에서 다른 제목으로 재사용 가능.
  final String? title;

  /// 외부 패딩 (기본: 좌우 16·상하 12). 부모가 이미 패딩을 줄 땐 zero 전달.
  final EdgeInsetsGeometry? outerPadding;

  const PortfolioSummaryCard({
    super.key,
    required this.portfolio,
    this.title,
    this.outerPadding,
  });

  static final _moneyFormat = NumberFormat('#,##0.00', 'en_US');

  String _formatMoney(double value) {
    final formatted = _moneyFormat.format(value.abs());
    return '${value < 0 ? '-' : ''}\$$formatted';
  }

  String _formatPct(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  String _formatMoneyWithSign(double value) {
    final formatted = _moneyFormat.format(value.abs());
    final sign = value >= 0 ? '+' : '-';
    return '$sign\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final totalCost = portfolio.totalCost;
    final totalPnl = portfolio.totalPnl;
    final totalPnlPct = portfolio.totalPnlPct;
    final totalValue = portfolio.totalValue;

    final isGain = totalPnlPct >= 0;
    final pnlColor = isGain
        ? context.mlColors.gainColor
        : context.mlColors.lossColor;

    return Padding(
      padding: outerPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
      child: BentoCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + last update time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? l10n.holdingsSummary,
                  style: AppTypography.cardTitle.copyWith(
                    color: context.mlColors.textSecondary,
                  ),
                ),
                if (portfolio.lastRefreshedAt != null)
                  Text(
                    l10n.lastUpdateTime(
                      _formatRelativeTime(portfolio.lastRefreshedAt!, l10n),
                    ),
                    style: AppTypography.label.copyWith(
                      color: context.mlColors.textTertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Row 1: 수익률 | 매수금
            Row(
              children: [
                Expanded(
                  child: _GridCell(
                    label: l10n.returnRate,
                    value:
                        '${totalPnlPct >= 0 ? '▲' : '▼'} ${totalPnlPct.abs().toStringAsFixed(2)}%',
                    // 2순위 — 히어로(평가금 30) 다음 가는 값.
                    valueStyle: AppTypography.changeHero.copyWith(
                      color: pnlColor,
                    ),
                  ),
                ),
                Expanded(
                  child: _GridCell(
                    label: l10n.purchaseAmount,
                    // 보조값 — bold 해제(카드당 w700은 히어로 1개만).
                    valueStyle: AppTypography.kvValue.copyWith(
                      color: context.mlColors.textPrimary,
                    ),
                    value: _formatMoney(totalCost),
                  ),
                ),
              ],
            ),

            Divider(
              height: AppSpacing.xxl,
              thickness: 0.5,
              color: context.mlColors.subtleBorder,
            ),

            // Row 2: 수익금 | 평가금
            Row(
              children: [
                Expanded(
                  child: _GridCell(
                    label: l10n.profitAmount,
                    value: _formatMoneyWithSign(totalPnl),
                    // 보조값 — bold 해제. 방향은 색이 이미 말해준다.
                    valueStyle: AppTypography.kvValue.copyWith(color: pnlColor),
                    subValue: '(${_formatPct(totalPnlPct)})',
                    subValueColor: pnlColor,
                  ),
                ),
                Expanded(
                  child: _GridCell(
                    label: l10n.evaluationAmount,
                    value: _formatMoney(totalValue),
                    // ★ 이 카드의 유일한 히어로 — 총자산.
                    // 개편 전 14px으로 수익률(16)보다 작아 위계가 역전돼 있었다.
                    valueStyle: AppTypography.priceLarge.copyWith(
                      color: context.mlColors.textPrimary,
                    ),
                    subValue: '(${_formatPct(totalPnlPct)})',
                    subValueColor: pnlColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final String? subValue;
  final Color? subValueColor;

  const _GridCell({
    required this.label,
    required this.value,
    required this.valueStyle,
    this.subValue,
    this.subValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: context.mlColors.textSecondary,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: valueStyle),
        ),
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.medium,
              color: subValueColor,
            ),
          ),
      ],
    );
  }
}
