// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get blockUser => 'Block user';

  @override
  String blockUserConfirm(String nickname) {
    return 'Block $nickname? You will no longer see their posts or comments.';
  }

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get userUnblocked => 'User unblocked.';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get noBlockedUsers => 'You haven\'t blocked anyone.';

  @override
  String get unblock => 'Unblock';

  @override
  String get termsAgreementRequired =>
      'You must agree to the Terms of Service to sign up.';

  @override
  String get eulaZeroTolerance =>
      'MarketLens has zero tolerance for objectionable content or abusive behavior.';

  @override
  String get eulaAgreePrefix => 'I agree to the ';

  @override
  String get eulaAgreeAnd => ' and ';

  @override
  String get eulaAgreeSuffix => '.';

  @override
  String get appTitle => 'MarketLens';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabDashboardTooltip => 'Market Dashboard';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabSearchTooltip => 'Search Tickers';

  @override
  String get tabNews => 'News';

  @override
  String get tabNewsTooltip => 'Market News';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabCommunityTooltip => 'Discussion Board';

  @override
  String get tabMarket => 'Market';

  @override
  String get tabMarketTooltip => 'Market Overview';

  @override
  String get tabAILens => 'AI';

  @override
  String get tabAILensTooltip => 'AI Analysis';

  @override
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabWatchlistTooltip => 'My Watchlist';

  @override
  String get tabHoldingsTooltip => 'My Holdings';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get login => 'Login';

  @override
  String get loginSubtitle => 'Access community features';

  @override
  String get signup => 'Sign Up';

  @override
  String get signupTitle => 'Sign Up';

  @override
  String get signupSubtitle => 'Create a new account';

  @override
  String get noAccountSignup => 'Don\'t have an account? Sign Up';

  @override
  String get hasAccountLogin => 'Already have an account? Login';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get welcome => 'Welcome!';

  @override
  String get accountCreated => 'Account created!';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email format';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'Nickname for the community';

  @override
  String get nicknameRequired => 'Please enter a nickname';

  @override
  String get nicknameTooShort => 'Nickname must be at least 2 characters';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordAllNumeric => 'Password cannot be entirely numbers';

  @override
  String get passwordTooCommon =>
      'This password is too common. Please choose a more unique one';

  @override
  String get passwordTooSimilar =>
      'Password is too similar to your email or nickname';

  @override
  String get passwordRequirements =>
      'At least 8 characters. Cannot be all numbers or a common password.';

  @override
  String get passwordRuleLength => 'At least 8 characters';

  @override
  String get passwordRuleNotNumeric => 'Not only numbers';

  @override
  String get passwordRuleNotCommon => 'Not a common password';

  @override
  String get passwordRuleNotSimilar => 'Different from email & nickname';

  @override
  String get passwordConfirm => 'Confirm Password';

  @override
  String get passwordConfirmHint => 'Re-enter your password';

  @override
  String get passwordConfirmRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordPolicyFailed =>
      'This password doesn\'t meet security requirements. Please choose another.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordGuide => 'Password Change Guide';

  @override
  String get oldPassword => 'Current Password';

  @override
  String get oldPasswordHint => 'Enter your current password';

  @override
  String get oldPasswordRequired => 'Please enter your current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordHint => 'Enter a new password (min 8 characters)';

  @override
  String get newPasswordRequired => 'Please enter a new password';

  @override
  String get newPasswordConfirm => 'Confirm New Password';

  @override
  String get newPasswordConfirmHint => 'Re-enter your new password';

  @override
  String get newPasswordConfirmRequired => 'Please confirm your new password';

  @override
  String get newPasswordMustDiffer =>
      'New password must differ from current password';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String passwordChangeFailed(String error) {
    return 'Password change failed: $error';
  }

  @override
  String get loginRequired => 'Login Required';

  @override
  String get loginPromptMessage => 'Login and join the community!';

  @override
  String get searchHint => 'Search by ticker or company (e.g. AAPL, Apple)';

  @override
  String get searchFailed => 'Search Failed';

  @override
  String get noSearchResults => 'No Results';

  @override
  String get tryDifferentSearch => 'Try a different ticker';

  @override
  String get tickerSearch => 'Ticker Search';

  @override
  String get enterTickerAbove => 'Enter a search term';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearAll => 'Clear All';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get sectorMarketOverview => 'Sector Overview';

  @override
  String get filterAll => 'All';

  @override
  String get filterNasdaq => 'NASDAQ';

  @override
  String get filterDow => 'Dow';

  @override
  String get marketLensAIScore => 'AI Score';

  @override
  String get aiTabAnalysis => 'AI Analysis';

  @override
  String get aiTabStocks => 'AI Stocks';

  @override
  String get aiTabSector => 'AI Sector';

  @override
  String get aiAnalysisComingSoonTitle => 'Conversational AI';

  @override
  String get aiAnalysisComingSoonBody =>
      'Ask like a messenger and AI analyzes the market and stocks for you. Coming soon.';

  @override
  String get comingSoonBadge => 'Coming soon';

  @override
  String get aiNoStocksInSegment => 'No stocks in this range';

  @override
  String get distributionShownOnFullLoad =>
      'Score distribution loads with all signals';

  @override
  String topN(int n) {
    return '▲ Top $n';
  }

  @override
  String bottomN(int n) {
    return '▼ Bottom $n';
  }

  @override
  String get noData => 'No data';

  @override
  String get signalLoadFailed => 'Failed to load signals';

  @override
  String dashboardLoadFailed(String error) {
    return 'Dashboard loading failed: $error';
  }

  @override
  String get allSignals => 'All Signals';

  @override
  String get sp500Signals => 'S&P 500 Signals';

  @override
  String get dow30Signals => 'Dow 30 Signals';

  @override
  String get nasdaq100Signals => 'NASDAQ 100 Signals';

  @override
  String get marketTrend => 'Overall Market Trend';

  @override
  String get loadingSignals => 'Loading signals...';

  @override
  String get loadingSP500Signals => 'Loading S&P 500 signals...';

  @override
  String get loadingDow30Signals => 'Loading Dow 30 signals...';

  @override
  String get loadingNasdaq100Signals => 'Loading NASDAQ 100 signals...';

  @override
  String get noAdditionalSignals => 'No additional signals';

  @override
  String showMore(int remaining) {
    return 'Show More ($remaining left)';
  }

  @override
  String nItems(int count) {
    return '$count items';
  }

  @override
  String get scoreStrongBuy => 'Strong Positive';

  @override
  String get scoreBuy => 'Positive';

  @override
  String get scoreHold => 'Neutral';

  @override
  String get scoreSell => 'Negative';

  @override
  String get scoreStrongSell => 'Strong Negative';

  @override
  String get score => 'Score';

  @override
  String get myWatchlist => 'My Watchlist';

  @override
  String nTickers(int count) {
    return '$count tickers';
  }

  @override
  String get watchlistEmpty => 'Watchlist is empty';

  @override
  String get watchlistEmptyHint => 'Search and add tickers from the Search tab';

  @override
  String get explore => 'Explore';

  @override
  String get tapToViewDetails => 'Tap for details';

  @override
  String tickerRemovedFromWatchlist(String ticker) {
    return '$ticker removed from watchlist';
  }

  @override
  String get undo => 'Undo';

  @override
  String get tickerDataLoadFailed => 'Failed to load ticker data';

  @override
  String get addToWatchlist => 'Add to Watchlist';

  @override
  String get removeFromWatchlist => 'Remove from Watchlist';

  @override
  String get addedToWatchlist => 'Added to watchlist';

  @override
  String get removedFromWatchlist => 'Removed from watchlist';

  @override
  String get watchlistDiscoveryTitle => 'Add to your watchlist';

  @override
  String get watchlistDiscoverySubtitle =>
      'Get news & signal alerts for your picks';

  @override
  String get topTradingVolume => 'Top Trading Volume Today';

  @override
  String get addWatchlistSearch => 'Search & add to watchlist';

  @override
  String get bookmarkGuide => 'Tap the bookmark icon to add to your watchlist';

  @override
  String get communitySearchHint => 'Search by title or content...';

  @override
  String get writePost => 'Write Post';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get deleteConfirm =>
      'Are you sure you want to delete this post?\nDeleted posts cannot be recovered.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get confirm => 'Confirm';

  @override
  String get dashboardIndexFilterHint =>
      'Tap an index to filter the chart to its stocks';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get report => 'Report';

  @override
  String get reportTitle => 'Report';

  @override
  String get reportAbuse => 'Abuse / Defamation';

  @override
  String get reportSpam => 'Spam / Advertising';

  @override
  String get reportInappropriate => 'Inappropriate Content';

  @override
  String get reportHarassment => 'Harassment';

  @override
  String get reportOther => 'Other';

  @override
  String get reportDescription => 'Description';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get reportSubmit => 'Report';

  @override
  String postDeleteFailed(String error) {
    return 'Failed to delete post: $error';
  }

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get writeFirstPost => 'Write the first post!';

  @override
  String get noSearchResultsCommunity => 'No search results';

  @override
  String get tryDifferentFilter => 'Try a different search or filter';

  @override
  String get networkError => 'Connection failed. Please try again later.';

  @override
  String get serverTimeout => 'Server timeout. Please try again later.';

  @override
  String get postsLoadFailed => 'Failed to load posts. Please try again later.';

  @override
  String get searchResultsLoadFailed => 'Failed to load search results';

  @override
  String get refresh => 'Refresh';

  @override
  String get all => 'All';

  @override
  String get add => 'Add';

  @override
  String tickerBoard(String ticker) {
    return '$ticker Board';
  }

  @override
  String get tickerSearchHint => 'Search ticker... (e.g. AAPL, TSLA)';

  @override
  String get popularTickers => 'Popular Tickers';

  @override
  String get freePost => 'Free';

  @override
  String get checkNetwork => 'Please check your network connection';

  @override
  String get tryAgainLater => 'Please try again later';

  @override
  String get newPost => 'New Post';

  @override
  String get editPostTitle => 'Edit Post';

  @override
  String get tickerOnlyBoard => 'Ticker-specific Board';

  @override
  String get selectTicker => 'Ticker';

  @override
  String get tickerSearchLabel => 'Search Ticker';

  @override
  String get tickerSearchHintCreate => 'Search by name, symbol, or Korean name';

  @override
  String get tickerNotSelectedHint =>
      'Post will be tagged as Free if no ticker is selected';

  @override
  String get noTickerSearchResults => 'No search results';

  @override
  String get postTitle => 'Title';

  @override
  String get postTitleHint => 'Enter post title';

  @override
  String get postTitleRequired => 'Please enter a title';

  @override
  String get postTitleTooShort => 'Title must be at least 2 characters';

  @override
  String get postContent => 'Content';

  @override
  String get postContentHint => 'Enter post content';

  @override
  String get postContentRequired => 'Please enter content';

  @override
  String get postContentTooShort => 'Content must be at least 5 characters';

  @override
  String get postCreated => 'Post created';

  @override
  String get postUpdated => 'Post updated';

  @override
  String get submitPost => 'Post';

  @override
  String get updatePostButton => 'Update';

  @override
  String get deleteComment => 'Delete Comment';

  @override
  String get deleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get editComment => 'Edit Comment';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get commentPlaceholder => 'Enter comment content';

  @override
  String get commentCreated => 'Comment posted';

  @override
  String get commentUpdated => 'Comment updated';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get commentRequired => 'Please enter a comment';

  @override
  String get loginToViewComments => 'Login to view comments';

  @override
  String get writeFirstComment => 'Write the first comment!';

  @override
  String get postDetail => 'Post';

  @override
  String get startWithFirstPost => 'Start with your first post';

  @override
  String get writeAPost => 'Write a Post';

  @override
  String get cannotLoadPosts => 'Cannot load posts';

  @override
  String get noPostsInTicker => 'No posts in this board yet';

  @override
  String get writeFirstPostInTicker => 'Write the first post!';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get clearRecentSearches => 'Clear Recent Searches';

  @override
  String nSearchRecords(int count) {
    return '$count search records';
  }

  @override
  String get clearRecentSearchesConfirm => 'Clear all recent search records?';

  @override
  String get recentSearchesCleared => 'Recent searches cleared';

  @override
  String get clearWatchlist => 'Clear Watchlist';

  @override
  String get clearWatchlistConfirm => 'Clear all watchlist tickers?';

  @override
  String get watchlistCleared => 'Watchlist cleared';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataConfirm =>
      'All local data including watchlist and search history will be deleted. This cannot be undone.';

  @override
  String get deleteAllButton => 'Delete All';

  @override
  String get allDataDeleted => 'All data deleted';

  @override
  String get removeAllLocalData => 'Remove all local data';

  @override
  String get info => 'Info';

  @override
  String get aboutMarketLens => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get appDescription =>
      'AI-powered stock analysis tool for data-driven investment decisions';

  @override
  String get aiStockAnalysis => 'AI Stock Analysis';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get admin => 'Admin';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminPanelSubtitle => 'User management and permissions';

  @override
  String get showAds => 'Show Ads';

  @override
  String get adsEnabledDescription => 'Banner ads shown to all users';

  @override
  String get adsDisabledDescription => 'Ads are hidden';

  @override
  String get sendPushNotification => 'Send Push Notification';

  @override
  String get sendPushNotificationSubtitle => 'Broadcast to all users';

  @override
  String get pushTitle => 'Title';

  @override
  String get pushBody => 'Message';

  @override
  String get send => 'Send';

  @override
  String pushSentResult(int count) {
    return 'Push sent to $count devices';
  }

  @override
  String get pushSendFailed => 'Failed to send push notification';

  @override
  String get promoteToGold => 'Promote to Gold';

  @override
  String get promoteToManager => 'Promote to Manager';

  @override
  String get demoteToRegular => 'Demote to Regular';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myPosts => 'My Posts';

  @override
  String get myComments => 'My Comments';

  @override
  String get viewAll => 'View All';

  @override
  String get noPosts => 'No posts';

  @override
  String get noComments => 'No comments';

  @override
  String joinDate(String date) {
    return 'Joined: $date';
  }

  @override
  String get deleteAccount => 'Withdraw Account';

  @override
  String get withdrawAccountConfirm =>
      'Are you sure you want to withdraw your account?\nYour account will be permanently deleted after 7 days. Log in again within that period to cancel.';

  @override
  String get withdrawAccountReasonHint =>
      'Please enter your reason for withdrawal (optional)';

  @override
  String get withdrawAccountSuccess =>
      'Account withdrawal requested. Your account will be permanently deleted in 7 days.';

  @override
  String get withdrawAccountFailed =>
      'Failed to request account withdrawal. Please try again.';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get imagePickerFailed => 'Failed to select image';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System Default';

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
  String get languageSettings => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get languageChanged => 'Language changed';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get companyOverview => 'Company Overview';

  @override
  String get companyDetails => 'Company Details';

  @override
  String get companyIntro => 'About';

  @override
  String employeeCount(String count) {
    return '$count employees';
  }

  @override
  String get valuation => 'Valuation';

  @override
  String get forwardPE => 'Forward PE';

  @override
  String get beta => 'Beta';

  @override
  String get profitabilityGrowth => 'Profitability & Growth';

  @override
  String get netProfitMargin => 'Net Margin';

  @override
  String get revenueGrowth => 'Rev Growth';

  @override
  String get operatingMargin => 'Op Margin';

  @override
  String get earningsGrowth => 'Earn Growth';

  @override
  String get financialHealth => 'Financial Health';

  @override
  String get debtRatio => 'D/E Ratio';

  @override
  String get liquidityRatio => 'Current Ratio';

  @override
  String get dividends => 'Dividends';

  @override
  String get dividendYield => 'Yield ';

  @override
  String get annualDividend => 'Annual ';

  @override
  String get shortInterest => 'Short Interest';

  @override
  String get shortInterestRatio => 'Short Ratio';

  @override
  String get shortPercentFloat => 'Short % Float';

  @override
  String shortDays(String days) {
    return '$days days';
  }

  @override
  String get shortInterestLow => 'Short interest low (stable)';

  @override
  String get shortInterestModerate => 'Short interest moderate (caution)';

  @override
  String get shortInterestHigh => 'Short interest high (warning)';

  @override
  String get institutionalInsiderFlow => 'Institutional / Insider Flow';

  @override
  String get institutional => 'Institutional';

  @override
  String get insider => 'Insider';

  @override
  String get oneDay => '1D';

  @override
  String get fiveDay => '5D';

  @override
  String tickerNews(String ticker) {
    return '$ticker News';
  }

  @override
  String newsCount(int count) {
    return '$count';
  }

  @override
  String get oneWeek => '1W';

  @override
  String get oneMonth => '1M';

  @override
  String get noNews => 'No news';

  @override
  String get marketNews => 'Market News';

  @override
  String get viewOriginalArticle => 'View Original Article';

  @override
  String get sentimentBullish => 'Bullish';

  @override
  String get sentimentNeutral => 'Neutral';

  @override
  String get sentimentBearish => 'Bearish';

  @override
  String get aiSummaryNews => 'AI Summary News';

  @override
  String get aiSummary => 'AI Summary';

  @override
  String get noNewsAvailable => 'No news available';

  @override
  String get earningsHistory => 'Earnings History';

  @override
  String get earningsHistoryEPS => 'Earnings History (EPS)';

  @override
  String get earningsEstimate => 'Estimate';

  @override
  String get earningsBeat => 'Beat';

  @override
  String get earningsMiss => 'Miss';

  @override
  String get earningsActual => 'Actual';

  @override
  String get earningsScheduled => 'Scheduled';

  @override
  String get epsEstimateLabel => 'EPS Estimate';

  @override
  String get revenueEstimateLabel => 'Revenue Estimate';

  @override
  String get averageLabel => 'avg';

  @override
  String get surpriseLabel => 'Surprise';

  @override
  String get thisWeekEarnings => 'This Week\'s Earnings';

  @override
  String get previousEarnings => 'Previous Earnings';

  @override
  String earningsCount(int count) {
    return '$count';
  }

  @override
  String get noEarningsThisWeek => 'No earnings scheduled this week';

  @override
  String get nextEarningsDate => 'Next Earnings';

  @override
  String get earningsConfirmed => 'Confirmed';

  @override
  String get keyEvents => 'Key Events';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get exDividendDate => 'Ex-Dividend Date';

  @override
  String get dividendPayDate => 'Dividend Pay Date';

  @override
  String recentEarningsQuarters(int count) {
    return 'Recent Earnings (${count}Q)';
  }

  @override
  String get earningsHistoryChart => 'Earnings History (Chart)';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get macroFedFunds => 'Fed Rate';

  @override
  String get macroDGS10 => '10Y Yield';

  @override
  String get macroDGS2 => '2Y Yield';

  @override
  String get macroT10Y2Y => 'Spread';

  @override
  String get macroVIXCLS => 'VIX';

  @override
  String get macroCPIAUCSL => 'CPI';

  @override
  String get macroUNRATE => 'Unemployment';

  @override
  String get macroFedFundsDesc => 'Federal Funds Rate';

  @override
  String get macroDGS10Desc => 'US 10-Year Treasury Yield';

  @override
  String get macroDGS2Desc => 'US 2-Year Treasury Yield';

  @override
  String get macroT10Y2YDesc => 'Yield Curve Spread (10Y-2Y)';

  @override
  String get macroVIXCLSDesc => 'Market Volatility Index';

  @override
  String get macroCPIAUCSLDesc => 'Consumer Price Index (CPI)';

  @override
  String get macroUNRATEDesc => 'US Unemployment Rate';

  @override
  String get riskBearish => 'Bearish';

  @override
  String get riskCautious => 'Cautious';

  @override
  String get riskNeutral => 'Neutral';

  @override
  String get riskPositive => 'Positive';

  @override
  String get riskBullish => 'Bullish';

  @override
  String get macroCategoryRates => 'Interest Rates';

  @override
  String get macroCategorySentiment => 'Sentiment';

  @override
  String get macroCategoryEconomy => 'Economy';

  @override
  String get macroYieldCurve => 'Yield Curve';

  @override
  String get macroLiquidity => 'Liquidity';

  @override
  String get macroOverall => 'Macro Overall';

  @override
  String macroCurrentValue(String value) {
    return 'Current: $value';
  }

  @override
  String macroChange(String value) {
    return 'Change: $value';
  }

  @override
  String epsEstimateValue(String value) {
    return 'Est. \$$value';
  }

  @override
  String get bbInterpretation => 'Bollinger Bands Interpretation';

  @override
  String get bbBandWidth => '• Band width: shows volatility (wider = higher)';

  @override
  String get bbUpperApproach => '• Upper band approach: potential overbought';

  @override
  String get bbLowerApproach => '• Lower band approach: potential oversold';

  @override
  String get bbMiddleLine => '• Middle line: 20-day moving average';

  @override
  String get cannotLoadData => 'Cannot load data';

  @override
  String get marketlensAI => 'MarketLens AI';

  @override
  String get marketlensAIOpinion => 'MarketLens AI Opinion';

  @override
  String get bullishFactors => 'Bullish Factors';

  @override
  String get bearishFactors => 'Bearish Factors';

  @override
  String get expertAnalysis => 'Expert Analysis';

  @override
  String get expertKeyFactors => 'Key Factors';

  @override
  String get predictionBullish => 'Bullish';

  @override
  String get predictionBearish => 'Bearish';

  @override
  String get predictionNeutral => 'Neutral';

  @override
  String get target => 'Target ';

  @override
  String get stopLoss => 'Stop ';

  @override
  String get averageTargetPrice => 'Avg Target Price';

  @override
  String get currentPrice => 'Current';

  @override
  String get targetPrice => 'Target';

  @override
  String get recentAnalystRatings => 'Recent Analyst Ratings';

  @override
  String get unknownFirm => 'Unknown';

  @override
  String get volume => 'Volume';

  @override
  String get legend => 'Legend';

  @override
  String get ratingBuy => 'Buy';

  @override
  String get ratingStrongBuy => 'Strong Buy';

  @override
  String get ratingOutperform => 'Outperform';

  @override
  String get ratingHold => 'Hold';

  @override
  String get ratingNeutral => 'Neutral';

  @override
  String get ratingMarketPerform => 'Market Perform';

  @override
  String get ratingSell => 'Sell';

  @override
  String get ratingStrongSell => 'Strong Sell';

  @override
  String get ratingUnderperform => 'Underperform';

  @override
  String get ratingActionUpgrade => 'Upgrade';

  @override
  String get ratingActionDowngrade => 'Downgrade';

  @override
  String get ratingActionReiterated => 'Reiterated';

  @override
  String get ratingActionInitiated => 'Initiated';

  @override
  String get roleMaster => 'Master';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleGold => 'Gold';

  @override
  String get roleRegular => 'Regular';

  @override
  String get roleGuest => 'Guest';

  @override
  String get errInvalidCredentials => 'Invalid email or password';

  @override
  String get errLoginRequired => 'Login required';

  @override
  String get errSessionExpired => 'Session expired. Please login again.';

  @override
  String get errCannotLoadUser => 'Cannot load user info';

  @override
  String get errServerConnection =>
      'Cannot connect to server. Please check your network.';

  @override
  String get errServerConnectionShort => 'Cannot connect to server';

  @override
  String get errNetworkFailed =>
      'Network connection failed. Please check your internet.';

  @override
  String get errResponseFormat => 'Invalid server response format';

  @override
  String errTimeout(int seconds) {
    return 'Server timeout (${seconds}s)';
  }

  @override
  String get errBadRequest => 'Please check your input';

  @override
  String get errForbidden => 'Access denied';

  @override
  String get errNotFound => 'Page not found';

  @override
  String get errServerError => 'Server error. Please try again later.';

  @override
  String get errNoEditPermission => 'No edit permission';

  @override
  String get errNoDeletePermission => 'No delete permission';

  @override
  String get errPostDeleteFailed => 'Failed to delete post';

  @override
  String get errCommentDeleteFailed => 'Failed to delete comment';

  @override
  String get errReportAlreadySubmitted =>
      'You have already reported this content';

  @override
  String get errCannotReportOwn => 'You cannot report your own content';

  @override
  String get errReportFailed => 'Failed to submit report';

  @override
  String get errManagerRequired => 'Manager or above access required';

  @override
  String get errMasterRequired => 'Master access required';

  @override
  String get errSearchRequired => 'Please enter a search term';

  @override
  String get errDemotionFailed => 'Demotion failed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayBeforeYesterday => '2 days ago';

  @override
  String expertCount(String count) {
    return 'Analyst Targets ($count)';
  }

  @override
  String scorePoints(String score) {
    return '$score pts';
  }

  @override
  String averageVolume(String volume) {
    return 'Avg: $volume';
  }

  @override
  String get showBullBearFactors => 'Show factors';

  @override
  String get hideBullBearFactors => 'Hide factors';

  @override
  String analystConsensus(String count) {
    return 'Analyst Targets ($count firms)';
  }

  @override
  String lowestPrice(String price) {
    return 'Low \$$price';
  }

  @override
  String highestPrice(String price) {
    return 'High \$$price';
  }

  @override
  String get liveTalk => '💬 Live Talk';

  @override
  String commentsCount(int count) {
    return '$count comments';
  }

  @override
  String get browsePosts => 'Browse Posts';

  @override
  String get loginPromptComments =>
      'See what other investors think and\nshare your own analysis!';

  @override
  String get shareThoughtsPrompt =>
      'Share your thoughts on tickers\nand connect with other investors';

  @override
  String get writeFirstCommentPrompt => 'Leave the first comment on a post';

  @override
  String get startConversationPrompt =>
      'Start a conversation by commenting\non other investors\' posts';

  @override
  String get ratingOverweight => 'Overweight';

  @override
  String get ratingUnderweight => 'Underweight';

  @override
  String get ratingSectorOutperform => 'Sector Outperform';

  @override
  String get ratingSectorPerform => 'Sector Perform';

  @override
  String get ratingSectorUnderperform => 'Sector Underperform';

  @override
  String get ratingPositive => 'Positive';

  @override
  String get ratingNegative => 'Negative';

  @override
  String get ratingEqualWeight => 'Equal Weight';

  @override
  String get keyMetricsComparison => 'Key Metrics Comparison';

  @override
  String get metric => 'Metric';

  @override
  String get serverCalculatedNote =>
      '※ All metrics are server-calculated values';

  @override
  String get priceTrendComparison => 'Price Trend Comparison';

  @override
  String get rsiComparison => 'RSI Comparison (Server Values)';

  @override
  String get rsiInterpretation => '※ RSI > 70: Overbought / RSI < 30: Oversold';

  @override
  String get passwordChangeInstructions =>
      '• New password must be at least 8 characters\n• Use a combination of letters, numbers, and symbols\n• You will need to login again with the new password';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllAsRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notificationsRetentionHint =>
      'Notifications from the last 7 days appear here.';

  @override
  String get bioLabel => 'Bio';

  @override
  String get bioHint => 'Tell us about yourself';

  @override
  String get profileEditGuide => 'Profile Edit Guide';

  @override
  String get profileEditGuideDetails =>
      '• Nickname: 2–30 characters, duplicates allowed\n• Bio: up to 200 characters (optional)\n• Profile photo: 800×800px recommended';

  @override
  String get updatedDate => 'Updated:';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabCalendarTooltip => 'Event Calendar';

  @override
  String get eventTypeFomc => 'FOMC';

  @override
  String get eventTypeEarnings => 'Earnings';

  @override
  String get eventTypeEconomic => 'Economic';

  @override
  String get eventTypeOptionsExpiry => 'Options Expiry';

  @override
  String get eventTypeConference => 'Conference';

  @override
  String get eventTypeDividend => 'Dividend';

  @override
  String get eventTypeProductLaunch => 'Product Launch';

  @override
  String get eventTypeShareholder => 'Shareholder Meeting';

  @override
  String get eventTypeFedSpeech => 'Fed Speech';

  @override
  String nEvents(int count) {
    return '$count events';
  }

  @override
  String get noEventsThisMonth => 'No events this month';

  @override
  String get noEventsSelectedDay => 'No events on this day';

  @override
  String get calendarNewsAnnouncements => 'News · Announcements';

  @override
  String get calendarEconomicIndicators => 'US Economic';

  @override
  String get calendarViewResult => 'View result';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a verification code.';

  @override
  String get sendVerificationCode => 'Send Code';

  @override
  String get verificationTitle => 'Email Verification';

  @override
  String verificationSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email.';
  }

  @override
  String verificationExpiry(String time) {
    return 'Expires in: $time';
  }

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get verificationCodeRequired => 'Enter the 6-digit verification code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendCodeCooldown(int seconds) {
    return 'Resend in (${seconds}s)';
  }

  @override
  String get verificationCodeResent => 'Verification code has been resent.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSubtitle => 'Enter your new password.';

  @override
  String get resetPasswordSuccess =>
      'Password has been reset. Please login with your new password.';

  @override
  String get errEmailNotVerified => 'Email verification required.';

  @override
  String get errRateLimited => 'Please try again later.';

  @override
  String get myHoldings => 'My Holdings';

  @override
  String nHoldings(int count) {
    return '$count holdings';
  }

  @override
  String get portfolioSummary => 'Portfolio Summary';

  @override
  String get totalValue => 'Total Value';

  @override
  String get totalPnl => 'Total P&L';

  @override
  String get dayPnl => 'Today';

  @override
  String get buyStock => 'Buy';

  @override
  String get shares => 'Shares';

  @override
  String get avgPrice => 'Avg Price';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get enterShares => 'Number of shares';

  @override
  String get enterAvgPrice => 'Average purchase price';

  @override
  String get buyConfirm => 'Add to Holdings';

  @override
  String holdingAdded(String ticker) {
    return '$ticker added to holdings';
  }

  @override
  String holdingRemoved(String ticker) {
    return '$ticker removed from holdings';
  }

  @override
  String removeHoldingConfirm(String ticker) {
    return 'Remove $ticker from holdings?';
  }

  @override
  String get aiAdvice => 'AI Advice';

  @override
  String get aiAdviceInstant => 'Instant AI Advice';

  @override
  String get bullishFactorsPortfolio => 'Bullish Factors';

  @override
  String get bearishFactorsPortfolio => 'Bearish Factors';

  @override
  String get detailedAnalysisComingSoon =>
      'Detailed analysis will be updated in the morning';

  @override
  String get loginForPortfolio => 'Log in to manage your portfolio';

  @override
  String get loginForPortfolioHint =>
      'Track holdings, get AI advice, and monitor P&L';

  @override
  String sharesAtPrice(String shares, String price) {
    return '$shares shares @ \$$price';
  }

  @override
  String get noHoldingsYet => 'No holdings yet';

  @override
  String get addFirstHolding => 'Buy stocks from your watchlist to get started';

  @override
  String get invalidShares => 'Please enter a valid number of shares';

  @override
  String get invalidPrice => 'Please enter a valid price';

  @override
  String get confidence => 'Confidence';

  @override
  String get tabHoldings => 'Holdings';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get sellDate => 'Sell Date';

  @override
  String get sellPrice => 'Sell Price';

  @override
  String get sellShares => 'Sell Quantity';

  @override
  String get sellConfirm => 'Confirm Sell';

  @override
  String get sellAll => 'Sell All';

  @override
  String get sellAmount => 'Sell Amount';

  @override
  String get realizedPnlLabel => 'Realized P&L';

  @override
  String get unrealizedPnl => 'Unrealized P&L';

  @override
  String get realizedPnl => 'Realized';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get additionalBuy => 'Buy More';

  @override
  String get partialSell => 'Sell';

  @override
  String get editHolding => 'Edit Info';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String holdingUpdated(String ticker) {
    return '$ticker holding updated';
  }

  @override
  String get portfolioAIAnalysis => 'Portfolio AI Analysis';

  @override
  String get aiRecommendations => 'Recommendations';

  @override
  String get todayPicks => 'Today\'s Picks';

  @override
  String get aiChatTitle => 'AI Chat';

  @override
  String get aiChatHint => 'Type a message';

  @override
  String get aiChatEmptyTitle => 'Ask me anything';

  @override
  String get aiChatEmptySubtitle =>
      'Chat with AI about stocks and your portfolio';

  @override
  String get aiChatDailyDisclaimer =>
      'AI analysis is for reference only. Investment decisions and their outcomes are your own responsibility.';

  @override
  String get aiChatSuggestionsTitle => 'Try asking';

  @override
  String get aiChatShuffle => 'Shuffle';

  @override
  String get aiChatAnalyzeMyHoldings => 'Analyze my holdings';

  @override
  String get macroAiCardTitle => 'AI volatility brief';

  @override
  String get macroAiCardLoading => 'Analyzing…';

  @override
  String get macroAiCardError =>
      'Couldn\'t fetch analysis right now. Please try again shortly.';

  @override
  String get macroAiCardRetry => 'Try again';

  @override
  String get macroAiCardCadence => 'Updates each trading day';

  @override
  String get macroAiCardWatchAdCta =>
      'Watch a short ad to unlock today\'s AI brief.';

  @override
  String get macroAiCardWatchAdAction => 'Watch ad for analysis';

  @override
  String get macroAiCardAdUnavailable =>
      'Couldn\'t load an ad. Please try again shortly.';

  @override
  String get aiChatGreetingCooldownTitle => 'AI greeting frequency';

  @override
  String get aiChatGreetingCooldownOff => 'Off';

  @override
  String get aiChatGreetingCooldown2h => 'Every 2 hours';

  @override
  String get aiChatGreetingCooldownDaily => 'Once a day';

  @override
  String get aiChatCopy => 'Copy';

  @override
  String get aiChatShare => 'Share';

  @override
  String get aiChatCopied => 'Copied';

  @override
  String get aiChatShareQ => 'Question';

  @override
  String get aiChatShareA => 'Answer';

  @override
  String get aiChatShareFooter => '— MarketLens AI';

  @override
  String get aiChatThinking => 'AI is thinking…';

  @override
  String get aiChatErrorRetry => 'Couldn\'t get a response. Please try again.';

  @override
  String get aiChatLoginRequired => 'Log in to chat with AI';

  @override
  String get aiChatNew => 'New chat';

  @override
  String get aiChatHistory => 'Past chats';

  @override
  String get aiChatNoHistory => 'No past conversations';

  @override
  String get aiChatFreeRemaining => 'Free left';

  @override
  String get aiChatSelect => 'Select';

  @override
  String aiChatSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get aiChatHide => 'Hide';

  @override
  String get aiChatHideConfirm =>
      'Hide the selected conversations from this phone? They remain stored on the server.';

  @override
  String get aiChatStorageSettings => 'AI Chat Storage';

  @override
  String get aiChatStorageSettingsSubtitle =>
      'On-device history limit and usage';

  @override
  String get aiChatStorageUsage => 'Current usage';

  @override
  String get aiChatStorageLimit => 'History limit';

  @override
  String get aiChatStorageBytes => 'Storage size';

  @override
  String get aiChatStorageNote =>
      'When the limit is reached, the oldest conversations are removed first. The server keeps all of them, so no learning data is lost.';

  @override
  String get aiChatUnlimited => 'Unlimited';

  @override
  String aiChatNConversations(int count) {
    return '$count chats';
  }

  @override
  String get aiChatClearLocal => 'Clear all chats on this phone';

  @override
  String get aiChatClearLocalDesc =>
      'Conversations on the server are not affected';

  @override
  String get aiChatClearLocalConfirm =>
      'Erase all cached chats stored on this phone?';

  @override
  String get aiChatLocalCleared => 'On-device chat cache cleared';

  @override
  String get recPortfolioOverview => 'Portfolio Overview';

  @override
  String get recTechnicalInsight => 'Technical Analysis';

  @override
  String get recMarketIntelligence => 'Market Intelligence';

  @override
  String get recActionSummary => 'Action Summary';

  @override
  String get recCompanyClassification => 'Company Classification';

  @override
  String get recAnalystSummary => 'Analyst Summary';

  @override
  String get recMarketSummary => 'Market Summary';

  @override
  String get recUpcomingEvents => 'Upcoming Events';

  @override
  String get recBuyRecommend => 'Increase Position (Buy)';

  @override
  String get recHoldRecommend => 'Hold Position (Watch)';

  @override
  String get recSellRecommend => 'Reduce Position (Sell)';

  @override
  String get recommendedAction => 'Recommended Action';

  @override
  String get analysisWaiting => 'AI analysis pending...';

  @override
  String get alreadyHeld => 'Held';

  @override
  String get goToWatchlistTab => 'Go to Watchlist';

  @override
  String get noHoldingsHint => 'Add holdings from the Watchlist tab';

  @override
  String get addHoldingDirect => 'Add Stock';

  @override
  String get aiPortfolioBenefitTitle =>
      'Register your stocks and get\ndaily AI investment insights';

  @override
  String get aiPortfolioBenefit1 => 'Portfolio rebalancing suggestions';

  @override
  String get aiPortfolioBenefit2 => 'Technical trading signal analysis';

  @override
  String get aiPortfolioBenefit3 => 'Market news impact assessment';

  @override
  String get searchTickerHint => 'Search by name or ticker';

  @override
  String get addToPortfolio => 'Add to Portfolio';

  @override
  String get alreadyInHoldings => 'Already in your holdings';

  @override
  String get closingPriceAuto => 'Closing price auto-filled';

  @override
  String holidayPriceNotice(String date) {
    return 'Closing price from $date (prior trading day)';
  }

  @override
  String get addToHoldings => 'Add to Holdings';

  @override
  String get currentHoldings => 'Current Holdings';

  @override
  String get holdingStatus => 'Holding Status';

  @override
  String addHoldingTitle(String ticker) {
    return '$ticker Add Holding';
  }

  @override
  String sellHoldingTitle(String ticker) {
    return '$ticker Sell';
  }

  @override
  String editHoldingTitle(String ticker) {
    return '$ticker Edit Holding';
  }

  @override
  String holdingSold(String ticker) {
    return '$ticker sold successfully';
  }

  @override
  String get deleteHolding => 'Delete Holding';

  @override
  String get avgPriceLabel => 'Avg Price';

  @override
  String get currentValueLabel => 'Current Value';

  @override
  String get dailyUpdate => 'Updated daily in the morning';

  @override
  String get aiRefreshOnChange => 'Auto-refreshes on changes';

  @override
  String get aiUpdateButton => 'Update AI Analysis';

  @override
  String get aiUpdating => 'Updating analysis…';

  @override
  String get aiNoChangeToAnalyze => 'No changes — a new analysis isn\'t needed';

  @override
  String get aiAnalysisOnDemandHint =>
      'You can update when your portfolio or the date changes';

  @override
  String get aiUpdateInProgressHint =>
      'Generating analysis… this can take up to a minute.';

  @override
  String get aiUpdateDelayed =>
      'Analysis is taking a little longer — it\'ll appear automatically soon.';

  @override
  String lastUpdateTime(String time) {
    return 'Last updated: $time';
  }

  @override
  String get viewAIAdvice => 'View AI Advice';

  @override
  String get noAnalysisYet => 'No analysis available yet';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String viewAllTransactions(int count) {
    return 'View all ($count)';
  }

  @override
  String get newsFilter => 'Filter';

  @override
  String get filterSource => 'Source';

  @override
  String get filterMyWatchlist => 'My Watchlist';

  @override
  String get filterNoWatchlist => 'Add watchlist items first';

  @override
  String get filterMarketOnly => 'Market News';

  @override
  String get filterSentiment => 'Sentiment';

  @override
  String get filterSector => 'Sector';

  @override
  String get filterBreakingOnly => 'Breaking only';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String hotTopicMore(int count) {
    return '+$count more';
  }

  @override
  String get sectorTechnology => 'Technology';

  @override
  String get sectorHealthcare => 'Healthcare';

  @override
  String get sectorEnergy => 'Energy';

  @override
  String get sectorCyclical => 'Cyclical';

  @override
  String get sectorDefensive => 'Defensive';

  @override
  String get sectorComm => 'Communication';

  @override
  String get sectorFinance => 'Finance';

  @override
  String get sectorIndustrials => 'Industrials';

  @override
  String get sectorUtilities => 'Utilities';

  @override
  String get sectorRealEstate => 'Real Estate';

  @override
  String get sectorMaterials => 'Materials';

  @override
  String get newsBubbleTitle => '24h Hot News';

  @override
  String get newsBubbleLegendBullish => 'Mostly Bullish';

  @override
  String get newsBubbleLegendBearish => 'Mostly Bearish';

  @override
  String get newsBubbleLegendMixed => 'Mixed';

  @override
  String newsBubbleMentions(int count) {
    return '$count mentions';
  }

  @override
  String get newsSentiment24hTitle => 'Last 24 Hours';

  @override
  String get newsBullish => 'Bullish';

  @override
  String get newsNeutral => 'Neutral';

  @override
  String get newsBearish => 'Bearish';

  @override
  String get keyNewsTitle => 'Today\'s Key News';

  @override
  String get viewTickerDetail => 'Go to Stock';

  @override
  String newsCountUnit(int count) {
    return '$count';
  }

  @override
  String get taxEstimateTitle => 'Tax Estimate';

  @override
  String get totalGains => 'Total Gains';

  @override
  String get annualExemption => 'Annual Exemption';

  @override
  String get estimatedTax => 'Estimated Tax (22%)';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get krwSuffix => ' KRW';

  @override
  String get taxTradeCount => ' sells';

  @override
  String get macro3mTitle => '3M';

  @override
  String get macro3mHigh => '3M High';

  @override
  String get macro3mAvg => '3M Avg';

  @override
  String get macro3mLow => '3M Low';

  @override
  String get tooltipClearSearch => 'Clear search';

  @override
  String get tooltipPreviousMonth => 'Previous month';

  @override
  String get tooltipNextMonth => 'Next month';

  @override
  String get tooltipSelectMonth => 'Select month';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get tooltipChangePhoto => 'Change photo';

  @override
  String get tooltipFilter => 'Filter';

  @override
  String get tooltipRemove => 'Remove';

  @override
  String get otherSectors => 'Other Sectors';

  @override
  String get otherTickers => 'Other Tickers';

  @override
  String nDaysAgo(int count) {
    return '${count}D ago';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabHomeTooltip => 'Home';

  @override
  String get tabAIAnalysis => 'AI Signal';

  @override
  String get tabToday => 'Today';

  @override
  String get tabUpDown => 'Up & Down';

  @override
  String get tabIndexes => 'Indexes';

  @override
  String get macroCurrentLabel => 'Current';

  @override
  String get macroChangeLabel => 'Change';

  @override
  String get tradingVolumeTop => 'Trading Volume';

  @override
  String get gainersTop => 'Gainers';

  @override
  String get losersTop => 'Losers';

  @override
  String get volumeTop => 'Volume';

  @override
  String get topByMarketCap => 'Top by Market Cap';

  @override
  String get viewMore => 'View More';

  @override
  String get gaugeStrongNegativeDesc =>
      'Strong Negative: Very high probability of decline';

  @override
  String get gaugeNegativeDesc => 'Negative: High probability of decline';

  @override
  String get gaugePositiveDesc => 'Positive: High probability of rise';

  @override
  String get gaugeStrongPositiveDesc =>
      'Strong Positive: Very high probability of rise';

  @override
  String aiRecommended20(int count) {
    return 'AI Top $count Recommended';
  }

  @override
  String aiCaution20(int count) {
    return 'AI Top $count Caution';
  }

  @override
  String get seeMore => 'See More';

  @override
  String get holdingsSummary => 'Holdings Summary';

  @override
  String get investmentReturn => 'Investment Return';

  @override
  String get returnRate => 'Return';

  @override
  String get purchaseAmount => 'Cost Basis';

  @override
  String get profitAmount => 'Profit/Loss';

  @override
  String get evaluationAmount => 'Market Value';

  @override
  String get watchAdToUnlock => 'Watch a short ad to view AI analysis';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get adNotReady => 'Ad is loading, please try again';

  @override
  String get holdingsLimitTitle => 'Holdings Limit';

  @override
  String get holdingsLimitMessage =>
      'Free users can track up to 3 holdings. Upgrade to Gold for unlimited holdings and ad-free AI analysis.';

  @override
  String get upgradeToGold => 'Upgrade to Gold';

  @override
  String get goldBenefitUnlimitedHoldings => 'Unlimited holdings';

  @override
  String get goldBenefitAIUnlimited => 'Ad-free AI analysis';

  @override
  String get goldBenefitNoAds => 'Ad-free experience';

  @override
  String get newAiAnalysisAvailable => 'New AI analysis available';

  @override
  String get viewingPreviousAnalysis => 'View previous analysis';

  @override
  String get goldUpgradeComingSoon =>
      'Gold membership coming soon! Stay tuned.';

  @override
  String get close => 'Close';

  @override
  String goldMonthlyPrice(String price) {
    return '$price/month';
  }

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get purchaseRestored => 'Purchases restored successfully';

  @override
  String get purchaseRestoreFailed => 'No previous purchases found';

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get purchaseCancelled => 'Purchase cancelled';

  @override
  String get subscriptionActive => 'Active';

  @override
  String subscriptionExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get subscriptionManage => 'Manage Subscription';

  @override
  String get subscriptionTermsIos =>
      'Payment will be charged to your App Store account. Subscription renews automatically unless cancelled 24 hours before the end of the current period.';

  @override
  String get subscriptionTermsAndroid =>
      'Payment will be charged to your Google Play account. Subscription renews automatically unless cancelled 24 hours before the end of the current period.';

  @override
  String get goldMembershipTitle => 'Gold Membership';

  @override
  String get goldComingSoon => 'Gold membership is coming soon!';

  @override
  String get subscription => 'Subscription';

  @override
  String get freeTrialStart => 'Start 7-Day Free Trial';

  @override
  String freeTrialInfo(String price) {
    return 'Free for 7 days, then $price/month. Cancel anytime.';
  }

  @override
  String get onFreeTrial => 'Free Trial';

  @override
  String trialEndsOn(String date) {
    return 'Trial ends: $date';
  }

  @override
  String get trialExpired => 'Your free trial has ended';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get restorePurchaseTitle => 'Restore Previous Purchase';

  @override
  String get restorePurchaseDescription =>
      'Use this if your subscription is not reflected after changing devices or reinstalling the app.';

  @override
  String calendarPremiumEvents(int count) {
    return '$count premium events';
  }

  @override
  String get calendarUnlockWithAd => 'Watch ad for 6h access';

  @override
  String calendarUnlockedUntil(String time) {
    return 'Unlocked until $time';
  }

  @override
  String get treemapLegend => 'Size = Volume  |  Green = Up  |  Red = Down';

  @override
  String get aiScoreSubtitle => 'AI Score (0: Sell Signal ~ 100: Buy Signal)';

  @override
  String get aiSignalStrongBuyDesc =>
      'Strong Buy (80-100): Technical and financial indicators show strong buy signals';

  @override
  String get aiSignalBuyDesc =>
      'Buy (60-79): Overall positive indicators suggest buying';

  @override
  String get aiSignalHoldDesc =>
      'Hold (40-59): Mixed signals, maintain current position';

  @override
  String get aiSignalSellDesc =>
      'Sell (20-39): Overall negative indicators suggest selling';

  @override
  String get aiSignalStrongSellDesc =>
      'Strong Sell (0-19): Technical and financial indicators show strong sell signals';

  @override
  String get watchlistSubtitle => 'Collect and track your favorite stocks';

  @override
  String get wlTargetPrice => 'Target';

  @override
  String get wlPrice1mAgo => '1M ago';

  @override
  String get wlPrice3mAgo => '3M ago';

  @override
  String get filterActiveLabel => 'Filter Active';

  @override
  String get tapToRemoveFilter => 'Tap to remove';

  @override
  String get searchTickersCta => 'Search Tickers';

  @override
  String get addTickersCta => 'Add Tickers';

  @override
  String get beFirstToPost => 'Be the first to share your thoughts!';

  @override
  String totalPosts(int count) {
    return '$count posts';
  }

  @override
  String get recentComments => 'Recent Comments';

  @override
  String get coachMarkDashboardTreemap =>
      'Colors show price changes, size represents trading volume';

  @override
  String get coachMarkAiLens =>
      'AI-analyzed buy/sell signal distribution for stocks';

  @override
  String get coachMarkWatchlist => 'Add your favorite stocks to track!';

  @override
  String get coachMarkHoldings => 'Register holdings to track your returns';

  @override
  String get coachMarkTickerScore =>
      'Check the AI score trend. Above 70 indicates a buy signal';

  @override
  String get coachMarkMacroGauge =>
      'Swipe left and right to view economic indicators';

  @override
  String get coachMarkGotIt => 'Got it';

  @override
  String get resetTutorials => 'Reset Tutorials';

  @override
  String get resetTutorialsDesc => 'All tutorials will be shown again';

  @override
  String get tutorialsReset => 'Tutorials have been reset';

  @override
  String get purchaseStoreUnavailable => 'App Store Unavailable';

  @override
  String get purchaseTemporarilyUnavailable =>
      'Subscription Temporarily Unavailable';

  @override
  String get purchaseStoreProblem =>
      'Unable to connect to the App Store. Please check your Apple ID settings, ensure payments are enabled, and try again.';

  @override
  String get purchaseRetry => 'Try Again';

  @override
  String get purchaseInitializing => 'Connecting to App Store...';

  @override
  String get loginRequiredForPurchase =>
      'Please log in to purchase Gold membership. Your subscription will be synced to your account.';

  @override
  String get aiScoreGuideTitle => 'AI Score Guide';

  @override
  String get aiScoreGuideDescription =>
      'AI scores are calculated based on a mid-to-long-term (3–12 month) investment perspective.';

  @override
  String get aiScoreGuideStrongPositive =>
      '80–100: Strong Positive – Very high probability of rise';

  @override
  String get aiScoreGuidePositive =>
      '60–79: Positive – High probability of rise';

  @override
  String get aiScoreGuideNeutral => '40–59: Neutral – Mixed signals';

  @override
  String get aiScoreGuideNegative =>
      '20–39: Negative – High probability of decline';

  @override
  String get aiScoreGuideStrongNegative =>
      '0–19: Strong Negative – Very high probability of decline';

  @override
  String get subscriptionPaymentAccountWarning =>
      'Payment is processed through the App Store / Google Play account signed in on this device. If you purchase on someone else\'s device, the device owner\'s account may be charged.';

  @override
  String get investmentProfileTitle => 'Investment Profile';

  @override
  String get investmentProfileSection => 'Investment Profile';

  @override
  String get investmentProfileEditSubtitle =>
      'View or edit your investment preferences';

  @override
  String get investmentProfileComplete => 'Complete';

  @override
  String get investmentProfileSaveFailed =>
      'Failed to save profile. Please try again.';

  @override
  String get investmentProfileLoadFailed =>
      'Failed to load your profile. Please try again.';

  @override
  String get yourInvestmentStyle => 'Your Investment Style';

  @override
  String get setInvestmentStyle => 'Set your investment style';

  @override
  String get myRecommendations => 'Recommended for You';

  @override
  String get recommendationFit => 'Fit';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get investmentStyleTitle => 'Investment Style';

  @override
  String get investmentStyleSubtitle =>
      'What describes your investment approach?';

  @override
  String get investmentStyleConservative => 'Conservative';

  @override
  String get investmentStyleConservativeDesc =>
      'Prioritize capital preservation with stable returns';

  @override
  String get investmentStyleBalanced => 'Balanced';

  @override
  String get investmentStyleBalancedDesc =>
      'Balance between growth and stability';

  @override
  String get investmentStyleAggressive => 'Aggressive';

  @override
  String get investmentStyleAggressiveDesc =>
      'Pursue high returns with higher risk tolerance';

  @override
  String get timeHorizonTitle => 'Investment Horizon';

  @override
  String get timeHorizonSubtitle => 'How long do you plan to invest?';

  @override
  String get timeHorizonShort => 'Short-term';

  @override
  String get timeHorizonShortDesc => 'Less than 1 year';

  @override
  String get timeHorizonMedium => 'Medium-term';

  @override
  String get timeHorizonMediumDesc => '1 to 5 years';

  @override
  String get timeHorizonLong => 'Long-term';

  @override
  String get timeHorizonLongDesc => '5+ years';

  @override
  String get riskToleranceTitle => 'Risk Tolerance';

  @override
  String get riskToleranceSubtitle => 'How much risk can you handle?';

  @override
  String get riskLevel1 => 'Very Low';

  @override
  String get riskLevel2 => 'Low';

  @override
  String get riskLevel3 => 'Moderate';

  @override
  String get riskLevel4 => 'High';

  @override
  String get riskLevel5 => 'Very High';

  @override
  String get riskLow => 'Low';

  @override
  String get riskHigh => 'High';

  @override
  String get targetReturnTitle => 'Target Annual Return';

  @override
  String get targetReturnSubtitle => 'What return are you aiming for?';

  @override
  String get targetReturn5Desc => 'Stable, low-risk investments';

  @override
  String get targetReturn10Desc => 'Moderate growth strategy';

  @override
  String get targetReturn20Desc => 'Aggressive growth strategy';

  @override
  String get targetReturnFlexible => 'Flexible';

  @override
  String get targetReturnFlexibleDesc =>
      'No specific target, adapt to market conditions';

  @override
  String get maxLossTitle => 'Maximum Acceptable Loss';

  @override
  String get maxLossSubtitle =>
      'What is the maximum drawdown you can tolerate?';

  @override
  String get maxLoss5Desc => 'Very conservative, minimal drawdown';

  @override
  String get maxLoss10Desc => 'Conservative, limited drawdown';

  @override
  String get maxLoss20Desc => 'Moderate, standard market volatility';

  @override
  String get maxLoss40Desc => 'Aggressive, can withstand significant drops';

  @override
  String get maxLossUnlimited => 'Unlimited';

  @override
  String get maxLossUnlimitedDesc =>
      'No limit, fully committed to long-term gains';
}
