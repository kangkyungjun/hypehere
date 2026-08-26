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

  /// 28px — 에디토리얼 섹션 리듬 (콘텐츠 블록 사이 큰 여백)
  static const double section = 28.0;
}

/// 밀도(Density) 토큰 — 레퍼런스풍 "편안하되 절제된" 카드/행 내부 여백.
///
/// 전역 여백을 키우지 않고(사용자 타이트 선호 존중), 카드 내부 패딩·키밸류
/// 행 높이 등 "굶주려 답답해 보이던" 지점만 단일 상수로 잡는다. 값을 여기서만
/// 바꾸면 [MlCard]/[BentoCard]·키밸류 컴포넌트에 일괄 반영된다.
abstract final class AppDensity {
  /// 콘텐츠 카드 내부 패딩 — 레퍼런스 카드(≈16~20). 밀도 단일 레버.
  static const double cardPad = 18.0;

  /// 카드 상단은 제목이 바짝 붙지 않게 살짝 더.
  static const double cardPadTop = 14.0;

  /// 키밸류 행 세로 패딩 — 영수증풍 편안한 행 높이.
  static const double rowV = 12.0;

  /// 카드 사이 간격 — 카드가 개별 부유 객체로 읽히도록.
  static const double cardGap = 16.0;
}

/// 화면 레이아웃 치수 토큰.
///
/// 여러 화면이 공유해야 하는 구조적 높이/너비를 한곳에서 관리한다.
abstract final class AppLayout {
  /// 플로팅 하단 탭바의 개별 아이템 높이.
  static const double bottomNavItemHeight = 48.0;

  /// 플로팅 하단 탭바의 콘텐츠 높이(안전영역 제외).
  ///
  /// SafeArea min top(xs=4) + 내부 padding(xs=4)*2 + 아이템(48) = 60.
  /// main.dart의 `_buildModernBottomNav`와 AI 채팅 입력창 클리어런스가 공유하여,
  /// 탭바 디자인이 바뀌어도 입력창이 탭바 밑으로 겹치지 않도록 보장한다.
  static const double bottomNavContentHeight =
      AppSpacing.xs + (AppSpacing.xs * 2) + bottomNavItemHeight;
}
