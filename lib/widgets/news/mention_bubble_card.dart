import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/mention_bubble_data.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/ticker_detail/ticker_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
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
      // 카드 **사이** 간격은 `cardGap`(12)이다. 개편 전 `xl`(16)은 기사 사이
      // 간격(16)과 값이 같아 층위 구분이 0이었다 — 눈이 "카드 묶음이 끝나고
      // 리스트가 시작됐다"를 읽지 못했다.
      margin: const EdgeInsets.only(bottom: AppDensity.cardGap),
      // 개편 전 (16,16,16,12)는 토큰 의도와 **상하가 반대**였다.
      // `cardPadTop`(12)은 제목이 바짝 붙지 않게 살짝만 주는 값이고
      // 바닥은 `cardPad`(16)다.
      padding: const EdgeInsets.fromLTRB(
        AppDensity.cardPad,
        AppDensity.cardPadTop,
        AppDensity.cardPad,
        AppDensity.cardPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목인데 본문 크기(15)에 뮤트색이라 제목으로 안 읽혔다.
          // `cardTitle`(18 w700 primary)로 올린다 — 세로 비용 3px.
          Text(
            l10n.newsBubbleTitle,
            style: TextStyle(
              fontSize: AppTypography.headlineLarge,
              fontWeight: AppTypography.bold,
              color: context.mlColors.textPrimary,
            ),
          ),
          // 불변식: 카드 **안쪽** 블록(≤8) < 카드 **사이**(12) < 섹션 사이(20).
        const SizedBox(height: AppSpacing.sm),

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
                        // 잉크는 **채움 밝기에 따라** 고른다. 고정 흰색이었을 때
                        // 다크모드의 밝은 감정색(#FB8A8A 등) 위에서 대비가
                        // 2.3~2.9까지 떨어졌다 — 라이트에서만 검증하면 못 잡는다.
                        inkOnDarkFill: context.mlColors.onPrimary,
                        inkOnLightFill: MarketLensColors.light.textPrimary,
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
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

/// WCAG 명도 대비비. 잉크 선택에만 쓴다.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Pack circles using spiral placement with collision resolution.
/// 배치된 버블 수 — 테스트에서 "몇 개가 실제로 보이는가"를 계약으로 건다.
/// `break`로 바꿨다가 10개 중 4개만 남은 적이 있고, 그건 캡쳐로만 보였다.
@visibleForTesting
int packedBubbleCount(List<TickerMention> items, Size size) =>
    _packCircles(items, size).length;

List<_BubbleNode> _packCircles(List<TickerMention> items, Size size) {
  if (items.isEmpty) return [];

  // Sort descending by mention count so largest is placed first
  final sorted = List<TickerMention>.from(items)
    ..sort((a, b) => b.mentionCount.compareTo(a.mentionCount));

  final maxCount = sorted.first.mentionCount;
  if (maxCount == 0) return [];

  // 하한은 **텍스트가 들어가는 최소 크기**에 맞춘다. 개편 전 14는
  // `_drawText`가 아무것도 그리지 않는 구간이라 빈 원이 떴다(캡쳐에서 10개 중
  // 4개). 18이면 지름 32px에 9px 티커가 들어간다.
  //
  // 상한은 52 → 42로 줄인다. 가장 큰 버블이 박스를 독차지하면 나머지가
  // 자리를 못 찾는다 — 20/52 조합에서 10개 중 4개만 배치됐다.
  const minR = 18.0;
  const maxR = 42.0;

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

    // 자리를 못 찾은 것은 건너뛴다. `break`로 바꿨더니 큰 것 하나가 실패하는
    // 순간 **뒤의 작은 것들까지 전부 버려져** 10개 중 4개만 남았다 —
    // 더 작은 버블은 같은 자리에 들어갈 수 있으므로 계속 시도해야 한다.
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
  final Color inkOnDarkFill;
  final Color inkOnLightFill;

  /// 앱 폰트. `TextPainter`는 테마를 상속하지 않아서, 비워두면 이 라벨만
  /// 시스템 폰트로 그려진다 — 앱 전체가 Pretendard인데 버블만 달라 보였다.
  final String? fontFamily;

  _BubblePainter({required this.nodes, required this.brightness, required this.formatMentions, required this.gainColor, required this.lossColor, required this.neutralSentimentColor, required this.inkOnDarkFill, required this.inkOnLightFill, this.fontFamily});

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      final color = _sentimentColor(node.item.dominantSentiment);

      // Filled circle
      canvas.drawCircle(
        Offset(node.x, node.y),
        node.radius,
        // ⚠️ 여기에 알파를 씌우면 안 된다. `withValues(alpha: 0.7)`이었을 때
        // 흰 카드 위 실효색이 밝아져 **흰 텍스트 대비가 세 색 모두 AA 미달**
        // 이었다(강세 3.12 / 약세 3.59 / 혼합 3.13). 불투명 토큰색이면
        // 5.48 / 5.74 / 6.00으로 전부 통과한다.
        Paint()..color = color,
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
      // 고정 임계값(휘도 0.45)은 중간 밝기 채움에서 틀린 쪽을 골랐다 —
      // 다크 `neutralColor`(#8F9AA9, 휘도 0.31)에 흰 잉크가 뽑혀 2.85:1이었다.
      // **두 후보 중 대비가 큰 쪽**을 고르면 경계값이 필요 없다.
      final textColor = _contrast(color, inkOnLightFill) >=
              _contrast(color, inkOnDarkFill)
          ? inkOnLightFill
          : inkOnDarkFill;
      // 임계값은 minR(18)과 맞물려야 한다. 어떤 버블도 **빈 원**으로 남으면 안 된다.
      if (node.radius >= 28) {
        // Large: ticker + count
        _drawText(canvas, node.x, node.y - 6, node.item.ticker, AppTypography.caption, AppTypography.bold, textColor, node.radius * 2 - 6);
        _drawText(canvas, node.x, node.y + 7, formatMentions(node.item.mentionCount), AppTypography.chartLabel, AppTypography.regular, textColor.withValues(alpha: 0.85), node.radius * 2 - 6);
      } else {
        // Medium: ticker only
        _drawText(canvas, node.x, node.y, node.item.ticker, AppTypography.chartLabel, AppTypography.bold, textColor, node.radius * 2 - 4);
      }
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
          fontFamily: fontFamily,
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
      oldDelegate.neutralSentimentColor != neutralSentimentColor ||
      oldDelegate.inkOnDarkFill != inkOnDarkFill ||
      oldDelegate.inkOnLightFill != inkOnLightFill ||
      oldDelegate.fontFamily != fontFamily;
}
