import 'dart:math';

/// 한 개의 추천(예시) 질문. 카테고리 태그로 사용자 관심사를 추적해
/// 맞춤 콘텐츠 신호로 활용한다. 텍스트는 ko/en 2개 언어를 보유하고,
/// 그 외 로케일은 en으로 폴백한다(채팅 API가 en/ko만 구분).
class ChatSuggestion {
  final String id;
  final String category;
  final String ko;
  final String en;

  const ChatSuggestion({
    required this.id,
    required this.category,
    required this.ko,
    required this.en,
  });

  String text(bool isKo) => isKo ? ko : en;
}

/// AI 채팅 인사말 + 예시 질문 뱅크.
///
/// - 예시 질문은 템플릿(티커/섹터) + 고정 질문을 합쳐 수백 개 규모.
/// - [pick]은 사용자 관심도(interest)를 가중치로 반영해 랜덤 N개를 뽑되,
///   같은 카테고리가 몰리지 않도록 약한 다양성 패널티를 준다.
class ChatSuggestions {
  ChatSuggestions._();

  // 인사말(접속 시 "대화를 걸어주는" 멘트). 오늘 시황/내 자산 방향성을 언급하고
  // "궁금한 건 물어보세요"로 마무리한다.
  static const List<({String ko, String en})> greetings = [
    (
      ko: '안녕하세요 👋 오늘 미국 증시 시황이 궁금하세요, 아니면 보유 자산의 방향성을 점검해 드릴까요? 무엇이든 편하게 물어보세요.',
      en: 'Hi 👋 Want today\'s US market recap, or a quick read on where your holdings are headed? Ask me anything.',
    ),
    (
      ko: '반가워요! 오늘 시장 분위기 요약부터, 내 포트폴리오 점검까지 도와드릴 수 있어요. 궁금한 걸 눌러보거나 직접 물어보세요.',
      en: 'Welcome back! I can recap today\'s market or review your portfolio. Tap a question below or just ask.',
    ),
    (
      ko: '오늘도 좋은 하루예요 ☀️ 시황 한 줄 요약이 필요하세요, 아니면 내 자산 흐름이 궁금하세요? 무엇이든 물어보세요.',
      en: 'Good to see you ☀️ Need a one-line market summary, or curious how your assets are trending? Ask away.',
    ),
    (
      ko: '시장이 쉬지 않네요 📈 오늘 주목할 섹터나 내 보유 종목 방향성, 어떤 게 더 궁금하세요? 편하게 물어보세요.',
      en: 'Markets never sleep 📈 Want today\'s standout sectors or a take on your holdings? Just ask.',
    ),
    (
      ko: '무엇을 도와드릴까요? 오늘 시황 요약, 관심 종목 분석, 내 자산 점검까지 가능해요. 궁금한 건 물어보세요.',
      en: 'How can I help? Today\'s recap, a stock deep-dive, or a portfolio check — ask me anything.',
    ),
    (
      ko: '잠깐 들렀어도 좋아요 🙂 오늘 시장에서 무슨 일이 있었는지, 내 자산은 어디로 향하는지 한눈에 정리해 드릴게요.',
      en: 'Even a quick visit counts 🙂 I\'ll sum up what moved today and where your assets are headed. Ask away.',
    ),
  ];

  /// 추천 질문 전체 뱅크(지연 생성).
  static List<ChatSuggestion>? _cache;
  static List<ChatSuggestion> get bank => _cache ??= _build();

  static ({String ko, String en}) pickGreeting({Random? rng}) {
    final r = rng ?? Random();
    return greetings[r.nextInt(greetings.length)];
  }

  /// 관심도 가중 + 카테고리 다양성을 반영해 [n]개를 중복 없이 뽑는다.
  static List<ChatSuggestion> pick(
    int n, {
    Map<String, int> interest = const {},
    Random? rng,
  }) {
    final r = rng ?? Random();
    final items = List<ChatSuggestion>.from(bank);
    final weights = items
        .map((s) => 1.0 + (interest[s.category] ?? 0) * 0.6)
        .toList();
    final result = <ChatSuggestion>[];

    for (int k = 0; k < n && items.isNotEmpty; k++) {
      double total = 0;
      for (final w in weights) {
        total += w;
      }
      double pickV = r.nextDouble() * total;
      int idx = 0;
      for (; idx < items.length; idx++) {
        pickV -= weights[idx];
        if (pickV <= 0) break;
      }
      if (idx >= items.length) idx = items.length - 1;

      final chosen = items[idx];
      result.add(chosen);
      items.removeAt(idx);
      weights.removeAt(idx);

      // 같은 카테고리가 연달아 나오지 않도록 약한 다양성 패널티
      for (int j = 0; j < items.length; j++) {
        if (items[j].category == chosen.category) weights[j] *= 0.3;
      }
    }
    return result;
  }

  // ── 뱅크 빌드 ──────────────────────────────────────────────────────────

  static List<ChatSuggestion> _build() {
    final out = <ChatSuggestion>[];
    out.addAll(_fixed);
    out.addAll(_tickerTemplated());
    out.addAll(_sectorTemplated());
    return out;
  }

  // 인기 티커 — 템플릿과 결합해 다수의 종목 질문을 생성
  static const List<String> _tickers = [
    'AAPL',
    'MSFT',
    'NVDA',
    'GOOGL',
    'AMZN',
    'META',
    'TSLA',
    'AMD',
    'NFLX',
    'AVGO',
    'JPM',
    'V',
    'JNJ',
    'WMT',
    'XOM',
    'KO',
    'DIS',
    'BA',
    'INTC',
    'CRM',
    'PYPL',
    'UBER',
    'COIN',
    'PLTR',
    'SOFI',
    'QCOM',
    'ORCL',
    'ADBE',
    'COST',
    'PEP',
  ];

  static List<ChatSuggestion> _tickerTemplated() {
    final templates = <({String ko, String en})>[
      (ko: '{t} 지금 사도 될까?', en: 'Is {t} a buy right now?'),
      (ko: '{t} 최근 실적 어땠어?', en: 'How were {t}\'s recent earnings?'),
      (ko: '{t} 전망 간단히 알려줘', en: 'Give me a quick outlook on {t}'),
      (ko: '{t} 리스크 요인은 뭐야?', en: 'What are the key risks for {t}?'),
      (ko: '{t} 적정 매수가는 어느 정도야?', en: 'What\'s a fair entry price for {t}?'),
    ];
    final out = <ChatSuggestion>[];
    for (final t in _tickers) {
      for (int i = 0; i < templates.length; i++) {
        out.add(
          ChatSuggestion(
            id: 'tk_${t}_$i',
            category: 'ticker',
            ko: templates[i].ko.replaceAll('{t}', t),
            en: templates[i].en.replaceAll('{t}', t),
          ),
        );
      }
    }
    return out;
  }

  // 섹터 — ko/en 라벨과 템플릿 결합
  static const List<({String ko, String en})> _sectors = [
    (ko: '기술', en: 'Technology'),
    (ko: '금융', en: 'Financials'),
    (ko: '헬스케어', en: 'Healthcare'),
    (ko: '에너지', en: 'Energy'),
    (ko: '임의소비재', en: 'Consumer Discretionary'),
    (ko: '필수소비재', en: 'Consumer Staples'),
    (ko: '산업재', en: 'Industrials'),
    (ko: '커뮤니케이션', en: 'Communication'),
    (ko: '유틸리티', en: 'Utilities'),
    (ko: '소재', en: 'Materials'),
    (ko: '부동산', en: 'Real Estate'),
  ];

  static List<ChatSuggestion> _sectorTemplated() {
    final templates = <({String ko, String en})>[
      (ko: '{s} 섹터 전망 어때?', en: 'What\'s the outlook for {s}?'),
      (ko: '{s} 섹터에서 주목할 종목은?', en: 'Top picks in the {s} sector?'),
      (ko: '{s} 섹터 지금 들어가도 될까?', en: 'Is now a good time for {s}?'),
    ];
    final out = <ChatSuggestion>[];
    for (int j = 0; j < _sectors.length; j++) {
      final s = _sectors[j];
      for (int i = 0; i < templates.length; i++) {
        out.add(
          ChatSuggestion(
            id: 'sc_${j}_$i',
            category: 'sector',
            ko: templates[i].ko.replaceAll('{s}', s.ko),
            en: templates[i].en.replaceAll('{s}', s.en),
          ),
        );
      }
    }
    return out;
  }

  // 고정 질문(카테고리별). 시황/포트폴리오/매크로/교육/전략/리스크/배당/실적.
  static const List<ChatSuggestion> _fixed = [
    // market_today
    ChatSuggestion(
      id: 'mt01',
      category: 'market_today',
      ko: '오늘 미국 증시 시황 한 줄로 요약해줘',
      en: 'Sum up today\'s US market in one line',
    ),
    ChatSuggestion(
      id: 'mt02',
      category: 'market_today',
      ko: '오늘 가장 많이 오른 섹터는 어디야?',
      en: 'Which sector gained the most today?',
    ),
    ChatSuggestion(
      id: 'mt03',
      category: 'market_today',
      ko: '오늘 시장 분위기가 위험 회피야, 위험 선호야?',
      en: 'Is today risk-on or risk-off?',
    ),
    ChatSuggestion(
      id: 'mt04',
      category: 'market_today',
      ko: '오늘 지수(S&P·나스닥·다우) 흐름 정리해줘',
      en: 'Recap the S&P, Nasdaq and Dow today',
    ),
    ChatSuggestion(
      id: 'mt05',
      category: 'market_today',
      ko: '오늘 시장을 움직인 뉴스는 뭐였어?',
      en: 'What news moved the market today?',
    ),
    ChatSuggestion(
      id: 'mt06',
      category: 'market_today',
      ko: '오늘 거래대금 상위 종목 알려줘',
      en: 'Top stocks by trading value today?',
    ),
    ChatSuggestion(
      id: 'mt07',
      category: 'market_today',
      ko: '오늘 변동성(VIX)은 어떤 상황이야?',
      en: 'How is volatility (VIX) today?',
    ),
    ChatSuggestion(
      id: 'mt08',
      category: 'market_today',
      ko: '장 마감 후 시간외에서 움직이는 종목 있어?',
      en: 'Any notable after-hours movers?',
    ),
    ChatSuggestion(
      id: 'mt09',
      category: 'market_today',
      ko: '이번 주 시장 핵심 일정 알려줘',
      en: 'Key market events this week?',
    ),
    ChatSuggestion(
      id: 'mt10',
      category: 'market_today',
      ko: '오늘 하락한 종목 중 눈여겨볼 곳 있어?',
      en: 'Any oversold names worth watching today?',
    ),
    ChatSuggestion(
      id: 'mt11',
      category: 'market_today',
      ko: '오늘 시장을 3줄로 브리핑해줘',
      en: 'Brief me on today\'s market in 3 lines',
    ),
    ChatSuggestion(
      id: 'mt12',
      category: 'market_today',
      ko: '지금 시장에서 가장 뜨거운 테마는?',
      en: 'What\'s the hottest theme right now?',
    ),

    // portfolio (내 자산 방향성)
    ChatSuggestion(
      id: 'pf01',
      category: 'portfolio',
      ko: '내 포트폴리오 방향성을 평가해줘',
      en: 'Assess the direction of my portfolio',
    ),
    ChatSuggestion(
      id: 'pf02',
      category: 'portfolio',
      ko: '내 보유 종목 중 위험 신호가 있는 건?',
      en: 'Any risk signals in my holdings?',
    ),
    ChatSuggestion(
      id: 'pf03',
      category: 'portfolio',
      ko: '내 자산 비중을 어떻게 조정하면 좋을까?',
      en: 'How should I rebalance my allocation?',
    ),
    ChatSuggestion(
      id: 'pf04',
      category: 'portfolio',
      ko: '내 포트폴리오가 시장 대비 잘하고 있어?',
      en: 'Is my portfolio beating the market?',
    ),
    ChatSuggestion(
      id: 'pf05',
      category: 'portfolio',
      ko: '내 보유 종목이 특정 섹터에 쏠려 있어?',
      en: 'Is my portfolio over-concentrated in a sector?',
    ),
    ChatSuggestion(
      id: 'pf06',
      category: 'portfolio',
      ko: '지금 분할매도하면 좋을 종목 있어?',
      en: 'Any holdings I should trim now?',
    ),
    ChatSuggestion(
      id: 'pf07',
      category: 'portfolio',
      ko: '내 포트폴리오의 분산이 충분해?',
      en: 'Is my portfolio diversified enough?',
    ),
    ChatSuggestion(
      id: 'pf08',
      category: 'portfolio',
      ko: '내 자산에서 배당 비중은 어느 정도야?',
      en: 'How much of my portfolio is dividend-paying?',
    ),
    ChatSuggestion(
      id: 'pf09',
      category: 'portfolio',
      ko: '내 보유 종목 다음 실적 일정 알려줘',
      en: 'Upcoming earnings dates for my holdings?',
    ),
    ChatSuggestion(
      id: 'pf10',
      category: 'portfolio',
      ko: '내 포트폴리오 리스크를 점수로 알려줘',
      en: 'Score my portfolio\'s risk level',
    ),
    ChatSuggestion(
      id: 'pf11',
      category: 'portfolio',
      ko: '현금 비중을 늘려야 할 타이밍이야?',
      en: 'Is it time to raise my cash position?',
    ),
    ChatSuggestion(
      id: 'pf12',
      category: 'portfolio',
      ko: '내 관심 종목 중 지금 매수 신호인 건?',
      en: 'Which of my watchlist names are a buy now?',
    ),

    // macro
    ChatSuggestion(
      id: 'mc01',
      category: 'macro',
      ko: '이번 CPI 결과가 시장에 어떤 영향을 줘?',
      en: 'How does the latest CPI affect markets?',
    ),
    ChatSuggestion(
      id: 'mc02',
      category: 'macro',
      ko: '연준 금리 인하 가능성 어떻게 봐?',
      en: 'What are the odds of a Fed rate cut?',
    ),
    ChatSuggestion(
      id: 'mc03',
      category: 'macro',
      ko: '국채 금리 흐름을 쉽게 설명해줘',
      en: 'Explain the bond yield trend simply',
    ),
    ChatSuggestion(
      id: 'mc04',
      category: 'macro',
      ko: '달러 강세가 내 종목에 어떤 영향이야?',
      en: 'How does a strong dollar affect my stocks?',
    ),
    ChatSuggestion(
      id: 'mc05',
      category: 'macro',
      ko: '지금 경기 사이클은 어디쯤이야?',
      en: 'Where are we in the economic cycle?',
    ),
    ChatSuggestion(
      id: 'mc06',
      category: 'macro',
      ko: '유가 변동이 증시에 주는 의미는?',
      en: 'What do oil moves mean for stocks?',
    ),
    ChatSuggestion(
      id: 'mc07',
      category: 'macro',
      ko: '이번 주 발표될 경제지표 뭐 있어?',
      en: 'Which economic data drops this week?',
    ),
    ChatSuggestion(
      id: 'mc08',
      category: 'macro',
      ko: '장단기 금리차(수익률 곡선) 지금 어때?',
      en: 'How is the yield curve looking now?',
    ),
    ChatSuggestion(
      id: 'mc09',
      category: 'macro',
      ko: '고용지표가 왜 중요한지 설명해줘',
      en: 'Why do jobs reports matter so much?',
    ),
    ChatSuggestion(
      id: 'mc10',
      category: 'macro',
      ko: '인플레이션이 둔화되면 어떤 종목이 유리해?',
      en: 'Which stocks benefit if inflation cools?',
    ),

    // education
    ChatSuggestion(
      id: 'ed01',
      category: 'education',
      ko: 'PER이 뭐고 어떻게 봐야 해?',
      en: 'What is P/E and how should I read it?',
    ),
    ChatSuggestion(
      id: 'ed02',
      category: 'education',
      ko: 'ETF 초보가 꼭 알아야 할 것은?',
      en: 'ETF basics every beginner should know?',
    ),
    ChatSuggestion(
      id: 'ed03',
      category: 'education',
      ko: '분할매수가 왜 유리한지 알려줘',
      en: 'Why is dollar-cost averaging useful?',
    ),
    ChatSuggestion(
      id: 'ed04',
      category: 'education',
      ko: '손절 기준은 어떻게 잡아야 해?',
      en: 'How should I set a stop-loss?',
    ),
    ChatSuggestion(
      id: 'ed05',
      category: 'education',
      ko: '시가총액과 주가의 차이가 뭐야?',
      en: 'Difference between market cap and price?',
    ),
    ChatSuggestion(
      id: 'ed06',
      category: 'education',
      ko: '배당수익률은 어떻게 계산해?',
      en: 'How is dividend yield calculated?',
    ),
    ChatSuggestion(
      id: 'ed07',
      category: 'education',
      ko: 'RSI 같은 보조지표 쉽게 설명해줘',
      en: 'Explain indicators like RSI simply',
    ),
    ChatSuggestion(
      id: 'ed08',
      category: 'education',
      ko: '성장주와 가치주의 차이가 뭐야?',
      en: 'Growth vs value stocks — what\'s the difference?',
    ),
    ChatSuggestion(
      id: 'ed09',
      category: 'education',
      ko: '공매도가 주가에 어떤 영향을 줘?',
      en: 'How does short selling affect a stock?',
    ),
    ChatSuggestion(
      id: 'ed10',
      category: 'education',
      ko: '실적 발표에서 뭘 봐야 해?',
      en: 'What should I look for in an earnings report?',
    ),
    ChatSuggestion(
      id: 'ed11',
      category: 'education',
      ko: '복리의 힘을 예시로 설명해줘',
      en: 'Explain the power of compounding with an example',
    ),
    ChatSuggestion(
      id: 'ed12',
      category: 'education',
      ko: '환율이 해외주식 투자에 주는 영향은?',
      en: 'How does FX impact investing in US stocks?',
    ),

    // strategy
    ChatSuggestion(
      id: 'st01',
      category: 'strategy',
      ko: '지금 같은 장에서 유효한 전략 알려줘',
      en: 'What strategy works in a market like this?',
    ),
    ChatSuggestion(
      id: 'st02',
      category: 'strategy',
      ko: '장기 투자자에게 맞는 비중 배분은?',
      en: 'A good allocation for a long-term investor?',
    ),
    ChatSuggestion(
      id: 'st03',
      category: 'strategy',
      ko: '하락장에 대비하는 방법 알려줘',
      en: 'How do I prepare for a downturn?',
    ),
    ChatSuggestion(
      id: 'st04',
      category: 'strategy',
      ko: '배당 성장주로 포트폴리오 짜는 법',
      en: 'How to build a dividend-growth portfolio',
    ),
    ChatSuggestion(
      id: 'st05',
      category: 'strategy',
      ko: '리밸런싱은 얼마나 자주 해야 해?',
      en: 'How often should I rebalance?',
    ),
    ChatSuggestion(
      id: 'st06',
      category: 'strategy',
      ko: '적립식 투자 vs 한 번에 투자, 뭐가 나아?',
      en: 'Lump sum vs dollar-cost averaging — which is better?',
    ),
    ChatSuggestion(
      id: 'st07',
      category: 'strategy',
      ko: '변동성 큰 종목 비중은 어떻게 관리해?',
      en: 'How to size positions in volatile names?',
    ),
    ChatSuggestion(
      id: 'st08',
      category: 'strategy',
      ko: '현금흐름 중심 투자 전략 알려줘',
      en: 'A cash-flow focused investing approach?',
    ),

    // risk
    ChatSuggestion(
      id: 'rk01',
      category: 'risk',
      ko: '지금 시장에서 가장 큰 리스크는 뭐야?',
      en: 'What\'s the biggest market risk right now?',
    ),
    ChatSuggestion(
      id: 'rk02',
      category: 'risk',
      ko: '집중 투자의 위험을 설명해줘',
      en: 'Explain the risk of concentration',
    ),
    ChatSuggestion(
      id: 'rk03',
      category: 'risk',
      ko: '하락에 강한 방어주 추천해줘',
      en: 'Suggest defensive stocks for a downturn',
    ),
    ChatSuggestion(
      id: 'rk04',
      category: 'risk',
      ko: '내 손실을 줄이려면 뭘 해야 해?',
      en: 'What can I do to cut my losses?',
    ),
    ChatSuggestion(
      id: 'rk05',
      category: 'risk',
      ko: '레버리지 ETF의 위험성 알려줘',
      en: 'What are the risks of leveraged ETFs?',
    ),
    ChatSuggestion(
      id: 'rk06',
      category: 'risk',
      ko: '지정학 리스크가 증시에 주는 영향은?',
      en: 'How do geopolitical risks hit markets?',
    ),

    // dividend
    ChatSuggestion(
      id: 'dv01',
      category: 'dividend',
      ko: '안정적인 고배당주 추천해줘',
      en: 'Suggest stable high-dividend stocks',
    ),
    ChatSuggestion(
      id: 'dv02',
      category: 'dividend',
      ko: '배당 성장률이 높은 종목은?',
      en: 'Stocks with strong dividend growth?',
    ),
    ChatSuggestion(
      id: 'dv03',
      category: 'dividend',
      ko: '배당락일이 뭔지 알려줘',
      en: 'What is an ex-dividend date?',
    ),
    ChatSuggestion(
      id: 'dv04',
      category: 'dividend',
      ko: '월배당 ETF 어떤 게 있어?',
      en: 'What monthly-dividend ETFs are there?',
    ),
    ChatSuggestion(
      id: 'dv05',
      category: 'dividend',
      ko: '배당주 vs 성장주, 지금은 뭐가 나아?',
      en: 'Dividend vs growth — which fits now?',
    ),

    // earnings
    ChatSuggestion(
      id: 'ea01',
      category: 'earnings',
      ko: '이번 주 실적 발표 주요 종목은?',
      en: 'Key earnings reports this week?',
    ),
    ChatSuggestion(
      id: 'ea02',
      category: 'earnings',
      ko: '실적 서프라이즈가 컸던 종목 알려줘',
      en: 'Which stocks had big earnings surprises?',
    ),
    ChatSuggestion(
      id: 'ea03',
      category: 'earnings',
      ko: '가이던스가 왜 주가를 움직여?',
      en: 'Why does guidance move the stock?',
    ),
    ChatSuggestion(
      id: 'ea04',
      category: 'earnings',
      ko: '실적 시즌에 주의할 점 알려줘',
      en: 'What to watch during earnings season?',
    ),
  ];
}
