import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('zh'),
    Locale('ja'),
    Locale('es'),
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'MarketLens'**
  String get appTitle;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabDashboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Market Dashboard'**
  String get tabDashboardTooltip;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search Tickers'**
  String get tabSearchTooltip;

  /// No description provided for @tabNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tabNews;

  /// No description provided for @tabNewsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Market News'**
  String get tabNewsTooltip;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @tabCommunityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Discussion Board'**
  String get tabCommunityTooltip;

  /// No description provided for @tabMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get tabMarket;

  /// No description provided for @tabMarketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Market Overview'**
  String get tabMarketTooltip;

  /// No description provided for @tabAILens.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get tabAILens;

  /// No description provided for @tabAILensTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get tabAILensTooltip;

  /// No description provided for @tabWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get tabWatchlist;

  /// No description provided for @tabWatchlistTooltip.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get tabWatchlistTooltip;

  /// No description provided for @tabHoldingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'My Holdings'**
  String get tabHoldingsTooltip;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @compareTickers.
  ///
  /// In en, this message translates to:
  /// **'Compare Tickers'**
  String get compareTickers;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access community features'**
  String get loginSubtitle;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get signupSubtitle;

  /// No description provided for @noAccountSignup.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get noAccountSignup;

  /// No description provided for @hasAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get hasAccountLogin;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get accountCreated;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get emailInvalid;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Nickname for the community'**
  String get nicknameHint;

  /// No description provided for @nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get nicknameRequired;

  /// No description provided for @nicknameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least 2 characters'**
  String get nicknameTooShort;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordConfirm;

  /// No description provided for @passwordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get passwordConfirmHint;

  /// No description provided for @passwordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get passwordConfirmRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordGuide.
  ///
  /// In en, this message translates to:
  /// **'Password Change Guide'**
  String get changePasswordGuide;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get oldPassword;

  /// No description provided for @oldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get oldPasswordHint;

  /// No description provided for @oldPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get oldPasswordRequired;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password (min 8 characters)'**
  String get newPasswordHint;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get newPasswordRequired;

  /// No description provided for @newPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get newPasswordConfirm;

  /// No description provided for @newPasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get newPasswordConfirmHint;

  /// No description provided for @newPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get newPasswordConfirmRequired;

  /// No description provided for @newPasswordMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'New password must differ from current password'**
  String get newPasswordMustDiffer;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password change failed: {error}'**
  String passwordChangeFailed(String error);

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @loginPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Login and join the community!'**
  String get loginPromptMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ticker or company (e.g. AAPL, Apple)'**
  String get searchHint;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search Failed'**
  String get searchFailed;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noSearchResults;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different ticker'**
  String get tryDifferentSearch;

  /// No description provided for @tickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Ticker Search'**
  String get tickerSearch;

  /// No description provided for @enterTickerAbove.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term'**
  String get enterTickerAbove;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @sectorMarketOverview.
  ///
  /// In en, this message translates to:
  /// **'Sector Overview'**
  String get sectorMarketOverview;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNasdaq.
  ///
  /// In en, this message translates to:
  /// **'NASDAQ'**
  String get filterNasdaq;

  /// No description provided for @filterDow.
  ///
  /// In en, this message translates to:
  /// **'Dow'**
  String get filterDow;

  /// No description provided for @marketLensAIScore.
  ///
  /// In en, this message translates to:
  /// **'AI Score'**
  String get marketLensAIScore;

  /// No description provided for @distributionShownOnFullLoad.
  ///
  /// In en, this message translates to:
  /// **'Score distribution loads with all signals'**
  String get distributionShownOnFullLoad;

  /// No description provided for @topN.
  ///
  /// In en, this message translates to:
  /// **'▲ Top {n}'**
  String topN(int n);

  /// No description provided for @bottomN.
  ///
  /// In en, this message translates to:
  /// **'▼ Bottom {n}'**
  String bottomN(int n);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @signalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load signals'**
  String get signalLoadFailed;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard loading failed: {error}'**
  String dashboardLoadFailed(String error);

  /// No description provided for @allSignals.
  ///
  /// In en, this message translates to:
  /// **'All Signals'**
  String get allSignals;

  /// No description provided for @sp500Signals.
  ///
  /// In en, this message translates to:
  /// **'S&P 500 Signals'**
  String get sp500Signals;

  /// No description provided for @dow30Signals.
  ///
  /// In en, this message translates to:
  /// **'Dow 30 Signals'**
  String get dow30Signals;

  /// No description provided for @nasdaq100Signals.
  ///
  /// In en, this message translates to:
  /// **'NASDAQ 100 Signals'**
  String get nasdaq100Signals;

  /// No description provided for @marketTrend.
  ///
  /// In en, this message translates to:
  /// **'Overall Market Trend'**
  String get marketTrend;

  /// No description provided for @loadingSignals.
  ///
  /// In en, this message translates to:
  /// **'Loading signals...'**
  String get loadingSignals;

  /// No description provided for @loadingSP500Signals.
  ///
  /// In en, this message translates to:
  /// **'Loading S&P 500 signals...'**
  String get loadingSP500Signals;

  /// No description provided for @loadingDow30Signals.
  ///
  /// In en, this message translates to:
  /// **'Loading Dow 30 signals...'**
  String get loadingDow30Signals;

  /// No description provided for @loadingNasdaq100Signals.
  ///
  /// In en, this message translates to:
  /// **'Loading NASDAQ 100 signals...'**
  String get loadingNasdaq100Signals;

  /// No description provided for @noAdditionalSignals.
  ///
  /// In en, this message translates to:
  /// **'No additional signals'**
  String get noAdditionalSignals;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More ({remaining} left)'**
  String showMore(int remaining);

  /// No description provided for @nItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String nItems(int count);

  /// No description provided for @scoreStrongBuy.
  ///
  /// In en, this message translates to:
  /// **'Strong Buy'**
  String get scoreStrongBuy;

  /// No description provided for @scoreBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get scoreBuy;

  /// No description provided for @scoreHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get scoreHold;

  /// No description provided for @scoreSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get scoreSell;

  /// No description provided for @scoreStrongSell.
  ///
  /// In en, this message translates to:
  /// **'Strong Sell'**
  String get scoreStrongSell;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @myWatchlist.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get myWatchlist;

  /// No description provided for @nTickers.
  ///
  /// In en, this message translates to:
  /// **'{count} tickers'**
  String nTickers(int count);

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Watchlist is empty'**
  String get watchlistEmpty;

  /// No description provided for @watchlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search and add tickers from the Search tab'**
  String get watchlistEmptyHint;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @tapToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get tapToViewDetails;

  /// No description provided for @tickerRemovedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{ticker} removed from watchlist'**
  String tickerRemovedFromWatchlist(String ticker);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @tickerDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ticker data'**
  String get tickerDataLoadFailed;

  /// No description provided for @addToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to Watchlist'**
  String get addToWatchlist;

  /// No description provided for @removeFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from Watchlist'**
  String get removeFromWatchlist;

  /// No description provided for @addedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Added to watchlist'**
  String get addedToWatchlist;

  /// No description provided for @removedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from watchlist'**
  String get removedFromWatchlist;

  /// No description provided for @watchlistDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to your watchlist'**
  String get watchlistDiscoveryTitle;

  /// No description provided for @watchlistDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get news & signal alerts for your picks'**
  String get watchlistDiscoverySubtitle;

  /// No description provided for @topTradingVolume.
  ///
  /// In en, this message translates to:
  /// **'Top Trading Volume Today'**
  String get topTradingVolume;

  /// No description provided for @communitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or content...'**
  String get communitySearchHint;

  /// No description provided for @writePost.
  ///
  /// In en, this message translates to:
  /// **'Write Post'**
  String get writePost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?\nDeleted posts cannot be recovered.'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @reportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse / Defamation'**
  String get reportAbuse;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam / Advertising'**
  String get reportSpam;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate Content'**
  String get reportInappropriate;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportHarassment;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @reportDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportDescription;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportSubmit;

  /// No description provided for @postDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post: {error}'**
  String postDeleteFailed(String error);

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @writeFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Write the first post!'**
  String get writeFirstPost;

  /// No description provided for @noSearchResultsCommunity.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResultsCommunity;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get tryDifferentFilter;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please try again later.'**
  String get networkError;

  /// No description provided for @serverTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server timeout. Please try again later.'**
  String get serverTimeout;

  /// No description provided for @postsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts. Please try again later.'**
  String get postsLoadFailed;

  /// No description provided for @searchResultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load search results'**
  String get searchResultsLoadFailed;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @tickerBoard.
  ///
  /// In en, this message translates to:
  /// **'{ticker} Board'**
  String tickerBoard(String ticker);

  /// No description provided for @tickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search ticker... (e.g. AAPL, TSLA)'**
  String get tickerSearchHint;

  /// No description provided for @popularTickers.
  ///
  /// In en, this message translates to:
  /// **'Popular Tickers'**
  String get popularTickers;

  /// No description provided for @freePost.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePost;

  /// No description provided for @checkNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection'**
  String get checkNetwork;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostTitle;

  /// No description provided for @tickerOnlyBoard.
  ///
  /// In en, this message translates to:
  /// **'Ticker-specific Board'**
  String get tickerOnlyBoard;

  /// No description provided for @selectTicker.
  ///
  /// In en, this message translates to:
  /// **'Ticker'**
  String get selectTicker;

  /// No description provided for @tickerSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Ticker'**
  String get tickerSearchLabel;

  /// No description provided for @tickerSearchHintCreate.
  ///
  /// In en, this message translates to:
  /// **'Search by name, symbol, or Korean name'**
  String get tickerSearchHintCreate;

  /// No description provided for @tickerNotSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Post will be tagged as Free if no ticker is selected'**
  String get tickerNotSelectedHint;

  /// No description provided for @noTickerSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noTickerSearchResults;

  /// No description provided for @postTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get postTitle;

  /// No description provided for @postTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter post title'**
  String get postTitleHint;

  /// No description provided for @postTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get postTitleRequired;

  /// No description provided for @postTitleTooShort.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 2 characters'**
  String get postTitleTooShort;

  /// No description provided for @postContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get postContent;

  /// No description provided for @postContentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter post content'**
  String get postContentHint;

  /// No description provided for @postContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter content'**
  String get postContentRequired;

  /// No description provided for @postContentTooShort.
  ///
  /// In en, this message translates to:
  /// **'Content must be at least 5 characters'**
  String get postContentTooShort;

  /// No description provided for @postCreated.
  ///
  /// In en, this message translates to:
  /// **'Post created'**
  String get postCreated;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get postUpdated;

  /// No description provided for @submitPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get submitPost;

  /// No description provided for @updatePostButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updatePostButton;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get deleteComment;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteCommentConfirm;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit Comment'**
  String get editComment;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentHint;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter comment content'**
  String get commentPlaceholder;

  /// No description provided for @commentCreated.
  ///
  /// In en, this message translates to:
  /// **'Comment posted'**
  String get commentCreated;

  /// No description provided for @commentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Comment updated'**
  String get commentUpdated;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @commentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a comment'**
  String get commentRequired;

  /// No description provided for @loginToViewComments.
  ///
  /// In en, this message translates to:
  /// **'Login to view comments'**
  String get loginToViewComments;

  /// No description provided for @writeFirstComment.
  ///
  /// In en, this message translates to:
  /// **'Write the first comment!'**
  String get writeFirstComment;

  /// No description provided for @postDetail.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetail;

  /// No description provided for @startWithFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Start with your first post'**
  String get startWithFirstPost;

  /// No description provided for @writeAPost.
  ///
  /// In en, this message translates to:
  /// **'Write a Post'**
  String get writeAPost;

  /// No description provided for @cannotLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Cannot load posts'**
  String get cannotLoadPosts;

  /// No description provided for @noPostsInTicker.
  ///
  /// In en, this message translates to:
  /// **'No posts in this board yet'**
  String get noPostsInTicker;

  /// No description provided for @writeFirstPostInTicker.
  ///
  /// In en, this message translates to:
  /// **'Write the first post!'**
  String get writeFirstPostInTicker;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @clearRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Clear Recent Searches'**
  String get clearRecentSearches;

  /// No description provided for @nSearchRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} search records'**
  String nSearchRecords(int count);

  /// No description provided for @clearRecentSearchesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all recent search records?'**
  String get clearRecentSearchesConfirm;

  /// No description provided for @recentSearchesCleared.
  ///
  /// In en, this message translates to:
  /// **'Recent searches cleared'**
  String get recentSearchesCleared;

  /// No description provided for @clearWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Clear Watchlist'**
  String get clearWatchlist;

  /// No description provided for @clearWatchlistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all watchlist tickers?'**
  String get clearWatchlistConfirm;

  /// No description provided for @watchlistCleared.
  ///
  /// In en, this message translates to:
  /// **'Watchlist cleared'**
  String get watchlistCleared;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'All local data including watchlist and search history will be deleted. This cannot be undone.'**
  String get deleteAllDataConfirm;

  /// No description provided for @deleteAllButton.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAllButton;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDataDeleted;

  /// No description provided for @removeAllLocalData.
  ///
  /// In en, this message translates to:
  /// **'Remove all local data'**
  String get removeAllLocalData;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @aboutMarketLens.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutMarketLens;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'AI-powered stock analysis tool for data-driven investment decisions'**
  String get appDescription;

  /// No description provided for @aiStockAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Stock Analysis'**
  String get aiStockAnalysis;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User management and permissions'**
  String get adminPanelSubtitle;

  /// No description provided for @showAds.
  ///
  /// In en, this message translates to:
  /// **'Show Ads'**
  String get showAds;

  /// No description provided for @adsEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Banner ads shown to all users'**
  String get adsEnabledDescription;

  /// No description provided for @adsDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Ads are hidden'**
  String get adsDisabledDescription;

  /// No description provided for @sendPushNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Push Notification'**
  String get sendPushNotification;

  /// No description provided for @sendPushNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast to all users'**
  String get sendPushNotificationSubtitle;

  /// No description provided for @pushTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get pushTitle;

  /// No description provided for @pushBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get pushBody;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @pushSentResult.
  ///
  /// In en, this message translates to:
  /// **'Push sent to {count} devices'**
  String pushSentResult(int count);

  /// No description provided for @pushSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send push notification'**
  String get pushSendFailed;

  /// No description provided for @promoteToGold.
  ///
  /// In en, this message translates to:
  /// **'Promote to Gold'**
  String get promoteToGold;

  /// No description provided for @promoteToManager.
  ///
  /// In en, this message translates to:
  /// **'Promote to Manager'**
  String get promoteToManager;

  /// No description provided for @demoteToRegular.
  ///
  /// In en, this message translates to:
  /// **'Demote to Regular'**
  String get demoteToRegular;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @myComments.
  ///
  /// In en, this message translates to:
  /// **'My Comments'**
  String get myComments;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts'**
  String get noPosts;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get noComments;

  /// No description provided for @joinDate.
  ///
  /// In en, this message translates to:
  /// **'Joined: {date}'**
  String joinDate(String date);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Account'**
  String get deleteAccount;

  /// No description provided for @withdrawAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw your account?\nYour account will be permanently deleted after 7 days. Log in again within that period to cancel.'**
  String get withdrawAccountConfirm;

  /// No description provided for @withdrawAccountReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter your reason for withdrawal (optional)'**
  String get withdrawAccountReasonHint;

  /// No description provided for @withdrawAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account withdrawal requested. Your account will be permanently deleted in 7 days.'**
  String get withdrawAccountSuccess;

  /// No description provided for @withdrawAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request account withdrawal. Please try again.'**
  String get withdrawAccountFailed;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @imagePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image'**
  String get imagePickerFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文(简体)'**
  String get languageChinese;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @companyOverview.
  ///
  /// In en, this message translates to:
  /// **'Company Overview'**
  String get companyOverview;

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get companyDetails;

  /// No description provided for @companyIntro.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get companyIntro;

  /// No description provided for @employeeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} employees'**
  String employeeCount(String count);

  /// No description provided for @valuation.
  ///
  /// In en, this message translates to:
  /// **'Valuation'**
  String get valuation;

  /// No description provided for @forwardPE.
  ///
  /// In en, this message translates to:
  /// **'Forward PE'**
  String get forwardPE;

  /// No description provided for @beta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get beta;

  /// No description provided for @profitabilityGrowth.
  ///
  /// In en, this message translates to:
  /// **'Profitability & Growth'**
  String get profitabilityGrowth;

  /// No description provided for @netProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Margin'**
  String get netProfitMargin;

  /// No description provided for @revenueGrowth.
  ///
  /// In en, this message translates to:
  /// **'Rev Growth'**
  String get revenueGrowth;

  /// No description provided for @operatingMargin.
  ///
  /// In en, this message translates to:
  /// **'Op Margin'**
  String get operatingMargin;

  /// No description provided for @earningsGrowth.
  ///
  /// In en, this message translates to:
  /// **'Earn Growth'**
  String get earningsGrowth;

  /// No description provided for @financialHealth.
  ///
  /// In en, this message translates to:
  /// **'Financial Health'**
  String get financialHealth;

  /// No description provided for @debtRatio.
  ///
  /// In en, this message translates to:
  /// **'D/E Ratio'**
  String get debtRatio;

  /// No description provided for @liquidityRatio.
  ///
  /// In en, this message translates to:
  /// **'Current Ratio'**
  String get liquidityRatio;

  /// No description provided for @dividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get dividends;

  /// No description provided for @dividendYield.
  ///
  /// In en, this message translates to:
  /// **'Yield '**
  String get dividendYield;

  /// No description provided for @annualDividend.
  ///
  /// In en, this message translates to:
  /// **'Annual '**
  String get annualDividend;

  /// No description provided for @shortInterest.
  ///
  /// In en, this message translates to:
  /// **'Short Interest'**
  String get shortInterest;

  /// No description provided for @shortInterestRatio.
  ///
  /// In en, this message translates to:
  /// **'Short Ratio'**
  String get shortInterestRatio;

  /// No description provided for @shortPercentFloat.
  ///
  /// In en, this message translates to:
  /// **'Short % Float'**
  String get shortPercentFloat;

  /// No description provided for @shortDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String shortDays(String days);

  /// No description provided for @shortInterestLow.
  ///
  /// In en, this message translates to:
  /// **'Short interest low (stable)'**
  String get shortInterestLow;

  /// No description provided for @shortInterestModerate.
  ///
  /// In en, this message translates to:
  /// **'Short interest moderate (caution)'**
  String get shortInterestModerate;

  /// No description provided for @shortInterestHigh.
  ///
  /// In en, this message translates to:
  /// **'Short interest high (warning)'**
  String get shortInterestHigh;

  /// No description provided for @institutionalInsiderFlow.
  ///
  /// In en, this message translates to:
  /// **'Institutional / Insider Flow'**
  String get institutionalInsiderFlow;

  /// No description provided for @institutional.
  ///
  /// In en, this message translates to:
  /// **'Institutional'**
  String get institutional;

  /// No description provided for @insider.
  ///
  /// In en, this message translates to:
  /// **'Insider'**
  String get insider;

  /// No description provided for @oneDay.
  ///
  /// In en, this message translates to:
  /// **'1D'**
  String get oneDay;

  /// No description provided for @fiveDay.
  ///
  /// In en, this message translates to:
  /// **'5D'**
  String get fiveDay;

  /// No description provided for @tickerNews.
  ///
  /// In en, this message translates to:
  /// **'{ticker} News'**
  String tickerNews(String ticker);

  /// No description provided for @newsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String newsCount(int count);

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get oneWeek;

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get oneMonth;

  /// No description provided for @noNews.
  ///
  /// In en, this message translates to:
  /// **'No news'**
  String get noNews;

  /// No description provided for @marketNews.
  ///
  /// In en, this message translates to:
  /// **'Market News'**
  String get marketNews;

  /// No description provided for @viewOriginalArticle.
  ///
  /// In en, this message translates to:
  /// **'View Original Article'**
  String get viewOriginalArticle;

  /// No description provided for @sentimentBullish.
  ///
  /// In en, this message translates to:
  /// **'Bullish'**
  String get sentimentBullish;

  /// No description provided for @sentimentNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get sentimentNeutral;

  /// No description provided for @sentimentBearish.
  ///
  /// In en, this message translates to:
  /// **'Bearish'**
  String get sentimentBearish;

  /// No description provided for @aiSummaryNews.
  ///
  /// In en, this message translates to:
  /// **'AI Summary News'**
  String get aiSummaryNews;

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Summary'**
  String get aiSummary;

  /// No description provided for @noNewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No news available'**
  String get noNewsAvailable;

  /// No description provided for @earningsHistory.
  ///
  /// In en, this message translates to:
  /// **'Earnings History'**
  String get earningsHistory;

  /// No description provided for @earningsHistoryEPS.
  ///
  /// In en, this message translates to:
  /// **'Earnings History (EPS)'**
  String get earningsHistoryEPS;

  /// No description provided for @earningsEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get earningsEstimate;

  /// No description provided for @earningsBeat.
  ///
  /// In en, this message translates to:
  /// **'Beat'**
  String get earningsBeat;

  /// No description provided for @earningsMiss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get earningsMiss;

  /// No description provided for @earningsActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get earningsActual;

  /// No description provided for @earningsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get earningsScheduled;

  /// No description provided for @epsEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'EPS Estimate'**
  String get epsEstimateLabel;

  /// No description provided for @revenueEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue Estimate'**
  String get revenueEstimateLabel;

  /// No description provided for @averageLabel.
  ///
  /// In en, this message translates to:
  /// **'avg'**
  String get averageLabel;

  /// No description provided for @surpriseLabel.
  ///
  /// In en, this message translates to:
  /// **'Surprise'**
  String get surpriseLabel;

  /// No description provided for @thisWeekEarnings.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Earnings'**
  String get thisWeekEarnings;

  /// No description provided for @previousEarnings.
  ///
  /// In en, this message translates to:
  /// **'Previous Earnings'**
  String get previousEarnings;

  /// No description provided for @earningsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String earningsCount(int count);

  /// No description provided for @noEarningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No earnings scheduled this week'**
  String get noEarningsThisWeek;

  /// No description provided for @nextEarningsDate.
  ///
  /// In en, this message translates to:
  /// **'Next Earnings'**
  String get nextEarningsDate;

  /// No description provided for @earningsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get earningsConfirmed;

  /// No description provided for @keyEvents.
  ///
  /// In en, this message translates to:
  /// **'Key Events'**
  String get keyEvents;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @exDividendDate.
  ///
  /// In en, this message translates to:
  /// **'Ex-Dividend Date'**
  String get exDividendDate;

  /// No description provided for @dividendPayDate.
  ///
  /// In en, this message translates to:
  /// **'Dividend Pay Date'**
  String get dividendPayDate;

  /// No description provided for @recentEarningsQuarters.
  ///
  /// In en, this message translates to:
  /// **'Recent Earnings ({count}Q)'**
  String recentEarningsQuarters(int count);

  /// No description provided for @earningsHistoryChart.
  ///
  /// In en, this message translates to:
  /// **'Earnings History (Chart)'**
  String get earningsHistoryChart;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @macroFedFunds.
  ///
  /// In en, this message translates to:
  /// **'Fed Rate'**
  String get macroFedFunds;

  /// No description provided for @macroDGS10.
  ///
  /// In en, this message translates to:
  /// **'10Y Yield'**
  String get macroDGS10;

  /// No description provided for @macroDGS2.
  ///
  /// In en, this message translates to:
  /// **'2Y Yield'**
  String get macroDGS2;

  /// No description provided for @macroT10Y2Y.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get macroT10Y2Y;

  /// No description provided for @macroVIXCLS.
  ///
  /// In en, this message translates to:
  /// **'VIX'**
  String get macroVIXCLS;

  /// No description provided for @macroCPIAUCSL.
  ///
  /// In en, this message translates to:
  /// **'CPI'**
  String get macroCPIAUCSL;

  /// No description provided for @macroUNRATE.
  ///
  /// In en, this message translates to:
  /// **'Unemployment'**
  String get macroUNRATE;

  /// No description provided for @macroFedFundsDesc.
  ///
  /// In en, this message translates to:
  /// **'Federal Funds Rate'**
  String get macroFedFundsDesc;

  /// No description provided for @macroDGS10Desc.
  ///
  /// In en, this message translates to:
  /// **'US 10-Year Treasury Yield'**
  String get macroDGS10Desc;

  /// No description provided for @macroDGS2Desc.
  ///
  /// In en, this message translates to:
  /// **'US 2-Year Treasury Yield'**
  String get macroDGS2Desc;

  /// No description provided for @macroT10Y2YDesc.
  ///
  /// In en, this message translates to:
  /// **'Yield Curve Spread (10Y-2Y)'**
  String get macroT10Y2YDesc;

  /// No description provided for @macroVIXCLSDesc.
  ///
  /// In en, this message translates to:
  /// **'Market Volatility Index'**
  String get macroVIXCLSDesc;

  /// No description provided for @macroCPIAUCSLDesc.
  ///
  /// In en, this message translates to:
  /// **'Consumer Price Index (CPI)'**
  String get macroCPIAUCSLDesc;

  /// No description provided for @macroUNRATEDesc.
  ///
  /// In en, this message translates to:
  /// **'US Unemployment Rate'**
  String get macroUNRATEDesc;

  /// No description provided for @riskBearish.
  ///
  /// In en, this message translates to:
  /// **'Bearish'**
  String get riskBearish;

  /// No description provided for @riskCautious.
  ///
  /// In en, this message translates to:
  /// **'Cautious'**
  String get riskCautious;

  /// No description provided for @riskNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get riskNeutral;

  /// No description provided for @riskPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get riskPositive;

  /// No description provided for @riskBullish.
  ///
  /// In en, this message translates to:
  /// **'Bullish'**
  String get riskBullish;

  /// No description provided for @macroCategoryRates.
  ///
  /// In en, this message translates to:
  /// **'Interest Rates'**
  String get macroCategoryRates;

  /// No description provided for @macroCategorySentiment.
  ///
  /// In en, this message translates to:
  /// **'Sentiment'**
  String get macroCategorySentiment;

  /// No description provided for @macroCategoryEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get macroCategoryEconomy;

  /// No description provided for @macroYieldCurve.
  ///
  /// In en, this message translates to:
  /// **'Yield Curve'**
  String get macroYieldCurve;

  /// No description provided for @macroLiquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get macroLiquidity;

  /// No description provided for @macroOverall.
  ///
  /// In en, this message translates to:
  /// **'Macro Overall'**
  String get macroOverall;

  /// No description provided for @macroCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String macroCurrentValue(String value);

  /// No description provided for @macroChange.
  ///
  /// In en, this message translates to:
  /// **'Change: {value}'**
  String macroChange(String value);

  /// No description provided for @epsEstimateValue.
  ///
  /// In en, this message translates to:
  /// **'Est. \${value}'**
  String epsEstimateValue(String value);

  /// No description provided for @bbInterpretation.
  ///
  /// In en, this message translates to:
  /// **'Bollinger Bands Interpretation'**
  String get bbInterpretation;

  /// No description provided for @bbBandWidth.
  ///
  /// In en, this message translates to:
  /// **'• Band width: shows volatility (wider = higher)'**
  String get bbBandWidth;

  /// No description provided for @bbUpperApproach.
  ///
  /// In en, this message translates to:
  /// **'• Upper band approach: potential overbought'**
  String get bbUpperApproach;

  /// No description provided for @bbLowerApproach.
  ///
  /// In en, this message translates to:
  /// **'• Lower band approach: potential oversold'**
  String get bbLowerApproach;

  /// No description provided for @bbMiddleLine.
  ///
  /// In en, this message translates to:
  /// **'• Middle line: 20-day moving average'**
  String get bbMiddleLine;

  /// No description provided for @cannotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Cannot load data'**
  String get cannotLoadData;

  /// No description provided for @marketlensAI.
  ///
  /// In en, this message translates to:
  /// **'MarketLens AI'**
  String get marketlensAI;

  /// No description provided for @marketlensAIOpinion.
  ///
  /// In en, this message translates to:
  /// **'MarketLens AI Opinion'**
  String get marketlensAIOpinion;

  /// No description provided for @bullishFactors.
  ///
  /// In en, this message translates to:
  /// **'Bullish Factors'**
  String get bullishFactors;

  /// No description provided for @bearishFactors.
  ///
  /// In en, this message translates to:
  /// **'Bearish Factors'**
  String get bearishFactors;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target '**
  String get target;

  /// No description provided for @stopLoss.
  ///
  /// In en, this message translates to:
  /// **'Stop '**
  String get stopLoss;

  /// No description provided for @averageTargetPrice.
  ///
  /// In en, this message translates to:
  /// **'Avg Target Price'**
  String get averageTargetPrice;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentPrice;

  /// No description provided for @targetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetPrice;

  /// No description provided for @recentAnalystRatings.
  ///
  /// In en, this message translates to:
  /// **'Recent Analyst Ratings'**
  String get recentAnalystRatings;

  /// No description provided for @unknownFirm.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownFirm;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @ratingBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get ratingBuy;

  /// No description provided for @ratingStrongBuy.
  ///
  /// In en, this message translates to:
  /// **'Strong Buy'**
  String get ratingStrongBuy;

  /// No description provided for @ratingOutperform.
  ///
  /// In en, this message translates to:
  /// **'Outperform'**
  String get ratingOutperform;

  /// No description provided for @ratingHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get ratingHold;

  /// No description provided for @ratingNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get ratingNeutral;

  /// No description provided for @ratingMarketPerform.
  ///
  /// In en, this message translates to:
  /// **'Market Perform'**
  String get ratingMarketPerform;

  /// No description provided for @ratingSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get ratingSell;

  /// No description provided for @ratingStrongSell.
  ///
  /// In en, this message translates to:
  /// **'Strong Sell'**
  String get ratingStrongSell;

  /// No description provided for @ratingUnderperform.
  ///
  /// In en, this message translates to:
  /// **'Underperform'**
  String get ratingUnderperform;

  /// No description provided for @ratingActionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get ratingActionUpgrade;

  /// No description provided for @ratingActionDowngrade.
  ///
  /// In en, this message translates to:
  /// **'Downgrade'**
  String get ratingActionDowngrade;

  /// No description provided for @ratingActionReiterated.
  ///
  /// In en, this message translates to:
  /// **'Reiterated'**
  String get ratingActionReiterated;

  /// No description provided for @ratingActionInitiated.
  ///
  /// In en, this message translates to:
  /// **'Initiated'**
  String get ratingActionInitiated;

  /// No description provided for @roleMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get roleMaster;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get roleGold;

  /// No description provided for @roleRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get roleRegular;

  /// No description provided for @roleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get roleGuest;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get errInvalidCredentials;

  /// No description provided for @errLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get errLoginRequired;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get errSessionExpired;

  /// No description provided for @errCannotLoadUser.
  ///
  /// In en, this message translates to:
  /// **'Cannot load user info'**
  String get errCannotLoadUser;

  /// No description provided for @errServerConnection.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your network.'**
  String get errServerConnection;

  /// No description provided for @errServerConnectionShort.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server'**
  String get errServerConnectionShort;

  /// No description provided for @errNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network connection failed. Please check your internet.'**
  String get errNetworkFailed;

  /// No description provided for @errResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid server response format'**
  String get errResponseFormat;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server timeout ({seconds}s)'**
  String errTimeout(int seconds);

  /// No description provided for @errBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Please check your input'**
  String get errBadRequest;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errNotFound;

  /// No description provided for @errServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errServerError;

  /// No description provided for @errNoEditPermission.
  ///
  /// In en, this message translates to:
  /// **'No edit permission'**
  String get errNoEditPermission;

  /// No description provided for @errNoDeletePermission.
  ///
  /// In en, this message translates to:
  /// **'No delete permission'**
  String get errNoDeletePermission;

  /// No description provided for @errPostDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post'**
  String get errPostDeleteFailed;

  /// No description provided for @errCommentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete comment'**
  String get errCommentDeleteFailed;

  /// No description provided for @errReportAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You have already reported this content'**
  String get errReportAlreadySubmitted;

  /// No description provided for @errCannotReportOwn.
  ///
  /// In en, this message translates to:
  /// **'You cannot report your own content'**
  String get errCannotReportOwn;

  /// No description provided for @errReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get errReportFailed;

  /// No description provided for @errManagerRequired.
  ///
  /// In en, this message translates to:
  /// **'Manager or above access required'**
  String get errManagerRequired;

  /// No description provided for @errMasterRequired.
  ///
  /// In en, this message translates to:
  /// **'Master access required'**
  String get errMasterRequired;

  /// No description provided for @errSearchRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term'**
  String get errSearchRequired;

  /// No description provided for @errDemotionFailed.
  ///
  /// In en, this message translates to:
  /// **'Demotion failed'**
  String get errDemotionFailed;

  /// No description provided for @errMaxCompare.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 tickers can be compared'**
  String get errMaxCompare;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @dayBeforeYesterday.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get dayBeforeYesterday;

  /// No description provided for @expertCount.
  ///
  /// In en, this message translates to:
  /// **'Analyst Targets ({count})'**
  String expertCount(String count);

  /// No description provided for @scorePoints.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String scorePoints(String score);

  /// No description provided for @averageVolume.
  ///
  /// In en, this message translates to:
  /// **'Avg: {volume}'**
  String averageVolume(String volume);

  /// No description provided for @showBullBearFactors.
  ///
  /// In en, this message translates to:
  /// **'Show factors'**
  String get showBullBearFactors;

  /// No description provided for @hideBullBearFactors.
  ///
  /// In en, this message translates to:
  /// **'Hide factors'**
  String get hideBullBearFactors;

  /// No description provided for @analystConsensus.
  ///
  /// In en, this message translates to:
  /// **'Analyst Targets ({count} firms)'**
  String analystConsensus(String count);

  /// No description provided for @lowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Low \${price}'**
  String lowestPrice(String price);

  /// No description provided for @highestPrice.
  ///
  /// In en, this message translates to:
  /// **'High \${price}'**
  String highestPrice(String price);

  /// No description provided for @liveTalk.
  ///
  /// In en, this message translates to:
  /// **'💬 Live Talk'**
  String get liveTalk;

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(int count);

  /// No description provided for @browsePosts.
  ///
  /// In en, this message translates to:
  /// **'Browse Posts'**
  String get browsePosts;

  /// No description provided for @loginPromptComments.
  ///
  /// In en, this message translates to:
  /// **'See what other investors think and\nshare your own analysis!'**
  String get loginPromptComments;

  /// No description provided for @shareThoughtsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts on tickers\nand connect with other investors'**
  String get shareThoughtsPrompt;

  /// No description provided for @writeFirstCommentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Leave the first comment on a post'**
  String get writeFirstCommentPrompt;

  /// No description provided for @startConversationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by commenting\non other investors\' posts'**
  String get startConversationPrompt;

  /// No description provided for @ratingOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get ratingOverweight;

  /// No description provided for @ratingUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get ratingUnderweight;

  /// No description provided for @ratingSectorOutperform.
  ///
  /// In en, this message translates to:
  /// **'Sector Outperform'**
  String get ratingSectorOutperform;

  /// No description provided for @ratingSectorPerform.
  ///
  /// In en, this message translates to:
  /// **'Sector Perform'**
  String get ratingSectorPerform;

  /// No description provided for @ratingSectorUnderperform.
  ///
  /// In en, this message translates to:
  /// **'Sector Underperform'**
  String get ratingSectorUnderperform;

  /// No description provided for @ratingPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get ratingPositive;

  /// No description provided for @ratingNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get ratingNegative;

  /// No description provided for @ratingEqualWeight.
  ///
  /// In en, this message translates to:
  /// **'Equal Weight'**
  String get ratingEqualWeight;

  /// No description provided for @keyMetricsComparison.
  ///
  /// In en, this message translates to:
  /// **'Key Metrics Comparison'**
  String get keyMetricsComparison;

  /// No description provided for @metric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get metric;

  /// No description provided for @serverCalculatedNote.
  ///
  /// In en, this message translates to:
  /// **'※ All metrics are server-calculated values'**
  String get serverCalculatedNote;

  /// No description provided for @priceTrendComparison.
  ///
  /// In en, this message translates to:
  /// **'Price Trend Comparison'**
  String get priceTrendComparison;

  /// No description provided for @rsiComparison.
  ///
  /// In en, this message translates to:
  /// **'RSI Comparison (Server Values)'**
  String get rsiComparison;

  /// No description provided for @rsiInterpretation.
  ///
  /// In en, this message translates to:
  /// **'※ RSI > 70: Overbought / RSI < 30: Oversold'**
  String get rsiInterpretation;

  /// No description provided for @passwordChangeInstructions.
  ///
  /// In en, this message translates to:
  /// **'• New password must be at least 8 characters\n• Use a combination of letters, numbers, and symbols\n• You will need to login again with the new password'**
  String get passwordChangeInstructions;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllAsRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notificationsRetentionHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications from the last 7 days appear here.'**
  String get notificationsRetentionHint;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get bioHint;

  /// No description provided for @profileEditGuide.
  ///
  /// In en, this message translates to:
  /// **'Profile Edit Guide'**
  String get profileEditGuide;

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get updatedDate;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabCalendarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Event Calendar'**
  String get tabCalendarTooltip;

  /// No description provided for @eventTypeFomc.
  ///
  /// In en, this message translates to:
  /// **'FOMC'**
  String get eventTypeFomc;

  /// No description provided for @eventTypeEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get eventTypeEarnings;

  /// No description provided for @eventTypeEconomic.
  ///
  /// In en, this message translates to:
  /// **'Economic'**
  String get eventTypeEconomic;

  /// No description provided for @eventTypeOptionsExpiry.
  ///
  /// In en, this message translates to:
  /// **'Options Expiry'**
  String get eventTypeOptionsExpiry;

  /// No description provided for @eventTypeConference.
  ///
  /// In en, this message translates to:
  /// **'Conference'**
  String get eventTypeConference;

  /// No description provided for @eventTypeDividend.
  ///
  /// In en, this message translates to:
  /// **'Dividend'**
  String get eventTypeDividend;

  /// No description provided for @eventTypeProductLaunch.
  ///
  /// In en, this message translates to:
  /// **'Product Launch'**
  String get eventTypeProductLaunch;

  /// No description provided for @eventTypeShareholder.
  ///
  /// In en, this message translates to:
  /// **'Shareholder Meeting'**
  String get eventTypeShareholder;

  /// No description provided for @eventTypeFedSpeech.
  ///
  /// In en, this message translates to:
  /// **'Fed Speech'**
  String get eventTypeFedSpeech;

  /// No description provided for @nEvents.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String nEvents(int count);

  /// No description provided for @noEventsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No events this month'**
  String get noEventsThisMonth;

  /// No description provided for @noEventsSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'No events on this day'**
  String get noEventsSelectedDay;

  /// No description provided for @calendarNewsAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'News · Announcements'**
  String get calendarNewsAnnouncements;

  /// No description provided for @calendarEconomicIndicators.
  ///
  /// In en, this message translates to:
  /// **'US Economic'**
  String get calendarEconomicIndicators;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a verification code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendVerificationCode;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get verificationTitle;

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}.'**
  String verificationSubtitle(String email);

  /// No description provided for @verificationExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires in: {time}'**
  String verificationExpiry(String time);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @verificationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code'**
  String get verificationCodeRequired;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend in ({seconds}s)'**
  String resendCodeCooldown(int seconds);

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code has been resent.'**
  String get verificationCodeResent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset. Please login with your new password.'**
  String get resetPasswordSuccess;

  /// No description provided for @errEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verification required.'**
  String get errEmailNotVerified;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get errRateLimited;

  /// No description provided for @myHoldings.
  ///
  /// In en, this message translates to:
  /// **'My Holdings'**
  String get myHoldings;

  /// No description provided for @nHoldings.
  ///
  /// In en, this message translates to:
  /// **'{count} holdings'**
  String nHoldings(int count);

  /// No description provided for @portfolioSummary.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Summary'**
  String get portfolioSummary;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @totalPnl.
  ///
  /// In en, this message translates to:
  /// **'Total P&L'**
  String get totalPnl;

  /// No description provided for @dayPnl.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayPnl;

  /// No description provided for @buyStock.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyStock;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @avgPrice.
  ///
  /// In en, this message translates to:
  /// **'Avg Price'**
  String get avgPrice;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @enterShares.
  ///
  /// In en, this message translates to:
  /// **'Number of shares'**
  String get enterShares;

  /// No description provided for @enterAvgPrice.
  ///
  /// In en, this message translates to:
  /// **'Average purchase price'**
  String get enterAvgPrice;

  /// No description provided for @buyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add to Holdings'**
  String get buyConfirm;

  /// No description provided for @holdingAdded.
  ///
  /// In en, this message translates to:
  /// **'{ticker} added to holdings'**
  String holdingAdded(String ticker);

  /// No description provided for @holdingRemoved.
  ///
  /// In en, this message translates to:
  /// **'{ticker} removed from holdings'**
  String holdingRemoved(String ticker);

  /// No description provided for @removeHoldingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {ticker} from holdings?'**
  String removeHoldingConfirm(String ticker);

  /// No description provided for @aiAdvice.
  ///
  /// In en, this message translates to:
  /// **'AI Advice'**
  String get aiAdvice;

  /// No description provided for @aiAdviceInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant AI Advice'**
  String get aiAdviceInstant;

  /// No description provided for @bullishFactorsPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Bullish Factors'**
  String get bullishFactorsPortfolio;

  /// No description provided for @bearishFactorsPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Bearish Factors'**
  String get bearishFactorsPortfolio;

  /// No description provided for @detailedAnalysisComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Detailed analysis will be updated in the morning'**
  String get detailedAnalysisComingSoon;

  /// No description provided for @loginForPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Log in to manage your portfolio'**
  String get loginForPortfolio;

  /// No description provided for @loginForPortfolioHint.
  ///
  /// In en, this message translates to:
  /// **'Track holdings, get AI advice, and monitor P&L'**
  String get loginForPortfolioHint;

  /// No description provided for @sharesAtPrice.
  ///
  /// In en, this message translates to:
  /// **'{shares} shares @ \${price}'**
  String sharesAtPrice(String shares, String price);

  /// No description provided for @noHoldingsYet.
  ///
  /// In en, this message translates to:
  /// **'No holdings yet'**
  String get noHoldingsYet;

  /// No description provided for @addFirstHolding.
  ///
  /// In en, this message translates to:
  /// **'Buy stocks from your watchlist to get started'**
  String get addFirstHolding;

  /// No description provided for @invalidShares.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number of shares'**
  String get invalidShares;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get invalidPrice;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @tabHoldings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get tabHoldings;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// No description provided for @sellDate.
  ///
  /// In en, this message translates to:
  /// **'Sell Date'**
  String get sellDate;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPrice;

  /// No description provided for @sellShares.
  ///
  /// In en, this message translates to:
  /// **'Sell Quantity'**
  String get sellShares;

  /// No description provided for @sellConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sell'**
  String get sellConfirm;

  /// No description provided for @sellAll.
  ///
  /// In en, this message translates to:
  /// **'Sell All'**
  String get sellAll;

  /// No description provided for @sellAmount.
  ///
  /// In en, this message translates to:
  /// **'Sell Amount'**
  String get sellAmount;

  /// No description provided for @realizedPnlLabel.
  ///
  /// In en, this message translates to:
  /// **'Realized P&L'**
  String get realizedPnlLabel;

  /// No description provided for @unrealizedPnl.
  ///
  /// In en, this message translates to:
  /// **'Unrealized P&L'**
  String get unrealizedPnl;

  /// No description provided for @realizedPnl.
  ///
  /// In en, this message translates to:
  /// **'Realized'**
  String get realizedPnl;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @additionalBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy More'**
  String get additionalBuy;

  /// No description provided for @partialSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get partialSell;

  /// No description provided for @editHolding.
  ///
  /// In en, this message translates to:
  /// **'Edit Info'**
  String get editHolding;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @holdingUpdated.
  ///
  /// In en, this message translates to:
  /// **'{ticker} holding updated'**
  String holdingUpdated(String ticker);

  /// No description provided for @portfolioAIAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Portfolio AI Analysis'**
  String get portfolioAIAnalysis;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get aiRecommendations;

  /// No description provided for @recPortfolioOverview.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Overview'**
  String get recPortfolioOverview;

  /// No description provided for @recTechnicalInsight.
  ///
  /// In en, this message translates to:
  /// **'Technical Analysis'**
  String get recTechnicalInsight;

  /// No description provided for @recMarketIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Market Intelligence'**
  String get recMarketIntelligence;

  /// No description provided for @recActionSummary.
  ///
  /// In en, this message translates to:
  /// **'Action Summary'**
  String get recActionSummary;

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended Action'**
  String get recommendedAction;

  /// No description provided for @analysisWaiting.
  ///
  /// In en, this message translates to:
  /// **'AI analysis pending...'**
  String get analysisWaiting;

  /// No description provided for @alreadyHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get alreadyHeld;

  /// No description provided for @goToWatchlistTab.
  ///
  /// In en, this message translates to:
  /// **'Go to Watchlist'**
  String get goToWatchlistTab;

  /// No description provided for @noHoldingsHint.
  ///
  /// In en, this message translates to:
  /// **'Add holdings from the Watchlist tab'**
  String get noHoldingsHint;

  /// No description provided for @closingPriceAuto.
  ///
  /// In en, this message translates to:
  /// **'Closing price auto-filled'**
  String get closingPriceAuto;

  /// No description provided for @holidayPriceNotice.
  ///
  /// In en, this message translates to:
  /// **'Closing price from {date} (prior trading day)'**
  String holidayPriceNotice(String date);

  /// No description provided for @addToHoldings.
  ///
  /// In en, this message translates to:
  /// **'Add to Holdings'**
  String get addToHoldings;

  /// No description provided for @currentHoldings.
  ///
  /// In en, this message translates to:
  /// **'Current Holdings'**
  String get currentHoldings;

  /// No description provided for @holdingStatus.
  ///
  /// In en, this message translates to:
  /// **'Holding Status'**
  String get holdingStatus;

  /// No description provided for @addHoldingTitle.
  ///
  /// In en, this message translates to:
  /// **'{ticker} Add Holding'**
  String addHoldingTitle(String ticker);

  /// No description provided for @sellHoldingTitle.
  ///
  /// In en, this message translates to:
  /// **'{ticker} Sell'**
  String sellHoldingTitle(String ticker);

  /// No description provided for @editHoldingTitle.
  ///
  /// In en, this message translates to:
  /// **'{ticker} Edit Holding'**
  String editHoldingTitle(String ticker);

  /// No description provided for @holdingSold.
  ///
  /// In en, this message translates to:
  /// **'{ticker} sold successfully'**
  String holdingSold(String ticker);

  /// No description provided for @deleteHolding.
  ///
  /// In en, this message translates to:
  /// **'Delete Holding'**
  String get deleteHolding;

  /// No description provided for @avgPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Price'**
  String get avgPriceLabel;

  /// No description provided for @currentValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get currentValueLabel;

  /// No description provided for @dailyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated daily in the morning'**
  String get dailyUpdate;

  /// No description provided for @viewAIAdvice.
  ///
  /// In en, this message translates to:
  /// **'View AI Advice'**
  String get viewAIAdvice;

  /// No description provided for @noAnalysisYet.
  ///
  /// In en, this message translates to:
  /// **'No analysis available yet'**
  String get noAnalysisYet;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @viewAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'View all ({count})'**
  String viewAllTransactions(int count);

  /// No description provided for @newsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get newsFilter;

  /// No description provided for @filterSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get filterSource;

  /// No description provided for @filterMyWatchlist.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get filterMyWatchlist;

  /// No description provided for @filterNoWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add watchlist items first'**
  String get filterNoWatchlist;

  /// No description provided for @filterMarketOnly.
  ///
  /// In en, this message translates to:
  /// **'Market News'**
  String get filterMarketOnly;

  /// No description provided for @filterSentiment.
  ///
  /// In en, this message translates to:
  /// **'Sentiment'**
  String get filterSentiment;

  /// No description provided for @filterSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get filterSector;

  /// No description provided for @filterBreakingOnly.
  ///
  /// In en, this message translates to:
  /// **'Breaking only'**
  String get filterBreakingOnly;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @hotTopicMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String hotTopicMore(int count);

  /// No description provided for @sectorTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get sectorTechnology;

  /// No description provided for @sectorHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get sectorHealthcare;

  /// No description provided for @sectorEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get sectorEnergy;

  /// No description provided for @sectorCyclical.
  ///
  /// In en, this message translates to:
  /// **'Cyclical'**
  String get sectorCyclical;

  /// No description provided for @sectorDefensive.
  ///
  /// In en, this message translates to:
  /// **'Defensive'**
  String get sectorDefensive;

  /// No description provided for @sectorComm.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get sectorComm;

  /// No description provided for @sectorFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get sectorFinance;

  /// No description provided for @sectorIndustrials.
  ///
  /// In en, this message translates to:
  /// **'Industrials'**
  String get sectorIndustrials;

  /// No description provided for @sectorUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get sectorUtilities;

  /// No description provided for @sectorRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get sectorRealEstate;

  /// No description provided for @sectorMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get sectorMaterials;

  /// No description provided for @newsBubbleTitle.
  ///
  /// In en, this message translates to:
  /// **'24h News Bubble'**
  String get newsBubbleTitle;

  /// No description provided for @newsBubbleLegendBullish.
  ///
  /// In en, this message translates to:
  /// **'Mostly Bullish'**
  String get newsBubbleLegendBullish;

  /// No description provided for @newsBubbleLegendBearish.
  ///
  /// In en, this message translates to:
  /// **'Mostly Bearish'**
  String get newsBubbleLegendBearish;

  /// No description provided for @newsBubbleLegendMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get newsBubbleLegendMixed;

  /// No description provided for @newsBubbleMentions.
  ///
  /// In en, this message translates to:
  /// **'{count} mentions'**
  String newsBubbleMentions(int count);

  /// No description provided for @taxEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Estimate'**
  String get taxEstimateTitle;

  /// No description provided for @totalGains.
  ///
  /// In en, this message translates to:
  /// **'Total Gains'**
  String get totalGains;

  /// No description provided for @annualExemption.
  ///
  /// In en, this message translates to:
  /// **'Annual Exemption'**
  String get annualExemption;

  /// No description provided for @estimatedTax.
  ///
  /// In en, this message translates to:
  /// **'Estimated Tax (22%)'**
  String get estimatedTax;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @krwSuffix.
  ///
  /// In en, this message translates to:
  /// **' KRW'**
  String get krwSuffix;

  /// No description provided for @taxTradeCount.
  ///
  /// In en, this message translates to:
  /// **' sells'**
  String get taxTradeCount;

  /// No description provided for @macro3mTitle.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get macro3mTitle;

  /// No description provided for @macro3mHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get macro3mHigh;

  /// No description provided for @macro3mAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get macro3mAvg;

  /// No description provided for @macro3mLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get macro3mLow;

  /// No description provided for @tooltipClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get tooltipClearSearch;

  /// No description provided for @tooltipPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get tooltipPreviousMonth;

  /// No description provided for @tooltipNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get tooltipNextMonth;

  /// No description provided for @tooltipShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get tooltipShowPassword;

  /// No description provided for @tooltipHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get tooltipHidePassword;

  /// No description provided for @tooltipChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get tooltipChangePhoto;

  /// No description provided for @tooltipFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get tooltipFilter;

  /// No description provided for @tooltipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get tooltipRemove;

  /// No description provided for @otherSectors.
  ///
  /// In en, this message translates to:
  /// **'Other Sectors'**
  String get otherSectors;

  /// No description provided for @otherTickers.
  ///
  /// In en, this message translates to:
  /// **'Other Tickers'**
  String get otherTickers;

  /// No description provided for @nDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}D ago'**
  String nDaysAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
