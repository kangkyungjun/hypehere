import 'package:flutter/animation.dart';

/// Semantic animation/transition duration tokens.
abstract final class AppDuration {
  static const Duration fastest = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration slower = Duration(milliseconds: 460);
  static const Duration slowest = Duration(milliseconds: 1000);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}
