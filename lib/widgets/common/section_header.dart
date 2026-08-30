import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 섹션 헤더 — 스크롤 흐름에서 "여기서 새 구간이 시작된다"를 만드는 장치.
///
/// ## 설계 원칙: 가시성은 크기가 아니라 구조로 만든다
///
/// 1차 개편에서 섹션 타이틀을 18→20px로 키웠으나 사용자 판정은 "과하다"였다.
/// 글씨를 키우면 부피만 늘고 구간 구분은 별로 안 생긴다 — 옆에 있는 카드 제목도
/// 같이 커져 상대 위계가 그대로이기 때문이다. 그래서 타이틀은 18로 되돌리고,
/// 대신 **글자 크기를 쓰지 않는 세 장치**로 구간을 만든다:
///
/// - **액센트 바** — 타이틀 왼쪽의 3×16 세로 막대. 세로 공간 비용 0.
///   `leading` 아이콘이 있으면 중복이므로 자동으로 숨긴다(둘 중 하나만).
/// - **비대칭 여백** — 위(`lg`=16) > 아래(`xs`=4). 헤더가 아래 콘텐츠에
///   "붙어" 보여 게슈탈트 근접성으로 한 덩어리가 된다. 이전 대칭(8/8)에서는
///   헤더가 위아래 어디에도 속하지 않아 구간이 안 생겼다.
/// - **자격 태그(subtitle)** — 레퍼런스의 `무사고 기준` pill 대응. 타이틀을
///   키우지 않고 맥락을 붙인다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTrailingTap,
    this.padding,
    this.accentBar = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  /// 타이틀 왼쪽 액센트 바. `leading`이 있으면 무시된다(시각 앵커는 하나만).
  final bool accentBar;

  @override
  Widget build(BuildContext context) {
    final colors = context.mlColors;
    final showBar = accentBar && leading == null;

    return Padding(
      // 비대칭 — 위는 넓게(구간 분리), 아래는 좁게(콘텐츠와 결합).
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xs,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: colors.accentBlue, size: 20),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else if (showBar) ...[
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: colors.accentBlue,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.sectionTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: AppTypography.label.copyWith(
                      color: colors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: onTrailingTap,
              behavior: HitTestBehavior.opaque,
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
