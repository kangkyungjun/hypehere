import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'bento_card.dart';

/// 확장 트리거 범위.
enum MlExpandTapTarget {
  /// 카드 어디를 눌러도 토글. 카드 안에 다른 탭 대상이 없을 때.
  wholeCard,

  /// 헤더 행만 토글. 본문에 링크·버튼이 있을 때.
  headerOnly,
}

/// 요약 ↔ 상세를 접었다 펴는 카드 — 헤이딜러 견적카드(②③)의 DNA.
///
/// ## 왜 이 컴포넌트가 필요했나
/// 앱에 `ExpansionTile`·`AnimatedCrossFade`·`SizeTransition` 사용이 **0건**이고,
/// 확장이 **13벌** 손 구현돼 있었다. 그 결과:
///
/// - **11벌에 애니메이션이 없어** 콘텐츠가 pop-in으로 튄다. 눈이 매번 다시
///   스캔해야 해서 피로하다.
/// - chevron 방언 5종(`keyboard_arrow_down` 회전 / `expand_less↔more` 스왑 /
///   `arrow_up↔down` 스왑 / 텍스트 버튼 / info 아이콘).
/// - 상태 네이밍 7종(`_expanded` / `_collapsed`(극성 반대!) / `_showAll*` /
///   `_showScoreChart`(기본 true) / `_showLegend` / `_visible` / `_displayCount`).
/// - `Duration(milliseconds: 200)` 하드코딩 — `AppDuration.fast`(180)가 있는데도.
///
/// 이 컴포넌트가 그 결정들을 **한 번만** 인코딩한다. 호출부는 무엇을 접을지만 정한다.
///
/// ## 접근성
/// `Semantics(button, expanded)`를 붙여 스크린리더가 접힘 상태를 읽는다.
/// `MediaQuery.disableAnimations`(모션 민감 설정) 시 애니메이션을 끈다.
class MlExpandableCard extends StatefulWidget {
  const MlExpandableCard({
    super.key,
    required this.header,
    required this.detail,
    this.summary,
    this.initiallyExpanded = false,
    this.tapTarget = MlExpandTapTarget.wholeCard,
    this.padding,
    this.margin,
    this.divider = true,
    this.card = true,
    this.onExpansionChanged,
  });

  /// 항상 보이는 헤더. chevron은 이 컴포넌트가 오른쪽에 붙인다.
  final Widget header;

  /// 펼쳤을 때만 보이는 내용. 접힌 동안 만들지 않도록 빌더로 받는다.
  final WidgetBuilder detail;

  /// 접혀 있어도 보이는 요약(헤이딜러 카드의 가격·배지 줄).
  final Widget? summary;

  final bool initiallyExpanded;
  final MlExpandTapTarget tapTarget;
  final EdgeInsetsGeometry? padding;

  /// 카드 바깥 여백. `card: false`면 무시된다.
  final EdgeInsetsGeometry? margin;

  /// 요약과 상세 사이 헤어라인.
  final bool divider;

  /// 카드 표면(BentoCard)으로 감쌀지.
  ///
  /// `false`면 확장 **동작만** 제공한다 — 이미 카드 안에 들어가는 섹션
  /// (애널리스트 평가, AI 인사이트 등)이 이중 카드가 되지 않도록.
  final bool card;

  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<MlExpandableCard> createState() => _MlExpandableCardState();
}

class _MlExpandableCardState extends State<MlExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onExpansionChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    // 모션 민감 사용자는 즉시 전환한다.
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final duration = noMotion ? Duration.zero : AppDuration.fast;

    final headerRow = Row(
      children: [
        Expanded(child: widget.header),
        const SizedBox(width: AppSpacing.sm),
        AnimatedRotation(
          duration: duration,
          curve: AppDuration.standard,
          turns: _expanded ? 0.5 : 0,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: mlc.textTertiary,
          ),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.tapTarget == MlExpandTapTarget.headerOnly
            ? GestureDetector(
                onTap: _toggle,
                behavior: HitTestBehavior.opaque,
                child: headerRow,
              )
            : headerRow,
        if (widget.summary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          widget.summary!,
        ],
        AnimatedSize(
          duration: duration,
          curve: AppDuration.standard,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.divider) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Divider(
                        height: 1,
                        color: mlc.subtleBorder.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ] else
                      const SizedBox(height: AppSpacing.sm),
                    widget.detail(context),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );

    return Semantics(
      button: true,
      expanded: _expanded,
      child: widget.card
          ? BentoCard(
              onTap: widget.tapTarget == MlExpandTapTarget.wholeCard
                  ? _toggle
                  : null,
              padding: widget.padding,
              margin: widget.margin,
              child: body,
            )
          : (widget.tapTarget == MlExpandTapTarget.wholeCard
                ? GestureDetector(
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: body,
                  )
                : body),
    );
  }
}

/// [MlExpandableCard.header] 에 넣는 기본 제목.
///
/// 확장 카드의 제목은 카드 안이므로 `SectionHeader`(자체 패딩·액센트 바를
/// 가진 화면 레벨 컴포넌트)가 아니라 이쪽을 쓴다.
class MlCardTitle extends StatelessWidget {
  const MlCardTitle(this.title, {super.key, this.subtitle});

  final String title;

  /// 레퍼런스의 `무사고 기준` 같은 자격 태그.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.sectionTitle.copyWith(color: mlc.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTypography.label.copyWith(color: mlc.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
