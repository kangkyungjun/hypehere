from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta
from app.database import get_db
from app.models import (
    TickerPrice, TickerScore, TickerIndicator, TickerTarget,
    TickerTrendline, TickerInstitution, TickerShort, TickerAIAnalysis,
    TickerAnalystRating,
    CompanyProfile, TickerKeyMetrics, TickerFinancials, TickerDividend,
    TickerCalendar, TickerEarningsHistory,
    TickerDefenseLine, TickerRecommendation, TickerInstitutionalHolder,
    TickerNews
)
from app.schemas import (
    CompleteChartResponse, ChartDataPoint, TrendlineValue,
    AnalystConsensus, AnalystRatingItem,
    CompanyProfileResponse, KeyMetricsResponse, FinancialsResponse, DividendEntry,
    CalendarResponse, EarningsHistoryItem,
    DefenseLineResponse, RecommendationsResponse, InstitutionalHolderResponse,
    NewsItemResponse
)

router = APIRouter()


def _compute_urgency(d_day: int | None) -> str | None:
    """Compute urgency level from D-Day value."""
    if d_day is None:
        return None
    if d_day <= 0:
        return "imminent"   # D-Day or past
    if d_day <= 3:
        return "urgent"     # 1~3 days
    if d_day <= 7:
        return "soon"       # 4~7 days
    if d_day <= 14:
        return "upcoming"   # 8~14 days
    return "scheduled"      # 15+ days


@router.get("/{ticker}", response_model=CompleteChartResponse)
def get_complete_chart_data(
    ticker: str,
    from_date: date = Query(None, alias="from", description="Start date (default: 90 days ago)"),
    to_date: date = Query(None, alias="to", description="End date (default: latest available)"),
    db: Session = Depends(get_db)
):
    """
    **Flutter 앱 차트용 통합 API** ⭐⭐⭐

    1번의 API 호출로 모든 차트 데이터 반환:
    - ✅ OHLCV 가격 (Candlestick 차트)
    - ✅ 점수/시그널 (Score 라인 차트)
    - ✅ 목표가/손절가 (수평선 오버레이)
    - ✅ RSI, MACD (보조 지표 차트)
    - ✅ Bollinger Bands (가격 차트 오버레이)
    - ✅ 추세선 계수 (선형 추세선 렌더링)
    - ✅ 기관/외인 보유율 변화 (별도 차트)
    - ✅ 공매도 데이터 (베어 센티먼트 지표)

    **Example**:
    ```
    GET /api/v1/charts/AAPL?from=2026-01-01&to=2026-02-06
    ```

    **Response**:
    ```json
    {
      "ticker": "AAPL",
      "data": [
        {
          "date": "2026-01-15",
          "open": 182.3, "high": 185.1, "low": 181.9, "close": 184.7,
          "volume": 53200000,
          "score": 85.7, "signal": "BUY",
          "target_price": 190.0, "stop_loss": 178.0,
          "rsi": 67.3, "macd": 2.1, "macd_hist": 0.3,
          "inst_ownership": 65.2, "foreign_ownership": 28.1,
          "short_percent_float": 1.2
        }
      ],
      "high_slope": 0.15, "high_intercept": 180.0,
      "low_slope": 0.12, "low_intercept": 175.0
    }
    ```
    """
    # Date range defaults
    if to_date is None:
        # ⭐ Phase 1: Check ALL tables for latest date (not just ticker_prices)
        # This prevents data loss when ticker_prices lags behind ticker_scores/indicators
        latest_price = db.query(func.max(TickerPrice.date)).scalar()
        latest_score = db.query(func.max(TickerScore.date)).scalar()
        latest_indicator = db.query(func.max(TickerIndicator.date)).scalar()

        # Get maximum date across all tables
        all_dates = [d for d in [latest_price, latest_score, latest_indicator] if d is not None]
        if not all_dates:
            # DB 전체가 비어있으면 빈 구조 반환 (404 금지)
            return CompleteChartResponse(
                ticker=ticker,
                data=[],
                high_slope=None,
                high_intercept=None,
                high_r_squared=None,
                low_slope=None,
                low_intercept=None,
                low_r_squared=None,
            )

        candidate_date = max(all_dates)

        # Validate against trading calendar
        from app.utils.trading_calendar import is_trading_day, get_latest_trading_date

        if is_trading_day(candidate_date):
            to_date = candidate_date
        else:
            # If weekend/holiday, find most recent trading day
            to_date = get_latest_trading_date(db, check_all_tables=True)
            if to_date is None:
                return CompleteChartResponse(
                    ticker=ticker,
                    data=[],
                    high_slope=None,
                    high_intercept=None,
                    high_r_squared=None,
                    low_slope=None,
                    low_intercept=None,
                    low_r_squared=None,
                )

    if from_date is None:
        from_date = to_date - timedelta(days=90)  # 3 months default

    # Validate date range
    if from_date > to_date:
        raise HTTPException(400, "from_date must be before to_date")

    ticker = ticker.upper()

    # ========================================
    # Query all data sources
    # ========================================

    # 1) Prices (required)
    prices = db.query(TickerPrice).filter(
        TickerPrice.ticker == ticker,
        TickerPrice.date >= from_date,
        TickerPrice.date <= to_date
    ).order_by(TickerPrice.date.asc()).all()

    if not prices:
        # 특정 티커에 데이터 없으면 빈 구조 반환 (404 금지)
        return CompleteChartResponse(
            ticker=ticker,
            data=[],
            high_slope=None,
            high_intercept=None,
            high_r_squared=None,
            low_slope=None,
            low_intercept=None,
            low_r_squared=None,
        )

    # 2) Scores (optional)
    scores = db.query(TickerScore).filter(
        TickerScore.ticker == ticker,
        TickerScore.date >= from_date,
        TickerScore.date <= to_date
    ).all()

    # 3) Indicators (optional)
    indicators = db.query(TickerIndicator).filter(
        TickerIndicator.ticker == ticker,
        TickerIndicator.date >= from_date,
        TickerIndicator.date <= to_date
    ).all()

    # 4) Targets (optional)
    targets = db.query(TickerTarget).filter(
        TickerTarget.ticker == ticker,
        TickerTarget.date >= from_date,
        TickerTarget.date <= to_date
    ).all()

    # 5) Institutions (optional)
    institutions = db.query(TickerInstitution).filter(
        TickerInstitution.ticker == ticker,
        TickerInstitution.date >= from_date,
        TickerInstitution.date <= to_date
    ).all()

    # 6) Shorts (optional)
    shorts = db.query(TickerShort).filter(
        TickerShort.ticker == ticker,
        TickerShort.date >= from_date,
        TickerShort.date <= to_date
    ).all()

    # 7) Latest trendline (optional)
    trendline = db.query(TickerTrendline).filter(
        TickerTrendline.ticker == ticker
    ).order_by(TickerTrendline.date.desc()).first()

    # 8) AI Analysis (optional)
    ai_analyses = db.query(TickerAIAnalysis).filter(
        TickerAIAnalysis.ticker == ticker,
        TickerAIAnalysis.date >= from_date,
        TickerAIAnalysis.date <= to_date
    ).all()

    # 9) Latest analyst consensus (from ticker_targets where analyst data exists)
    latest_analyst_target = db.query(TickerTarget).filter(
        TickerTarget.ticker == ticker,
        TickerTarget.analyst_target_mean.isnot(None),
    ).order_by(TickerTarget.date.desc()).first()

    # 10) Analyst ratings (from ticker_analyst_ratings, matching latest analyst date)
    analyst_ratings_objs = []
    if latest_analyst_target:
        analyst_ratings_objs = db.query(TickerAnalystRating).filter(
            TickerAnalystRating.ticker == ticker,
            TickerAnalystRating.date == latest_analyst_target.date,
        ).order_by(TickerAnalystRating.rating_date.desc()).all()

    # 11) Company Profile (ticker PK, non-time-series)
    profile_obj = db.query(CompanyProfile).filter(
        CompanyProfile.ticker == ticker
    ).first()

    # 12) Latest Key Metrics (most recent date)
    metrics_obj = db.query(TickerKeyMetrics).filter(
        TickerKeyMetrics.ticker == ticker
    ).order_by(TickerKeyMetrics.date.desc()).first()

    # 13) Financials (ticker PK, non-time-series)
    financials_obj = db.query(TickerFinancials).filter(
        TickerFinancials.ticker == ticker
    ).first()

    # 14) Recent Dividends (last 8 entries)
    dividend_objs = db.query(TickerDividend).filter(
        TickerDividend.ticker == ticker
    ).order_by(TickerDividend.ex_date.desc()).limit(8).all()

    # 15) Latest calendar (most recent upload)
    calendar_obj = db.query(TickerCalendar).filter(
        TickerCalendar.ticker == ticker
    ).order_by(TickerCalendar.date.desc()).first()

    # 16) Earnings history (last 8 quarters)
    earnings_objs = db.query(TickerEarningsHistory).filter(
        TickerEarningsHistory.ticker == ticker
    ).order_by(TickerEarningsHistory.earnings_date.desc()).limit(8).all()

    # 17) Latest defense lines (most recent upload)
    latest_dl_date = db.query(func.max(TickerDefenseLine.date)).filter(
        TickerDefenseLine.ticker == ticker
    ).scalar()
    defense_line_objs = []
    if latest_dl_date:
        defense_line_objs = db.query(TickerDefenseLine).filter(
            TickerDefenseLine.ticker == ticker,
            TickerDefenseLine.date == latest_dl_date,
        ).order_by(TickerDefenseLine.period.asc()).all()

    # 18) Latest recommendations (most recent upload)
    recommendation_obj = db.query(TickerRecommendation).filter(
        TickerRecommendation.ticker == ticker
    ).order_by(TickerRecommendation.date.desc()).first()

    # 19) Latest institutional holders (most recent upload)
    latest_ih_date = db.query(func.max(TickerInstitutionalHolder.date)).filter(
        TickerInstitutionalHolder.ticker == ticker
    ).scalar()
    institutional_holder_objs = []
    if latest_ih_date:
        institutional_holder_objs = db.query(TickerInstitutionalHolder).filter(
            TickerInstitutionalHolder.ticker == ticker,
            TickerInstitutionalHolder.date == latest_ih_date,
        ).order_by(TickerInstitutionalHolder.pct_held.desc()).limit(20).all()

    # 20) Latest news (5 articles)
    news_objs = db.query(TickerNews).filter(
        TickerNews.ticker == ticker
    ).order_by(TickerNews.published_at.desc()).limit(5).all()

    # ========================================
    # Build lookup dictionaries by date
    # ========================================
    price_dict = {p.date: p for p in prices}
    score_dict = {s.date: s for s in scores}
    indicator_dict = {i.date: i for i in indicators}
    target_dict = {t.date: t for t in targets}
    institution_dict = {inst.date: inst for inst in institutions}
    short_dict = {sh.date: sh for sh in shorts}
    ai_dict = {ai.date: ai for ai in ai_analyses}

    # ========================================
    # ⭐ Phase 2-Debug: Merge all data by date UNION
    # (Temporary fix - allows displaying scores/indicators even without price data)
    # TODO: Remove this after ticker_prices backfill is complete (use price-based loop)
    # ========================================

    # Collect ALL dates from all tables
    all_dates = set()
    all_dates.update(p.date for p in prices)
    all_dates.update(score_dict.keys())
    all_dates.update(indicator_dict.keys())
    all_dates.update(target_dict.keys())
    all_dates.update(institution_dict.keys())
    all_dates.update(short_dict.keys())
    all_dates.update(ai_dict.keys())

    # Sort dates chronologically
    sorted_dates = sorted(all_dates)

    chart_data = []
    for d in sorted_dates:
        price_obj = price_dict.get(d)
        score_obj = score_dict.get(d)
        indicator_obj = indicator_dict.get(d)
        target_obj = target_dict.get(d)
        inst_obj = institution_dict.get(d)
        short_obj = short_dict.get(d)
        ai_obj = ai_dict.get(d)

        chart_data.append(ChartDataPoint(
            date=d,

            # Price (nullable - allows chart points without OHLCV)
            open=price_obj.open if price_obj else None,
            high=price_obj.high if price_obj else None,
            low=price_obj.low if price_obj else None,
            close=price_obj.close if price_obj else None,
            volume=price_obj.volume if price_obj else None,

            # Score
            score=score_obj.score if score_obj else None,
            signal=score_obj.signal if score_obj else None,

            # Target
            target_price=target_obj.target_price if target_obj else None,
            stop_loss=target_obj.stop_loss if target_obj else None,

            # Indicators
            rsi=indicator_obj.rsi if indicator_obj else None,
            mfi=indicator_obj.mfi if indicator_obj else None,
            macd=indicator_obj.macd if indicator_obj else None,
            macd_signal=indicator_obj.macd_signal if indicator_obj else None,
            macd_hist=indicator_obj.macd_hist if indicator_obj else None,
            bb_width=indicator_obj.bb_width if indicator_obj else None,
            bb_upper=indicator_obj.bb_upper if indicator_obj else None,
            bb_lower=indicator_obj.bb_lower if indicator_obj else None,
            bb_middle=indicator_obj.bb_middle if indicator_obj else None,

            # Institutions
            inst_ownership=inst_obj.inst_ownership if inst_obj else None,
            foreign_ownership=inst_obj.foreign_ownership if inst_obj else None,
            insider_ownership=inst_obj.insider_ownership if inst_obj else None,
            inst_chg_1d=inst_obj.inst_chg_1d if inst_obj else None,
            inst_chg_5d=inst_obj.inst_chg_5d if inst_obj else None,
            foreign_chg_1d=inst_obj.foreign_chg_1d if inst_obj else None,
            foreign_chg_5d=inst_obj.foreign_chg_5d if inst_obj else None,

            # Shorts
            short_ratio=short_obj.short_ratio if short_obj else None,
            short_percent_float=short_obj.short_percent_float if short_obj else None,

            # AI Analysis
            ai_probability=ai_obj.probability if ai_obj else None,
            ai_summary=ai_obj.summary if ai_obj else None,
            ai_bullish_reasons=ai_obj.bullish_reasons if ai_obj else None,
            ai_bearish_reasons=ai_obj.bearish_reasons if ai_obj else None,
            ai_final_comment=ai_obj.final_comment if ai_obj else None,
        ))

    # ========================================
    # Return complete chart response
    # ========================================
    # Convert JSONB high_values/low_values to TrendlineValue objects
    high_values_list = None
    low_values_list = None
    if trendline:
        if trendline.high_values:
            high_values_list = [TrendlineValue(**v) for v in trendline.high_values]
        if trendline.low_values:
            low_values_list = [TrendlineValue(**v) for v in trendline.low_values]

    # Build analyst consensus
    analyst_consensus = None
    if latest_analyst_target and latest_analyst_target.analyst_target_mean is not None:
        analyst_consensus = AnalystConsensus(
            mean=latest_analyst_target.analyst_target_mean,
            high=latest_analyst_target.analyst_target_high,
            low=latest_analyst_target.analyst_target_low,
            count=latest_analyst_target.analyst_count,
            recommendation=latest_analyst_target.recommendation,
        )

    # Build analyst ratings list
    analyst_ratings_list = [
        AnalystRatingItem(
            date=str(r.rating_date) if r.rating_date else None,
            status=r.status,
            firm=r.firm,
            rating=r.rating,
            target_from=r.target_from,
            target_to=r.target_to,
        ) for r in analyst_ratings_objs
    ] or None

    return CompleteChartResponse(
        ticker=ticker,
        data=chart_data,

        # Trendlines (latest calculation)
        high_slope=trendline.high_slope if trendline else None,
        high_intercept=trendline.high_intercept if trendline else None,
        high_r_squared=trendline.high_r_squared if trendline else None,
        high_values=high_values_list,
        low_slope=trendline.low_slope if trendline else None,
        low_intercept=trendline.low_intercept if trendline else None,
        low_r_squared=trendline.low_r_squared if trendline else None,
        low_values=low_values_list,

        # Analyst data (latest snapshot)
        analyst_consensus=analyst_consensus,
        analyst_ratings=analyst_ratings_list,

        # Fundamentals (latest snapshot)
        profile=CompanyProfileResponse(
            long_name=profile_obj.long_name,
            industry=profile_obj.industry,
            website=profile_obj.website,
            country=profile_obj.country,
            employees=profile_obj.employees,
            summary=profile_obj.summary,
        ) if profile_obj else None,
        key_metrics=KeyMetricsResponse(
            market_cap=metrics_obj.market_cap,
            pe=metrics_obj.pe,
            forward_pe=metrics_obj.forward_pe,
            peg=metrics_obj.peg,
            pb=metrics_obj.pb,
            ps=metrics_obj.ps,
            ev_revenue=metrics_obj.ev_revenue,
            ev_ebitda=metrics_obj.ev_ebitda,
            profit_margin=metrics_obj.profit_margin,
            operating_margin=metrics_obj.operating_margin,
            gross_margin=metrics_obj.gross_margin,
            roe=metrics_obj.roe,
            roa=metrics_obj.roa,
            debt_to_equity=metrics_obj.debt_to_equity,
            current_ratio=metrics_obj.current_ratio,
            beta=metrics_obj.beta,
            dividend_yield=metrics_obj.dividend_yield,
            payout_ratio=metrics_obj.payout_ratio,
            earnings_growth=metrics_obj.earnings_growth,
            revenue_growth=metrics_obj.revenue_growth,
        ) if metrics_obj else None,
        financials=FinancialsResponse(
            latest_quarter=financials_obj.latest_quarter,
            income=financials_obj.income,
            balance_sheet=financials_obj.balance_sheet,
            cash_flow=financials_obj.cash_flow,
        ) if financials_obj else None,
        dividends=[
            DividendEntry(ex_date=str(d.ex_date), amount=d.amount)
            for d in dividend_objs
        ] or None,
        calendar=CalendarResponse(
            next_earnings_date=str(calendar_obj.next_earnings_date) if calendar_obj.next_earnings_date else None,
            next_earnings_date_end=str(calendar_obj.next_earnings_date_end) if calendar_obj.next_earnings_date_end else None,
            earnings_confirmed=calendar_obj.earnings_confirmed,
            d_day=calendar_obj.d_day,
            urgency=_compute_urgency(calendar_obj.d_day),
            earnings_days_remaining=(calendar_obj.next_earnings_date - date.today()).days if calendar_obj.next_earnings_date else None,
            ex_dividend_date=str(calendar_obj.ex_dividend_date) if calendar_obj.ex_dividend_date else None,
            dividend_date=str(calendar_obj.dividend_date) if calendar_obj.dividend_date else None,
            earnings_estimate={
                "high": calendar_obj.earnings_high,
                "low": calendar_obj.earnings_low,
                "avg": calendar_obj.earnings_avg,
            } if calendar_obj.earnings_avg else None,
            revenue_estimate={
                "high": calendar_obj.revenue_high,
                "low": calendar_obj.revenue_low,
                "avg": calendar_obj.revenue_avg,
            } if calendar_obj.revenue_avg else None,
        ) if calendar_obj else None,
        earnings_history=[
            EarningsHistoryItem(
                date=str(e.earnings_date),
                eps_estimate=e.eps_estimate,
                reported_eps=e.reported_eps,
                surprise_pct=e.surprise_pct,
            ) for e in reversed(earnings_objs)
        ] or None,

        # Phase 2: New data sources
        defense_lines=[
            DefenseLineResponse(
                period=dl.period,
                price=dl.price,
                label=dl.label,
                distance_pct=dl.distance_pct,
            ) for dl in defense_line_objs
        ] or None,
        recommendations=RecommendationsResponse(
            strong_buy=recommendation_obj.strong_buy,
            buy=recommendation_obj.buy,
            hold=recommendation_obj.hold,
            sell=recommendation_obj.sell,
            strong_sell=recommendation_obj.strong_sell,
            consensus_score=recommendation_obj.consensus_score,
        ) if recommendation_obj else None,
        institutional_holders=[
            InstitutionalHolderResponse(
                holder=ih.holder,
                pct_held=ih.pct_held,
                pct_change=ih.pct_change,
            ) for ih in institutional_holder_objs
        ] or None,

        # News (latest 5)
        news=[
            NewsItemResponse(
                date=n.date,
                ticker=n.ticker,
                title=n.title,
                source=n.source,
                source_url=n.source_url,
                published_at=n.published_at,
                ai_summary=n.ai_summary,
                sentiment_score=n.sentiment_score,
                sentiment_grade=n.sentiment_grade,
                sentiment_label=n.sentiment_label,
                future_event=n.future_event,
            ) for n in news_objs
        ] or None,
    )
