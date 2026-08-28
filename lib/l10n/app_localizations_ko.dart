// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get blockUser => '사용자 차단';

  @override
  String blockUserConfirm(String nickname) {
    return '$nickname님을 차단할까요? 이 사용자의 게시글과 댓글이 더 이상 표시되지 않습니다.';
  }

  @override
  String get userBlocked => '사용자를 차단했습니다.';

  @override
  String get userUnblocked => '차단을 해제했습니다.';

  @override
  String get blockedUsers => '차단한 사용자';

  @override
  String get noBlockedUsers => '차단한 사용자가 없습니다.';

  @override
  String get unblock => '차단 해제';

  @override
  String get termsAgreementRequired => '가입하려면 이용약관에 동의해야 합니다.';

  @override
  String get eulaZeroTolerance =>
      'MarketLens는 부적절한 콘텐츠와 악의적 행위에 대해 무관용 원칙을 적용합니다.';

  @override
  String get eulaAgreePrefix => '본인은 ';

  @override
  String get eulaAgreeAnd => ' 및 ';

  @override
  String get eulaAgreeSuffix => '에 동의합니다.';

  @override
  String get appTitle => '마켓렌즈';

  @override
  String get tabDashboard => '대시보드';

  @override
  String get tabDashboardTooltip => '마켓 대시보드';

  @override
  String get tabSearch => '검색';

  @override
  String get tabSearchTooltip => '종목 검색';

  @override
  String get tabNews => '뉴스';

  @override
  String get tabNewsTooltip => '시장 뉴스';

  @override
  String get tabCommunity => '커뮤니티';

  @override
  String get tabCommunityTooltip => '토론 게시판';

  @override
  String get tabMarket => '시장';

  @override
  String get tabMarketTooltip => '시장 현황';

  @override
  String get tabAILens => 'AI';

  @override
  String get tabAILensTooltip => 'AI 분석';

  @override
  String get tabWatchlist => '관심종목';

  @override
  String get tabWatchlistTooltip => '나의 관심목록';

  @override
  String get tabHoldingsTooltip => '나의 보유종목';

  @override
  String get settings => '설정';

  @override
  String get settingsTooltip => '설정';

  @override
  String get account => '계정';

  @override
  String get login => '로그인';

  @override
  String get loginSubtitle => '커뮤니티 기능 이용하기';

  @override
  String get signup => '회원가입';

  @override
  String get signupTitle => '회원가입';

  @override
  String get signupSubtitle => '새 계정 만들기';

  @override
  String get noAccountSignup => '계정이 없으신가요? 회원가입';

  @override
  String get hasAccountLogin => '이미 계정이 있으신가요? 로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirmTitle => '로그아웃';

  @override
  String get logoutConfirmMessage => '정말 로그아웃 하시겠습니까?';

  @override
  String get welcome => '환영합니다!';

  @override
  String get accountCreated => '계정이 생성되었습니다!';

  @override
  String get email => '이메일';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => '이메일을 입력하세요';

  @override
  String get emailInvalid => '올바른 이메일 형식이 아닙니다';

  @override
  String get nickname => '닉네임';

  @override
  String get nicknameHint => '커뮤니티에서 사용할 닉네임';

  @override
  String get nicknameRequired => '닉네임을 입력하세요';

  @override
  String get nicknameTooShort => '닉네임은 2글자 이상이어야 합니다';

  @override
  String get password => '비밀번호';

  @override
  String get passwordHint => '비밀번호를 입력하세요';

  @override
  String get passwordRequired => '비밀번호를 입력하세요';

  @override
  String get passwordTooShort => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get passwordAllNumeric => '비밀번호는 숫자로만 구성할 수 없습니다';

  @override
  String get passwordTooCommon => '너무 흔한 비밀번호입니다. 더 안전한 비밀번호를 사용하세요';

  @override
  String get passwordTooSimilar => '비밀번호가 이메일 또는 닉네임과 너무 유사합니다';

  @override
  String get passwordRequirements => '8자 이상, 숫자만 불가, 흔한 비밀번호 불가';

  @override
  String get passwordRuleLength => '8자 이상';

  @override
  String get passwordRuleNotNumeric => '숫자로만 구성 불가';

  @override
  String get passwordRuleNotCommon => '흔한 비밀번호 아님';

  @override
  String get passwordRuleNotSimilar => '이메일·닉네임과 다름';

  @override
  String get passwordConfirm => '비밀번호 확인';

  @override
  String get passwordConfirmHint => '비밀번호를 다시 입력하세요';

  @override
  String get passwordConfirmRequired => '비밀번호 확인을 입력하세요';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get passwordPolicyFailed => '비밀번호가 보안 규칙에 맞지 않습니다. 다른 비밀번호를 사용해 주세요.';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get changePasswordGuide => '비밀번호 변경 안내';

  @override
  String get oldPassword => '현재 비밀번호';

  @override
  String get oldPasswordHint => '현재 사용 중인 비밀번호를 입력하세요';

  @override
  String get oldPasswordRequired => '기존 비밀번호를 입력해주세요';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get newPasswordHint => '새로운 비밀번호를 입력하세요 (최소 8자)';

  @override
  String get newPasswordRequired => '새 비밀번호를 입력해주세요';

  @override
  String get newPasswordConfirm => '새 비밀번호 확인';

  @override
  String get newPasswordConfirmHint => '새 비밀번호를 다시 입력하세요';

  @override
  String get newPasswordConfirmRequired => '새 비밀번호 확인을 입력해주세요';

  @override
  String get newPasswordMustDiffer => '새 비밀번호는 기존 비밀번호와 달라야 합니다';

  @override
  String get passwordChanged => '비밀번호가 성공적으로 변경되었습니다';

  @override
  String passwordChangeFailed(String error) {
    return '비밀번호 변경 실패: $error';
  }

  @override
  String get loginRequired => '로그인이 필요합니다';

  @override
  String get loginPromptMessage => '로그인하고 커뮤니티에 참여하세요!';

  @override
  String get searchHint => '티커 또는 기업명 검색 (예: AAPL, 애플)';

  @override
  String get searchFailed => '검색 실패';

  @override
  String get noSearchResults => '검색 결과 없음';

  @override
  String get tryDifferentSearch => '다른 티커를 검색해보세요';

  @override
  String get tickerSearch => '티커 검색';

  @override
  String get enterTickerAbove => '검색어를 입력하세요';

  @override
  String get recentSearches => '최근 검색';

  @override
  String get clearAll => '전체 삭제';

  @override
  String get retry => '재시도';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get sectorMarketOverview => '섹터별 시장현황';

  @override
  String get filterAll => '전체';

  @override
  String get filterNasdaq => '나스닥';

  @override
  String get filterDow => '다우';

  @override
  String get marketLensAIScore => 'AI 점수';

  @override
  String get aiTabAnalysis => 'AI분석';

  @override
  String get aiTabStocks => 'AI종목';

  @override
  String get aiTabSector => 'AI섹터';

  @override
  String get aiAnalysisComingSoonTitle => '대화형 AI 분석';

  @override
  String get aiAnalysisComingSoonBody =>
      '메신저처럼 질문하면 AI가 시장과 종목을 분석해 드립니다. 기능 구현 예정입니다.';

  @override
  String get comingSoonBadge => '출시 예정';

  @override
  String get aiNoStocksInSegment => '해당 구간 종목이 없습니다';

  @override
  String get distributionShownOnFullLoad => '전체 시그널 로딩 시 분포 표시';

  @override
  String topN(int n) {
    return '▲ 상위 $n';
  }

  @override
  String bottomN(int n) {
    return '▼ 하위 $n';
  }

  @override
  String get noData => '데이터 없음';

  @override
  String get signalLoadFailed => '시그널 로딩 실패';

  @override
  String dashboardLoadFailed(String error) {
    return '대시보드 로딩 실패: $error';
  }

  @override
  String get allSignals => '전체 시그널';

  @override
  String get sp500Signals => 'S&P 500 시그널';

  @override
  String get dow30Signals => 'Dow 30 시그널';

  @override
  String get nasdaq100Signals => 'NASDAQ 100 시그널';

  @override
  String get marketTrend => '전체 시장 동향';

  @override
  String get loadingSignals => '전체 시그널 불러오는 중...';

  @override
  String get loadingSP500Signals => 'S&P 500 시그널 불러오는 중...';

  @override
  String get loadingDow30Signals => 'Dow 30 시그널 불러오는 중...';

  @override
  String get loadingNasdaq100Signals => 'NASDAQ 100 시그널 불러오는 중...';

  @override
  String get noAdditionalSignals => '추가 시그널 없음';

  @override
  String showMore(int remaining) {
    return '더 보기 ($remaining개 남음)';
  }

  @override
  String nItems(int count) {
    return '$count개';
  }

  @override
  String get scoreStrongBuy => '강력긍정';

  @override
  String get scoreBuy => '긍정';

  @override
  String get scoreHold => '중립';

  @override
  String get scoreSell => '부정';

  @override
  String get scoreStrongSell => '강력부정';

  @override
  String get score => '점수';

  @override
  String get myWatchlist => '나의 관심종목';

  @override
  String nTickers(int count) {
    return '$count개 종목';
  }

  @override
  String get watchlistEmpty => '관심 목록이 비어있습니다';

  @override
  String get watchlistEmptyHint => '검색 탭에서 종목을 검색하고 추가하세요';

  @override
  String get explore => '탐색';

  @override
  String get tapToViewDetails => '탭하여 상세 보기';

  @override
  String tickerRemovedFromWatchlist(String ticker) {
    return '$ticker 관심 목록에서 삭제됨';
  }

  @override
  String get undo => '되돌리기';

  @override
  String get tickerDataLoadFailed => '종목 데이터를 불러올 수 없습니다';

  @override
  String get addToWatchlist => '관심 목록에 추가';

  @override
  String get removeFromWatchlist => '관심 목록에서 삭제';

  @override
  String get addedToWatchlist => '관심 목록에 추가됨';

  @override
  String get removedFromWatchlist => '관심 목록에서 삭제됨';

  @override
  String get watchlistDiscoveryTitle => '관심종목을 등록해보세요';

  @override
  String get watchlistDiscoverySubtitle => '등록하면 관련 뉴스·시그널 알림을 받을 수 있어요';

  @override
  String get topTradingVolume => '오늘의 거래량 TOP';

  @override
  String get addWatchlistSearch => '종목 검색하고 추가하기';

  @override
  String get bookmarkGuide => '북마크를 눌러 관심종목에 추가하세요';

  @override
  String get communitySearchHint => '제목, 내용으로 검색...';

  @override
  String get writePost => '글쓰기';

  @override
  String get deletePost => '게시글 삭제';

  @override
  String get deleteConfirm => '정말 이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get done => '완료';

  @override
  String get confirm => '확인';

  @override
  String get dashboardIndexFilterHint => '지수를 탭하면 해당 지수 종목만 필터링됩니다';

  @override
  String get postDeleted => '게시글이 삭제되었습니다';

  @override
  String get report => '신고';

  @override
  String get reportTitle => '신고하기';

  @override
  String get reportAbuse => '욕설/비방';

  @override
  String get reportSpam => '스팸/광고';

  @override
  String get reportInappropriate => '부적절한 내용';

  @override
  String get reportHarassment => '성희롱';

  @override
  String get reportOther => '기타';

  @override
  String get reportDescription => '상세 설명';

  @override
  String get reportSubmitted => '신고가 접수되었습니다';

  @override
  String get reportSubmit => '신고';

  @override
  String postDeleteFailed(String error) {
    return '게시글 삭제 실패: $error';
  }

  @override
  String get noPostsYet => '현재 게시글이 없습니다';

  @override
  String get writeFirstPost => '첫 게시글을 작성해 보세요!';

  @override
  String get noSearchResultsCommunity => '검색 결과가 없습니다';

  @override
  String get tryDifferentFilter => '다른 검색어나 필터를 시도해 보세요';

  @override
  String get networkError => '서버 연결 실패. 잠시 후 다시 시도하세요';

  @override
  String get serverTimeout => '서버 응답 지연. 잠시 후 다시 시도하세요';

  @override
  String get postsLoadFailed => '게시글을 불러올 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get searchResultsLoadFailed => '검색 결과를 불러올 수 없습니다';

  @override
  String get refresh => '새로고침';

  @override
  String get all => '전체';

  @override
  String get add => '추가';

  @override
  String tickerBoard(String ticker) {
    return '$ticker 게시판';
  }

  @override
  String get tickerSearchHint => '티커 검색... (예: AAPL, 테슬라)';

  @override
  String get popularTickers => '인기 티커';

  @override
  String get freePost => '자유';

  @override
  String get checkNetwork => '네트워크 연결을 확인해 주세요';

  @override
  String get tryAgainLater => '잠시 후 다시 시도해 주세요';

  @override
  String get newPost => '새 게시글';

  @override
  String get editPostTitle => '게시글 수정';

  @override
  String get tickerOnlyBoard => '종목 전용 게시판';

  @override
  String get selectTicker => '종목';

  @override
  String get tickerSearchLabel => '종목 검색';

  @override
  String get tickerSearchHintCreate => '영어, 한글, 심볼로 검색';

  @override
  String get tickerNotSelectedHint => '종목을 선택하지 않으면 자유 게시글로 등록됩니다';

  @override
  String get noTickerSearchResults => '검색 결과가 없습니다';

  @override
  String get postTitle => '제목';

  @override
  String get postTitleHint => '게시글 제목을 입력하세요';

  @override
  String get postTitleRequired => '제목을 입력해주세요';

  @override
  String get postTitleTooShort => '제목은 2자 이상 입력해주세요';

  @override
  String get postContent => '내용';

  @override
  String get postContentHint => '게시글 내용을 입력하세요';

  @override
  String get postContentRequired => '내용을 입력해주세요';

  @override
  String get postContentTooShort => '내용은 5자 이상 입력해주세요';

  @override
  String get postCreated => '게시글이 작성되었습니다';

  @override
  String get postUpdated => '게시글이 수정되었습니다';

  @override
  String get submitPost => '게시하기';

  @override
  String get updatePostButton => '수정하기';

  @override
  String get deleteComment => '댓글 삭제';

  @override
  String get deleteCommentConfirm => '정말 이 댓글을 삭제하시겠습니까?';

  @override
  String get editComment => '댓글 수정';

  @override
  String get commentHint => '댓글을 입력하세요...';

  @override
  String get commentPlaceholder => '댓글 내용을 입력하세요';

  @override
  String get commentCreated => '댓글이 작성되었습니다';

  @override
  String get commentUpdated => '댓글이 수정되었습니다';

  @override
  String get commentDeleted => '댓글이 삭제되었습니다';

  @override
  String get commentRequired => '댓글 내용을 입력해주세요';

  @override
  String get loginToViewComments => '댓글을 보려면 로그인이 필요해요';

  @override
  String get writeFirstComment => '첫 번째 댓글을 남겨보세요!';

  @override
  String get postDetail => '게시글';

  @override
  String get startWithFirstPost => '첫 게시글로 시작해보세요';

  @override
  String get writeAPost => '게시글 작성하기';

  @override
  String get cannotLoadPosts => '게시글을 불러올 수 없습니다';

  @override
  String get noPostsInTicker => '아직 게시글이 없습니다';

  @override
  String get writeFirstPostInTicker => '첫 번째 게시글을 작성해보세요!';

  @override
  String get dataManagement => '데이터 관리';

  @override
  String get clearRecentSearches => '최근 검색 기록 삭제';

  @override
  String nSearchRecords(int count) {
    return '$count개 검색 기록';
  }

  @override
  String get clearRecentSearchesConfirm => '모든 최근 검색 기록을 삭제하시겠습니까?';

  @override
  String get recentSearchesCleared => '최근 검색 기록이 삭제되었습니다';

  @override
  String get clearWatchlist => '관심 종목 삭제';

  @override
  String get clearWatchlistConfirm => '모든 관심 종목을 삭제하시겠습니까?';

  @override
  String get watchlistCleared => '관심 종목이 삭제되었습니다';

  @override
  String get deleteAllData => '모든 데이터 삭제';

  @override
  String get deleteAllDataConfirm =>
      '관심 종목 및 최근 검색 기록을 포함한 모든 로컬 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteAllButton => '모두 삭제';

  @override
  String get allDataDeleted => '모든 데이터가 삭제되었습니다';

  @override
  String get removeAllLocalData => '모든 로컬 데이터 제거';

  @override
  String get info => '정보';

  @override
  String get aboutMarketLens => '앱 정보';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get appDescription => '데이터 기반 투자 결정을 위한 AI 기반 주식 분석 도구';

  @override
  String get aiStockAnalysis => 'AI 기반 주식 분석';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get termsOfService => '서비스 이용약관';

  @override
  String get admin => '관리';

  @override
  String get adminPanel => '관리자 패널';

  @override
  String get adminPanelSubtitle => '사용자 관리 및 권한 부여';

  @override
  String get showAds => '광고 표시';

  @override
  String get adsEnabledDescription => '모든 사용자에게 배너 광고 표시 중';

  @override
  String get adsDisabledDescription => '광고가 숨겨진 상태';

  @override
  String get sendPushNotification => '푸시 알림 발송';

  @override
  String get sendPushNotificationSubtitle => '전체 사용자에게 알림 발송';

  @override
  String get pushTitle => '제목';

  @override
  String get pushBody => '내용';

  @override
  String get send => '발송';

  @override
  String pushSentResult(int count) {
    return '$count개 디바이스에 발송 완료';
  }

  @override
  String get pushSendFailed => '푸시 알림 발송 실패';

  @override
  String get promoteToGold => 'Gold 승급';

  @override
  String get promoteToManager => 'Manager 임명';

  @override
  String get demoteToRegular => '일반 회원 강등';

  @override
  String get profile => '프로필';

  @override
  String get editProfile => '프로필 편집';

  @override
  String get myPosts => '내 게시글';

  @override
  String get myComments => '내 댓글';

  @override
  String get viewAll => '전체보기';

  @override
  String get noPosts => '게시글 없음';

  @override
  String get noComments => '댓글 없음';

  @override
  String joinDate(String date) {
    return '가입일: $date';
  }

  @override
  String get deleteAccount => '계정 탈퇴';

  @override
  String get withdrawAccountConfirm =>
      '정말 계정을 탈퇴하시겠습니까?\n7일 후 계정이 영구 삭제되며, 그 전에 다시 로그인하면 탈퇴가 취소됩니다.';

  @override
  String get withdrawAccountReasonHint => '탈퇴 사유를 입력해주세요 (선택사항)';

  @override
  String get withdrawAccountSuccess => '계정 탈퇴가 요청되었습니다. 7일 후 영구 삭제됩니다.';

  @override
  String get withdrawAccountFailed => '계정 탈퇴 요청에 실패했습니다. 다시 시도해주세요.';

  @override
  String get deactivateAccount => '계정 비활성화';

  @override
  String get profileUpdated => '프로필이 업데이트되었습니다';

  @override
  String get imagePickerFailed => '이미지 선택 실패';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文(简体)';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSettings => '언어 설정';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get languageChanged => '언어가 변경되었습니다';

  @override
  String get timeJustNow => '방금 전';

  @override
  String timeMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String get timeYesterday => '어제';

  @override
  String timeDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get companyOverview => '기업 개요';

  @override
  String get companyDetails => '기업 상세';

  @override
  String get companyIntro => '기업 소개';

  @override
  String employeeCount(String count) {
    return '직원 $count명';
  }

  @override
  String get valuation => '밸류에이션';

  @override
  String get forwardPE => '선행 PER';

  @override
  String get beta => '베타';

  @override
  String get profitabilityGrowth => '수익성 & 성장';

  @override
  String get netProfitMargin => '순이익률';

  @override
  String get revenueGrowth => '매출성장';

  @override
  String get operatingMargin => '영업이익률';

  @override
  String get earningsGrowth => '이익성장';

  @override
  String get financialHealth => '재무 건전성';

  @override
  String get debtRatio => '부채비율';

  @override
  String get liquidityRatio => '유동비율';

  @override
  String get dividends => '배당금';

  @override
  String get dividendYield => '배당률 ';

  @override
  String get annualDividend => '연간 ';

  @override
  String get shortInterest => '공매도';

  @override
  String get shortInterestRatio => '공매도 비율';

  @override
  String get shortPercentFloat => '유통주식 대비 %';

  @override
  String shortDays(String days) {
    return '$days일';
  }

  @override
  String get shortInterestLow => '공매도 낮음 (안정)';

  @override
  String get shortInterestModerate => '공매도 보통 (주의)';

  @override
  String get shortInterestHigh => '공매도 높음 (경고)';

  @override
  String get institutionalInsiderFlow => '기관/내부자 흐름';

  @override
  String get institutional => '기관';

  @override
  String get insider => '내부자';

  @override
  String get oneDay => '1일';

  @override
  String get fiveDay => '5일';

  @override
  String tickerNews(String ticker) {
    return '$ticker 뉴스';
  }

  @override
  String newsCount(int count) {
    return '$count건';
  }

  @override
  String get oneWeek => '1주';

  @override
  String get oneMonth => '1월';

  @override
  String get noNews => '뉴스 없음';

  @override
  String get marketNews => '시장 뉴스';

  @override
  String get viewOriginalArticle => '원문 기사 보기';

  @override
  String get sentimentBullish => '호재';

  @override
  String get sentimentNeutral => '중립';

  @override
  String get sentimentBearish => '악재';

  @override
  String get aiSummaryNews => 'AI 요약 뉴스';

  @override
  String get aiSummary => 'AI 요약';

  @override
  String get noNewsAvailable => '뉴스가 없습니다';

  @override
  String get earningsHistory => '이전 실적';

  @override
  String get earningsHistoryEPS => '실적 히스토리 (주당순이익)';

  @override
  String get earningsEstimate => '예상';

  @override
  String get earningsBeat => '상회';

  @override
  String get earningsMiss => '하회';

  @override
  String get earningsActual => '실제';

  @override
  String get earningsScheduled => '예정';

  @override
  String get epsEstimateLabel => '주당순이익(EPS) 예상';

  @override
  String get revenueEstimateLabel => '매출 예상';

  @override
  String get averageLabel => '평균';

  @override
  String get surpriseLabel => '서프라이즈';

  @override
  String get thisWeekEarnings => '이번 주 실적 발표';

  @override
  String get previousEarnings => '이전 실적';

  @override
  String earningsCount(int count) {
    return '$count건';
  }

  @override
  String get noEarningsThisWeek => '이번 주 예정된 실적 발표가 없습니다';

  @override
  String get nextEarningsDate => '다음 실적 발표';

  @override
  String get earningsConfirmed => '확정';

  @override
  String get keyEvents => '주요 일정';

  @override
  String get eventDetails => '일정 상세';

  @override
  String get upcomingEvents => '다음 일정';

  @override
  String get exDividendDate => '배당 기준일';

  @override
  String get dividendPayDate => '배당 지급일';

  @override
  String recentEarningsQuarters(int count) {
    return '최근 실적 ($count분기)';
  }

  @override
  String get earningsHistoryChart => '실적 히스토리 (차트)';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get macroFedFunds => '기준금리';

  @override
  String get macroDGS10 => '장기금리';

  @override
  String get macroDGS2 => '단기금리';

  @override
  String get macroT10Y2Y => '금리차';

  @override
  String get macroVIXCLS => '시장심리';

  @override
  String get macroCPIAUCSL => '물가';

  @override
  String get macroUNRATE => '실업률';

  @override
  String get macroFedFundsDesc => '연준 기준금리';

  @override
  String get macroDGS10Desc => '미국 10년 국채금리';

  @override
  String get macroDGS2Desc => '미국 2년 국채금리';

  @override
  String get macroT10Y2YDesc => '장단기 금리차 (10Y-2Y)';

  @override
  String get macroVIXCLSDesc => '시장 변동성 지수';

  @override
  String get macroCPIAUCSLDesc => '소비자물가지수 (CPI)';

  @override
  String get macroUNRATEDesc => '미국 실업률';

  @override
  String get riskBearish => '위험';

  @override
  String get riskCautious => '주의';

  @override
  String get riskNeutral => '중립';

  @override
  String get riskPositive => '양호';

  @override
  String get riskBullish => '강세';

  @override
  String get macroCategoryRates => '금리';

  @override
  String get macroCategorySentiment => '심리';

  @override
  String get macroCategoryEconomy => '경제';

  @override
  String get macroYieldCurve => '수익률곡선';

  @override
  String get macroLiquidity => '유동성';

  @override
  String get macroOverall => '거시경제';

  @override
  String macroCurrentValue(String value) {
    return '현재값: $value';
  }

  @override
  String macroChange(String value) {
    return '변동: $value';
  }

  @override
  String epsEstimateValue(String value) {
    return '예상 \$$value';
  }

  @override
  String get bbInterpretation => 'Bollinger Bands 해석';

  @override
  String get bbBandWidth => '• 밴드 폭: 변동성 표시 (넓을수록 변동성 높음)';

  @override
  String get bbUpperApproach => '• 상단 밴드 접근: 과매수 가능성';

  @override
  String get bbLowerApproach => '• 하단 밴드 접근: 과매도 가능성';

  @override
  String get bbMiddleLine => '• 중간선: 20일 이동평균선';

  @override
  String get cannotLoadData => '데이터를 불러올 수 없습니다';

  @override
  String get marketlensAI => '마켓랜즈 AI';

  @override
  String get marketlensAIOpinion => '마켓랜즈 AI 의견';

  @override
  String get bullishFactors => '강세 요인';

  @override
  String get bearishFactors => '약세 요인';

  @override
  String get expertAnalysis => '전문가 분석';

  @override
  String get expertKeyFactors => '핵심 요인';

  @override
  String get predictionBullish => '상승';

  @override
  String get predictionBearish => '하락';

  @override
  String get predictionNeutral => '중립';

  @override
  String get target => '목표 ';

  @override
  String get stopLoss => '손절 ';

  @override
  String get averageTargetPrice => '평균 목표가';

  @override
  String get currentPrice => '현재가';

  @override
  String get targetPrice => '목표가';

  @override
  String get recentAnalystRatings => '최근 투자 의견';

  @override
  String get unknownFirm => '미상';

  @override
  String get volume => '거래량';

  @override
  String get legend => '범례';

  @override
  String get ratingBuy => '매수';

  @override
  String get ratingStrongBuy => '적극 매수';

  @override
  String get ratingOutperform => '시장 상회';

  @override
  String get ratingHold => '보유';

  @override
  String get ratingNeutral => '중립';

  @override
  String get ratingMarketPerform => '시장 수준';

  @override
  String get ratingSell => '매도';

  @override
  String get ratingStrongSell => '적극 매도';

  @override
  String get ratingUnderperform => '시장 하회';

  @override
  String get ratingActionUpgrade => '상향';

  @override
  String get ratingActionDowngrade => '하향';

  @override
  String get ratingActionReiterated => '유지';

  @override
  String get ratingActionInitiated => '신규';

  @override
  String get roleMaster => 'Master';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleGold => 'Gold';

  @override
  String get roleRegular => '일반';

  @override
  String get roleGuest => '게스트';

  @override
  String get errInvalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get errLoginRequired => '로그인이 필요합니다';

  @override
  String get errSessionExpired => '인증이 만료되었습니다. 다시 로그인해주세요.';

  @override
  String get errCannotLoadUser => '사용자 정보를 불러올 수 없습니다';

  @override
  String get errServerConnection => '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.';

  @override
  String get errServerConnectionShort => '서버에 연결할 수 없습니다';

  @override
  String get errNetworkFailed => '네트워크 연결 실패. 인터넷 연결을 확인해주세요.';

  @override
  String get errResponseFormat => '서버 응답 형식 오류';

  @override
  String errTimeout(int seconds) {
    return '서버 응답 시간 초과 ($seconds초)';
  }

  @override
  String get errBadRequest => '입력 정보를 확인해주세요';

  @override
  String get errForbidden => '접근 권한이 없습니다';

  @override
  String get errNotFound => '요청한 페이지를 찾을 수 없습니다';

  @override
  String get errServerError => '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get errNoEditPermission => '수정 권한이 없습니다';

  @override
  String get errNoDeletePermission => '삭제 권한이 없습니다';

  @override
  String get errPostDeleteFailed => '게시글 삭제 실패';

  @override
  String get errCommentDeleteFailed => '댓글 삭제 실패';

  @override
  String get errReportAlreadySubmitted => '이미 신고한 게시물입니다';

  @override
  String get errCannotReportOwn => '자신의 글은 신고할 수 없습니다';

  @override
  String get errReportFailed => '신고 접수에 실패했습니다';

  @override
  String get errManagerRequired => '권한이 없습니다. Manager 이상만 접근 가능합니다.';

  @override
  String get errMasterRequired => '권한이 없습니다. Master만 접근 가능합니다.';

  @override
  String get errSearchRequired => '검색어를 입력해주세요';

  @override
  String get errDemotionFailed => '강등 실패';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get dayBeforeYesterday => '그저께';

  @override
  String expertCount(String count) {
    return '기관 목표가 ($count기관)';
  }

  @override
  String scorePoints(String score) {
    return '$score점';
  }

  @override
  String averageVolume(String volume) {
    return '평균: $volume';
  }

  @override
  String get showBullBearFactors => '강세/약세 요인 보기';

  @override
  String get hideBullBearFactors => '강세/약세 요인 접기';

  @override
  String analystConsensus(String count) {
    return '증권사 목표가 ($count 기관)';
  }

  @override
  String lowestPrice(String price) {
    return '최저 \$$price';
  }

  @override
  String highestPrice(String price) {
    return '최고 \$$price';
  }

  @override
  String get liveTalk => '💬 실시간 토크';

  @override
  String commentsCount(int count) {
    return '댓글 $count개';
  }

  @override
  String get browsePosts => '게시글 둘러보기';

  @override
  String get loginPromptComments => '다른 투자자들의 의견을 확인하고\n나만의 분석을 공유해보세요!';

  @override
  String get shareThoughtsPrompt => '관심 종목에 대한 생각을 공유하고\n다른 투자자들과 소통해보세요';

  @override
  String get writeFirstCommentPrompt => '게시글에 첫 댓글을 남겨보세요';

  @override
  String get startConversationPrompt => '다른 투자자들의 의견에 댓글로\n대화를 시작해보세요';

  @override
  String get ratingOverweight => '비중확대';

  @override
  String get ratingUnderweight => '비중축소';

  @override
  String get ratingSectorOutperform => '업종 상회';

  @override
  String get ratingSectorPerform => '업종 수준';

  @override
  String get ratingSectorUnderperform => '업종 하회';

  @override
  String get ratingPositive => '긍정';

  @override
  String get ratingNegative => '부정';

  @override
  String get ratingEqualWeight => '중립';

  @override
  String get keyMetricsComparison => '주요 지표 비교';

  @override
  String get metric => '지표';

  @override
  String get serverCalculatedNote => '※ 모든 지표는 서버에서 계산된 값입니다';

  @override
  String get priceTrendComparison => '가격 추이 비교';

  @override
  String get rsiComparison => 'RSI 비교 (서버 계산 값)';

  @override
  String get rsiInterpretation => '※ RSI > 70: 과매수 / RSI < 30: 과매도';

  @override
  String get passwordChangeInstructions =>
      '• 새 비밀번호는 최소 8자 이상이어야 합니다\n• 영문, 숫자, 특수문자를 조합하여 사용하세요\n• 변경 후 새 비밀번호로 다시 로그인해주세요';

  @override
  String get notifications => '알림';

  @override
  String get markAllAsRead => '모두 읽음';

  @override
  String get noNotifications => '알림이 없습니다';

  @override
  String get notificationsRetentionHint => '최근 7일간의 알림이 표시됩니다.';

  @override
  String get bioLabel => '소개글';

  @override
  String get bioHint => '자신을 소개해주세요';

  @override
  String get profileEditGuide => '프로필 편집 안내';

  @override
  String get profileEditGuideDetails =>
      '• 닉네임: 2-30자, 다른 사용자와 중복 가능\n• 소개글: 최대 200자 (선택사항)\n• 프로필 사진: 권장 크기 800x800px';

  @override
  String get updatedDate => '업데이트:';

  @override
  String get tabCalendar => '캘린더';

  @override
  String get tabCalendarTooltip => '이벤트 캘린더';

  @override
  String get eventTypeFomc => 'FOMC';

  @override
  String get eventTypeEarnings => '실적발표';

  @override
  String get eventTypeEconomic => '경제지표';

  @override
  String get eventTypeOptionsExpiry => '옵션만기';

  @override
  String get eventTypeConference => '컨퍼런스';

  @override
  String get eventTypeDividend => '배당';

  @override
  String get eventTypeProductLaunch => '제품출시';

  @override
  String get eventTypeShareholder => '주주총회';

  @override
  String get eventTypeFedSpeech => '연준 연설';

  @override
  String nEvents(int count) {
    return '$count개 이벤트';
  }

  @override
  String get noEventsThisMonth => '이번 달 이벤트가 없습니다';

  @override
  String get noEventsSelectedDay => '선택한 날짜에 이벤트가 없습니다';

  @override
  String get calendarNewsAnnouncements => '뉴스·발표';

  @override
  String get calendarEconomicIndicators => '미국 경제지표';

  @override
  String get calendarViewResult => '결과 보기';

  @override
  String get forgotPassword => '비밀번호 찾기';

  @override
  String get forgotPasswordSubtitle => '가입한 이메일을 입력하시면 인증코드를 보내드립니다.';

  @override
  String get sendVerificationCode => '인증코드 발송';

  @override
  String get verificationTitle => '이메일 인증';

  @override
  String verificationSubtitle(String email) {
    return '$email로 발송된 6자리 인증코드를 입력하세요.';
  }

  @override
  String verificationExpiry(String time) {
    return '유효시간: $time';
  }

  @override
  String get verificationCode => '인증코드';

  @override
  String get verificationCodeRequired => '6자리 인증코드를 입력하세요';

  @override
  String get verifyButton => '인증하기';

  @override
  String get resendCode => '인증코드 재발송';

  @override
  String resendCodeCooldown(int seconds) {
    return '재발송 가능 ($seconds초)';
  }

  @override
  String get verificationCodeResent => '인증코드가 재발송되었습니다.';

  @override
  String get resetPassword => '비밀번호 재설정';

  @override
  String get resetPasswordSubtitle => '새로운 비밀번호를 입력하세요.';

  @override
  String get resetPasswordSuccess => '비밀번호가 재설정되었습니다. 새 비밀번호로 로그인하세요.';

  @override
  String get errEmailNotVerified => '이메일 인증이 필요합니다.';

  @override
  String get errRateLimited => '잠시 후 다시 시도해주세요.';

  @override
  String get myHoldings => '나의 보유종목';

  @override
  String nHoldings(int count) {
    return '$count개 보유';
  }

  @override
  String get portfolioSummary => '포트폴리오 요약';

  @override
  String get totalValue => '총 가치';

  @override
  String get totalPnl => '총 손익';

  @override
  String get dayPnl => '오늘';

  @override
  String get buyStock => '매수';

  @override
  String get shares => '주수';

  @override
  String get avgPrice => '평균단가';

  @override
  String get totalCost => '총 매수금액';

  @override
  String get enterShares => '주수를 입력하세요';

  @override
  String get enterAvgPrice => '평균 매수가를 입력하세요';

  @override
  String get buyConfirm => '보유에 추가';

  @override
  String holdingAdded(String ticker) {
    return '$ticker 보유종목에 추가됨';
  }

  @override
  String holdingRemoved(String ticker) {
    return '$ticker 보유종목에서 삭제됨';
  }

  @override
  String removeHoldingConfirm(String ticker) {
    return '$ticker을(를) 보유종목에서 삭제하시겠습니까?';
  }

  @override
  String get aiAdvice => 'AI 자문';

  @override
  String get aiAdviceInstant => '즉시 AI 자문';

  @override
  String get bullishFactorsPortfolio => '상승 요인';

  @override
  String get bearishFactorsPortfolio => '하락 요인';

  @override
  String get detailedAnalysisComingSoon => '상세 분석은 내일 오전에 업데이트됩니다';

  @override
  String get loginForPortfolio => '로그인하여 포트폴리오를 관리하세요';

  @override
  String get loginForPortfolioHint => '보유종목 추적, AI 자문, 손익 관리';

  @override
  String sharesAtPrice(String shares, String price) {
    return '$shares주 @ \$$price';
  }

  @override
  String get noHoldingsYet => '보유종목이 없습니다';

  @override
  String get addFirstHolding => '관심종목에서 매수하여 시작하세요';

  @override
  String get invalidShares => '유효한 주수를 입력하세요';

  @override
  String get invalidPrice => '유효한 가격을 입력하세요';

  @override
  String get confidence => '신뢰도';

  @override
  String get tabHoldings => '보유종목';

  @override
  String get purchaseDate => '매수일';

  @override
  String get sellDate => '매도일';

  @override
  String get sellPrice => '매도 단가';

  @override
  String get sellShares => '매도 수량';

  @override
  String get sellConfirm => '매도 확인';

  @override
  String get sellAll => '전량 매도';

  @override
  String get sellAmount => '매도금액';

  @override
  String get realizedPnlLabel => '실현손익';

  @override
  String get unrealizedPnl => '미실현손익';

  @override
  String get realizedPnl => '실현손익';

  @override
  String get transactionHistory => '거래 이력';

  @override
  String get additionalBuy => '추가 매수';

  @override
  String get partialSell => '매도';

  @override
  String get editHolding => '정보 수정';

  @override
  String get saveChanges => '수정 저장';

  @override
  String holdingUpdated(String ticker) {
    return '$ticker 보유 정보가 수정되었습니다';
  }

  @override
  String get portfolioAIAnalysis => '포트폴리오 AI 분석';

  @override
  String get aiRecommendations => '추천사항';

  @override
  String get todayPicks => '오늘의 추천 종목';

  @override
  String get aiChatTitle => 'AI 대화';

  @override
  String get aiChatHint => '메시지를 입력하세요';

  @override
  String get aiChatEmptyTitle => '무엇이든 물어보세요';

  @override
  String get aiChatEmptySubtitle => '종목·포트폴리오에 대해 AI와 대화하세요';

  @override
  String get aiChatDailyDisclaimer =>
      'AI 분석은 참고용 정보이며, 투자 판단과 그 책임은 본인에게 있습니다.';

  @override
  String get aiChatSuggestionsTitle => '이런 질문은 어때요?';

  @override
  String get aiChatShuffle => '다른 질문';

  @override
  String get aiChatAnalyzeMyHoldings => '내 보유 종목 분석';

  @override
  String get macroAiCardTitle => 'AI 변동성 분석';

  @override
  String get macroAiCardLoading => '분석 중…';

  @override
  String get macroAiCardError => '지금은 분석을 가져올 수 없어요. 잠시 후 다시 시도해 보세요.';

  @override
  String get macroAiCardRetry => '다시 시도';

  @override
  String get macroAiCardCadence => '거래일마다 갱신';

  @override
  String get macroAiCardWatchAdCta => '오늘 AI 분석을 받으려면 짧은 광고를 시청해 주세요.';

  @override
  String get macroAiCardWatchAdAction => '광고 보고 분석 받기';

  @override
  String get macroAiCardAdUnavailable => '광고를 불러올 수 없어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get aiChatGreetingCooldownTitle => 'AI 인사 빈도';

  @override
  String get aiChatGreetingCooldownOff => '끄기';

  @override
  String get aiChatGreetingCooldown2h => '2시간';

  @override
  String get aiChatGreetingCooldownDaily => '하루 1회';

  @override
  String get aiChatCopy => '복사';

  @override
  String get aiChatShare => '공유';

  @override
  String get aiChatCopied => '복사됨';

  @override
  String get aiChatShareQ => '질문';

  @override
  String get aiChatShareA => '답변';

  @override
  String get aiChatShareFooter => '— MarketLens AI';

  @override
  String get aiChatThinking => 'AI가 생각 중…';

  @override
  String get aiChatErrorRetry => '응답을 가져오지 못했어요. 다시 시도해 주세요.';

  @override
  String get aiChatLoginRequired => 'AI와 대화하려면 로그인하세요';

  @override
  String get aiChatNew => '새 대화';

  @override
  String get aiChatHistory => '이전 대화';

  @override
  String get aiChatNoHistory => '이전 대화가 없습니다';

  @override
  String get aiChatFreeRemaining => '남은 무료';

  @override
  String get aiChatSelect => '선택';

  @override
  String aiChatSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get aiChatHide => '숨기기';

  @override
  String get aiChatHideConfirm => '선택한 대화를 이 폰에서 숨기시겠어요? 서버에는 그대로 보관됩니다.';

  @override
  String get aiChatStorageSettings => 'AI 채팅 저장 설정';

  @override
  String get aiChatStorageSettingsSubtitle => '대화 보관 한도 · 폰 저장량 관리';

  @override
  String get aiChatStorageUsage => '현재 사용량';

  @override
  String get aiChatStorageLimit => '보관 한도';

  @override
  String get aiChatStorageBytes => '저장 용량';

  @override
  String get aiChatStorageNote =>
      '한도를 넘으면 가장 오래된 대화부터 자동 삭제됩니다. 서버에는 모두 보존되므로 학습 자료는 손실되지 않습니다.';

  @override
  String get aiChatUnlimited => '무제한';

  @override
  String aiChatNConversations(int count) {
    return '$count건';
  }

  @override
  String get aiChatClearLocal => '이 폰의 모든 대화 캐시 삭제';

  @override
  String get aiChatClearLocalDesc => '서버에 저장된 대화는 그대로 유지됩니다';

  @override
  String get aiChatClearLocalConfirm => '이 폰에 저장된 모든 대화 캐시를 지우시겠어요?';

  @override
  String get aiChatLocalCleared => '폰의 대화 캐시가 삭제되었습니다';

  @override
  String get recPortfolioOverview => '포트폴리오 개요';

  @override
  String get recTechnicalInsight => '기술적 분석';

  @override
  String get recMarketIntelligence => '시장 인텔리전스';

  @override
  String get recActionSummary => '실행 요약';

  @override
  String get recCompanyClassification => '기업분류';

  @override
  String get recAnalystSummary => '애널리스트 요약';

  @override
  String get recMarketSummary => '시장 요약';

  @override
  String get recUpcomingEvents => '향후 주요 이벤트';

  @override
  String get recBuyRecommend => '보유 확대 (추가매수 추천)';

  @override
  String get recHoldRecommend => '보유 유지 (관망 필요)';

  @override
  String get recSellRecommend => '보유 축소 (매도 추천)';

  @override
  String get recommendedAction => '권고 사항';

  @override
  String get analysisWaiting => 'AI 분석 대기 중...';

  @override
  String get alreadyHeld => '보유중';

  @override
  String get goToWatchlistTab => '관심종목 탭으로 이동';

  @override
  String get noHoldingsHint => '관심종목에서 보유 종목을 추가하세요';

  @override
  String get addHoldingDirect => '종목 추가하기';

  @override
  String get aiPortfolioBenefitTitle => '종목을 등록하면 매일 아침\nAI가 맞춤 투자 인사이트를 제공합니다';

  @override
  String get aiPortfolioBenefit1 => '포트폴리오 리밸런싱 제안';

  @override
  String get aiPortfolioBenefit2 => '기술적 매매 신호 분석';

  @override
  String get aiPortfolioBenefit3 => '시장 뉴스 기반 영향도 평가';

  @override
  String get searchTickerHint => '종목명 또는 티커 검색';

  @override
  String get addToPortfolio => '보유종목에 추가';

  @override
  String get alreadyInHoldings => '이미 보유 중인 종목입니다';

  @override
  String get closingPriceAuto => '종가 자동 입력';

  @override
  String holidayPriceNotice(String date) {
    return '$date 종가 기준 (직전 거래일)';
  }

  @override
  String get addToHoldings => '보유에 추가';

  @override
  String get currentHoldings => '보유현황';

  @override
  String get holdingStatus => '보유 현황';

  @override
  String addHoldingTitle(String ticker) {
    return '$ticker 보유 추가';
  }

  @override
  String sellHoldingTitle(String ticker) {
    return '$ticker 매도';
  }

  @override
  String editHoldingTitle(String ticker) {
    return '$ticker 보유 정보 수정';
  }

  @override
  String holdingSold(String ticker) {
    return '$ticker 매도 완료';
  }

  @override
  String get deleteHolding => '보유 삭제';

  @override
  String get avgPriceLabel => '평균단가';

  @override
  String get currentValueLabel => '평가액';

  @override
  String get dailyUpdate => '매일 오전 업데이트';

  @override
  String get aiRefreshOnChange => '종목 변경 시 자동 갱신';

  @override
  String get aiUpdateButton => 'AI 분석 업데이트';

  @override
  String get aiUpdating => '분석 업데이트 중…';

  @override
  String get aiNoChangeToAnalyze => '변경 사항이 없어 새 분석이 필요하지 않습니다';

  @override
  String get aiAnalysisOnDemandHint => '포트폴리오 변경 또는 날짜가 바뀌면 업데이트할 수 있어요';

  @override
  String get aiUpdateInProgressHint => '분석 생성 중… 최대 1분 정도 걸려요.';

  @override
  String get aiUpdateDelayed => '분석 생성이 조금 지연되고 있어요. 잠시 후 자동으로 반영됩니다.';

  @override
  String lastUpdateTime(String time) {
    return '마지막 업데이트: $time';
  }

  @override
  String get viewAIAdvice => 'AI 의견 보기';

  @override
  String get noAnalysisYet => '아직 분석이 없습니다';

  @override
  String get recentTransactions => '최근 거래';

  @override
  String viewAllTransactions(int count) {
    return '전체 보기 ($count건)';
  }

  @override
  String get newsFilter => '필터';

  @override
  String get filterSource => '소스';

  @override
  String get filterMyWatchlist => '관심종목';

  @override
  String get filterNoWatchlist => '관심종목을 먼저 추가하세요';

  @override
  String get filterMarketOnly => '시장뉴스';

  @override
  String get filterSentiment => '감성';

  @override
  String get filterSector => '섹터';

  @override
  String get filterBreakingOnly => '속보만 보기';

  @override
  String get filterReset => '초기화';

  @override
  String get filterApply => '적용';

  @override
  String hotTopicMore(int count) {
    return '+$count 더보기';
  }

  @override
  String get sectorTechnology => '기술';

  @override
  String get sectorHealthcare => '헬스케어';

  @override
  String get sectorEnergy => '에너지';

  @override
  String get sectorCyclical => '경기소비재';

  @override
  String get sectorDefensive => '필수소비재';

  @override
  String get sectorComm => '커뮤니케이션';

  @override
  String get sectorFinance => '금융';

  @override
  String get sectorIndustrials => '산업재';

  @override
  String get sectorUtilities => '유틸리티';

  @override
  String get sectorRealEstate => '부동산';

  @override
  String get sectorMaterials => '소재';

  @override
  String get newsBubbleTitle => '24시간 Hot 뉴스';

  @override
  String get newsBubbleLegendBullish => '강세 다수';

  @override
  String get newsBubbleLegendBearish => '약세 다수';

  @override
  String get newsBubbleLegendMixed => '혼합';

  @override
  String newsBubbleMentions(int count) {
    return '$count건';
  }

  @override
  String get newsSentiment24hTitle => '최근 24시간';

  @override
  String get newsBullish => '강세뉴스';

  @override
  String get newsNeutral => '중립뉴스';

  @override
  String get newsBearish => '약세뉴스';

  @override
  String get keyNewsTitle => '금일 핵심 뉴스';

  @override
  String get viewTickerDetail => '종목으로 이동';

  @override
  String newsCountUnit(int count) {
    return '$count건';
  }

  @override
  String get taxEstimateTitle => '양도소득세 예상';

  @override
  String get totalGains => '총 양도차익';

  @override
  String get annualExemption => '기본공제 (250만원)';

  @override
  String get estimatedTax => '예상 세금 (22%)';

  @override
  String get netProfit => '세후 순수익';

  @override
  String get krwSuffix => '원';

  @override
  String get taxTradeCount => '건 매도';

  @override
  String get macro3mTitle => '3개월';

  @override
  String get macro3mHigh => '3M 최고';

  @override
  String get macro3mAvg => '3M 평균';

  @override
  String get macro3mLow => '3M 최저';

  @override
  String get tooltipClearSearch => '검색 지우기';

  @override
  String get tooltipPreviousMonth => '이전 달';

  @override
  String get tooltipNextMonth => '다음 달';

  @override
  String get tooltipSelectMonth => '월 선택';

  @override
  String get tooltipShowPassword => '비밀번호 표시';

  @override
  String get tooltipHidePassword => '비밀번호 숨기기';

  @override
  String get tooltipChangePhoto => '사진 변경';

  @override
  String get tooltipFilter => '필터';

  @override
  String get tooltipRemove => '삭제';

  @override
  String get otherSectors => '기타 섹터';

  @override
  String get otherTickers => '기타 종목';

  @override
  String nDaysAgo(int count) {
    return '$count일전';
  }

  @override
  String get tabHome => '홈';

  @override
  String get tabHomeTooltip => '홈';

  @override
  String get tabAIAnalysis => 'AI 신호';

  @override
  String get tabToday => '오늘';

  @override
  String get tabUpDown => '등락';

  @override
  String get tabIndexes => '지표';

  @override
  String get macroCurrentLabel => '현재값';

  @override
  String get macroChangeLabel => '변동';

  @override
  String get tradingVolumeTop => '거래대금';

  @override
  String get gainersTop => '상승률';

  @override
  String get losersTop => '하락률';

  @override
  String get volumeTop => '거래량';

  @override
  String get topByMarketCap => '시가총액 상위';

  @override
  String get viewMore => '더보기';

  @override
  String get gaugeStrongNegativeDesc => '강력부정: 주가 하락 확률 매우 높음';

  @override
  String get gaugeNegativeDesc => '부정: 주가 하락 확률 높음';

  @override
  String get gaugePositiveDesc => '긍정: 주가 상승 확률 높음';

  @override
  String get gaugeStrongPositiveDesc => '강력긍정: 주가 상승 확률 매우 높음';

  @override
  String aiRecommended20(int count) {
    return 'AI 분석 추천 $count 종목';
  }

  @override
  String aiCaution20(int count) {
    return 'AI 분석 주의 $count 종목';
  }

  @override
  String get seeMore => '더보기';

  @override
  String get holdingsSummary => '보유현황';

  @override
  String get investmentReturn => '투자 수익률';

  @override
  String get returnRate => '수익률';

  @override
  String get purchaseAmount => '매수금';

  @override
  String get profitAmount => '수익금';

  @override
  String get evaluationAmount => '평가금';

  @override
  String get watchAdToUnlock => '짧은 광고를 보고 AI 분석을 확인하세요';

  @override
  String get watchAd => '광고 보기';

  @override
  String get adNotReady => '광고를 준비 중입니다. 잠시 후 다시 시도하세요';

  @override
  String get holdingsLimitTitle => '보유종목 제한';

  @override
  String get holdingsLimitMessage =>
      '무료 회원은 최대 3개 종목까지 보유할 수 있습니다. Gold으로 업그레이드하면 무제한 종목 관리와 광고 없는 AI 분석을 이용하세요.';

  @override
  String get upgradeToGold => 'Gold 업그레이드';

  @override
  String get goldBenefitUnlimitedHoldings => '무제한 보유종목 관리';

  @override
  String get goldBenefitAIUnlimited => '광고 없는 AI 분석';

  @override
  String get goldBenefitNoAds => '광고 완전 제거';

  @override
  String get newAiAnalysisAvailable => '새로운 AI 분석이 도착했습니다';

  @override
  String get viewingPreviousAnalysis => '이전 분석 보기';

  @override
  String get goldUpgradeComingSoon => 'Gold 멤버십이 곧 출시됩니다! 기대해주세요.';

  @override
  String get close => '닫기';

  @override
  String goldMonthlyPrice(String price) {
    return '월 $price';
  }

  @override
  String get subscribeNow => '구독하기';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get purchaseRestored => '구매가 복원되었습니다';

  @override
  String get purchaseRestoreFailed => '복원할 구매 내역이 없습니다';

  @override
  String get purchaseFailed => '구매에 실패했습니다. 다시 시도해주세요.';

  @override
  String get purchaseCancelled => '구매가 취소되었습니다';

  @override
  String get subscriptionActive => '활성';

  @override
  String subscriptionExpires(String date) {
    return '$date 만료';
  }

  @override
  String get subscriptionManage => '구독 관리';

  @override
  String get subscriptionTermsIos =>
      '결제는 App Store 계정으로 청구됩니다. 현재 기간 종료 24시간 전에 취소하지 않으면 자동으로 갱신됩니다.';

  @override
  String get subscriptionTermsAndroid =>
      '결제는 Google Play 계정으로 청구됩니다. 현재 기간 종료 24시간 전에 취소하지 않으면 자동으로 갱신됩니다.';

  @override
  String get goldMembershipTitle => 'Gold 멤버십';

  @override
  String get goldComingSoon => 'Gold 멤버십 준비 중입니다!';

  @override
  String get subscription => '구독';

  @override
  String get freeTrialStart => '7일 무료 체험 시작하기';

  @override
  String freeTrialInfo(String price) {
    return '7일 무료, 이후 $price/월. 언제든 취소 가능.';
  }

  @override
  String get onFreeTrial => '무료 체험 중';

  @override
  String trialEndsOn(String date) {
    return '체험 종료: $date';
  }

  @override
  String get trialExpired => '무료 체험이 종료되었습니다';

  @override
  String get manageSubscription => '구독 관리';

  @override
  String get restorePurchaseTitle => '이전 구매 복원';

  @override
  String get restorePurchaseDescription =>
      '기기 변경이나 앱 재설치 후 구독이 반영되지 않을 때 사용하세요.';

  @override
  String calendarPremiumEvents(int count) {
    return '$count개 프리미엄 일정';
  }

  @override
  String get calendarUnlockWithAd => '광고 보고 6시간 이용';

  @override
  String calendarUnlockedUntil(String time) {
    return '$time까지 잠금 해제';
  }

  @override
  String get treemapLegend => '크기 = 거래대금  |  초록 = 상승  |  빨강 = 하락';

  @override
  String get aiScoreSubtitle => 'AI 점수 (0: 매도 신호 ~ 100: 매수 신호)';

  @override
  String get aiSignalStrongBuyDesc => '강력 매수 (80-100): 기술적·재무적 지표가 모두 강한 매수 신호';

  @override
  String get aiSignalBuyDesc => '매수 (60-79): 전반적으로 긍정적 신호';

  @override
  String get aiSignalHoldDesc => '보유 (40-59): 혼합 신호, 현재 포지션 유지';

  @override
  String get aiSignalSellDesc => '매도 (20-39): 전반적으로 부정적 신호';

  @override
  String get aiSignalStrongSellDesc => '강력 매도 (0-19): 기술적·재무적 지표가 모두 강한 매도 신호';

  @override
  String get watchlistSubtitle => '관심 종목을 모아보세요';

  @override
  String get wlTargetPrice => '목표가';

  @override
  String get wlPrice1mAgo => '1개월 전';

  @override
  String get wlPrice3mAgo => '3개월 전';

  @override
  String get filterActiveLabel => '필터 적용 중';

  @override
  String get tapToRemoveFilter => '탭하여 해제';

  @override
  String get searchTickersCta => '종목 검색하기';

  @override
  String get addTickersCta => '종목 추가하기';

  @override
  String get beFirstToPost => '첫 글을 작성해보세요!';

  @override
  String totalPosts(int count) {
    return '$count개 게시글';
  }

  @override
  String get recentComments => '최근 댓글';

  @override
  String get coachMarkDashboardTreemap => '색상은 주가 변동, 크기는 거래량을 나타냅니다';

  @override
  String get coachMarkAiLens => 'AI가 분석한 종목별 매수/매도 신호 분포입니다';

  @override
  String get coachMarkWatchlist => '관심 종목을 추가해보세요!';

  @override
  String get coachMarkHoldings => '보유 종목을 등록하면 수익률을 추적할 수 있습니다';

  @override
  String get coachMarkTickerScore => 'AI 점수 추이를 확인하세요. 70 이상은 매수 신호입니다';

  @override
  String get coachMarkMacroGauge => '좌우로 스와이프하여 경제 지표를 확인하세요';

  @override
  String get coachMarkGotIt => '확인';

  @override
  String get resetTutorials => '튜토리얼 다시 보기';

  @override
  String get resetTutorialsDesc => '모든 튜토리얼이 다시 표시됩니다';

  @override
  String get tutorialsReset => '튜토리얼이 초기화되었습니다';

  @override
  String get purchaseStoreUnavailable => 'App Store 연결 불가';

  @override
  String get purchaseTemporarilyUnavailable => '구독을 일시적으로 이용할 수 없습니다';

  @override
  String get purchaseStoreProblem =>
      'App Store에 연결할 수 없습니다. Apple ID 설정을 확인하고, 결제가 활성화되어 있는지 확인한 후 다시 시도해주세요.';

  @override
  String get purchaseRetry => '다시 시도';

  @override
  String get purchaseInitializing => 'App Store에 연결 중...';

  @override
  String get loginRequiredForPurchase =>
      'Gold 멤버십 구매를 위해 로그인이 필요합니다. 구독 정보가 계정에 동기화됩니다.';

  @override
  String get aiScoreGuideTitle => 'AI 점수 안내';

  @override
  String get aiScoreGuideDescription => 'AI 점수는 중장기(3~12개월) 투자 관점을 기반으로 산출됩니다.';

  @override
  String get aiScoreGuideStrongPositive => '80–100: 강력 긍정 – 상승 가능성 매우 높음';

  @override
  String get aiScoreGuidePositive => '60–79: 긍정 – 상승 가능성 높음';

  @override
  String get aiScoreGuideNeutral => '40–59: 중립 – 혼합 신호';

  @override
  String get aiScoreGuideNegative => '20–39: 부정 – 하락 가능성 높음';

  @override
  String get aiScoreGuideStrongNegative => '0–19: 강력 부정 – 하락 가능성 매우 높음';

  @override
  String get subscriptionPaymentAccountWarning =>
      '결제는 이 기기에 로그인된 App Store / Google Play 계정으로 처리됩니다. 다른 사람의 기기에서 구매 시, 기기 소유자의 계정으로 청구될 수 있습니다.';

  @override
  String get investmentProfileTitle => '투자 프로필';

  @override
  String get investmentProfileSection => '투자 프로필';

  @override
  String get investmentProfileEditSubtitle => '투자 성향을 확인하거나 수정합니다';

  @override
  String get investmentProfileComplete => '완료';

  @override
  String get investmentProfileSaveFailed => '프로필 저장에 실패했습니다. 다시 시도해주세요.';

  @override
  String get investmentProfileLoadFailed => '프로필을 불러오지 못했습니다. 다시 시도해주세요.';

  @override
  String get yourInvestmentStyle => '당신의 투자성향';

  @override
  String get setInvestmentStyle => '투자성향 설정하기';

  @override
  String get myRecommendations => '내 추천 종목';

  @override
  String get recommendationFit => '적합도';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get investmentStyleTitle => '투자 성향';

  @override
  String get investmentStyleSubtitle => '나의 투자 스타일은?';

  @override
  String get investmentStyleConservative => '보수적';

  @override
  String get investmentStyleConservativeDesc => '안정적인 수익으로 원금 보존을 우선시합니다';

  @override
  String get investmentStyleBalanced => '균형형';

  @override
  String get investmentStyleBalancedDesc => '성장과 안정 사이의 균형을 추구합니다';

  @override
  String get investmentStyleAggressive => '공격적';

  @override
  String get investmentStyleAggressiveDesc => '높은 위험을 감수하고 높은 수익을 추구합니다';

  @override
  String get timeHorizonTitle => '투자 기간';

  @override
  String get timeHorizonSubtitle => '얼마나 오래 투자할 계획인가요?';

  @override
  String get timeHorizonShort => '단기';

  @override
  String get timeHorizonShortDesc => '1년 미만';

  @override
  String get timeHorizonMedium => '중기';

  @override
  String get timeHorizonMediumDesc => '1~5년';

  @override
  String get timeHorizonLong => '장기';

  @override
  String get timeHorizonLongDesc => '5년 이상';

  @override
  String get riskToleranceTitle => '리스크 허용도';

  @override
  String get riskToleranceSubtitle => '어느 정도의 위험을 감수할 수 있나요?';

  @override
  String get riskLevel1 => '매우 낮음';

  @override
  String get riskLevel2 => '낮음';

  @override
  String get riskLevel3 => '보통';

  @override
  String get riskLevel4 => '높음';

  @override
  String get riskLevel5 => '매우 높음';

  @override
  String get riskLow => '낮음';

  @override
  String get riskHigh => '높음';

  @override
  String get targetReturnTitle => '목표 연간 수익률';

  @override
  String get targetReturnSubtitle => '어느 정도의 수익률을 목표로 하나요?';

  @override
  String get targetReturn5Desc => '안정적이고 저위험 투자';

  @override
  String get targetReturn10Desc => '적정 성장 전략';

  @override
  String get targetReturn20Desc => '공격적 성장 전략';

  @override
  String get targetReturnFlexible => '유연';

  @override
  String get targetReturnFlexibleDesc => '특정 목표 없이, 시장 상황에 맞춰 대응';

  @override
  String get maxLossTitle => '최대 허용 손실';

  @override
  String get maxLossSubtitle => '최대 어느 정도의 하락까지 감수할 수 있나요?';

  @override
  String get maxLoss5Desc => '매우 보수적, 최소한의 하락만 허용';

  @override
  String get maxLoss10Desc => '보수적, 제한된 하락 허용';

  @override
  String get maxLoss20Desc => '보통, 일반적인 시장 변동성 수준';

  @override
  String get maxLoss40Desc => '공격적, 큰 폭의 하락도 감수 가능';

  @override
  String get maxLossUnlimited => '제한 없음';

  @override
  String get maxLossUnlimitedDesc => '제한 없이, 장기 수익에 전념';
}
