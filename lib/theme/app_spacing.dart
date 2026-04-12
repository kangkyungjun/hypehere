/// MarketLens 간격 시스템
///
/// 전체 앱에서 일관된 간격 사용을 위한 시맨틱 토큰.
/// SizedBox, EdgeInsets 등에 매직넘버 대신 이 상수를 사용.
abstract final class AppSpacing {
  /// 2px — 아이콘-텍스트 미세 간격
  static const double xxs = 2.0;

  /// 4px — 인접 요소 간 최소 간격
  static const double xs = 4.0;

  /// 6px — 밀접 요소 간 간격
  static const double sm = 6.0;

  /// 8px — 기본 간격 (가장 빈번하게 사용)
  static const double md = 8.0;

  /// 12px — 관련 그룹 내 간격
  static const double lg = 12.0;

  /// 16px — 섹션 내 요소 간 간격, 기본 패딩
  static const double xl = 16.0;

  /// 24px — 섹션 간 간격
  static const double xxl = 24.0;

  /// 32px — 대형 섹션 간 간격, 화면 여백
  static const double xxxl = 32.0;
}
