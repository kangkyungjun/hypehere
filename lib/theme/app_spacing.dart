/// MarketLens 간격 시스템
///
/// 전체 앱에서 일관된 간격 사용을 위한 시맨틱 토큰.
/// SizedBox, EdgeInsets 등에 매직넘버 대신 이 상수를 사용.
abstract final class AppSpacing {
  /// 2px — 아이콘-텍스트 미세 간격
  static const double xxs = 2.0;

  /// 4px — 인접 요소 간 최소 간격
  static const double xs = 4.0;

  /// 8px — 밀접 요소 간 간격
  static const double sm = 8.0;

  /// 12px — 관련 요소 간 기본 간격
  static const double md = 12.0;

  /// 16px — 카드 내부 패딩, 리스트 그룹 간격
  static const double lg = 16.0;

  /// 16px — 화면 좌우 여백, 큰 그룹 간격
  static const double xl = 16.0;

  /// 20px — 섹션 간 간격
  static const double xxl = 20.0;

  /// 24px — 대형 섹션 간 간격
  static const double xxxl = 24.0;
}
