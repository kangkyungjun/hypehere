/// ContactoTalk 앱 전역 상수 정의
///
/// API URLs, 앱 정보, Storage Keys 등을 관리합니다.
library;

// ============================================================================
// API URLs (자동 fallback 지원 - AWS 우선)
// ============================================================================

/// Django REST API 기본 URL 목록 (우선순위 순서: AWS → localhost → 127.0.0.1)
///
/// EndpointManager가 자동으로 연결 가능한 서버를 찾습니다.
const List<String> apiBaseUrls = [
  'http://43.200.129.55:8000', // 1순위: AWS 프로덕션 서버
  'http://localhost:8000',      // 2순위: 로컬 개발 서버
  'http://127.0.0.1:8000',      // 3순위: 로컬 IP
];

/// WebSocket 서버 기본 URL 목록 (우선순위 순서: AWS → localhost → 127.0.0.1)
const List<String> wsBaseUrls = [
  'ws://43.200.129.55:8001', // 1순위: AWS 프로덕션 서버
  'ws://localhost:8001',      // 2순위: 로컬 개발 서버
  'ws://127.0.0.1:8001',      // 3순위: 로컬 IP
];

/// 기본 API URL (하위 호환성 유지, 첫 번째 우선순위 URL 사용)
const String apiBaseUrl = 'http://43.200.129.55:8000';

/// 기본 WebSocket URL (하위 호환성 유지, 첫 번째 우선순위 URL 사용)
const String wsBaseUrl = 'ws://43.200.129.55:8001';

/// API 엔드포인트
class ApiEndpoints {
  // 인증
  static const String login = '/api/accounts/login/';
  static const String register = '/api/accounts/register/';
  static const String logout = '/api/accounts/logout/';
  static const String tokenRefresh = '/api/accounts/token/refresh/';
  static const String profile = '/api/accounts/profile/';
  static const String stats = '/api/accounts/stats/';

  // 매칭
  static const String matching = '/api/chat/matching/';
  static const String matches = '/api/chat/matches/';

  // 1:1 채팅
  static const String chatRooms = '/api/chat/rooms/';
  static String chatRoom(int id) => '/api/chat/rooms/$id/';
  static String chatMessages(int roomId) => '/api/chat/rooms/$roomId/messages/';

  // 오픈 채팅
  static const String openChatRooms = '/api/chat/open-chat/rooms/';
  static String openChatRoom(int id) => '/api/chat/open-chat/rooms/$id/';
  static String openChatMessages(int roomId) =>
      '/api/chat/open-chat/rooms/$roomId/messages/';
  static String openChatJoin(int roomId) =>
      '/api/chat/open-chat/rooms/$roomId/join/';
  static String openChatLeave(int roomId) =>
      '/api/chat/open-chat/rooms/$roomId/leave/';

  // 차단
  static const String blockedUsers = '/api/chat/blocked-users/';
  static String blockUser(int userId) => '/api/chat/blocked-users/$userId/';
}

/// WebSocket 엔드포인트
class WsEndpoints {
  /// 1:1 채팅 WebSocket
  static String chat(int roomId, String token) =>
      '$wsBaseUrl/ws/chat/$roomId/?token=$token';

  /// 오픈 채팅 WebSocket
  static String openChat(int roomId, String token) =>
      '$wsBaseUrl/ws/open-chat/$roomId/?token=$token';
}

// ============================================================================
// 앱 정보
// ============================================================================

/// 앱 이름
const String appName = 'ContactoTalk';

/// 앱 버전
const String appVersion = '1.0.0';

/// 앱 빌드 번호
const int appBuildNumber = 1;

// ============================================================================
// Storage Keys (Secure Storage & SharedPreferences)
// ============================================================================

/// JWT 액세스 토큰 키
const String accessTokenKey = 'access_token';

/// JWT 리프레시 토큰 키
const String refreshTokenKey = 'refresh_token';

/// 사용자 정보 키
const String userInfoKey = 'user_info';

/// 로그인 상태 유지 키
const String rememberMeKey = 'remember_me';

/// 언어 설정 키
const String languageKey = 'language';

/// 테마 모드 키 (light/dark/system)
const String themeModeKey = 'theme_mode';

// ============================================================================
// 제약 조건 상수
// ============================================================================

/// 최대 메시지 길이
const int maxMessageLength = 500;

/// 최대 프로필 소개 길이
const int maxProfileBioLength = 200;

/// 최대 닉네임 길이
const int maxNicknameLength = 20;

/// 최소 닉네임 길이
const int minNicknameLength = 2;

/// 최소 비밀번호 길이
const int minPasswordLength = 8;

/// 오픈 채팅방 최대 참여자 수
const int maxOpenChatParticipants = 100;

/// 오픈 채팅방 제목 최대 길이
const int maxOpenChatTitleLength = 50;

/// 오픈 채팅방 설명 최대 길이
const int maxOpenChatDescriptionLength = 200;

// ============================================================================
// 타임아웃 설정
// ============================================================================

/// API 요청 타임아웃 (밀리초)
const int apiTimeoutMs = 30000; // 30초

/// WebSocket 연결 타임아웃 (밀리초)
const int wsConnectTimeoutMs = 10000; // 10초

/// 이미지 로딩 캐시 시간 (초)
const int imageCacheDuration = 86400; // 24시간

// ============================================================================
// 페이지네이션
// ============================================================================

/// 기본 페이지 크기
const int defaultPageSize = 20;

/// 메시지 로딩 개수
const int messagesPerPage = 50;

// ============================================================================
// 국가 코드 목록
// ============================================================================

/// 지원하는 국가 코드
const List<String> supportedCountryCodes = [
  'KR', // 대한민국
  'US', // 미국
  'JP', // 일본
  'CN', // 중국
  'GB', // 영국
  'FR', // 프랑스
  'DE', // 독일
  'ES', // 스페인
  'IT', // 이탈리아
  'BR', // 브라질
];

/// 지원하는 국가 목록 (코드: 국가명)
const Map<String, String> supportedCountries = {
  'KR': '대한민국',
  'US': '미국',
  'JP': '일본',
  'CN': '중국',
  'GB': '영국',
  'FR': '프랑스',
  'DE': '독일',
  'ES': '스페인',
  'IT': '이탈리아',
  'BR': '브라질',
  'CA': '캐나다',
  'AU': '호주',
  'IN': '인도',
  'RU': '러시아',
  'MX': '멕시코',
};

// ============================================================================
// 성별 코드
// ============================================================================

/// 성별: 남성
const String genderMale = 'M';

/// 성별: 여성
const String genderFemale = 'F';

/// 성별: 기타
const String genderOther = 'O';

// ============================================================================
// 사용자 역할
// ============================================================================

/// 일반 사용자
const String roleUser = 'user';

/// 프리미엄 사용자
const String rolePremium = 'premium';

/// 관리자
const String roleAdmin = 'admin';

// ============================================================================
// 개발 환경 플래그
// ============================================================================

/// 디버그 모드 여부
const bool isDebugMode = true;

/// 로그 출력 여부
const bool enableLogging = true;
