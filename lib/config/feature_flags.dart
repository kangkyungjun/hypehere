/// ──────────────────────────────────────────────────────────────────
/// [GOLD_PURCHASE_FLAG] — 마스터 플래그
/// Gold 멤버십 IAP 구매 기능 + Holdings 제한의 활성화 여부를 제어.
///
/// false (현재) →
///   - 모든 골드 구매 UI가 "Coming Soon" 메시지로 대체됨
///   - Holdings(보유 종목) 3개 제한이 해제됨 (무제한)
///   - 광고(AdMob)만 수익화 수단으로 노출됨
///
/// true (복원 시) →
///   - 기존 골드 구매 기능이 정상 동작함
///   - Holdings 3개 제한이 복원됨 + 업그레이드 유도 다이얼로그 표시
///
/// 【복원 방법】
/// 이 값을 true로 변경하기만 하면 골드 결제 + Holdings 제한이 즉시 복원됩니다.
/// 백엔드(Django), RevenueCat, 광고 시스템은 수정할 필요 없습니다.
///
/// 관련 파일 (이 플래그를 참조하는 곳):
///   - lib/widgets/common/gold_upgrade_sheet.dart       → show() 메서드 게이트
///   - lib/screens/settings/settings_screen.dart        → 구독 섹션 Coming Soon 표시
///   - lib/screens/watchlist/watchlist_screen.dart       → Holdings 제한 체크 + 다이얼로그
///   - lib/screens/holdings/holdings_screen.dart         → Holdings 제한 체크 + 다이얼로그
///   - lib/screens/ticker_detail/ticker_detail_screen.dart → Holdings 제한 체크 + 다이얼로그
///   - lib/screens/watchlist/widgets/portfolio_ai_card.dart → Upgrade 버튼 숨김
///   - lib/screens/calendar/event_calendar_screen.dart   → Upgrade 버튼 숨김
/// ──────────────────────────────────────────────────────────────────
class FeatureFlags {
  static const bool kGoldPurchaseEnabled = false;

  /// ──────────────────────────────────────────────────────────────────
  /// [COMMUNITY_FLAG] — 커뮤니티(UGC) 마스터 플래그
  /// 커뮤니티(게시글/댓글 등 사용자 생성 콘텐츠)의 모든 진입점 노출 여부를 제어.
  ///
  /// false (현재) →
  ///   - 앱 내 모든 커뮤니티 진입점이 숨겨짐 (UGC 미노출)
  ///   - App Store 심사 가이드라인 1.2(UGC 안전장치) 적용 대상에서 제외됨
  ///   - 백엔드/신고/차단/모더레이션 코드는 그대로 유지 (휴면 상태)
  ///
  /// true (복원 시) →
  ///   - 커뮤니티 + 신고 + 차단 + EULA 동의 + 콘텐츠 필터가 즉시 전부 복원됨
  ///   - 단, 복원해 재출시할 때는 1.2 대응(가입 EULA·신고·차단)을 심사 녹화로 제출해야 함
  ///
  /// 【복원 방법 — 명령 한 번】
  /// 이 값을 true로 변경하기만 하면 아래 모든 진입점이 자동 복원됩니다.
  /// 백엔드(Django), 신고/차단 API, EULA, 콘텐츠 필터는 수정할 필요 없습니다.
  ///
  /// 관련 파일 (이 플래그를 참조해 게이트하는 곳):
  ///   - lib/screens/settings/settings_screen.dart        → 설정 '커뮤니티' 섹션(피드/차단관리 진입)
  ///   - lib/screens/ticker_detail/ticker_detail_screen.dart → 종목 상세 하단 실시간 토크 섹션
  ///   - lib/screens/profile/profile_screen.dart           → 프로필 '내 게시글/내 댓글' 섹션
  ///   - lib/main.dart                                     → 푸시 알림 → 게시글 상세 딥링크 라우팅
  ///
  /// 복원 후 점검 체크리스트:
  ///   1) 위 4개 진입점이 모두 노출되는지
  ///   2) 가입 화면 EULA 필수 동의 체크박스 동작 (signup_screen.dart, 항상 유지됨)
  ///   3) 게시글/댓글 신고·차단 메뉴 동작
  ///   4) 백엔드 moderation 마이그레이션 적용 여부 (BlockedUser 테이블)
  ///   5) 심사 제출 시 1.2 대응 실기기 녹화(EULA/신고/차단) 첨부
  /// ──────────────────────────────────────────────────────────────────
  static const bool kCommunityEnabled = false;

  /// ──────────────────────────────────────────────────────────────────
  /// [SUBSCRIPTION_VISIBILITY_FLAG] — 설정 내 구독(Gold 멤버십) 섹션 노출 제어
  /// 설정 화면의 '구독' 섹션(구독 상태·관리·구매 복원·업그레이드 유도) 전체
  /// 노출 여부를 제어. (결제 자체 마스터 플래그는 [GOLD_PURCHASE_FLAG] 별도)
  ///
  /// false (현재) →
  ///   - 설정 화면에서 구독(Gold 멤버십) 섹션이 완전히 숨겨짐
  ///   - 상태/관리/복원/업그레이드 진입점 모두 비노출 (Gold 유저 포함)
  ///   - 백엔드(Django)·RevenueCat·구독 로직·Provider는 그대로 유지 (휴면)
  ///
  /// true (복원 시) →
  ///   - 설정 '구독' 섹션이 즉시 복원됨
  ///   - 내부 표시는 [GOLD_PURCHASE_FLAG] 값에 따라 Coming Soon 또는
  ///     실제 업그레이드 UI로 자동 분기
  ///
  /// 【복원 방법 — 명령 한 번】
  /// 이 값을 true로 변경하기만 하면 설정 구독 섹션이 자동 복원됩니다.
  /// 다른 파일/백엔드 수정 불필요.
  ///
  /// 관련 파일 (이 플래그를 참조해 게이트하는 곳):
  ///   - lib/screens/settings/settings_screen.dart → 구독 섹션 호출부 게이트
  /// ──────────────────────────────────────────────────────────────────
  static const bool kShowSubscriptionInSettings = false;
}
