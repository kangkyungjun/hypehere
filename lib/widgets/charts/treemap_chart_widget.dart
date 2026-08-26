import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/treemap_data.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_typography.dart';
import '../common/ml_divider.dart';

/// 2-level drilldown treemap widget
///
/// Level 1: Sector view — each rectangle is a sector, sized by totalTradingValue
/// Level 2: Ticker view — each rectangle is a ticker within a sector, sized by tradingValue
///
/// Uses squarified treemap algorithm with CustomPainter for rendering.
class TreemapChartWidget extends StatefulWidget {
  final TreemapData data;
  final Function(String ticker) onTickerTap;

  const TreemapChartWidget({
    super.key,
    required this.data,
    required this.onTickerTap,
  });

  @override
  State<TreemapChartWidget> createState() => _TreemapChartWidgetState();
}

class _TreemapChartWidgetState extends State<TreemapChartWidget> {
  TreemapSector? _currentSector; // null = sector view, non-null = ticker view

  void _goBack() => setState(() => _currentSector = null);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chartHeight = screenWidth > 600 ? 450.0 : 350.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back header (only in ticker view)
        if (_currentSector != null)
          GestureDetector(
            onTap: _goBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: context.mlColors.accentBlue,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      _currentSector!.sector,
                      style: TextStyle(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.semiBold,
                        color: context.mlColors.accentBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Treemap
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: double.infinity,
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final nodes = _computeLayout(size);

                return GestureDetector(
                  onTapDown: (details) => _onTap(details.localPosition, nodes),
                  child: CustomPaint(
                    size: size,
                    painter: _TreemapPainter(
                      nodes: nodes,
                      isSectorView: _currentSector == null,
                      borderColor: context.mlColors.cardBackground,
                      mlColors: context.mlColors,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_TreemapNode> _computeLayout(Size size) {
    if (_currentSector == null) {
      // Level 1: Sector view
      final items =
          widget.data.sectors
              .where(
                (s) => s.totalTradingValue != null && s.totalTradingValue! > 0,
              )
              .toList()
            ..sort(
              (a, b) => (b.totalTradingValue ?? 0).compareTo(
                a.totalTradingValue ?? 0,
              ),
            );

      if (items.isEmpty) return [];

      final entries = items
          .map(
            (s) => _SquarifyEntry(value: s.totalTradingValue ?? 1.0, data: s),
          )
          .toList();

      return _squarify(entries, Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      // Level 2: Ticker view
      final items =
          _currentSector!.items
              .where((t) => t.tradingValue != null && t.tradingValue! > 0)
              .toList()
            ..sort(
              (a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0),
            );

      // Include items with null trading value at minimum size
      final nullItems = _currentSector!.items
          .where((t) => t.tradingValue == null || t.tradingValue == 0)
          .toList();

      final minValue = items.isNotEmpty ? items.last.tradingValue! * 0.1 : 1.0;

      final entries = [
        ...items.map((t) => _SquarifyEntry(value: t.tradingValue!, data: t)),
        ...nullItems.map((t) => _SquarifyEntry(value: minValue, data: t)),
      ];

      if (entries.isEmpty) return [];

      return _squarify(entries, Rect.fromLTWH(0, 0, size.width, size.height));
    }
  }

  void _onTap(Offset position, List<_TreemapNode> nodes) {
    for (final node in nodes) {
      if (node.rect.contains(position)) {
        if (_currentSector == null) {
          // Level 1: Sector view
          final w = node.rect.width;
          final h = node.rect.height;
          if (w < 40 || h < 25) {
            _showSmallSectorsModal(nodes);
          } else {
            final sector = node.data as TreemapSector;
            setState(() => _currentSector = sector);
          }
        } else {
          // Level 2: Ticker view
          final w = node.rect.width;
          final h = node.rect.height;
          if (w < 50 || h < 30) {
            _showSmallTickersModal(nodes);
          } else {
            final item = node.data as TreemapItem;
            widget.onTickerTap(item.ticker);
          }
        }
        return;
      }
    }
  }

  void _showSmallSectorsModal(List<_TreemapNode> nodes) {
    final smallSectors =
        nodes
            .where((n) => n.rect.width < 40 || n.rect.height < 25)
            .map((n) => n.data as TreemapSector)
            .toList()
          ..sort(
            (a, b) =>
                (b.totalTradingValue ?? 0).compareTo(a.totalTradingValue ?? 0),
          );

    if (smallSectors.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mlc = ctx.mlColors;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: mlc.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mlc.textSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.otherSectors,
                          style: TextStyle(
                            fontSize: AppTypography.headlineMedium,
                            fontWeight: AppTypography.bold,
                            color: mlc.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.nItems(smallSectors.length),
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          color: mlc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const MlDivider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: smallSectors.length,
                    itemBuilder: (ctx, i) {
                      final sector = smallSectors[i];
                      final changePct = sector.avgChangePct;
                      final changeText = changePct != null
                          ? '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%'
                          : '-';
                      final itemMlc = ctx.mlColors;
                      final changeColor = changePct == null
                          ? itemMlc.neutralColor
                          : changePct >= 0
                          ? itemMlc.gainColor
                          : itemMlc.lossColor;

                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() => _currentSector = sector);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sector.sector,
                                  style: TextStyle(
                                    fontSize: AppTypography.bodyLarge,
                                    fontWeight: AppTypography.bold,
                                    color: itemMlc.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                l10n.nTickers(sector.tickerCount),
                                style: TextStyle(
                                  fontSize: AppTypography.bodySmall,
                                  color: itemMlc.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(
                                changeText,
                                style: TextStyle(
                                  fontSize: AppTypography.bodyLarge,
                                  fontWeight: AppTypography.semiBold,
                                  color: changeColor,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  sector.formattedTradingValue,
                                  style: TextStyle(
                                    fontSize: AppTypography.bodySmall,
                                    color: itemMlc.textSecondary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSmallTickersModal(List<_TreemapNode> nodes) {
    final smallTickers =
        nodes
            .where((n) => n.rect.width < 50 || n.rect.height < 30)
            .map((n) => n.data as TreemapItem)
            .toList()
          ..sort(
            (a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0),
          );

    if (smallTickers.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mlc = ctx.mlColors;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: mlc.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mlc.textSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.otherTickers,
                          style: TextStyle(
                            fontSize: AppTypography.headlineMedium,
                            fontWeight: AppTypography.bold,
                            color: mlc.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.nItems(smallTickers.length),
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          color: mlc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const MlDivider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: smallTickers.length,
                    itemBuilder: (ctx, i) =>
                        _buildTickerRow(ctx, smallTickers[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTickerRow(BuildContext ctx, TreemapItem item) {
    final changePct = item.changePct;
    final changeText = changePct != null
        ? '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%'
        : '-';
    final mlc = ctx.mlColors;
    final changeColor = changePct == null
        ? mlc.neutralColor
        : changePct >= 0
        ? mlc.gainColor
        : mlc.lossColor;

    return InkWell(
      onTap: () {
        Navigator.of(ctx).pop();
        widget.onTickerTap(item.ticker);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ticker,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.bold,
                      color: ctx.mlColors.textPrimary,
                    ),
                  ),
                  if (item.name != null)
                    Text(
                      item.name!,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: ctx.mlColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              changeText,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: AppTypography.semiBold,
                color: changeColor,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: 60,
              child: Text(
                item.formattedTradingValue,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: ctx.mlColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Squarified treemap layout algorithm
  List<_TreemapNode> _squarify(List<_SquarifyEntry> entries, Rect bounds) {
    if (entries.isEmpty) return [];

    final totalValue = entries.fold(0.0, (sum, e) => sum + e.value);
    if (totalValue <= 0) return [];

    final result = <_TreemapNode>[];
    var remaining = bounds;
    var currentRow = <_SquarifyEntry>[];
    var currentRowValue = 0.0;
    var remainingValue = totalValue;

    for (final entry in entries) {
      final testRow = [...currentRow, entry];
      final testRowValue = currentRowValue + entry.value;

      if (currentRow.isEmpty ||
          _worstRatio(testRow, testRowValue, remaining, remainingValue) <=
              _worstRatio(
                currentRow,
                currentRowValue,
                remaining,
                remainingValue,
              )) {
        currentRow = testRow;
        currentRowValue = testRowValue;
      } else {
        // Layout current row
        final rowResult = _layoutRow(
          currentRow,
          currentRowValue,
          remaining,
          remainingValue,
        );
        result.addAll(rowResult.nodes);
        remaining = rowResult.remaining;
        remainingValue -= currentRowValue;

        currentRow = [entry];
        currentRowValue = entry.value;
      }
    }

    // Layout last row
    if (currentRow.isNotEmpty) {
      final rowResult = _layoutRow(
        currentRow,
        currentRowValue,
        remaining,
        remainingValue,
      );
      result.addAll(rowResult.nodes);
    }

    return result;
  }

  double _worstRatio(
    List<_SquarifyEntry> row,
    double rowValue,
    Rect bounds,
    double totalValue,
  ) {
    if (row.isEmpty || totalValue <= 0 || rowValue <= 0) return double.infinity;

    final fraction = rowValue / totalValue;
    final isHorizontal = bounds.width >= bounds.height;
    final shortSide = isHorizontal ? bounds.height : bounds.width;
    final longSide = isHorizontal
        ? bounds.width * fraction
        : bounds.height * fraction;

    if (shortSide <= 0 || longSide <= 0) return double.infinity;

    double worst = 0;
    for (final entry in row) {
      final entryFraction = entry.value / rowValue;
      final w = isHorizontal ? longSide : shortSide;
      final h = isHorizontal ? shortSide * entryFraction : longSide;
      final actualW = isHorizontal ? w : shortSide;
      final actualH = isHorizontal ? h : longSide * entryFraction;

      if (actualW <= 0 || actualH <= 0) continue;
      final ratio = max(actualW / actualH, actualH / actualW);
      worst = max(worst, ratio);
    }
    return worst;
  }

  _LayoutResult _layoutRow(
    List<_SquarifyEntry> row,
    double rowValue,
    Rect bounds,
    double totalValue,
  ) {
    if (totalValue <= 0 || rowValue <= 0) {
      return _LayoutResult(nodes: [], remaining: bounds);
    }

    final fraction = rowValue / totalValue;
    final isHorizontal = bounds.width >= bounds.height;
    final nodes = <_TreemapNode>[];

    if (isHorizontal) {
      final rowWidth = bounds.width * fraction;
      var y = bounds.top;
      for (final entry in row) {
        final entryHeight = bounds.height * (entry.value / rowValue);
        nodes.add(
          _TreemapNode(
            rect: Rect.fromLTWH(bounds.left, y, rowWidth, entryHeight),
            data: entry.data,
          ),
        );
        y += entryHeight;
      }
      return _LayoutResult(
        nodes: nodes,
        remaining: Rect.fromLTWH(
          bounds.left + rowWidth,
          bounds.top,
          bounds.width - rowWidth,
          bounds.height,
        ),
      );
    } else {
      final rowHeight = bounds.height * fraction;
      var x = bounds.left;
      for (final entry in row) {
        final entryWidth = bounds.width * (entry.value / rowValue);
        nodes.add(
          _TreemapNode(
            rect: Rect.fromLTWH(x, bounds.top, entryWidth, rowHeight),
            data: entry.data,
          ),
        );
        x += entryWidth;
      }
      return _LayoutResult(
        nodes: nodes,
        remaining: Rect.fromLTWH(
          bounds.left,
          bounds.top + rowHeight,
          bounds.width,
          bounds.height - rowHeight,
        ),
      );
    }
  }
}

/// CustomPainter for treemap rendering
class _TreemapPainter extends CustomPainter {
  final List<_TreemapNode> nodes;
  final bool isSectorView;
  final Color borderColor;
  final MarketLensColors mlColors;

  _TreemapPainter({
    required this.nodes,
    required this.isSectorView,
    required this.borderColor,
    required this.mlColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSectorView ? 1.0 : 0.6;

    for (final node in nodes) {
      final rect = node.rect;
      if (rect.width < 1 || rect.height < 1) continue;

      // Fill color
      final Color fillColor;
      if (isSectorView) {
        fillColor = (node.data as TreemapSector).changeColorOf(mlColors);
      } else {
        fillColor = (node.data as TreemapItem).changeColorOf(mlColors);
      }

      canvas.drawRect(rect, Paint()..color = fillColor);
      canvas.drawRect(rect, borderPaint);

      // Text rendering
      _drawNodeText(canvas, rect, node.data);
    }
  }

  void _drawNodeText(Canvas canvas, Rect rect, dynamic data) {
    final w = rect.width;
    final h = rect.height;

    if (isSectorView) {
      final sector = data as TreemapSector;
      _drawSectorText(canvas, rect, sector, w, h);
    } else {
      final item = data as TreemapItem;
      _drawTickerText(canvas, rect, item, w, h);
    }
  }

  void _drawSectorText(
    Canvas canvas,
    Rect rect,
    TreemapSector sector,
    double w,
    double h,
  ) {
    if (w < 40 || h < 25) return; // too small for text

    final lines = <_TextLine>[];

    if (w >= 100 && h >= 60) {
      // Large: sector name + change% + trading value
      lines.add(
        _TextLine(
          _shortenSector(sector.sector, w),
          AppTypography.bodyMedium,
          AppTypography.bold,
        ),
      );
      if (sector.avgChangePct != null) {
        final sign = sector.avgChangePct! >= 0 ? '+' : '';
        lines.add(
          _TextLine(
            '$sign${sector.avgChangePct!.toStringAsFixed(2)}%',
            AppTypography.bodySmall,
            AppTypography.medium,
          ),
        );
      }
      lines.add(
        _TextLine(
          sector.formattedTradingValue,
          AppTypography.caption,
          AppTypography.regular,
        ),
      );
    } else if (w >= 60 && h >= 40) {
      // Medium: sector name + change%
      lines.add(
        _TextLine(
          _shortenSector(sector.sector, w),
          AppTypography.caption,
          AppTypography.bold,
        ),
      );
      if (sector.avgChangePct != null) {
        final sign = sector.avgChangePct! >= 0 ? '+' : '';
        lines.add(
          _TextLine(
            '$sign${sector.avgChangePct!.toStringAsFixed(1)}%',
            AppTypography.micro,
            AppTypography.medium,
          ),
        );
      }
    } else {
      // Small: abbreviated sector name only
      lines.add(
        _TextLine(_abbreviateSector(sector.sector), 9, AppTypography.bold),
      );
    }

    _paintLines(canvas, rect, lines);
  }

  void _drawTickerText(
    Canvas canvas,
    Rect rect,
    TreemapItem item,
    double w,
    double h,
  ) {
    if (w < 25 || h < 18) return; // too small for text

    final lines = <_TextLine>[];

    if (w >= 80 && h >= 55) {
      // Large: ticker + name + change% + trading value
      lines.add(
        _TextLine(item.ticker, AppTypography.bodyMedium, AppTypography.bold),
      );
      if (item.name != null) {
        final displayName = item.name!.length > 12
            ? '${item.name!.substring(0, 10)}..'
            : item.name!;
        lines.add(
          _TextLine(displayName, AppTypography.micro, AppTypography.regular),
        );
      }
      if (item.changePct != null) {
        final sign = item.changePct! >= 0 ? '+' : '';
        lines.add(
          _TextLine(
            '$sign${item.changePct!.toStringAsFixed(2)}%',
            AppTypography.caption,
            AppTypography.medium,
          ),
        );
      }
      lines.add(
        _TextLine(
          item.formattedTradingValue,
          AppTypography.micro,
          AppTypography.regular,
        ),
      );
    } else if (w >= 50 && h >= 30) {
      // Medium: ticker + change%
      lines.add(
        _TextLine(item.ticker, AppTypography.caption, AppTypography.bold),
      );
      if (item.changePct != null) {
        final sign = item.changePct! >= 0 ? '+' : '';
        lines.add(
          _TextLine(
            '$sign${item.changePct!.toStringAsFixed(1)}%',
            AppTypography.micro,
            AppTypography.medium,
          ),
        );
      }
    } else if (w >= 30) {
      // Small: ticker only
      lines.add(_TextLine(item.ticker, 9, AppTypography.bold));
    }

    _paintLines(canvas, rect, lines);
  }

  void _paintLines(Canvas canvas, Rect rect, List<_TextLine> lines) {
    if (lines.isEmpty) return;

    final totalHeight = lines.fold(0.0, (sum, line) => sum + line.fontSize + 3);
    var y = rect.center.dy - totalHeight / 2;

    for (final line in lines) {
      final tp = TextPainter(
        text: TextSpan(
          text: line.text,
          style: TextStyle(
            color: mlColors.onPrimary,
            fontSize: line.fontSize,
            fontWeight: line.fontWeight,
            shadows: AppShadow.textDrop,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '..',
      );
      tp.layout(maxWidth: rect.width - 6);
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, y));
      y += line.fontSize + 3;
    }
  }

  String _shortenSector(String sector, double maxWidth) {
    // Shorten common long sector names
    const abbreviations = {
      'Information Technology': 'Info Tech',
      'Communication Services': 'Comm Services',
      'Consumer Discretionary': 'Cons Discret',
      'Consumer Staples': 'Cons Staples',
      'Health Care': 'Health Care',
      'Real Estate': 'Real Estate',
    };
    if (maxWidth < 120) {
      return abbreviations[sector] ?? sector;
    }
    return sector;
  }

  String _abbreviateSector(String sector) {
    const abbr = {
      'Information Technology': 'IT',
      'Communication Services': 'Comm',
      'Consumer Discretionary': 'CDisc',
      'Consumer Staples': 'CStap',
      'Health Care': 'HC',
      'Financials': 'Fin',
      'Industrials': 'Ind',
      'Materials': 'Mat',
      'Real Estate': 'RE',
      'Utilities': 'Util',
      'Energy': 'Enrg',
    };
    return abbr[sector] ??
        (sector.length > 4 ? sector.substring(0, 4) : sector);
  }

  @override
  bool shouldRepaint(_TreemapPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.isSectorView != isSectorView ||
        oldDelegate.borderColor != borderColor;
  }
}

// --- Internal data structures ---

class _SquarifyEntry {
  final double value;
  final dynamic data; // TreemapSector or TreemapItem

  _SquarifyEntry({required this.value, required this.data});
}

class _TreemapNode {
  final Rect rect;
  final dynamic data;

  _TreemapNode({required this.rect, required this.data});
}

class _LayoutResult {
  final List<_TreemapNode> nodes;
  final Rect remaining;

  _LayoutResult({required this.nodes, required this.remaining});
}

class _TextLine {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  _TextLine(this.text, this.fontSize, this.fontWeight);
}
