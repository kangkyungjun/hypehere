import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/mention_bubble_data.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/ticker_detail/ticker_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_typography.dart';
import '../common/bento_card.dart';

/// Circle-packing bubble chart showing the most-mentioned tickers
/// in the last 24 hours of news. Tap a bubble to navigate to
/// TickerDetailScreen scrolled to the news section.
class MentionBubbleCard extends StatelessWidget {
  final MentionBubbleData data;

  const MentionBubbleCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BentoCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            l10n.newsBubbleTitle,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.semiBold,
              color: context.mlColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

            // Bubble area
            SizedBox(
              height: 200,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  final nodes = _packCircles(data.items, size);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final hit = _hitTest(details.localPosition, nodes);
                      if (hit != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TickerDetailScreen(
                              ticker: hit.ticker,
                              initialSection: 'news',
                            ),
                          ),
                        );
                      }
                    },
                    child: CustomPaint(
                      size: size,
                      painter: _BubblePainter(
                        nodes: nodes,
                        brightness: theme.brightness,
                        formatMentions: (count) => l10n.newsBubbleMentions(count),
                        gainColor: context.mlColors.gainColor,
                        lossColor: context.mlColors.lossColor,
                        neutralSentimentColor: context.mlColors.neutralColor,
                        bubbleTextColor: context.mlColors.onPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _legendDot(
                    context.mlColors.gainColor, l10n.newsBubbleLegendBullish),
              ),
              const SizedBox(width: AppSpacing.lg),
              Flexible(
                child: _legendDot(
                    context.mlColors.lossColor, l10n.newsBubbleLegendBearish),
              ),
              const SizedBox(width: AppSpacing.lg),
              Flexible(
                child: _legendDot(
                    context.mlColors.neutralColor, l10n.newsBubbleLegendMixed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: AppTypography.caption),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Circle packing ──────────────────────────────────────────

class _BubbleNode {
  final TickerMention item;
  double x;
  double y;
  double radius;

  _BubbleNode({
    required this.item,
    required this.x,
    required this.y,
    required this.radius,
  });

  String get ticker => item.ticker;
}

/// Pack circles using spiral placement with collision resolution.
List<_BubbleNode> _packCircles(List<TickerMention> items, Size size) {
  if (items.isEmpty) return [];

  // Sort descending by mention count so largest is placed first
  final sorted = List<TickerMention>.from(items)
    ..sort((a, b) => b.mentionCount.compareTo(a.mentionCount));

  final maxCount = sorted.first.mentionCount;
  if (maxCount == 0) return [];

  const minR = 14.0;
  const maxR = 52.0;

  final cx = size.width / 2;
  final cy = size.height / 2;
  final nodes = <_BubbleNode>[];

  for (final item in sorted) {
    final ratio = item.mentionCount / maxCount;
    final scaledRatio = pow(ratio, 1.5).toDouble();
    final r = minR + (maxR - minR) * scaledRatio;

    if (nodes.isEmpty) {
      nodes.add(_BubbleNode(item: item, x: cx, y: cy, radius: r));
      continue;
    }

    // Spiral outward — finer step for accurate placement
    bool placed = false;
    for (double angle = 0; angle < 30 * pi; angle += 0.1) {
      final dist = 2.0 + angle * 3.0;
      final tx = cx + cos(angle) * dist;
      final ty = cy + sin(angle) * dist;

      if (!_collides(tx, ty, r, nodes) && _inBounds(tx, ty, r, size)) {
        nodes.add(_BubbleNode(item: item, x: tx, y: ty, radius: r));
        placed = true;
        break;
      }
    }

    // Skip bubble if no valid position — don't force-overlap
    if (!placed) continue;
  }

  return nodes;
}

bool _collides(double x, double y, double r, List<_BubbleNode> nodes) {
  const padding = 4.0;
  for (final n in nodes) {
    final dx = x - n.x;
    final dy = y - n.y;
    final minDist = r + n.radius + padding;
    if (dx * dx + dy * dy < minDist * minDist) return true;
  }
  return false;
}

bool _inBounds(double x, double y, double r, Size size) {
  return x - r >= 0 && x + r <= size.width && y - r >= 0 && y + r <= size.height;
}

_BubbleNode? _hitTest(Offset pos, List<_BubbleNode> nodes) {
  for (final n in nodes) {
    final dx = pos.dx - n.x;
    final dy = pos.dy - n.y;
    if (dx * dx + dy * dy <= n.radius * n.radius) return n;
  }
  return null;
}

// ─── Painter ─────────────────────────────────────────────────

class _BubblePainter extends CustomPainter {
  final List<_BubbleNode> nodes;
  final Brightness brightness;
  final String Function(int) formatMentions;
  final Color gainColor;
  final Color lossColor;
  final Color neutralSentimentColor;
  final Color bubbleTextColor;

  _BubblePainter({required this.nodes, required this.brightness, required this.formatMentions, required this.gainColor, required this.lossColor, required this.neutralSentimentColor, required this.bubbleTextColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      final color = _sentimentColor(node.item.dominantSentiment);

      // Filled circle
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        Paint()..color = color.withValues(alpha: 0.7),
      );

      // Border
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Text: ticker + (count)
      final textColor = bubbleTextColor;
      if (node.radius >= 26) {
        // Large: ticker + count
        _drawText(canvas, node.x, node.y - 6, node.item.ticker, AppTypography.caption, AppTypography.bold, textColor, node.radius * 2 - 6);
        _drawText(canvas, node.x, node.y + 7, formatMentions(node.item.mentionCount), 9, AppTypography.regular, textColor.withValues(alpha: 0.85), node.radius * 2 - 6);
      } else if (node.radius >= 20) {
        // Medium: ticker only
        _drawText(canvas, node.x, node.y, node.item.ticker, 9, AppTypography.bold, textColor, node.radius * 2 - 4);
      }
      // Small: no text
    }
  }

  void _drawText(Canvas canvas, double cx, double cy, String text,
      double fontSize, FontWeight weight, Color color, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          shadows: AppShadow.textDrop,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '..',
    );
    tp.layout(maxWidth: max(maxWidth, 10));
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'bullish':
        return gainColor;
      case 'bearish':
        return lossColor;
      default:
        return neutralSentimentColor;
    }
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.brightness != brightness || oldDelegate.formatMentions != formatMentions ||
      oldDelegate.neutralSentimentColor != neutralSentimentColor || oldDelegate.bubbleTextColor != bubbleTextColor;
}
