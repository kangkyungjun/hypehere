// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

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
  String get tabWatchlist => '관심';

  @override
  String get tabWatchlistTooltip => '나의 관심목록';

  @override
  String get settings => '설정';

  @override
  String get settingsTooltip => '설정';

  @override
  String get compareTickers => '종목 비교';

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
  String get passwordConfirm => '비밀번호 확인';

  @override
  String get passwordConfirmHint => '비밀번호를 다시 입력하세요';

  @override
  String get passwordConfirmRequired => '비밀번호 확인을 입력하세요';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

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
  String get scoreStrongBuy => '강력매수';

  @override
  String get scoreBuy => '매수권고';

  @override
  String get scoreHold => '관망';

  @override
  String get scoreSell => '매도권고';

  @override
  String get scoreStrongSell => '강력매도';

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
  String get errMaxCompare => '최대 3개까지 비교 가능합니다';

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
  String get updatedDate => '업데이트:';
}
