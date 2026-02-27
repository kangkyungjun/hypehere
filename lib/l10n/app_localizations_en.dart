// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabWatchlistTooltip => 'My Watchlist';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get compareTickers => 'Compare Tickers';

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
  String get passwordConfirm => 'Confirm Password';

  @override
  String get passwordConfirmHint => 'Re-enter your password';

  @override
  String get passwordConfirmRequired => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

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
  String get scoreStrongBuy => 'Strong Buy';

  @override
  String get scoreBuy => 'Buy';

  @override
  String get scoreHold => 'Hold';

  @override
  String get scoreSell => 'Sell';

  @override
  String get scoreStrongSell => 'Strong Sell';

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
  String get errMaxCompare => 'Maximum 3 tickers can be compared';

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
  String get updatedDate => 'Updated:';
}
