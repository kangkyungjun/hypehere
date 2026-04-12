// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MarketLens';

  @override
  String get tabDashboard => 'ダッシュボード';

  @override
  String get tabDashboardTooltip => 'マーケットダッシュボード';

  @override
  String get tabSearch => '検索';

  @override
  String get tabSearchTooltip => '銘柄検索';

  @override
  String get tabNews => 'ニュース';

  @override
  String get tabNewsTooltip => 'マーケットニュース';

  @override
  String get tabCommunity => 'コミュニティ';

  @override
  String get tabCommunityTooltip => '掲示板';

  @override
  String get tabMarket => 'マーケット';

  @override
  String get tabMarketTooltip => 'マーケット概要';

  @override
  String get tabAILens => 'AI';

  @override
  String get tabAILensTooltip => 'AI分析';

  @override
  String get tabWatchlist => 'ウォッチリスト';

  @override
  String get tabWatchlistTooltip => 'マイウォッチリスト';

  @override
  String get tabHoldingsTooltip => '保有銘柄';

  @override
  String get settings => '設定';

  @override
  String get settingsTooltip => '設定';

  @override
  String get compareTickers => '銘柄比較';

  @override
  String get account => 'アカウント';

  @override
  String get login => 'ログイン';

  @override
  String get loginSubtitle => 'コミュニティ機能を利用する';

  @override
  String get signup => '新規登録';

  @override
  String get signupTitle => '新規登録';

  @override
  String get signupSubtitle => '新しいアカウントを作成';

  @override
  String get noAccountSignup => 'アカウントをお持ちでない方は新規登録';

  @override
  String get hasAccountLogin => 'すでにアカウントをお持ちの方はログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirmTitle => 'ログアウト';

  @override
  String get logoutConfirmMessage => 'ログアウトしてもよろしいですか？';

  @override
  String get welcome => 'ようこそ！';

  @override
  String get accountCreated => 'アカウントが作成されました！';

  @override
  String get email => 'メールアドレス';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => 'メールアドレスを入力してください';

  @override
  String get emailInvalid => 'メールアドレスの形式が正しくありません';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get nicknameHint => 'コミュニティで使用するニックネーム';

  @override
  String get nicknameRequired => 'ニックネームを入力してください';

  @override
  String get nicknameTooShort => 'ニックネームは2文字以上で入力してください';

  @override
  String get password => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力してください';

  @override
  String get passwordRequired => 'パスワードを入力してください';

  @override
  String get passwordTooShort => 'パスワードは8文字以上で入力してください';

  @override
  String get passwordConfirm => 'パスワード確認';

  @override
  String get passwordConfirmHint => 'パスワードを再入力してください';

  @override
  String get passwordConfirmRequired => 'パスワードの確認を入力してください';

  @override
  String get passwordMismatch => 'パスワードが一致しません';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get changePasswordGuide => 'パスワード変更ガイド';

  @override
  String get oldPassword => '現在のパスワード';

  @override
  String get oldPasswordHint => '現在使用中のパスワードを入力してください';

  @override
  String get oldPasswordRequired => '現在のパスワードを入力してください';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get newPasswordHint => '新しいパスワードを入力してください（8文字以上）';

  @override
  String get newPasswordRequired => '新しいパスワードを入力してください';

  @override
  String get newPasswordConfirm => '新しいパスワード確認';

  @override
  String get newPasswordConfirmHint => '新しいパスワードを再入力してください';

  @override
  String get newPasswordConfirmRequired => '新しいパスワードの確認を入力してください';

  @override
  String get newPasswordMustDiffer => '新しいパスワードは現在のパスワードと異なる必要があります';

  @override
  String get passwordChanged => 'パスワードが正常に変更されました';

  @override
  String passwordChangeFailed(String error) {
    return 'パスワード変更失敗：$error';
  }

  @override
  String get loginRequired => 'ログインが必要です';

  @override
  String get loginPromptMessage => 'ログインしてコミュニティに参加しましょう！';

  @override
  String get searchHint => 'ティッカーまたは企業名で検索（例：AAPL、Apple）';

  @override
  String get searchFailed => '検索失敗';

  @override
  String get noSearchResults => '検索結果なし';

  @override
  String get tryDifferentSearch => '他のティッカーを検索してみてください';

  @override
  String get tickerSearch => 'ティッカー検索';

  @override
  String get enterTickerAbove => '検索キーワードを入力してください';

  @override
  String get recentSearches => '最近の検索';

  @override
  String get clearAll => 'すべて削除';

  @override
  String get retry => '再試行';

  @override
  String get tryAgain => 'もう一度';

  @override
  String get sectorMarketOverview => 'セクター別市場概況';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterNasdaq => 'NASDAQ';

  @override
  String get filterDow => 'ダウ';

  @override
  String get marketLensAIScore => 'AIスコア';

  @override
  String get distributionShownOnFullLoad => '全シグナル読込時にスコア分布を表示';

  @override
  String topN(int n) {
    return '▲ 上位 $n';
  }

  @override
  String bottomN(int n) {
    return '▼ 下位 $n';
  }

  @override
  String get noData => 'データなし';

  @override
  String get signalLoadFailed => 'シグナルの読み込みに失敗しました';

  @override
  String dashboardLoadFailed(String error) {
    return 'ダッシュボードの読み込みに失敗しました：$error';
  }

  @override
  String get allSignals => '全シグナル';

  @override
  String get sp500Signals => 'S&P 500 シグナル';

  @override
  String get dow30Signals => 'ダウ30 シグナル';

  @override
  String get nasdaq100Signals => 'NASDAQ 100 シグナル';

  @override
  String get marketTrend => '市場全体のトレンド';

  @override
  String get loadingSignals => '全シグナルを読み込み中...';

  @override
  String get loadingSP500Signals => 'S&P 500 シグナルを読み込み中...';

  @override
  String get loadingDow30Signals => 'ダウ30 シグナルを読み込み中...';

  @override
  String get loadingNasdaq100Signals => 'NASDAQ 100 シグナルを読み込み中...';

  @override
  String get noAdditionalSignals => '追加シグナルなし';

  @override
  String showMore(int remaining) {
    return 'もっと見る（残り $remaining 件）';
  }

  @override
  String nItems(int count) {
    return '$count 件';
  }

  @override
  String get scoreStrongBuy => '強い買い';

  @override
  String get scoreBuy => '買い推奨';

  @override
  String get scoreHold => '様子見';

  @override
  String get scoreSell => '売り推奨';

  @override
  String get scoreStrongSell => '強い売り';

  @override
  String get score => 'スコア';

  @override
  String get myWatchlist => 'マイウォッチリスト';

  @override
  String nTickers(int count) {
    return '$count 銘柄';
  }

  @override
  String get watchlistEmpty => 'ウォッチリストが空です';

  @override
  String get watchlistEmptyHint => '検索タブから銘柄を検索して追加してください';

  @override
  String get explore => '探索';

  @override
  String get tapToViewDetails => 'タップして詳細を表示';

  @override
  String tickerRemovedFromWatchlist(String ticker) {
    return '$ticker をウォッチリストから削除しました';
  }

  @override
  String get undo => '元に戻す';

  @override
  String get tickerDataLoadFailed => '銘柄データを読み込めませんでした';

  @override
  String get addToWatchlist => 'ウォッチリストに追加';

  @override
  String get removeFromWatchlist => 'ウォッチリストから削除';

  @override
  String get addedToWatchlist => 'ウォッチリストに追加しました';

  @override
  String get removedFromWatchlist => 'ウォッチリストから削除しました';

  @override
  String get watchlistDiscoveryTitle => 'ウォッチリストに追加しよう';

  @override
  String get watchlistDiscoverySubtitle => '登録するとニュース・シグナル通知を受け取れます';

  @override
  String get topTradingVolume => '本日の出来高トップ';

  @override
  String get communitySearchHint => 'タイトルや内容で検索...';

  @override
  String get writePost => '投稿する';

  @override
  String get deletePost => '投稿を削除';

  @override
  String get deleteConfirm => 'この投稿を削除してもよろしいですか？\n削除した投稿は復元できません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get done => '完了';

  @override
  String get confirm => '確認';

  @override
  String get postDeleted => '投稿が削除されました';

  @override
  String get report => '通報';

  @override
  String get reportTitle => '通報する';

  @override
  String get reportAbuse => '暴言・誹謗中傷';

  @override
  String get reportSpam => 'スパム・広告';

  @override
  String get reportInappropriate => '不適切なコンテンツ';

  @override
  String get reportHarassment => 'ハラスメント';

  @override
  String get reportOther => 'その他';

  @override
  String get reportDescription => '詳細説明';

  @override
  String get reportSubmitted => '通報が受理されました';

  @override
  String get reportSubmit => '通報';

  @override
  String postDeleteFailed(String error) {
    return '投稿の削除に失敗しました：$error';
  }

  @override
  String get noPostsYet => '投稿がまだありません';

  @override
  String get writeFirstPost => '最初の投稿を書いてみましょう！';

  @override
  String get noSearchResultsCommunity => '検索結果がありません';

  @override
  String get tryDifferentFilter => '他の検索キーワードやフィルターを試してください';

  @override
  String get networkError => '接続に失敗しました。しばらくしてから再試行してください。';

  @override
  String get serverTimeout => 'サーバーがタイムアウトしました。しばらくしてから再試行してください。';

  @override
  String get postsLoadFailed => '投稿を読み込めませんでした。しばらくしてから再試行してください。';

  @override
  String get searchResultsLoadFailed => '検索結果を読み込めませんでした';

  @override
  String get refresh => '更新';

  @override
  String get all => '全体';

  @override
  String get add => '追加';

  @override
  String tickerBoard(String ticker) {
    return '$ticker 掲示板';
  }

  @override
  String get tickerSearchHint => 'ティッカー検索...（例：AAPL、TSLA）';

  @override
  String get popularTickers => '人気ティッカー';

  @override
  String get freePost => '自由';

  @override
  String get checkNetwork => 'ネットワーク接続を確認してください';

  @override
  String get tryAgainLater => 'しばらくしてから再試行してください';

  @override
  String get newPost => '新規投稿';

  @override
  String get editPostTitle => '投稿を編集';

  @override
  String get tickerOnlyBoard => '銘柄別掲示板';

  @override
  String get selectTicker => '銘柄';

  @override
  String get tickerSearchLabel => '銘柄検索';

  @override
  String get tickerSearchHintCreate => '名前、シンボル、または日本語名で検索';

  @override
  String get tickerNotSelectedHint => '銘柄を選択しない場合、自由投稿として登録されます';

  @override
  String get noTickerSearchResults => '検索結果がありません';

  @override
  String get postTitle => 'タイトル';

  @override
  String get postTitleHint => '投稿タイトルを入力してください';

  @override
  String get postTitleRequired => 'タイトルを入力してください';

  @override
  String get postTitleTooShort => 'タイトルは2文字以上で入力してください';

  @override
  String get postContent => '内容';

  @override
  String get postContentHint => '投稿内容を入力してください';

  @override
  String get postContentRequired => '内容を入力してください';

  @override
  String get postContentTooShort => '内容は5文字以上で入力してください';

  @override
  String get postCreated => '投稿が作成されました';

  @override
  String get postUpdated => '投稿が更新されました';

  @override
  String get submitPost => '投稿する';

  @override
  String get updatePostButton => '更新する';

  @override
  String get deleteComment => 'コメントを削除';

  @override
  String get deleteCommentConfirm => 'このコメントを削除してもよろしいですか？';

  @override
  String get editComment => 'コメントを編集';

  @override
  String get commentHint => 'コメントを入力...';

  @override
  String get commentPlaceholder => 'コメント内容を入力してください';

  @override
  String get commentCreated => 'コメントが投稿されました';

  @override
  String get commentUpdated => 'コメントが更新されました';

  @override
  String get commentDeleted => 'コメントが削除されました';

  @override
  String get commentRequired => 'コメント内容を入力してください';

  @override
  String get loginToViewComments => 'コメントを見るにはログインが必要です';

  @override
  String get writeFirstComment => '最初のコメントを書いてみましょう！';

  @override
  String get postDetail => '投稿';

  @override
  String get startWithFirstPost => '最初の投稿から始めましょう';

  @override
  String get writeAPost => '投稿を書く';

  @override
  String get cannotLoadPosts => '投稿を読み込めません';

  @override
  String get noPostsInTicker => 'この掲示板にはまだ投稿がありません';

  @override
  String get writeFirstPostInTicker => '最初の投稿を書いてみましょう！';

  @override
  String get dataManagement => 'データ管理';

  @override
  String get clearRecentSearches => '検索履歴を削除';

  @override
  String nSearchRecords(int count) {
    return '$count 件の検索履歴';
  }

  @override
  String get clearRecentSearchesConfirm => 'すべての検索履歴を削除しますか？';

  @override
  String get recentSearchesCleared => '検索履歴が削除されました';

  @override
  String get clearWatchlist => 'ウォッチリストを削除';

  @override
  String get clearWatchlistConfirm => 'すべてのウォッチリスト銘柄を削除しますか？';

  @override
  String get watchlistCleared => 'ウォッチリストが削除されました';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get deleteAllDataConfirm =>
      'ウォッチリストと検索履歴を含むすべてのローカルデータが削除されます。この操作は元に戻せません。';

  @override
  String get deleteAllButton => 'すべて削除';

  @override
  String get allDataDeleted => 'すべてのデータが削除されました';

  @override
  String get removeAllLocalData => 'すべてのローカルデータを削除';

  @override
  String get info => '情報';

  @override
  String get aboutMarketLens => 'アプリについて';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get appDescription => 'データに基づく投資判断のためのAI株式分析ツール';

  @override
  String get aiStockAnalysis => 'AI株式分析';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get admin => '管理';

  @override
  String get adminPanel => '管理パネル';

  @override
  String get adminPanelSubtitle => 'ユーザー管理と権限設定';

  @override
  String get showAds => '広告を表示';

  @override
  String get adsEnabledDescription => '全ユーザーにバナー広告を表示中';

  @override
  String get adsDisabledDescription => '広告は非表示です';

  @override
  String get sendPushNotification => 'プッシュ通知を送信';

  @override
  String get sendPushNotificationSubtitle => '全ユーザーに通知を送信';

  @override
  String get pushTitle => 'タイトル';

  @override
  String get pushBody => 'メッセージ';

  @override
  String get send => '送信';

  @override
  String pushSentResult(int count) {
    return '$count台のデバイスに送信完了';
  }

  @override
  String get pushSendFailed => 'プッシュ通知の送信に失敗しました';

  @override
  String get promoteToGold => 'Goldに昇格';

  @override
  String get promoteToManager => 'Managerに昇格';

  @override
  String get demoteToRegular => '一般ユーザーに降格';

  @override
  String get profile => 'プロフィール';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get myPosts => '自分の投稿';

  @override
  String get myComments => '自分のコメント';

  @override
  String get viewAll => 'すべて表示';

  @override
  String get noPosts => '投稿なし';

  @override
  String get noComments => 'コメントなし';

  @override
  String joinDate(String date) {
    return '登録日：$date';
  }

  @override
  String get deleteAccount => 'アカウント退会';

  @override
  String get withdrawAccountConfirm =>
      '本当にアカウントを退会しますか？\n7日後にアカウントが完全に削除されます。その前にログインすれば退会がキャンセルされます。';

  @override
  String get withdrawAccountReasonHint => '退会理由をご記入ください（任意）';

  @override
  String get withdrawAccountSuccess => 'アカウント退会が申請されました。7日後に完全に削除されます。';

  @override
  String get withdrawAccountFailed => 'アカウント退会の申請に失敗しました。もう一度お試しください。';

  @override
  String get deactivateAccount => 'アカウント無効化';

  @override
  String get profileUpdated => 'プロフィールが更新されました';

  @override
  String get imagePickerFailed => '画像の選択に失敗しました';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムのデフォルト';

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
  String get languageSettings => '言語設定';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get languageChanged => '言語が変更されました';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int n) {
    return '$n分前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n時間前';
  }

  @override
  String get timeYesterday => '昨日';

  @override
  String timeDaysAgo(int n) {
    return '$n日前';
  }

  @override
  String get companyOverview => '企業概要';

  @override
  String get companyDetails => '企業詳細';

  @override
  String get companyIntro => '企業紹介';

  @override
  String employeeCount(String count) {
    return '従業員 $count 名';
  }

  @override
  String get valuation => 'バリュエーション';

  @override
  String get forwardPE => '予想PER';

  @override
  String get beta => 'ベータ';

  @override
  String get profitabilityGrowth => '収益性と成長';

  @override
  String get netProfitMargin => '純利益率';

  @override
  String get revenueGrowth => '売上成長率';

  @override
  String get operatingMargin => '営業利益率';

  @override
  String get earningsGrowth => '利益成長率';

  @override
  String get financialHealth => '財務健全性';

  @override
  String get debtRatio => '負債比率';

  @override
  String get liquidityRatio => '流動比率';

  @override
  String get dividends => '配当';

  @override
  String get dividendYield => '配当利回り ';

  @override
  String get annualDividend => '年間 ';

  @override
  String get shortInterest => '空売り';

  @override
  String get shortInterestRatio => '空売り比率';

  @override
  String get shortPercentFloat => '浮動株空売り比率';

  @override
  String shortDays(String days) {
    return '$days日';
  }

  @override
  String get shortInterestLow => '空売り低水準（安定）';

  @override
  String get shortInterestModerate => '空売り中水準（注意）';

  @override
  String get shortInterestHigh => '空売り高水準（警告）';

  @override
  String get institutionalInsiderFlow => '機関投資家 / インサイダー動向';

  @override
  String get institutional => '機関';

  @override
  String get insider => 'インサイダー';

  @override
  String get oneDay => '1日';

  @override
  String get fiveDay => '5日';

  @override
  String tickerNews(String ticker) {
    return '$ticker ニュース';
  }

  @override
  String newsCount(int count) {
    return '$count件';
  }

  @override
  String get oneWeek => '1週';

  @override
  String get oneMonth => '1ヶ月';

  @override
  String get noNews => 'ニュースなし';

  @override
  String get marketNews => 'マーケットニュース';

  @override
  String get viewOriginalArticle => '原文記事を見る';

  @override
  String get sentimentBullish => '強気';

  @override
  String get sentimentNeutral => '中立';

  @override
  String get sentimentBearish => '弱気';

  @override
  String get aiSummaryNews => 'AI要約ニュース';

  @override
  String get aiSummary => 'AI要約';

  @override
  String get noNewsAvailable => 'ニュースはありません';

  @override
  String get earningsHistory => '過去の業績';

  @override
  String get earningsHistoryEPS => '業績履歴（EPS）';

  @override
  String get earningsEstimate => '予想';

  @override
  String get earningsBeat => '上回り';

  @override
  String get earningsMiss => '下回り';

  @override
  String get earningsActual => '実績';

  @override
  String get earningsScheduled => '予定';

  @override
  String get epsEstimateLabel => 'EPS予想';

  @override
  String get revenueEstimateLabel => '売上高予想';

  @override
  String get averageLabel => '平均';

  @override
  String get surpriseLabel => 'サプライズ';

  @override
  String get thisWeekEarnings => '今週の決算発表';

  @override
  String get previousEarnings => '過去の決算';

  @override
  String earningsCount(int count) {
    return '$count件';
  }

  @override
  String get noEarningsThisWeek => '今週予定されている決算発表はありません';

  @override
  String get nextEarningsDate => '次回決算発表日';

  @override
  String get earningsConfirmed => '確定';

  @override
  String get keyEvents => '主要イベント';

  @override
  String get eventDetails => 'イベント詳細';

  @override
  String get upcomingEvents => '今後のイベント';

  @override
  String get exDividendDate => '配当権利落ち日';

  @override
  String get dividendPayDate => '配当支払日';

  @override
  String recentEarningsQuarters(int count) {
    return '直近決算（$count四半期）';
  }

  @override
  String get earningsHistoryChart => '業績履歴（チャート）';

  @override
  String get weekdayMon => '月';

  @override
  String get weekdayTue => '火';

  @override
  String get weekdayWed => '水';

  @override
  String get weekdayThu => '木';

  @override
  String get weekdayFri => '金';

  @override
  String get weekdaySat => '土';

  @override
  String get weekdaySun => '日';

  @override
  String get macroFedFunds => '政策金利';

  @override
  String get macroDGS10 => '長期金利';

  @override
  String get macroDGS2 => '短期金利';

  @override
  String get macroT10Y2Y => '利回り格差';

  @override
  String get macroVIXCLS => 'VIX';

  @override
  String get macroCPIAUCSL => 'CPI';

  @override
  String get macroUNRATE => '失業率';

  @override
  String get macroFedFundsDesc => '米連邦準備制度政策金利';

  @override
  String get macroDGS10Desc => '米国10年国債利回り';

  @override
  String get macroDGS2Desc => '米国2年国債利回り';

  @override
  String get macroT10Y2YDesc => '長短金利差（10Y-2Y）';

  @override
  String get macroVIXCLSDesc => '市場変動率指数';

  @override
  String get macroCPIAUCSLDesc => '消費者物価指数（CPI）';

  @override
  String get macroUNRATEDesc => '米国失業率';

  @override
  String get riskBearish => '弱気';

  @override
  String get riskCautious => '注意';

  @override
  String get riskNeutral => '中立';

  @override
  String get riskPositive => '良好';

  @override
  String get riskBullish => '強気';

  @override
  String get macroCategoryRates => '金利';

  @override
  String get macroCategorySentiment => 'センチメント';

  @override
  String get macroCategoryEconomy => '経済';

  @override
  String get macroYieldCurve => 'イールドカーブ';

  @override
  String get macroLiquidity => '流動性';

  @override
  String get macroOverall => 'マクロ全体';

  @override
  String macroCurrentValue(String value) {
    return '現在値：$value';
  }

  @override
  String macroChange(String value) {
    return '変動：$value';
  }

  @override
  String epsEstimateValue(String value) {
    return '予想 \$$value';
  }

  @override
  String get bbInterpretation => 'ボリンジャーバンド解釈';

  @override
  String get bbBandWidth => '・バンド幅：ボラティリティを表示（広いほど変動が大きい）';

  @override
  String get bbUpperApproach => '・上限バンド接近：買われ過ぎの可能性';

  @override
  String get bbLowerApproach => '・下限バンド接近：売られ過ぎの可能性';

  @override
  String get bbMiddleLine => '・中間線：20日移動平均線';

  @override
  String get cannotLoadData => 'データを読み込めません';

  @override
  String get marketlensAI => 'MarketLens AI';

  @override
  String get marketlensAIOpinion => 'MarketLens AI の見解';

  @override
  String get bullishFactors => '強気要因';

  @override
  String get bearishFactors => '弱気要因';

  @override
  String get target => '目標 ';

  @override
  String get stopLoss => '損切 ';

  @override
  String get averageTargetPrice => '平均目標株価';

  @override
  String get currentPrice => '現在値';

  @override
  String get targetPrice => '目標株価';

  @override
  String get recentAnalystRatings => '最新アナリスト評価';

  @override
  String get unknownFirm => '不明';

  @override
  String get volume => '出来高';

  @override
  String get legend => '凡例';

  @override
  String get ratingBuy => '買い';

  @override
  String get ratingStrongBuy => '強い買い';

  @override
  String get ratingOutperform => 'アウトパフォーム';

  @override
  String get ratingHold => '保有';

  @override
  String get ratingNeutral => '中立';

  @override
  String get ratingMarketPerform => 'マーケットパフォーム';

  @override
  String get ratingSell => '売り';

  @override
  String get ratingStrongSell => '強い売り';

  @override
  String get ratingUnderperform => 'アンダーパフォーム';

  @override
  String get ratingActionUpgrade => '格上げ';

  @override
  String get ratingActionDowngrade => '格下げ';

  @override
  String get ratingActionReiterated => '据え置き';

  @override
  String get ratingActionInitiated => '新規';

  @override
  String get roleMaster => 'Master';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleGold => 'Gold';

  @override
  String get roleRegular => '一般';

  @override
  String get roleGuest => 'ゲスト';

  @override
  String get errInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get errLoginRequired => 'ログインが必要です';

  @override
  String get errSessionExpired => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get errCannotLoadUser => 'ユーザー情報を読み込めません';

  @override
  String get errServerConnection => 'サーバーに接続できません。ネットワークを確認してください。';

  @override
  String get errServerConnectionShort => 'サーバーに接続できません';

  @override
  String get errNetworkFailed => 'ネットワーク接続に失敗しました。インターネット接続を確認してください。';

  @override
  String get errResponseFormat => 'サーバーの応答形式が正しくありません';

  @override
  String errTimeout(int seconds) {
    return 'サーバー応答タイムアウト（$seconds秒）';
  }

  @override
  String get errBadRequest => '入力内容を確認してください';

  @override
  String get errForbidden => 'アクセス権限がありません';

  @override
  String get errNotFound => 'ページが見つかりません';

  @override
  String get errServerError => 'サーバーエラーが発生しました。しばらくしてから再試行してください。';

  @override
  String get errNoEditPermission => '編集権限がありません';

  @override
  String get errNoDeletePermission => '削除権限がありません';

  @override
  String get errPostDeleteFailed => '投稿の削除に失敗しました';

  @override
  String get errCommentDeleteFailed => 'コメントの削除に失敗しました';

  @override
  String get errReportAlreadySubmitted => '既に通報済みです';

  @override
  String get errCannotReportOwn => '自分の投稿は通報できません';

  @override
  String get errReportFailed => '通報の送信に失敗しました';

  @override
  String get errManagerRequired => '権限が不足しています。Manager以上のみアクセスできます。';

  @override
  String get errMasterRequired => '権限が不足しています。Masterのみアクセスできます。';

  @override
  String get errSearchRequired => '検索キーワードを入力してください';

  @override
  String get errDemotionFailed => '降格に失敗しました';

  @override
  String get errMaxCompare => '最大3銘柄まで比較できます';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get dayBeforeYesterday => '一昨日';

  @override
  String expertCount(String count) {
    return 'アナリスト目標株価（$count社）';
  }

  @override
  String scorePoints(String score) {
    return '$score点';
  }

  @override
  String averageVolume(String volume) {
    return '平均：$volume';
  }

  @override
  String get showBullBearFactors => '強気/弱気要因を表示';

  @override
  String get hideBullBearFactors => '強気/弱気要因を閉じる';

  @override
  String analystConsensus(String count) {
    return '証券会社目標株価（$count 社）';
  }

  @override
  String lowestPrice(String price) {
    return '最安値 \$$price';
  }

  @override
  String highestPrice(String price) {
    return '最高値 \$$price';
  }

  @override
  String get liveTalk => 'リアルタイムトーク';

  @override
  String commentsCount(int count) {
    return 'コメント $count 件';
  }

  @override
  String get browsePosts => '投稿を閲覧';

  @override
  String get loginPromptComments => '他の投資家の意見を確認して\nあなたの分析を共有しましょう！';

  @override
  String get shareThoughtsPrompt => '注目銘柄について意見を共有し\n他の投資家と交流しましょう';

  @override
  String get writeFirstCommentPrompt => '投稿に最初のコメントを書いてみましょう';

  @override
  String get startConversationPrompt => '他の投資家の投稿にコメントして\n会話を始めましょう';

  @override
  String get ratingOverweight => 'オーバーウェイト';

  @override
  String get ratingUnderweight => 'アンダーウェイト';

  @override
  String get ratingSectorOutperform => 'セクターアウトパフォーム';

  @override
  String get ratingSectorPerform => 'セクターパフォーム';

  @override
  String get ratingSectorUnderperform => 'セクターアンダーパフォーム';

  @override
  String get ratingPositive => 'ポジティブ';

  @override
  String get ratingNegative => 'ネガティブ';

  @override
  String get ratingEqualWeight => 'イコールウェイト';

  @override
  String get keyMetricsComparison => '主要指標比較';

  @override
  String get metric => '指標';

  @override
  String get serverCalculatedNote => '※ すべての指標はサーバーで計算された値です';

  @override
  String get priceTrendComparison => '株価推移比較';

  @override
  String get rsiComparison => 'RSI比較（サーバー計算値）';

  @override
  String get rsiInterpretation => '※ RSI > 70：買われ過ぎ / RSI < 30：売られ過ぎ';

  @override
  String get passwordChangeInstructions =>
      '・新しいパスワードは8文字以上必要です\n・英字、数字、記号を組み合わせてください\n・変更後は新しいパスワードで再ログインしてください';

  @override
  String get notifications => '通知';

  @override
  String get markAllAsRead => 'すべて既読';

  @override
  String get noNotifications => '通知はありません';

  @override
  String get notificationsRetentionHint => '過去7日間の通知が表示されます。';

  @override
  String get bioLabel => '自己紹介';

  @override
  String get bioHint => '自己紹介を入力してください';

  @override
  String get profileEditGuide => 'プロフィール編集ガイド';

  @override
  String get updatedDate => '更新日：';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get tabCalendarTooltip => 'イベントカレンダー';

  @override
  String get eventTypeFomc => 'FOMC';

  @override
  String get eventTypeEarnings => '決算';

  @override
  String get eventTypeEconomic => '経済指標';

  @override
  String get eventTypeOptionsExpiry => 'オプション満期';

  @override
  String get eventTypeConference => 'カンファレンス';

  @override
  String get eventTypeDividend => '配当';

  @override
  String get eventTypeProductLaunch => '製品発表';

  @override
  String get eventTypeShareholder => '株主総会';

  @override
  String get eventTypeFedSpeech => 'FRB講演';

  @override
  String nEvents(int count) {
    return '$count件のイベント';
  }

  @override
  String get noEventsThisMonth => '今月のイベントはありません';

  @override
  String get noEventsSelectedDay => 'この日のイベントはありません';

  @override
  String get calendarNewsAnnouncements => 'ニュース·発表';

  @override
  String get calendarEconomicIndicators => '米国経済指標';

  @override
  String get forgotPassword => 'パスワードを忘れた';

  @override
  String get forgotPasswordSubtitle => '登録したメールアドレスを入力してください。認証コードをお送りします。';

  @override
  String get sendVerificationCode => '認証コード送信';

  @override
  String get verificationTitle => 'メール認証';

  @override
  String verificationSubtitle(String email) {
    return '$emailに送信された6桁の認証コードを入力してください。';
  }

  @override
  String verificationExpiry(String time) {
    return '有効期限: $time';
  }

  @override
  String get verificationCode => '認証コード';

  @override
  String get verificationCodeRequired => '6桁の認証コードを入力してください';

  @override
  String get verifyButton => '認証する';

  @override
  String get resendCode => '認証コード再送信';

  @override
  String resendCodeCooldown(int seconds) {
    return '再送信可能 ($seconds秒)';
  }

  @override
  String get verificationCodeResent => '認証コードが再送信されました。';

  @override
  String get resetPassword => 'パスワード再設定';

  @override
  String get resetPasswordSubtitle => '新しいパスワードを入力してください。';

  @override
  String get resetPasswordSuccess => 'パスワードが再設定されました。新しいパスワードでログインしてください。';

  @override
  String get errEmailNotVerified => 'メール認証が必要です。';

  @override
  String get errRateLimited => 'しばらくしてから再度お試しください。';

  @override
  String get myHoldings => '保有銘柄';

  @override
  String nHoldings(int count) {
    return '$count銘柄保有';
  }

  @override
  String get portfolioSummary => 'ポートフォリオ概要';

  @override
  String get totalValue => '総資産';

  @override
  String get totalPnl => '損益合計';

  @override
  String get dayPnl => '本日';

  @override
  String get buyStock => '購入';

  @override
  String get shares => '株数';

  @override
  String get avgPrice => '平均単価';

  @override
  String get totalCost => '購入総額';

  @override
  String get enterShares => '株数を入力';

  @override
  String get enterAvgPrice => '平均取得単価を入力';

  @override
  String get buyConfirm => '保有に追加';

  @override
  String holdingAdded(String ticker) {
    return '$ticker を保有銘柄に追加しました';
  }

  @override
  String holdingRemoved(String ticker) {
    return '$ticker を保有銘柄から削除しました';
  }

  @override
  String removeHoldingConfirm(String ticker) {
    return '$ticker を保有銘柄から削除しますか？';
  }

  @override
  String get aiAdvice => 'AIアドバイス';

  @override
  String get aiAdviceInstant => '即時AIアドバイス';

  @override
  String get bullishFactorsPortfolio => '強気要因';

  @override
  String get bearishFactorsPortfolio => '弱気要因';

  @override
  String get detailedAnalysisComingSoon => '詳細分析は翌朝更新されます';

  @override
  String get loginForPortfolio => 'ログインしてポートフォリオを管理';

  @override
  String get loginForPortfolioHint => '保有銘柄の追跡、AIアドバイス、損益管理';

  @override
  String sharesAtPrice(String shares, String price) {
    return '$shares株 @ \$$price';
  }

  @override
  String get noHoldingsYet => '保有銘柄がありません';

  @override
  String get addFirstHolding => 'ウォッチリストから購入して始めましょう';

  @override
  String get invalidShares => '有効な株数を入力してください';

  @override
  String get invalidPrice => '有効な価格を入力してください';

  @override
  String get confidence => '信頼度';

  @override
  String get tabHoldings => '保有銘柄';

  @override
  String get purchaseDate => '購入日';

  @override
  String get sellDate => '売却日';

  @override
  String get sellPrice => '売却価格';

  @override
  String get sellShares => '売却数量';

  @override
  String get sellConfirm => '売却確認';

  @override
  String get sellAll => '全量売却';

  @override
  String get sellAmount => '売却金額';

  @override
  String get realizedPnlLabel => '実現損益';

  @override
  String get unrealizedPnl => '未実現損益';

  @override
  String get realizedPnl => '実現損益';

  @override
  String get transactionHistory => '取引履歴';

  @override
  String get additionalBuy => '追加購入';

  @override
  String get partialSell => '売却';

  @override
  String get editHolding => '情報修正';

  @override
  String get saveChanges => '変更を保存';

  @override
  String holdingUpdated(String ticker) {
    return '$ticker の保有情報が更新されました';
  }

  @override
  String get portfolioAIAnalysis => 'ポートフォリオAI分析';

  @override
  String get aiRecommendations => '推奨事項';

  @override
  String get recPortfolioOverview => 'ポートフォリオ概要';

  @override
  String get recTechnicalInsight => 'テクニカル分析';

  @override
  String get recMarketIntelligence => 'マーケット情報';

  @override
  String get recActionSummary => 'アクションサマリー';

  @override
  String get recommendedAction => '推奨アクション';

  @override
  String get analysisWaiting => 'AI分析待機中...';

  @override
  String get alreadyHeld => '保有中';

  @override
  String get goToWatchlistTab => 'ウォッチリストへ';

  @override
  String get noHoldingsHint => 'ウォッチリストから保有銘柄を追加してください';

  @override
  String get closingPriceAuto => '終値自動入力';

  @override
  String holidayPriceNotice(String date) {
    return '$date 終値基準（前営業日）';
  }

  @override
  String get addToHoldings => '保有に追加';

  @override
  String get currentHoldings => '保有状況';

  @override
  String get holdingStatus => '保有状況';

  @override
  String addHoldingTitle(String ticker) {
    return '$ticker 保有追加';
  }

  @override
  String sellHoldingTitle(String ticker) {
    return '$ticker 売却';
  }

  @override
  String editHoldingTitle(String ticker) {
    return '$ticker 保有情報修正';
  }

  @override
  String holdingSold(String ticker) {
    return '$ticker 売却完了';
  }

  @override
  String get deleteHolding => '保有削除';

  @override
  String get avgPriceLabel => '平均単価';

  @override
  String get currentValueLabel => '評価額';

  @override
  String get dailyUpdate => '毎朝更新';

  @override
  String get viewAIAdvice => 'AI意見を見る';

  @override
  String get noAnalysisYet => 'まだ分析がありません';

  @override
  String get recentTransactions => '最近の取引';

  @override
  String viewAllTransactions(int count) {
    return 'すべて表示 ($count件)';
  }

  @override
  String get newsFilter => 'フィルター';

  @override
  String get filterSource => 'ソース';

  @override
  String get filterMyWatchlist => 'ウォッチリスト';

  @override
  String get filterNoWatchlist => '先にウォッチリストを追加してください';

  @override
  String get filterMarketOnly => '市場ニュース';

  @override
  String get filterSentiment => 'センチメント';

  @override
  String get filterSector => 'セクター';

  @override
  String get filterBreakingOnly => '速報のみ';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterApply => '適用';

  @override
  String hotTopicMore(int count) {
    return '+$count もっと見る';
  }

  @override
  String get sectorTechnology => 'テクノロジー';

  @override
  String get sectorHealthcare => 'ヘルスケア';

  @override
  String get sectorEnergy => 'エネルギー';

  @override
  String get sectorCyclical => '景気循環消費財';

  @override
  String get sectorDefensive => '生活必需品';

  @override
  String get sectorComm => '通信サービス';

  @override
  String get sectorFinance => '金融';

  @override
  String get sectorIndustrials => '資本財';

  @override
  String get sectorUtilities => '公益事業';

  @override
  String get sectorRealEstate => '不動産';

  @override
  String get sectorMaterials => '素材';

  @override
  String get newsBubbleTitle => '24時間ニュースバブル';

  @override
  String get newsBubbleLegendBullish => '強気多数';

  @override
  String get newsBubbleLegendBearish => '弱気多数';

  @override
  String get newsBubbleLegendMixed => '混合';

  @override
  String newsBubbleMentions(int count) {
    return '$count件';
  }

  @override
  String get taxEstimateTitle => '税金見積もり';

  @override
  String get totalGains => '総利益';

  @override
  String get annualExemption => '年間控除額';

  @override
  String get estimatedTax => '予想税額 (22%)';

  @override
  String get netProfit => '税引後利益';

  @override
  String get krwSuffix => 'ウォン';

  @override
  String get taxTradeCount => '件売却';

  @override
  String get macro3mTitle => '3ヶ月';

  @override
  String get macro3mHigh => '最高';

  @override
  String get macro3mAvg => '平均';

  @override
  String get macro3mLow => '最低';

  @override
  String get tooltipClearSearch => '検索をクリア';

  @override
  String get tooltipPreviousMonth => '前月';

  @override
  String get tooltipNextMonth => '翌月';

  @override
  String get tooltipShowPassword => 'パスワードを表示';

  @override
  String get tooltipHidePassword => 'パスワードを非表示';

  @override
  String get tooltipChangePhoto => '写真を変更';

  @override
  String get tooltipFilter => 'フィルター';

  @override
  String get tooltipRemove => '削除';

  @override
  String get otherSectors => 'その他セクター';

  @override
  String get otherTickers => 'その他銘柄';

  @override
  String nDaysAgo(int count) {
    return '$count日前';
  }
}
