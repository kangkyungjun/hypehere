import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/utils/badge_colors.dart';

void main() {
  group('BadgeColors.tickerBadge', () {
    test('empty string returns grey', () {
      expect(BadgeColors.tickerBadge(''), const Color(0xFF757575));
    });

    test('TSLA returns blue', () {
      expect(BadgeColors.tickerBadge('TSLA'), const Color(0xFF1E88E5));
    });

    test('AAPL returns dark grey', () {
      expect(BadgeColors.tickerBadge('AAPL'), const Color(0xFF424242));
    });

    test('NVDA returns NVIDIA green', () {
      expect(BadgeColors.tickerBadge('NVDA'), const Color(0xFF76B900));
    });

    test('unknown ticker falls back to blue', () {
      expect(BadgeColors.tickerBadge('MSFT'), const Color(0xFF1E88E5));
      expect(BadgeColors.tickerBadge('GOOG'), const Color(0xFF1E88E5));
      expect(BadgeColors.tickerBadge('AMZN'), const Color(0xFF1E88E5));
    });
  });

  group('BadgeColors.roleBadge', () {
    const mlc = MarketLensColors.light;

    test('master returns roleMasterColor', () {
      expect(BadgeColors.roleBadge('master', mlc), mlc.roleMasterColor);
    });

    test('manager returns roleManagerColor', () {
      expect(BadgeColors.roleBadge('manager', mlc), mlc.roleManagerColor);
    });

    test('gold returns roleGoldColor', () {
      expect(BadgeColors.roleBadge('gold', mlc), mlc.roleGoldColor);
    });

    test('regular returns roleRegularColor', () {
      expect(BadgeColors.roleBadge('regular', mlc), mlc.roleRegularColor);
    });

    test('unknown role falls back to roleRegularColor (default case)', () {
      expect(BadgeColors.roleBadge('unknown', mlc), mlc.roleRegularColor);
      expect(BadgeColors.roleBadge('', mlc), mlc.roleRegularColor);
      expect(BadgeColors.roleBadge('admin', mlc), mlc.roleRegularColor);
    });
  });
}
