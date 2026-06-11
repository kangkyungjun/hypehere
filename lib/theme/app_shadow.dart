import 'package:flutter/material.dart';

/// Semantic box shadow tokens for consistent elevation.
abstract final class AppShadow {
  /// 카드 부드러운 그림자 — 그룹(회색) 배경 위 흰 카드를 띄울 때 (에디토리얼 톤)
  /// 낮은 alpha + 넓은 blur로 테두리 없이 부드럽게 분리
  static List<BoxShadow> card(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.05),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ];

  /// 미세 그림자 — 목록 항목, 작은 요소
  static List<BoxShadow> sm(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// 기본 카드 그림자 — 대부분의 카드에 사용
  static List<BoxShadow> md(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.10),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  /// 강조 그림자 — 모달, 떠있는 카드
  static List<BoxShadow> lg(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.14),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];

  /// 텍스트 드롭 섀도 — 트리맵, 뉴스 오버레이 등
  static const List<Shadow> textDrop = [
    Shadow(offset: Offset(0, 1), blurRadius: 1.2, color: Color(0x66000000)),
  ];
}
