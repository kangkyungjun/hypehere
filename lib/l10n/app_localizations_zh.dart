// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MarketLens';

  @override
  String get tabDashboard => '仪表盘';

  @override
  String get tabDashboardTooltip => '市场仪表盘';

  @override
  String get tabSearch => '搜索';

  @override
  String get tabSearchTooltip => '搜索股票';

  @override
  String get tabNews => '新闻';

  @override
  String get tabNewsTooltip => '市场新闻';

  @override
  String get tabCommunity => '社区';

  @override
  String get tabCommunityTooltip => '讨论区';

  @override
  String get tabWatchlist => '自选';

  @override
  String get tabWatchlistTooltip => '我的自选股';

  @override
  String get settings => '设置';

  @override
  String get settingsTooltip => '设置';

  @override
  String get compareTickers => '股票对比';

  @override
  String get account => '账户';

  @override
  String get login => '登录';

  @override
  String get loginSubtitle => '使用社区功能';

  @override
  String get signup => '注册';

  @override
  String get signupTitle => '注册';

  @override
  String get signupSubtitle => '创建新账户';

  @override
  String get noAccountSignup => '还没有账户？注册';

  @override
  String get hasAccountLogin => '已有账户？登录';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirmTitle => '退出登录';

  @override
  String get logoutConfirmMessage => '确定要退出登录吗？';

  @override
  String get welcome => '欢迎！';

  @override
  String get accountCreated => '账户创建成功！';

  @override
  String get email => '邮箱';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailRequired => '请输入邮箱';

  @override
  String get emailInvalid => '邮箱格式不正确';

  @override
  String get nickname => '昵称';

  @override
  String get nicknameHint => '社区中使用的昵称';

  @override
  String get nicknameRequired => '请输入昵称';

  @override
  String get nicknameTooShort => '昵称至少需要2个字符';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get passwordTooShort => '密码至少需要8个字符';

  @override
  String get passwordConfirm => '确认密码';

  @override
  String get passwordConfirmHint => '请再次输入密码';

  @override
  String get passwordConfirmRequired => '请确认密码';

  @override
  String get passwordMismatch => '两次密码不一致';

  @override
  String get changePassword => '修改密码';

  @override
  String get changePasswordGuide => '修改密码指南';

  @override
  String get oldPassword => '当前密码';

  @override
  String get oldPasswordHint => '请输入当前密码';

  @override
  String get oldPasswordRequired => '请输入当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get newPasswordHint => '请输入新密码（至少8位）';

  @override
  String get newPasswordRequired => '请输入新密码';

  @override
  String get newPasswordConfirm => '确认新密码';

  @override
  String get newPasswordConfirmHint => '请再次输入新密码';

  @override
  String get newPasswordConfirmRequired => '请确认新密码';

  @override
  String get newPasswordMustDiffer => '新密码不能与当前密码相同';

  @override
  String get passwordChanged => '密码修改成功';

  @override
  String passwordChangeFailed(String error) {
    return '密码修改失败：$error';
  }

  @override
  String get loginRequired => '需要登录';

  @override
  String get loginPromptMessage => '登录并加入社区！';

  @override
  String get searchHint => '搜索股票代码或公司名（如 AAPL、Apple）';

  @override
  String get searchFailed => '搜索失败';

  @override
  String get noSearchResults => '无搜索结果';

  @override
  String get tryDifferentSearch => '请尝试其他股票代码';

  @override
  String get tickerSearch => '股票搜索';

  @override
  String get enterTickerAbove => '请输入搜索词';

  @override
  String get recentSearches => '最近搜索';

  @override
  String get clearAll => '全部清除';

  @override
  String get retry => '重试';

  @override
  String get tryAgain => '再试一次';

  @override
  String get sectorMarketOverview => '板块概览';

  @override
  String get filterAll => '全部';

  @override
  String get filterNasdaq => '纳斯达克';

  @override
  String get filterDow => '道琼斯';

  @override
  String get marketLensAIScore => 'AI评分';

  @override
  String get distributionShownOnFullLoad => '加载全部信号后显示分布';

  @override
  String topN(int n) {
    return '▲ 前 $n';
  }

  @override
  String bottomN(int n) {
    return '▼ 后 $n';
  }

  @override
  String get noData => '暂无数据';

  @override
  String get signalLoadFailed => '信号加载失败';

  @override
  String dashboardLoadFailed(String error) {
    return '仪表盘加载失败：$error';
  }

  @override
  String get allSignals => '全部信号';

  @override
  String get sp500Signals => '标普500信号';

  @override
  String get dow30Signals => '道琼斯30信号';

  @override
  String get nasdaq100Signals => '纳斯达克100信号';

  @override
  String get marketTrend => '市场整体趋势';

  @override
  String get loadingSignals => '正在加载全部信号...';

  @override
  String get loadingSP500Signals => '正在加载标普500信号...';

  @override
  String get loadingDow30Signals => '正在加载道琼斯30信号...';

  @override
  String get loadingNasdaq100Signals => '正在加载纳斯达克100信号...';

  @override
  String get noAdditionalSignals => '暂无更多信号';

  @override
  String showMore(int remaining) {
    return '查看更多（剩余 $remaining 个）';
  }

  @override
  String nItems(int count) {
    return '$count 个';
  }

  @override
  String get scoreStrongBuy => '强烈买入';

  @override
  String get scoreBuy => '买入';

  @override
  String get scoreHold => '观望';

  @override
  String get scoreSell => '卖出';

  @override
  String get scoreStrongSell => '强烈卖出';

  @override
  String get score => '评分';

  @override
  String get myWatchlist => '我的自选股';

  @override
  String nTickers(int count) {
    return '$count 只股票';
  }

  @override
  String get watchlistEmpty => '自选股列表为空';

  @override
  String get watchlistEmptyHint => '在搜索页面搜索并添加股票';

  @override
  String get explore => '探索';

  @override
  String get tapToViewDetails => '点击查看详情';

  @override
  String tickerRemovedFromWatchlist(String ticker) {
    return '$ticker 已从自选股移除';
  }

  @override
  String get undo => '撤销';

  @override
  String get tickerDataLoadFailed => '无法加载股票数据';

  @override
  String get addToWatchlist => '添加到自选股';

  @override
  String get removeFromWatchlist => '从自选股移除';

  @override
  String get addedToWatchlist => '已添加到自选股';

  @override
  String get removedFromWatchlist => '已从自选股移除';

  @override
  String get communitySearchHint => '按标题或内容搜索...';

  @override
  String get writePost => '发帖';

  @override
  String get deletePost => '删除帖子';

  @override
  String get deleteConfirm => '确定要删除这篇帖子吗？\n删除后无法恢复。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get done => '完成';

  @override
  String get confirm => '确认';

  @override
  String get postDeleted => '帖子已删除';

  @override
  String get report => '举报';

  @override
  String get reportTitle => '举报';

  @override
  String get reportAbuse => '辱骂/诽谤';

  @override
  String get reportSpam => '垃圾信息/广告';

  @override
  String get reportInappropriate => '不当内容';

  @override
  String get reportHarassment => '骚扰';

  @override
  String get reportOther => '其他';

  @override
  String get reportDescription => '详细说明';

  @override
  String get reportSubmitted => '举报已提交';

  @override
  String get reportSubmit => '举报';

  @override
  String postDeleteFailed(String error) {
    return '帖子删除失败：$error';
  }

  @override
  String get noPostsYet => '暂无帖子';

  @override
  String get writeFirstPost => '来写第一篇帖子吧！';

  @override
  String get noSearchResultsCommunity => '无搜索结果';

  @override
  String get tryDifferentFilter => '请尝试其他搜索词或筛选条件';

  @override
  String get networkError => '连接失败，请稍后重试。';

  @override
  String get serverTimeout => '服务器超时，请稍后重试。';

  @override
  String get postsLoadFailed => '无法加载帖子，请稍后重试。';

  @override
  String get searchResultsLoadFailed => '无法加载搜索结果';

  @override
  String get refresh => '刷新';

  @override
  String get all => '全部';

  @override
  String get add => '添加';

  @override
  String tickerBoard(String ticker) {
    return '$ticker 讨论区';
  }

  @override
  String get tickerSearchHint => '搜索股票...（如 AAPL、TSLA）';

  @override
  String get popularTickers => '热门股票';

  @override
  String get freePost => '自由';

  @override
  String get checkNetwork => '请检查网络连接';

  @override
  String get tryAgainLater => '请稍后重试';

  @override
  String get newPost => '新帖子';

  @override
  String get editPostTitle => '编辑帖子';

  @override
  String get tickerOnlyBoard => '个股专区';

  @override
  String get selectTicker => '股票';

  @override
  String get tickerSearchLabel => '搜索股票';

  @override
  String get tickerSearchHintCreate => '按名称、代码或中文名搜索';

  @override
  String get tickerNotSelectedHint => '未选择股票时将发布为自由帖子';

  @override
  String get noTickerSearchResults => '无搜索结果';

  @override
  String get postTitle => '标题';

  @override
  String get postTitleHint => '请输入帖子标题';

  @override
  String get postTitleRequired => '请输入标题';

  @override
  String get postTitleTooShort => '标题至少需要2个字符';

  @override
  String get postContent => '内容';

  @override
  String get postContentHint => '请输入帖子内容';

  @override
  String get postContentRequired => '请输入内容';

  @override
  String get postContentTooShort => '内容至少需要5个字符';

  @override
  String get postCreated => '帖子已发布';

  @override
  String get postUpdated => '帖子已更新';

  @override
  String get submitPost => '发布';

  @override
  String get updatePostButton => '更新';

  @override
  String get deleteComment => '删除评论';

  @override
  String get deleteCommentConfirm => '确定要删除这条评论吗？';

  @override
  String get editComment => '编辑评论';

  @override
  String get commentHint => '写评论...';

  @override
  String get commentPlaceholder => '请输入评论内容';

  @override
  String get commentCreated => '评论已发布';

  @override
  String get commentUpdated => '评论已更新';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get commentRequired => '请输入评论内容';

  @override
  String get loginToViewComments => '登录后查看评论';

  @override
  String get writeFirstComment => '来写第一条评论吧！';

  @override
  String get postDetail => '帖子详情';

  @override
  String get startWithFirstPost => '从第一篇帖子开始吧';

  @override
  String get writeAPost => '写帖子';

  @override
  String get cannotLoadPosts => '无法加载帖子';

  @override
  String get noPostsInTicker => '该讨论区暂无帖子';

  @override
  String get writeFirstPostInTicker => '来写第一篇帖子吧！';

  @override
  String get dataManagement => '数据管理';

  @override
  String get clearRecentSearches => '清除搜索记录';

  @override
  String nSearchRecords(int count) {
    return '$count 条搜索记录';
  }

  @override
  String get clearRecentSearchesConfirm => '确定要清除所有搜索记录吗？';

  @override
  String get recentSearchesCleared => '搜索记录已清除';

  @override
  String get clearWatchlist => '清空自选股';

  @override
  String get clearWatchlistConfirm => '确定要清空所有自选股吗？';

  @override
  String get watchlistCleared => '自选股已清空';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get deleteAllDataConfirm => '将删除包括自选股和搜索记录在内的所有本地数据。此操作不可撤销。';

  @override
  String get deleteAllButton => '全部删除';

  @override
  String get allDataDeleted => '所有数据已删除';

  @override
  String get removeAllLocalData => '移除所有本地数据';

  @override
  String get info => '信息';

  @override
  String get aboutMarketLens => '关于';

  @override
  String version(String version) {
    return '版本 $version';
  }

  @override
  String get appDescription => '基于AI的股票分析工具，助力数据驱动的投资决策';

  @override
  String get aiStockAnalysis => 'AI股票分析';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get admin => '管理';

  @override
  String get adminPanel => '管理面板';

  @override
  String get adminPanelSubtitle => '用户管理及权限设置';

  @override
  String get showAds => '显示广告';

  @override
  String get adsEnabledDescription => '向所有用户展示横幅广告';

  @override
  String get adsDisabledDescription => '广告已隐藏';

  @override
  String get sendPushNotification => '发送推送通知';

  @override
  String get sendPushNotificationSubtitle => '向所有用户广播通知';

  @override
  String get pushTitle => '标题';

  @override
  String get pushBody => '内容';

  @override
  String get send => '发送';

  @override
  String pushSentResult(int count) {
    return '已发送到$count台设备';
  }

  @override
  String get pushSendFailed => '推送通知发送失败';

  @override
  String get promoteToGold => '升级为Gold';

  @override
  String get promoteToManager => '升级为Manager';

  @override
  String get demoteToRegular => '降级为普通用户';

  @override
  String get profile => '个人资料';

  @override
  String get editProfile => '编辑资料';

  @override
  String get myPosts => '我的帖子';

  @override
  String get myComments => '我的评论';

  @override
  String get viewAll => '查看全部';

  @override
  String get noPosts => '暂无帖子';

  @override
  String get noComments => '暂无评论';

  @override
  String joinDate(String date) {
    return '注册日期：$date';
  }

  @override
  String get deleteAccount => '注销账户';

  @override
  String get withdrawAccountConfirm => '确定要注销账户吗？\n7天后账户将被永久删除。在此期间重新登录可取消注销。';

  @override
  String get withdrawAccountReasonHint => '请输入注销原因（可选）';

  @override
  String get withdrawAccountSuccess => '账户注销已申请。7天后将永久删除。';

  @override
  String get withdrawAccountFailed => '账户注销申请失败，请重试。';

  @override
  String get deactivateAccount => '停用账户';

  @override
  String get profileUpdated => '资料已更新';

  @override
  String get imagePickerFailed => '图片选择失败';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '系统默认';

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
  String get languageSettings => '语言设置';

  @override
  String get systemDefault => '系统默认';

  @override
  String get languageChanged => '语言已更改';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int n) {
    return '$n分钟前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n小时前';
  }

  @override
  String get timeYesterday => '昨天';

  @override
  String timeDaysAgo(int n) {
    return '$n天前';
  }

  @override
  String get companyOverview => '公司概况';

  @override
  String get companyDetails => '公司详情';

  @override
  String get companyIntro => '公司简介';

  @override
  String employeeCount(String count) {
    return '$count 名员工';
  }

  @override
  String get valuation => '估值';

  @override
  String get forwardPE => '预期市盈率';

  @override
  String get beta => '贝塔系数';

  @override
  String get profitabilityGrowth => '盈利能力与增长';

  @override
  String get netProfitMargin => '净利润率';

  @override
  String get revenueGrowth => '营收增长';

  @override
  String get operatingMargin => '营业利润率';

  @override
  String get earningsGrowth => '利润增长';

  @override
  String get financialHealth => '财务健康';

  @override
  String get debtRatio => '负债率';

  @override
  String get liquidityRatio => '流动比率';

  @override
  String get dividends => '股息';

  @override
  String get dividendYield => '股息率 ';

  @override
  String get annualDividend => '年度 ';

  @override
  String get shortInterest => '空头持仓';

  @override
  String get shortInterestRatio => '空头比率';

  @override
  String get shortPercentFloat => '流通股空头占比';

  @override
  String shortDays(String days) {
    return '$days 天';
  }

  @override
  String get shortInterestLow => '空头持仓较低（稳定）';

  @override
  String get shortInterestModerate => '空头持仓适中（注意）';

  @override
  String get shortInterestHigh => '空头持仓较高（警告）';

  @override
  String get institutionalInsiderFlow => '机构/内部人资金流';

  @override
  String get institutional => '机构';

  @override
  String get insider => '内部人';

  @override
  String get oneDay => '1日';

  @override
  String get fiveDay => '5日';

  @override
  String tickerNews(String ticker) {
    return '$ticker 新闻';
  }

  @override
  String newsCount(int count) {
    return '$count';
  }

  @override
  String get oneWeek => '1周';

  @override
  String get oneMonth => '1月';

  @override
  String get noNews => '暂无新闻';

  @override
  String get marketNews => '市场新闻';

  @override
  String get viewOriginalArticle => '查看原文';

  @override
  String get sentimentBullish => '看涨';

  @override
  String get sentimentNeutral => '中性';

  @override
  String get sentimentBearish => '看跌';

  @override
  String get aiSummaryNews => 'AI摘要新闻';

  @override
  String get aiSummary => 'AI摘要';

  @override
  String get noNewsAvailable => '暂无新闻';

  @override
  String get earningsHistory => '历史业绩';

  @override
  String get earningsHistoryEPS => '业绩历史（每股收益）';

  @override
  String get earningsEstimate => '预期';

  @override
  String get earningsBeat => '超预期';

  @override
  String get earningsMiss => '不及预期';

  @override
  String get earningsActual => '实际';

  @override
  String get earningsScheduled => '预定';

  @override
  String get epsEstimateLabel => '每股收益(EPS)预期';

  @override
  String get revenueEstimateLabel => '营收预期';

  @override
  String get averageLabel => '均值';

  @override
  String get surpriseLabel => '偏离';

  @override
  String get thisWeekEarnings => '本周财报';

  @override
  String get previousEarnings => '往期业绩';

  @override
  String earningsCount(int count) {
    return '$count';
  }

  @override
  String get noEarningsThisWeek => '本周无财报发布';

  @override
  String get nextEarningsDate => '下次财报日';

  @override
  String get earningsConfirmed => '已确认';

  @override
  String get keyEvents => '重要事件';

  @override
  String get eventDetails => '事件详情';

  @override
  String get upcomingEvents => '即将到来';

  @override
  String get exDividendDate => '除权除息日';

  @override
  String get dividendPayDate => '股息支付日';

  @override
  String recentEarningsQuarters(int count) {
    return '近期业绩（$count季）';
  }

  @override
  String get earningsHistoryChart => '业绩历史（图表）';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get macroFedFunds => '联邦基金利率';

  @override
  String get macroDGS10 => '10年期收益率';

  @override
  String get macroDGS2 => '2年期收益率';

  @override
  String get macroT10Y2Y => '利差';

  @override
  String get macroVIXCLS => 'VIX';

  @override
  String get macroCPIAUCSL => 'CPI';

  @override
  String get macroUNRATE => '失业率';

  @override
  String get macroFedFundsDesc => '美联储基准利率';

  @override
  String get macroDGS10Desc => '美国10年期国债收益率';

  @override
  String get macroDGS2Desc => '美国2年期国债收益率';

  @override
  String get macroT10Y2YDesc => '长短期利差（10Y-2Y）';

  @override
  String get macroVIXCLSDesc => '市场波动率指数';

  @override
  String get macroCPIAUCSLDesc => '消费者物价指数（CPI）';

  @override
  String get macroUNRATEDesc => '美国失业率';

  @override
  String get riskBearish => '看跌';

  @override
  String get riskCautious => '谨慎';

  @override
  String get riskNeutral => '中性';

  @override
  String get riskPositive => '乐观';

  @override
  String get riskBullish => '看涨';

  @override
  String get macroCategoryRates => '利率';

  @override
  String get macroCategorySentiment => '情绪';

  @override
  String get macroCategoryEconomy => '经济';

  @override
  String get macroYieldCurve => '收益率曲线';

  @override
  String get macroLiquidity => '流动性';

  @override
  String get macroOverall => '宏观总览';

  @override
  String macroCurrentValue(String value) {
    return '当前值：$value';
  }

  @override
  String macroChange(String value) {
    return '变动：$value';
  }

  @override
  String epsEstimateValue(String value) {
    return '预期 \$$value';
  }

  @override
  String get bbInterpretation => '布林带解读';

  @override
  String get bbBandWidth => '- 带宽：反映波动性（越宽波动越大）';

  @override
  String get bbUpperApproach => '- 触及上轨：可能超买';

  @override
  String get bbLowerApproach => '- 触及下轨：可能超卖';

  @override
  String get bbMiddleLine => '- 中轨：20日均线';

  @override
  String get cannotLoadData => '无法加载数据';

  @override
  String get marketlensAI => 'MarketLens AI';

  @override
  String get marketlensAIOpinion => 'MarketLens AI 观点';

  @override
  String get bullishFactors => '看涨因素';

  @override
  String get bearishFactors => '看跌因素';

  @override
  String get target => '目标 ';

  @override
  String get stopLoss => '止损 ';

  @override
  String get averageTargetPrice => '平均目标价';

  @override
  String get currentPrice => '当前价';

  @override
  String get targetPrice => '目标价';

  @override
  String get recentAnalystRatings => '近期分析师评级';

  @override
  String get unknownFirm => '未知';

  @override
  String get volume => '成交量';

  @override
  String get legend => '图例';

  @override
  String get ratingBuy => '买入';

  @override
  String get ratingStrongBuy => '强烈买入';

  @override
  String get ratingOutperform => '跑赢大盘';

  @override
  String get ratingHold => '持有';

  @override
  String get ratingNeutral => '中性';

  @override
  String get ratingMarketPerform => '与大盘持平';

  @override
  String get ratingSell => '卖出';

  @override
  String get ratingStrongSell => '强烈卖出';

  @override
  String get ratingUnderperform => '跑输大盘';

  @override
  String get ratingActionUpgrade => '上调';

  @override
  String get ratingActionDowngrade => '下调';

  @override
  String get ratingActionReiterated => '维持';

  @override
  String get ratingActionInitiated => '首次覆盖';

  @override
  String get roleMaster => 'Master';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleGold => 'Gold';

  @override
  String get roleRegular => '普通用户';

  @override
  String get roleGuest => '访客';

  @override
  String get errInvalidCredentials => '邮箱或密码不正确';

  @override
  String get errLoginRequired => '需要登录';

  @override
  String get errSessionExpired => '登录已过期，请重新登录。';

  @override
  String get errCannotLoadUser => '无法加载用户信息';

  @override
  String get errServerConnection => '无法连接服务器，请检查网络连接。';

  @override
  String get errServerConnectionShort => '无法连接服务器';

  @override
  String get errNetworkFailed => '网络连接失败，请检查网络。';

  @override
  String get errResponseFormat => '服务器响应格式错误';

  @override
  String errTimeout(int seconds) {
    return '服务器响应超时（$seconds秒）';
  }

  @override
  String get errBadRequest => '请检查输入信息';

  @override
  String get errForbidden => '没有访问权限';

  @override
  String get errNotFound => '页面未找到';

  @override
  String get errServerError => '服务器错误，请稍后重试。';

  @override
  String get errNoEditPermission => '没有编辑权限';

  @override
  String get errNoDeletePermission => '没有删除权限';

  @override
  String get errPostDeleteFailed => '帖子删除失败';

  @override
  String get errCommentDeleteFailed => '评论删除失败';

  @override
  String get errReportAlreadySubmitted => '您已举报过此内容';

  @override
  String get errCannotReportOwn => '无法举报自己的内容';

  @override
  String get errReportFailed => '举报提交失败';

  @override
  String get errManagerRequired => '权限不足，需要Manager及以上权限。';

  @override
  String get errMasterRequired => '权限不足，仅限Master访问。';

  @override
  String get errSearchRequired => '请输入搜索词';

  @override
  String get errDemotionFailed => '降级失败';

  @override
  String get errMaxCompare => '最多可对比3只股票';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get dayBeforeYesterday => '前天';

  @override
  String expertCount(String count) {
    return '分析师目标价（$count家）';
  }

  @override
  String scorePoints(String score) {
    return '$score分';
  }

  @override
  String averageVolume(String volume) {
    return '均量：$volume';
  }

  @override
  String get showBullBearFactors => '查看多空因素';

  @override
  String get hideBullBearFactors => '收起多空因素';

  @override
  String analystConsensus(String count) {
    return '机构目标价（$count 家）';
  }

  @override
  String lowestPrice(String price) {
    return '最低 \$$price';
  }

  @override
  String highestPrice(String price) {
    return '最高 \$$price';
  }

  @override
  String get liveTalk => '实时讨论';

  @override
  String commentsCount(int count) {
    return '$count 条评论';
  }

  @override
  String get browsePosts => '浏览帖子';

  @override
  String get loginPromptComments => '查看其他投资者的观点，\n分享你的分析！';

  @override
  String get shareThoughtsPrompt => '分享你对股票的看法，\n与其他投资者交流';

  @override
  String get writeFirstCommentPrompt => '在帖子下留下第一条评论吧';

  @override
  String get startConversationPrompt => '在其他投资者的帖子下\n开始对话吧';

  @override
  String get ratingOverweight => '增持';

  @override
  String get ratingUnderweight => '减持';

  @override
  String get ratingSectorOutperform => '行业领先';

  @override
  String get ratingSectorPerform => '行业持平';

  @override
  String get ratingSectorUnderperform => '行业落后';

  @override
  String get ratingPositive => '正面';

  @override
  String get ratingNegative => '负面';

  @override
  String get ratingEqualWeight => '持平';

  @override
  String get keyMetricsComparison => '核心指标对比';

  @override
  String get metric => '指标';

  @override
  String get serverCalculatedNote => '※ 所有指标均为服务器计算值';

  @override
  String get priceTrendComparison => '价格走势对比';

  @override
  String get rsiComparison => 'RSI对比（服务器计算值）';

  @override
  String get rsiInterpretation => '※ RSI > 70：超买 / RSI < 30：超卖';

  @override
  String get passwordChangeInstructions =>
      '- 新密码至少需要8个字符\n- 建议使用字母、数字和符号组合\n- 修改后需使用新密码重新登录';

  @override
  String get notifications => '通知';

  @override
  String get noNotifications => '暂无通知';

  @override
  String get notificationsRetentionHint => '最近7天的通知显示在这里。';

  @override
  String get bioLabel => '简介';

  @override
  String get bioHint => '介绍一下你自己';

  @override
  String get profileEditGuide => '编辑资料指南';

  @override
  String get updatedDate => '更新日期：';
}
