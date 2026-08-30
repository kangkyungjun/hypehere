import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 키밸류 행의 레이아웃.
enum MlKvLayout {
  /// 라벨 좌 · 값 우 (기본). 값이 **숫자**일 때 쓴다 — 우측정렬 + tabular
  /// figures가 자릿수를 세로로 맞춰 스캔이 쉬워진다.
  row,

  /// 라벨 위 · 값 아래. 좁은 열(그리드 셀)에 넣을 때.
  stack,
}

/// 값의 강조 등급.
enum MlKvEmphasis {
  /// 기본 — `kvValue`(14 w600) + textPrimary.
  normal,

  /// 카드의 대표값 — `priceCard`(16 w600).
  strong,

  /// 비방향성 히어로(목표가·집계 규모) — accentBlue.
  ///
  /// ⚠️ 방향성 수치(가격 변동·손익)에는 쓰지 않는다. RULE-BLUE 참조.
  blue,

  /// 방향성 수치 — 값의 부호로 gain/loss 색이 자동 결정된다.
  directional,
}

/// 라벨+값 한 행 — 헤이딜러 견적카드 KV의 원자.
///
/// ## 왜 이 컴포넌트가 필요했나
/// 같은 일을 하는 위젯이 앱 전체에 **14벌 489줄**로 재구현돼 있었다. 그 결과
/// 라벨 크기 4종(11·12·13·14), 값 크기 6종(12~22), 색 소스 3종(`mlColors` /
/// `colorScheme` / 무지정), 세로 패딩 5종(0·2·3·8·16)이 화면마다 다르게 섞였다.
/// `FittedBox` 방어도 8벌엔 있고 6벌엔 없었다.
///
/// 그래서 `AppTypography.kvValue`와 `AppDensity.rowV`는 **사용처 0**의 死코드였다.
/// 이 컴포넌트가 그 토큰들을 소비하는 유일한 자리다.
///
/// ## 위계는 크기가 아니라 색·굵기로 만든다
/// 레퍼런스 계측 결과 라벨과 값의 **크기가 사실상 같다**(둘 다 14~15dp).
/// 차이는 오직 색(뮤트↔진함)과 굵기(w500↔w600)다. 크기를 벌리면 행이 높아지지만
/// 색과 굵기는 **픽셀 비용이 0**이라, 사용자의 "여백 타이트" 제약과 양립한다.
class MlKeyValueRow extends StatelessWidget {
  const MlKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.layout = MlKvLayout.row,
    this.emphasis = MlKvEmphasis.normal,
    this.unit,
    this.sub,
    this.subColor,
    this.dense = false,
    this.labelWidth,
    this.placeholder = '-',
  });

  final String label;

  /// 값. 비어 있거나 [placeholder]와 같으면 흐리게 표시한다.
  final String value;

  final MlKvLayout layout;
  final MlKvEmphasis emphasis;

  /// 값 뒤에 붙는 작은 단위(`%`·`M`·`pt`). 값보다 한 단계 뮤트·한 단계 얇게.
  final String? unit;

  /// 값 아래 보조값. 예: 평가손익의 `(+3.2%)`.
  final String? sub;
  final Color? subColor;

  /// 4행 이상이 붙는 표에서 행 높이를 줄인다.
  final bool dense;

  /// 라벨 열 고정폭. 지정하면 값이 **좌측정렬**로 바뀌어 여러 행의 값 시작 x가
  /// 세로로 맞는다 — 레퍼런스의 `사고 / 완전무사고` 리듬이다.
  ///
  /// 값이 **텍스트**일 때 쓴다. 숫자는 지정하지 않는 편이 낫다(우측정렬 +
  /// tabular figures가 자릿수를 맞춰준다).
  /// [MlKvLayout.stack] 에서는 무시된다.
  final double? labelWidth;

  /// 값이 없을 때 표시할 문자열.
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final shown = value.trim().isEmpty ? placeholder : value;
    final isEmpty = shown == placeholder;

    final valueColor = isEmpty
        ? mlc.textTertiary
        : switch (emphasis) {
            MlKvEmphasis.normal || MlKvEmphasis.strong => mlc.textPrimary,
            MlKvEmphasis.blue => mlc.accentBlue,
            MlKvEmphasis.directional =>
              shown.startsWith('-') || shown.startsWith('▼')
                  ? mlc.lossColor
                  : mlc.gainColor,
          };

    final valueStyle =
        (emphasis == MlKvEmphasis.strong
                ? AppTypography.priceCard
                : AppTypography.kvValue)
            .copyWith(color: valueColor);

    final labelWidget = Text(
      label,
      style: AppTypography.kvLabel.copyWith(color: mlc.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // FittedBox(scaleDown): 좁은 폭에서 '…'로 숫자를 숨기지 않고 살짝 축소한다.
    // 데이터가 잘리지 않으면서 구조도 안 깨진다.
    // 정렬 규칙: 숫자는 우측(자릿수 정렬) / 텍스트는 좌측(라벨 고정폭과 함께
    // 값 시작 x를 맞춘다). 레퍼런스도 KV 상세는 좌측, 리스트 가격만 우측이다.
    final alignRight = layout == MlKvLayout.row && labelWidth == null;

    final valueWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: unit == null
          ? Text(shown, style: valueStyle, maxLines: 1, softWrap: false)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: shown, style: valueStyle),
                  TextSpan(
                    text: unit,
                    style: AppTypography.unitSuffix.copyWith(
                      color: emphasis == MlKvEmphasis.directional
                          ? valueColor.withValues(alpha: 0.7)
                          : mlc.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
    );

    final subWidget = sub == null
        ? null
        : Text(
            sub!,
            style: AppTypography.label.copyWith(
              color: subColor ?? mlc.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    final vPad = dense ? AppDensity.rowVDense : AppDensity.rowV;

    if (layout == MlKvLayout.stack) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: AppSpacing.xs),
            valueWidget,
            if (subWidget != null) subWidget,
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelWidth != null)
            SizedBox(width: labelWidth, child: labelWidget)
          else
            Flexible(child: labelWidget),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [valueWidget, if (subWidget != null) subWidget],
            ),
          ),
        ],
      ),
    );
  }
}
