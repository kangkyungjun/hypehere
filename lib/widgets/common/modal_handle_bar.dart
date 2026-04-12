import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// 바텀시트 상단 드래그 핸들바
///
/// ```dart
/// Column(children: [
///   const ModalHandleBar(),
///   // ... 시트 내용
/// ])
/// ```
class ModalHandleBar extends StatelessWidget {
  const ModalHandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.mlColors.subtleBorder,
          borderRadius: BorderRadius.circular(AppRadius.xxs),
        ),
      ),
    );
  }
}
