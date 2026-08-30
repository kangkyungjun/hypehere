import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// "더보기 / 줄이기" 버튼 — 리스트를 늘렸다 줄이는 단일 컨트롤.
///
/// ## 왜 이 컴포넌트가 필요했나
/// 같은 버튼이 앱에 **7벌 203줄**로 재구현돼 있었고, 그중 두 쌍
/// (`top_stocks_list_screen`↔`movers_list_screen`, `holdings_tab`↔
/// `holding_detail_sheet`)은 **광고 삽입 산술까지 똑같은 복붙**이었다.
///
/// 그 결과 제각각이 됐다:
/// - **7곳 중 4곳은 접기가 안 되는 단방향**이었다. 한 번 펼치면 되돌릴 수 없다
/// - 버튼 형태 3종 (전폭 TextButton / OutlinedButton / TextButton.icon)
/// - 반경 2종 (`AppRadius.md` / `AppRadius.full`)
/// - 라벨 소스 5종 — `l10n.viewMore` / `l10n.seeMore` /
///   `l10n.viewAllTransactions` / 하드코딩 `'더보기 (n)'` /
///   하드코딩 `'줄이기' : 'Show less'` (**`showLess` l10n 키가 아예 없었다**)
///
/// 슬리버 안에서도 쓸 수 있도록 **버튼만** 떼어냈다. 박스 컨텍스트라면
/// 리스트까지 함께 처리하는 [MlShowMoreList]를 쓰는 편이 짧다.
class MlShowMoreButton extends StatelessWidget {
  const MlShowMoreButton({
    super.key,
    required this.expanded,
    required this.onPressed,
    this.remaining,
    this.collapsible = true,
  });

  /// 현재 펼쳐진 상태인지. `true`면 "줄이기"를 보여준다.
  final bool expanded;

  final VoidCallback onPressed;

  /// 남은 항목 수. 주면 `더보기 (12)`처럼 개수를 함께 보여준다.
  final int? remaining;

  /// 접기를 허용할지. `false`면 펼친 뒤 버튼이 사라진다(단방향).
  ///
  /// 기본값이 `true`인 이유 — 개편 전 7곳 중 4곳이 단방향이라 한 번 펼치면
  /// 되돌릴 수 없었다. 접을 수 있는 편이 기본값이어야 한다.
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    if (expanded && !collapsible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final label = expanded
        ? l10n.showLess
        : (remaining == null ? l10n.viewMore : '${l10n.viewMore} ($remaining)');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: mlc.subtleBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: mlc.accentBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: mlc.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 처음 N개만 보여주고 나머지는 접어두는 리스트.
///
/// 상태(`_showAll*` / `_displayCount` / `_visible` — 개편 전 네이밍 7종)를
/// 이 위젯이 갖는다. 호출부는 항목과 빌더만 넘긴다.
class MlShowMoreList<T> extends StatefulWidget {
  const MlShowMoreList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 3,
    this.collapsible = true,
    this.separator,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// 접힌 상태에서 보여줄 개수.
  final int initialCount;

  final bool collapsible;

  /// 항목 사이에 끼울 위젯(구분선 등).
  final Widget? separator;

  @override
  State<MlShowMoreList<T>> createState() => _MlShowMoreListState<T>();
}

class _MlShowMoreListState<T> extends State<MlShowMoreList<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final hasMore = total > widget.initialCount;
    final shown = _expanded ? total : widget.initialCount.clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < shown; i++) ...[
          if (i > 0 && widget.separator != null) widget.separator!,
          widget.itemBuilder(context, widget.items[i], i),
        ],
        if (hasMore)
          MlShowMoreButton(
            expanded: _expanded,
            collapsible: widget.collapsible,
            remaining: _expanded ? null : total - shown,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}
