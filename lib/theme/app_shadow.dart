import 'package:flutter/material.dart';

/// Semantic box shadow tokens for consistent elevation.
abstract final class AppShadow {
  static BoxShadow sm(Color color) => BoxShadow(
        color: color,
        blurRadius: 2,
      );

  static BoxShadow md(Color color) => BoxShadow(
        color: color,
        blurRadius: 4,
        offset: const Offset(0, 2),
      );

  static BoxShadow lg(Color color) => BoxShadow(
        color: color,
        blurRadius: 8,
        offset: const Offset(0, 2),
      );
}
