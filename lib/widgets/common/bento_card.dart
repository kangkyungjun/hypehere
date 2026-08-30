import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';

/// Reusable surface card wrapper for dense financial content.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final radius = BorderRadius.circular(AppRadius.card);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 테두리 없이 부드러운 그림자로 카드를 띄운다(레퍼런스 일치).
    // 기본은 옅은 card 그림자, emphasized는 한 단계 강한 md 그림자.
    //
    // 다크 모드: 검정 배경 위의 검정 그림자는 보이지 않으므로 **명도 스텝**으로
    // 카드를 분리한다. 개편 전 카드(#111111) vs 배경(#0A0A0A)이 1.048:1이라
    // 사실상 구분이 안 됐고, 그 실패를 저알파 헤어라인으로 임시 보완하고 있었다.
    // 이제 카드(#191C21) vs 배경(#090A0C) = 1.159:1로 스텝 자체가 충분하므로
    // 헤어라인을 제거하고, 무의미한 그림자 렌더링도 끈다.
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isDark
            ? const []
            : (emphasized
                  ? AppShadow.md(Colors.black)
                  : AppShadow.card(Colors.black)),
      ),
      child: Material(
        color: mlc.cardBackground,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            // 레퍼런스풍 편안한 카드 내부 패딩(밀도 토큰). 제목이 위에 바짝
            // 붙지 않게 top만 살짝 더. 밀집 리스트 행은 명시적 padding을 넘겨
            // 이 기본값의 영향을 받지 않는다.
            padding: padding ??
                const EdgeInsets.fromLTRB(
                  AppDensity.cardPad,
                  AppDensity.cardPadTop,
                  AppDensity.cardPad,
                  AppDensity.cardPad,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
