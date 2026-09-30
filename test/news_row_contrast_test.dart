import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/theme/app_colors.dart';

/// 버블차트 텍스트 대비 계약.
///
/// 개편 전 `_BubblePainter`는 채움에 `withValues(alpha: 0.7)`을 씌웠다.
/// 흰 카드 위에서 실효색이 밝아져 **흰 텍스트 대비가 세 감정 색 모두 WCAG AA
/// (4.5:1) 미달**이었다 — 강세 3.12 / 약세 3.59 / 혼합 3.13. 캡쳐에서 가장 큰
/// 두 버블(META 회색, DOW 빨강)이 둘 다 미달 조합이었다.
///
/// `AppShadow.textDrop`이 붙어 있었지만 그건 대비 실패의 반창고지 해결이 아니다.
/// 스펙 §4가 세 색을 **불투명 상태로** AA 검증해 뒀으므로 알파만 걷으면 된다.
/// 다시 알파가 들어오면 이 테스트가 잡는다.
void main() {
  double lin(int c) {
    final v = c / 255.0;
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(Color c) =>
      0.2126 * lin((c.r * 255).round()) +
      0.7152 * lin((c.g * 255).round()) +
      0.0722 * lin((c.b * 255).round());

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    final hi = math.max(la, lb), lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// 채움 위에 흰 텍스트를 올렸을 때의 대비. `alpha`는 채움 불투명도.
  double bubbleContrast(Color fill, Color card, Color text, double alpha) {
    final composited = Color.fromARGB(
      255,
      ((fill.r * alpha + card.r * (1 - alpha)) * 255).round(),
      ((fill.g * alpha + card.g * (1 - alpha)) * 255).round(),
      ((fill.b * alpha + card.b * (1 - alpha)) * 255).round(),
    );
    return contrast(composited, text);
  }

  for (final theme in [
    ('light', MarketLensColors.light),
    ('dark', MarketLensColors.dark),
  ]) {
    final c = theme.$2;
    final sentiments = {
      '강세': c.gainColor,
      '약세': c.lossColor,
      '혼합': c.neutralColor,
    };

    // 위젯이 쓰는 것과 **같은 규칙**: 두 잉크 후보 중 대비가 큰 쪽.
    // (`mention_bubble_card.dart`의 `_contrast(...) >= _contrast(...)`)
    Color ink(Color fill) {
      final dark = MarketLensColors.light.textPrimary;
      return contrast(fill, dark) >= contrast(fill, c.onPrimary)
          ? dark
          : c.onPrimary;
    }

    sentiments.forEach((name, fill) {
      test('버블 $name 텍스트 대비 ≥ 4.5 — ${theme.$1}', () {
        // 프로덕션은 알파 없이(1.0) 칠한다.
        final ratio = bubbleContrast(fill, c.cardBackground, ink(fill), 1.0);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name 대비 ${ratio.toStringAsFixed(2)}:1 — AA 미달',
        );
      });
    });

    test('알파 0.7을 다시 씌우면 AA가 깨진다 (회귀 근거) — ${theme.$1}', () {
      final broken = sentiments.values
          .map((f) => bubbleContrast(f, c.cardBackground, ink(f), 0.7))
          .where((r) => r < 4.5)
          .length;
      // 이 테스트가 실패한다면 알파를 다시 써도 안전해졌다는 뜻이므로,
      // 위 계약의 근거를 다시 확인할 것.
      expect(broken, greaterThan(0));
    });
  }
}
