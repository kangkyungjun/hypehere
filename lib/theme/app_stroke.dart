/// MarketLens 선 굵기 토큰
///
/// 차트 라인, 로딩 인디케이터, 구분선 등의 일관된 선 굵기.
abstract final class AppStroke {
  /// 0.5px — 차트 보조선
  static const double hairline = 0.5;

  /// 1.0px — 기본 차트 라인
  static const double thin = 1.0;

  /// 2.0px — 로딩 인디케이터, 활성 라인
  static const double medium = 2.0;
}
