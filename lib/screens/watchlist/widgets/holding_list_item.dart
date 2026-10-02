import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/portfolio_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/bento_card.dart';

/// A single holding row in the portfolio section.
///
/// Layout:
/// [Score] [Ticker + name + shares@price + 📅date] [Value + P&L%] [Signal] [✏️]
class HoldingListItem extends StatelessWidget {
  final PortfolioHolding holding;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HoldingListItem({
    super.key,
    required this.holding,
    required this.onTap,
    required this.onDelete,
  });

  Color _signalColor(BuildContext context, String? signal) {
    final s = signal?.toUpperCase() ?? '';
    if (s == 'BUY' || s == 'STRONG_BUY' || s.contains('매수')) {
      return context.mlColors.gainColor;
    }
    if (s == 'SELL' || s == 'STRONG_SELL' || s.contains('매도')) {
      return context.mlColors.lossColor;
    }
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

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKo && holding.nameKo != null
        ? holding.nameKo!
        : holding.name ?? holding.ticker;

    return Dismissible(
      key: Key('holding_${holding.ticker}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.confirm),
                content: Text(l10n.removeHoldingConfirm(holding.ticker)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: context.mlColors.dangerColor,
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.mlColors.dangerColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Icon(Icons.delete, color: context.mlColors.onPrimary),
      ),
      child: BentoCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: onTap,
        child: Row(
          children: [
            // Score box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: holding.score != null
                    ? _signalColor(
                        context,
                        holding.signal,
                      ).withValues(alpha: 0.1)
                    : context.mlColors.groupedBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              // ⚠️ 48px 고정 박스 안의 텍스트에는 **명시적 행간이 필수**다.
              // 비워두면 Pretendard 기본 행간(~1.45)으로 렌더돼
              // (16+11) × 1.45 × 1.3배 = 50.9 > 48로 넘친다.
              // 1.2로 고정하면 1.3배에서도 42.1 < 48로 들어간다.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    holding.score?.toStringAsFixed(0) ?? '—',
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      height: 1.2,
                      color: holding.score != null
                          ? _signalColor(context, holding.signal)
                          : context.mlColors.textTertiary,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                  Text(
                    l10n.score,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      height: 1.2,
                      color: mlc.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // Ticker + name + shares@price + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 티커. **절대 줄이지 않는다.**
                  //
                  // 처음엔 변경 표시를 같은 Row에 Flexible로 넣었다가
                  // `BK → ...`로 새 티커가 잘리고, 상장폐지 행에서는
                  // `거래종료`에 밀려 **티커가 통째로 사라졌다**. 어느
                  // 종목인지 못 읽는 건 원래 버그보다 나쁘다.
                  // 좁은 칼럼에서 둘을 경쟁시키면 안 된다 — 줄을 나눈다.
                  Text(
                    holding.ticker,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                  ),

                  // 정체성 변경 표시 (S6). 서버가 개명 종목의 가격·점수를
                  // **새 심볼로 조인해서** 내려준다. 여기서 말해 주지
                  // 않으면 사용자는 아래 숫자가 저장된 티커의 것이라고 믿는다.
                  // caption(11) + 2줄 허용. bodySmall(13)로 뒀더니 좁은
                  // 기기(320px) × 최대 배율(1.3)에서 `→ ...`로 잘렸다.
                  // 화살표가 아무것도 가리키지 않는 표시는 없느니만 못하다.
                  // 2줄까지 흘러가게 두면 최악의 경우에도 읽을 수 있다.
                  if (holding.resolvedTicker != null)
                    Text(
                      '→ ${holding.resolvedTicker}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: AppTypography.bold,
                        color: mlc.accentBlue,
                      ),
                    )
                  else if (holding.isDelisted)
                    Text(
                      l10n.delistedShort,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: AppTypography.semiBold,
                        color: mlc.textTertiary,
                      ),
                    ),

                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: mlc.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (holding.shares != null && holding.avgPrice != null)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.sharesAtPrice(
                              holding.shares!.toStringAsFixed(
                                holding.shares! ==
                                        holding.shares!.truncateToDouble()
                                    ? 0
                                    : 2,
                              ),
                              holding.avgPrice!.toStringAsFixed(2),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: mlc.textSecondary,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ),
                        if (holding.createdAt != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: mlc.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            _formatDate(holding.createdAt!),
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: mlc.textSecondary,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // Current value + P&L%
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (holding.currentPrice != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$${holding.currentValue.toStringAsFixed(2)}',
                      // 행의 히어로 값(평가액) — priceCard(17).
                      style: AppTypography.priceCard.copyWith(
                        color: mlc.textPrimary,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${holding.pnlPct >= 0 ? '▲' : '▼'} ${holding.pnlPct.abs().toStringAsFixed(2)}%',
                    // 방향성 수치 — changeBadge(14 w700). 크기는 그대로 두고
                    // 굵기만 승격해 오버플로 위험 없이 대비를 얻는다.
                    style: AppTypography.changeBadge.copyWith(
                      color: holding.pnlPct >= 0
                          ? context.mlColors.gainColor
                          : context.mlColors.lossColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // Signal pill
            if (holding.signal != null &&
                _signalLabel(context, holding.signal).isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _signalColor(context, holding.signal),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  _signalLabel(context, holding.signal),
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),

            // Chevron
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: mlc.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
