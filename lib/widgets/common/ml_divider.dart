import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 테마 인식 구분선 — 일관된 스타일의 Divider
///
/// ```dart
/// const MlDivider()          // 기본 (컴팩트)
/// const MlDivider.spacious() // 섹션 사이 (넓은 여백)
/// ```
class MlDivider extends StatelessWidget {
  const MlDivider({
    super.key,
    this.height = 1,
    this.thickness = 0.5,
    this.indent = 0,
    this.endIndent = 0,
  });

  /// 섹션 사이 구분선 (상하 여백 포함)
  const MlDivider.spacious({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
  })  : height = 24,
        thickness = 0.5;

  final double height;
  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: context.mlColors.subtleBorder,
    );
  }
}
