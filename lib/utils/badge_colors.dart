import 'package:flutter/material.dart';

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

  /// Returns the background colour for a user-role badge.
  static Color roleBadge(String role) {
    switch (role) {
      case 'master':
        return const Color(0xFFD32F2F); // 빨강 (Master)
      case 'manager':
        return const Color(0xFFF57C00); // 주황 (Manager)
      case 'gold':
        return const Color(0xFFFFA000); // 골드 (Gold)
      case 'regular':
      default:
        return const Color(0xFF757575); // 회색 (Regular)
    }
  }
}
