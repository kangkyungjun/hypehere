import 'package:flutter/material.dart';
import '../../../models/ticker_score.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Top by Market Cap section showing top 3 stocks with a "View More" button.
class TopStocksSection extends StatelessWidget {
  const TopStocksSection({
    super.key,
    required this.topStocks,
    required this.onTickerTap,
    required this.onViewMore,
  });

  final List<TickerScore> topStocks;
  final void Function(String ticker) onTickerTap;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    if (topStocks.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: mlc.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: mlc.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.topByMarketCap,
                style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              onPressed: onViewMore,
              child: Text(
                l10n.viewMore,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.semiBold,
                  color: mlc.accentBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Stock rows
        for (int i = 0; i < topStocks.length; i++) ...[
          _StockRow(
            rank: i + 1,
            stock: topStocks[i],
            onTap: () => onTickerTap(topStocks[i].ticker),
          ),
          if (i < topStocks.length - 1)
            Divider(height: AppSpacing.lg, color: mlc.subtleBorder),
        ],
      ],
    );
  }
}

/// Individual stock row: rank | ticker | name | close price | change%
class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.rank,
    required this.stock,
    required this.onTap,
  });

  final int rank;
  final TickerScore stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = (isKo && stock.nameKo != null)
        ? stock.nameKo!
        : (stock.name ?? stock.ticker);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // Rank — 오늘의집 스타일 스퀴르클 (상위권 강조)
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? mlc.infoBg : mlc.overlayDim,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: AppTypography.bold,
                  color: rank <= 3 ? mlc.accentBlue : mlc.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Ticker (bold)
            SizedBox(
              width: 56,
              child: Text(
                stock.ticker,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.bold,
                  color: mlc.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name (lighter, flexible)
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: mlc.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Close price — 큰 값 축소 방어(FittedBox)
            if (stock.close != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '\$${_formatClose(stock.close!)}',
                    style: AppTypography.changeBadge.copyWith(
                      color: mlc.textPrimary,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.md),

            // Change %
            if (stock.changePct != null) _buildChangePct(stock.changePct!, mlc),
          ],
        ),
      ),
    );
  }

  /// Format close price: comma format if >= 1000, 2 decimal places otherwise.
  String _formatClose(double price) {
    if (price >= 1000) {
      final intPart = price.truncate();
      final formatted = _addCommas(intPart);
      final decimal = ((price - intPart) * 100).round();
      if (decimal == 0) return formatted;
      return '$formatted.${decimal.toString().padLeft(2, '0')}';
    }
    return price.toStringAsFixed(2);
  }

  /// Add commas to integer part (e.g. 1234567 -> "1,234,567").
  String _addCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Build change percentage text with arrow and gain/loss color.
  Widget _buildChangePct(double pct, MarketLensColors mlc) {
    final String arrow;
    final Color color;

    if (pct > 0) {
      arrow = '\u25B2'; // ▲
      color = mlc.gainColor;
    } else if (pct < 0) {
      arrow = '\u25BC'; // ▼
      color = mlc.lossColor;
    } else {
      arrow = '\u2500'; // ─
      color = mlc.neutralColor;
    }

    final sign = pct >= 0 ? '+' : '';

    return Text(
      '$arrow $sign${pct.toStringAsFixed(1)}%',
      style: AppTypography.numericSecondary.copyWith(
        color: color,
        fontWeight: AppTypography.semiBold,
      ),
    );
  }
}
