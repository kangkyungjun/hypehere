import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared badge color helpers used across community and admin screens.
///
/// Centralises ticker-badge and role-badge colour logic so that
/// post_card, post_detail_screen, admin_panel_screen and settings_screen
/// all reference a single source of truth.
class BadgeColors {
  BadgeColors._(); // prevent instantiation

  // ── Ticker badge colours ────────────────────────────────────────────

  /// Returns the background colour for a community-post ticker badge.
  ///
  /// Empty ticker (자유 게시글) → grey, then per-ticker overrides:
  /// TSLA → blue, AAPL → dark grey, NVDA → NVIDIA green.
  /// Everything else falls back to blue.
  /// Brand colors are intentionally fixed across themes.
  static Color tickerBadge(String ticker) {
    if (ticker.isEmpty) return const Color(0xFF757575); // 자유 게시글 회색
    switch (ticker) {
      case 'TSLA':
        return const Color(0xFF1E88E5); // Blue
      case 'AAPL':
        return const Color(0xFF424242); // Gray
      case 'NVDA':
        return const Color(0xFF76B900); // Green
      default:
        return const Color(0xFF1E88E5);
    }
  }

  // ── Role badge colours ──────────────────────────────────────────────

  /// Returns the background colour for a user-role badge (theme-aware).
  static Color roleBadge(String role, MarketLensColors mlc) {
    switch (role) {
      case 'master':
        return mlc.roleMasterColor;
      case 'manager':
        return mlc.roleManagerColor;
      case 'gold':
        return mlc.roleGoldColor;
      case 'regular':
      default:
        return mlc.roleRegularColor;
    }
  }
}
