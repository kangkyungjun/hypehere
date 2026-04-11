from fastapi import APIRouter, Header, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date, datetime, timedelta
import hashlib
import logging

from app.database import get_db
from app.models import (
    TickerScore, TickerPrice, TickerIndicator, TickerTarget,
    TickerTrendline, TickerInstitution, TickerShort, TickerAIAnalysis,
    TickerAnalystRating, Ticker,
    CompanyProfile, TickerKeyMetrics, TickerFinancials, TickerDividend,
    MacroIndicator, MacroChartData, TickerCalendar, TickerEarningsHistory,
    TickerDefenseLine, TickerRecommendation, TickerInstitutionalHolder,
    EarningsWeekEvent, MarketIndex, MarketIndexChart, StockMembership,
    TickerNews, AccountWithdrawal, MarketCalendarEvent,
    # Phase 1: AI 투자 브레인
    UserPortfolio, PortfolioAdvice, PortfolioSummary, UserAlert, ExchangeRate,
    AISignal, AIMessage,
    # 실시간 분석 파이프라인
    AnalysisRequest,
)
from app.schemas import (
    IngestPayload, ExtendedItemIngest, MacroIngestPayload,
    EarningsWeekIngestPayload, MarketIndicesIngestPayload,
    NewsIngestPayload, NewsIngestResponse,
    WithdrawalRequest, WithdrawalResponse,
    ScheduledNotificationRequest,
    MarketCalendarIngestPayload,
    # Phase 1: AI 투자 브레인
    PortfolioAdviceIngestPayload, PortfolioSummaryIngestPayload,
    AlertsIngestPayload, ExchangeRateIngestPayload,
    UserPortfolioInternal,
    AISignalsIngestPayload, AIMessagesIngestPayload,
    # 실시간 분석 파이프라인
    AnalysisRequestResponse, AnalysisQueueCompleteRequest,
)
from app.config import settings
from app.utils.trading_calendar import is_trading_day
from app.services.fcm_service import (
    process_score_notifications,
    process_news_notifications,
    process_breaking_news_notification,
    process_bullish_surge_notifications,
    process_daily_summary_notification,
    process_morning_briefing,
    process_closing_report,
    process_market_open,
    send_portfolio_advice_notification,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/internal/ingest",
    tags=["Internal"],
)

EXPECTED_API_KEY = settings.ANALYTICS_API_KEY


# ============================
# API Key 검증
# ============================
def verify_api_key(x_api_key: str = Header(None)):
    """
    Verify API key for internal endpoints.

    Raises:
        HTTPException: 403 if API key is invalid or missing
        HTTPException: 500 if server API key is not configured
    """
    if EXPECTED_API_KEY is None:
        raise HTTPException(
            status_code=500,
            detail="Server API key not configured"
        )

    if x_api_key != EXPECTED_API_KEY:
        raise HTTPException(
            status_code=403,
            detail="Invalid API key"
        )


# ============================
# 거시경제 지표 Ingest 엔드포인트
# ============================
@router.post("/macro", dependencies=[Depends(verify_api_key)])
def ingest_macro_indicators(payload: MacroIngestPayload, db: Session = Depends(get_db)):
    """거시경제 지표 + 시장레이더/머니프린팅 신호 + 차트 시계열 업로드 (Mac mini → AWS)"""
    ingest_date = datetime.strptime(payload.date, "%Y-%m-%d").date()
    upserted = 0
    chart_points = 0

    # ==========================================
    # 1) 기존 indicators (FRED 지표) 처리
    # ==========================================
    if payload.indicators:
        for code, item in payload.indicators.items():
            prev = db.query(MacroIndicator).filter(
                MacroIndicator.indicator_code == code,
                MacroIndicator.date < ingest_date,
            ).order_by(MacroIndicator.date.desc()).first()

            previous_value = prev.value if prev else None
            change_pct = (
                round((item.value - previous_value) / previous_value * 100, 4)
                if previous_value else None
            )

            obs_date = (
                datetime.strptime(item.observation_date, "%Y-%m-%d").date()
                if item.observation_date else None
            )

            obj = db.query(MacroIndicator).filter(
                MacroIndicator.date == ingest_date,
                MacroIndicator.indicator_code == code,
            ).first()

            if obj:
                obj.value = item.value
                obj.indicator_name = item.name
                obj.observation_date = obs_date
                obj.previous_value = previous_value
                obj.change_pct = change_pct
                obj.risk_level = item.risk_level
                obj.signal_message = item.signal_message
            else:
                db.add(MacroIndicator(
                    date=ingest_date, indicator_code=code,
                    indicator_name=item.name, observation_date=obs_date,
                    value=item.value, previous_value=previous_value,
                    change_pct=change_pct, source='FRED',
                    risk_level=item.risk_level,
                    signal_message=item.signal_message,
                ))
            upserted += 1

    # ==========================================
    # 2) signals (시장레이더/머니프린팅) 처리
    # ==========================================
    if payload.signals:
        for code, sig in payload.signals.items():
            prev = db.query(MacroIndicator).filter(
                MacroIndicator.indicator_code == code,
                MacroIndicator.date < ingest_date,
            ).order_by(MacroIndicator.date.desc()).first()

            previous_value = prev.value if prev else None
            change_pct = (
                round((sig.value - previous_value) / previous_value * 100, 4)
                if previous_value and previous_value != 0 else None
            )

            obj = db.query(MacroIndicator).filter(
                MacroIndicator.date == ingest_date,
                MacroIndicator.indicator_code == code,
            ).first()

            if obj:
                obj.value = sig.value
                obj.risk_level = sig.risk_level
                obj.signal_message = sig.signal_message
                obj.liquidity_status = sig.liquidity_status
                obj.previous_value = previous_value
                obj.change_pct = change_pct
            else:
                db.add(MacroIndicator(
                    date=ingest_date, indicator_code=code,
                    value=sig.value,
                    risk_level=sig.risk_level,
                    signal_message=sig.signal_message,
                    liquidity_status=sig.liquidity_status,
                    previous_value=previous_value,
                    change_pct=change_pct,
                    source='SIGNAL',
                ))
            upserted += 1

    # ==========================================
    # 3) charts (시계열 차트 데이터) 처리
    # ==========================================
    if payload.charts:
        for series_id, points in payload.charts.items():
            for pt in points:
                pt_date = datetime.strptime(pt.date, "%Y-%m-%d").date()
                obj = db.query(MacroChartData).filter(
                    MacroChartData.series_id == series_id,
                    MacroChartData.date == pt_date,
                ).first()

                if obj:
                    obj.value = pt.value
                else:
                    db.add(MacroChartData(
                        series_id=series_id,
                        date=pt_date,
                        value=pt.value,
                    ))
                chart_points += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.macro_indicators "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.execute(text(
        "DELETE FROM analytics.macro_chart_data "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted, "chart_points": chart_points}


# ============================
# 점수 Ingest 엔드포인트
# ============================
@router.post("/scores", dependencies=[Depends(verify_api_key)])
def ingest_scores(payload: IngestPayload, db: Session = Depends(get_db)):
    """
    Ingest ticker scores from Mac mini.

    **Internal API** - Not for mobile app use.

    Payload format:
    ```json
    {
        "date": "2026-02-03",
        "count": 503,
        "items": [
            {
                "date": "2026-02-03",
                "ticker": "AAPL",
                "score": 85.7,
                "signal": "BUY"
            }
        ]
    }
    ```

    Features:
    - UPSERT logic (ticker + date as unique key)
    - Auto-delete data older than 3 years
    - Safe for duplicate uploads

    Returns:
    ```json
    {
        "status": "ok",
        "received": 503,
        "upserted": 503
    }
    ```
    """
    items = payload.items
    upserted = 0

    for item in items:
        # Determine payload type (extended nested vs simple flat)
        is_extended = isinstance(item, ExtendedItemIngest)

        # Extract common fields
        ticker = item.ticker
        score_date = item.date

        # Debug: Log type detection and AI data presence
        logger.info(
            f"Processing {ticker} on {score_date}: "
            f"is_extended={is_extended}, has_ai_analysis={hasattr(item, 'ai_analysis')}"
        )

        # ==========================================
        # Trading Day Validation (skip weekends/holidays)
        # ==========================================
        if not is_trading_day(score_date):
            logger.warning(
                f"Skipping non-trading day data: {ticker} on {score_date} "
                f"({'weekend' if score_date.weekday() >= 5 else 'holiday'})"
            )
            continue  # Skip this item, don't increment upserted count

        # ==========================================
        # 1) UPSERT to ticker_prices (OHLCV data)
        # ==========================================
        # Extract price data based on payload type
        if is_extended:
            open_price = item.price.open
            high_price = item.price.high
            low_price = item.price.low
            close_price = item.price.close
            volume = item.price.volume
            # Treemap market data (nested)
            change_pct = item.market_data.change_pct if item.market_data else None
            trading_value = item.market_data.trading_value if item.market_data else None
        else:
            # Simple flat structure (backward compatibility)
            open_price = item.open
            high_price = item.high
            low_price = item.low
            close_price = item.close
            volume = item.volume
            # Treemap market data (flat)
            change_pct = getattr(item, 'change_pct', None)
            trading_value = getattr(item, 'trading_value', None)

        price_obj = (
            db.query(TickerPrice)
            .filter(
                TickerPrice.ticker == ticker,
                TickerPrice.date == score_date,
            )
            .first()
        )

        if price_obj:
            # Update existing price record
            price_obj.open = open_price
            price_obj.high = high_price
            price_obj.low = low_price
            price_obj.close = close_price
            price_obj.volume = volume
            price_obj.change_pct = change_pct
            price_obj.trading_value = trading_value
        else:
            # Insert new price record
            price_obj = TickerPrice(
                ticker=ticker,
                date=score_date,
                open=open_price,
                high=high_price,
                low=low_price,
                close=close_price,
                volume=volume,
                change_pct=change_pct,
                trading_value=trading_value,
            )
            db.add(price_obj)

        # ==========================================
        # 2) UPSERT to ticker_scores (score data)
        # ==========================================
        # Extract score data based on payload type
        if is_extended:
            score_value = item.score.value
            signal = item.score.signal
        else:
            # Simple flat structure (backward compatibility)
            score_value = item.score
            signal = item.signal

        # Process score (always present in both formats)
        score_obj = (
            db.query(TickerScore)
            .filter(
                TickerScore.ticker == ticker,
                TickerScore.date == score_date,
            )
            .first()
        )

        if score_obj:
            # Update existing score record
            score_obj.score = score_value
            score_obj.signal = signal
        else:
            # Insert new score record
            score_obj = TickerScore(
                ticker=ticker,
                date=score_date,
                score=score_value,
                signal=signal,
            )
            db.add(score_obj)

        # ==========================================
        # 2.5) UPSERT to tickers (metadata: name_en, name_ko)
        # ==========================================
        # Extract ticker names if provided (optional fields)
        name_en = getattr(item, 'name_en', None)
        name_ko = getattr(item, 'name_ko', None)
        sector = getattr(item, 'sector', None)
        sub_industry = getattr(item, 'sub_industry', None)

        if name_en or sector or sub_industry:
            ticker_obj = (
                db.query(Ticker)
                .filter(Ticker.ticker == ticker)
                .first()
            )

            if ticker_obj:
                # Update existing ticker metadata
                if name_en:
                    ticker_obj.name = name_en
                    ticker_obj.ticker_name = name_en  # For search ILIKE queries

                # Update Korean name in JSONB metadata
                if name_ko:
                    existing_metadata = ticker_obj.extra_data or {}
                    existing_metadata['name_ko'] = name_ko
                    ticker_obj.extra_data = existing_metadata

                # Update sector/sub_industry only if provided (preserve existing)
                if sector is not None:
                    ticker_obj.sector = sector
                if sub_industry is not None:
                    ticker_obj.sub_industry = sub_industry
            else:
                # Insert new ticker metadata
                metadata = {'name_ko': name_ko} if name_ko else None
                ticker_obj = Ticker(
                    ticker=ticker,
                    name=name_en,
                    ticker_name=name_en if name_en else None,  # For search
                    sector=sector,
                    sub_industry=sub_industry,
                    extra_data=metadata,
                )
                db.add(ticker_obj)

        # ==========================================
        # 2.6) Sync stock_membership (index membership tags)
        # ==========================================
        membership = getattr(item, 'membership', None) or []
        if membership:
            db.query(StockMembership).filter(StockMembership.ticker == ticker).delete()
            for code in membership:
                db.add(StockMembership(ticker=ticker, index_code=code))

        # ==========================================
        # 3) UPSERT to ticker_indicators (RSI, MACD, BB)
        # ==========================================
        # Extract indicator data based on payload type
        if is_extended:
            # Extended nested structure
            indicators = item.indicators
            rsi = indicators.rsi
            macd = indicators.macd
            macd_signal = indicators.macd_signal
            macd_hist = indicators.macd_hist
            bb_upper = indicators.bb_upper
            bb_middle = indicators.bb_middle
            bb_lower = indicators.bb_lower
            bb_width = indicators.bb_width
            mfi = indicators.mfi
            has_indicators = True  # Extended format always includes indicators
        else:
            # Simple flat structure (backward compatibility)
            rsi = item.rsi
            macd = item.macd
            macd_signal = item.macd_signal
            macd_hist = item.macd_hist
            bb_width = item.bb_width
            bb_upper = item.bb_upper
            bb_lower = item.bb_lower
            bb_middle = item.bb_middle
            mfi = item.mfi
            # Only save if at least one indicator is present
            has_indicators = any([rsi, macd, bb_width, mfi])

        if has_indicators:
            indicator_obj = (
                db.query(TickerIndicator)
                .filter(
                    TickerIndicator.ticker == ticker,
                    TickerIndicator.date == score_date,
                )
                .first()
            )

            if indicator_obj:
                # Update existing indicator record
                indicator_obj.rsi = rsi
                indicator_obj.macd = macd
                indicator_obj.macd_signal = macd_signal
                indicator_obj.macd_hist = macd_hist
                indicator_obj.bb_width = bb_width
                indicator_obj.bb_upper = bb_upper
                indicator_obj.bb_lower = bb_lower
                indicator_obj.bb_middle = bb_middle
                indicator_obj.mfi = mfi
            else:
                # Insert new indicator record
                indicator_obj = TickerIndicator(
                    ticker=ticker,
                    date=score_date,
                    rsi=rsi,
                    macd=macd,
                    macd_signal=macd_signal,
                    macd_hist=macd_hist,
                    bb_width=bb_width,
                    bb_upper=bb_upper,
                    bb_lower=bb_lower,
                    bb_middle=bb_middle,
                    mfi=mfi,
                )
                db.add(indicator_obj)

        # ==========================================
        # 4) UPSERT to ticker_ai_analysis (AI predictions)
        # ==========================================
        # AI analysis only available in extended format
        # Robust detection: check both isinstance and hasattr to handle Union type edge cases
        if is_extended and hasattr(item, 'ai_analysis'):
            ai_analysis = item.ai_analysis

            ai_obj = (
                db.query(TickerAIAnalysis)
                .filter(
                    TickerAIAnalysis.ticker == ticker,
                    TickerAIAnalysis.date == score_date,
                )
                .first()
            )

            if ai_obj:
                # Update existing AI analysis record
                ai_obj.probability = ai_analysis.probability
                ai_obj.summary = ai_analysis.summary
                ai_obj.bullish_reasons = ai_analysis.bullish_reasons
                ai_obj.bearish_reasons = ai_analysis.bearish_reasons
                ai_obj.final_comment = ai_analysis.final_comment
            else:
                # Insert new AI analysis record
                ai_obj = TickerAIAnalysis(
                    ticker=ticker,
                    date=score_date,
                    probability=ai_analysis.probability,
                    summary=ai_analysis.summary,
                    bullish_reasons=ai_analysis.bullish_reasons,
                    bearish_reasons=ai_analysis.bearish_reasons,
                    final_comment=ai_analysis.final_comment,
                )
                db.add(ai_obj)

            # Debug: Log successful AI analysis storage
            logger.info(
                f"Stored AI analysis for {ticker} on {score_date}: "
                f"probability={ai_analysis.probability:.3f}, summary='{ai_analysis.summary[:50]}...'"
            )

        # ==========================================
        # 5) UPSERT to ticker_trendlines (trendline coefficients + values)
        # ==========================================
        # Extract trendline data based on payload type
        if is_extended and hasattr(item, 'trend') and item.trend:
            # Extended nested structure with trend.high/low.slope/intercept/r_sq/values
            trend = item.trend
            high_slope = trend.high.slope if trend.high else None
            high_intercept = trend.high.intercept if trend.high else None
            high_r_squared = trend.high.r_sq if trend.high else None
            high_values = [v.model_dump() for v in trend.high.values] if (trend.high and trend.high.values) else None

            low_slope = trend.low.slope if trend.low else None
            low_intercept = trend.low.intercept if trend.low else None
            low_r_squared = trend.low.r_sq if trend.low else None
            low_values = [v.model_dump() for v in trend.low.values] if (trend.low and trend.low.values) else None
        else:
            # Simple flat structure (backward compatibility) - no values
            high_slope = getattr(item, 'high_slope', None)
            high_intercept = getattr(item, 'high_intercept', None)
            high_r_squared = getattr(item, 'high_r_squared', None)
            high_values = None

            low_slope = getattr(item, 'low_slope', None)
            low_intercept = getattr(item, 'low_intercept', None)
            low_r_squared = getattr(item, 'low_r_squared', None)
            low_values = None

        if high_slope is not None or low_slope is not None:
            trendline_obj = (
                db.query(TickerTrendline)
                .filter(
                    TickerTrendline.ticker == ticker,
                    TickerTrendline.date == score_date,
                )
                .first()
            )

            if trendline_obj:
                # Update existing trendline record
                trendline_obj.high_slope = high_slope
                trendline_obj.high_intercept = high_intercept
                trendline_obj.high_r_squared = high_r_squared
                trendline_obj.high_values = high_values
                trendline_obj.low_slope = low_slope
                trendline_obj.low_intercept = low_intercept
                trendline_obj.low_r_squared = low_r_squared
                trendline_obj.low_values = low_values
                trendline_obj.trend_period_days = getattr(item, 'trend_period_days', 30)
            else:
                # Insert new trendline record
                trendline_obj = TickerTrendline(
                    ticker=ticker,
                    date=score_date,
                    high_slope=high_slope,
                    high_intercept=high_intercept,
                    high_r_squared=high_r_squared,
                    high_values=high_values,
                    low_slope=low_slope,
                    low_intercept=low_intercept,
                    low_r_squared=low_r_squared,
                    low_values=low_values,
                    trend_period_days=getattr(item, 'trend_period_days', 30),
                )
                db.add(trendline_obj)

        # ==========================================
        # 6) UPSERT to ticker_targets (target/stop)
        # ==========================================
        # Handle Extended format strategy (nested object)
        if is_extended and hasattr(item, 'strategy') and item.strategy:
            target_obj = (
                db.query(TickerTarget)
                .filter(
                    TickerTarget.ticker == ticker,
                    TickerTarget.date == score_date,
                )
                .first()
            )

            # Extract analyst consensus if present
            consensus = item.strategy.analyst_consensus

            if target_obj:
                # Update existing target record
                target_obj.target_price = item.strategy.target_price
                target_obj.stop_loss = item.strategy.stop_loss
                target_obj.risk_reward_ratio = item.strategy.risk_reward_ratio
                target_obj.analyst_target_mean = consensus.mean if consensus else None
                target_obj.analyst_target_high = consensus.high if consensus else None
                target_obj.analyst_target_low = consensus.low if consensus else None
                target_obj.analyst_count = consensus.count if consensus else None
                target_obj.recommendation = consensus.recommendation if consensus else None
            else:
                # Insert new target record
                target_obj = TickerTarget(
                    ticker=ticker,
                    date=score_date,
                    target_price=item.strategy.target_price,
                    stop_loss=item.strategy.stop_loss,
                    risk_reward_ratio=item.strategy.risk_reward_ratio,
                    analyst_target_mean=consensus.mean if consensus else None,
                    analyst_target_high=consensus.high if consensus else None,
                    analyst_target_low=consensus.low if consensus else None,
                    analyst_count=consensus.count if consensus else None,
                    recommendation=consensus.recommendation if consensus else None,
                )
                db.add(target_obj)

            # ==========================================
            # 6.5) UPSERT to ticker_analyst_ratings (institutional ratings)
            # ==========================================
            if item.strategy.analyst_ratings:
                # Delete existing ratings for this ticker+date, then re-insert
                db.query(TickerAnalystRating).filter(
                    TickerAnalystRating.ticker == ticker,
                    TickerAnalystRating.date == score_date,
                ).delete()

                for r in item.strategy.analyst_ratings:
                    # Parse rating_date string to date object
                    rating_date_val = None
                    if r.date:
                        try:
                            rating_date_val = datetime.strptime(r.date, "%Y-%m-%d").date()
                        except ValueError:
                            logger.warning(f"Invalid rating_date format: {r.date}")
                            continue

                    if rating_date_val and r.firm:
                        rating_obj = TickerAnalystRating(
                            ticker=ticker,
                            date=score_date,
                            rating_date=rating_date_val,
                            status=r.status,
                            firm=r.firm,
                            rating=r.rating,
                            target_from=r.target_from,
                            target_to=r.target_to,
                        )
                        db.add(rating_obj)

            # ==========================================
            # 6.6) UPSERT to ticker_defense_lines (이평선 방어선)
            # ==========================================
            if item.strategy.defense_lines:
                # Delete existing defense lines for this ticker+date, then re-insert
                db.query(TickerDefenseLine).filter(
                    TickerDefenseLine.ticker == ticker,
                    TickerDefenseLine.date == score_date,
                ).delete()

                for dl in item.strategy.defense_lines:
                    db.add(TickerDefenseLine(
                        ticker=ticker,
                        date=score_date,
                        period=dl.period,
                        price=dl.price,
                        label=dl.label,
                        distance_pct=dl.distance_pct,
                    ))

            # ==========================================
            # 6.7) UPSERT to ticker_recommendations (의견분포)
            # ==========================================
            if item.strategy.recommendations:
                recs = item.strategy.recommendations
                rec_obj = db.query(TickerRecommendation).filter(
                    TickerRecommendation.ticker == ticker,
                    TickerRecommendation.date == score_date,
                ).first()

                if rec_obj:
                    rec_obj.strong_buy = recs.strong_buy
                    rec_obj.buy = recs.buy
                    rec_obj.hold = recs.hold
                    rec_obj.sell = recs.sell
                    rec_obj.strong_sell = recs.strong_sell
                    rec_obj.consensus_score = recs.consensus_score
                else:
                    db.add(TickerRecommendation(
                        ticker=ticker,
                        date=score_date,
                        strong_buy=recs.strong_buy,
                        buy=recs.buy,
                        hold=recs.hold,
                        sell=recs.sell,
                        strong_sell=recs.strong_sell,
                        consensus_score=recs.consensus_score,
                    ))

        # ==========================================
        # 6.8) UPSERT ownership data (Extended format)
        # ==========================================
        if is_extended and hasattr(item, 'ownership') and item.ownership:
            own = item.ownership
            inst_obj = db.query(TickerInstitution).filter(
                TickerInstitution.ticker == ticker,
                TickerInstitution.date == score_date,
            ).first()

            if inst_obj:
                if own.institution is not None:
                    inst_obj.inst_ownership = own.institution
                if own.insider is not None:
                    inst_obj.insider_ownership = own.insider
            else:
                inst_obj = TickerInstitution(
                    ticker=ticker,
                    date=score_date,
                    inst_ownership=own.institution,
                    insider_ownership=own.insider,
                )
                db.add(inst_obj)

            # Also update short_float in ticker_shorts if provided
            if own.short_float is not None:
                short_obj = db.query(TickerShort).filter(
                    TickerShort.ticker == ticker,
                    TickerShort.date == score_date,
                ).first()

                if short_obj:
                    short_obj.short_percent_float = own.short_float
                else:
                    db.add(TickerShort(
                        ticker=ticker,
                        date=score_date,
                        short_percent_float=own.short_float,
                    ))

        # ==========================================
        # 6.9) UPSERT institutional_holders (Extended format)
        # ==========================================
        if is_extended and hasattr(item, 'institutional_holders') and item.institutional_holders:
            # Delete existing holders for this ticker+date, then re-insert
            db.query(TickerInstitutionalHolder).filter(
                TickerInstitutionalHolder.ticker == ticker,
                TickerInstitutionalHolder.date == score_date,
            ).delete()

            for ih in item.institutional_holders:
                db.add(TickerInstitutionalHolder(
                    ticker=ticker,
                    date=score_date,
                    holder=ih.holder,
                    pct_held=ih.pct_held,
                    pct_change=ih.pct_change,
                ))

        # Handle Simple flat format (backward compatibility)
        elif not is_extended:
            # Simple flat format may have optional target fields
            target_price = getattr(item, 'target_price', None)
            stop_loss = getattr(item, 'stop_loss', None)
            risk_reward_ratio = getattr(item, 'risk_reward_ratio', None)

            if target_price is not None or stop_loss is not None:
                target_obj = (
                    db.query(TickerTarget)
                    .filter(
                        TickerTarget.ticker == ticker,
                        TickerTarget.date == score_date,
                    )
                    .first()
                )

                if target_obj:
                    # Update existing target record
                    target_obj.target_price = target_price
                    target_obj.stop_loss = stop_loss
                    target_obj.risk_reward_ratio = risk_reward_ratio
                else:
                    # Insert new target record
                    target_obj = TickerTarget(
                        ticker=ticker,
                        date=score_date,
                        target_price=target_price,
                        stop_loss=stop_loss,
                        risk_reward_ratio=risk_reward_ratio,
                    )
                    db.add(target_obj)

            # ==========================================
            # 7) UPSERT to ticker_institutions (inst/foreign ownership)
            # ==========================================
            inst_ownership = getattr(item, 'inst_ownership', None)
            foreign_ownership = getattr(item, 'foreign_ownership', None)

            if inst_ownership is not None or foreign_ownership is not None:
                inst_obj = (
                    db.query(TickerInstitution)
                    .filter(
                        TickerInstitution.ticker == ticker,
                        TickerInstitution.date == score_date,
                    )
                    .first()
                )

                if inst_obj:
                    # Update existing institution record
                    inst_obj.inst_ownership = inst_ownership
                    inst_obj.foreign_ownership = foreign_ownership
                    inst_obj.inst_chg_1d = getattr(item, 'inst_chg_1d', None)
                    inst_obj.inst_chg_5d = getattr(item, 'inst_chg_5d', None)
                    inst_obj.inst_chg_15d = getattr(item, 'inst_chg_15d', None)
                    inst_obj.inst_chg_30d = getattr(item, 'inst_chg_30d', None)
                    inst_obj.foreign_chg_1d = getattr(item, 'foreign_chg_1d', None)
                    inst_obj.foreign_chg_5d = getattr(item, 'foreign_chg_5d', None)
                    inst_obj.foreign_chg_15d = getattr(item, 'foreign_chg_15d', None)
                    inst_obj.foreign_chg_30d = getattr(item, 'foreign_chg_30d', None)
                else:
                    # Insert new institution record
                    inst_obj = TickerInstitution(
                        ticker=ticker,
                        date=score_date,
                        inst_ownership=inst_ownership,
                        foreign_ownership=foreign_ownership,
                        inst_chg_1d=getattr(item, 'inst_chg_1d', None),
                        inst_chg_5d=getattr(item, 'inst_chg_5d', None),
                        inst_chg_15d=getattr(item, 'inst_chg_15d', None),
                        inst_chg_30d=getattr(item, 'inst_chg_30d', None),
                        foreign_chg_1d=getattr(item, 'foreign_chg_1d', None),
                        foreign_chg_5d=getattr(item, 'foreign_chg_5d', None),
                        foreign_chg_15d=getattr(item, 'foreign_chg_15d', None),
                        foreign_chg_30d=getattr(item, 'foreign_chg_30d', None),
                    )
                    db.add(inst_obj)

            # ==========================================
            # 8) UPSERT to ticker_shorts (short selling data)
            # ==========================================
            short_ratio = getattr(item, 'short_ratio', None)
            short_percent_float = getattr(item, 'short_percent_float', None)

            if short_ratio is not None or short_percent_float is not None:
                short_obj = (
                    db.query(TickerShort)
                    .filter(
                        TickerShort.ticker == ticker,
                        TickerShort.date == score_date,
                    )
                    .first()
                )

                if short_obj:
                    # Update existing short record
                    short_obj.short_ratio = short_ratio
                    short_obj.short_percent_float = short_percent_float
                    short_obj.short_percent_shares = getattr(item, 'short_percent_shares', None)
                    short_obj.short_interest = getattr(item, 'short_interest', None)
                else:
                    # Insert new short record
                    short_obj = TickerShort(
                        ticker=ticker,
                        date=score_date,
                        short_ratio=short_ratio,
                        short_percent_float=short_percent_float,
                        short_percent_shares=getattr(item, 'short_percent_shares', None),
                        short_interest=getattr(item, 'short_interest', None),
                    )
                    db.add(short_obj)

        # ==========================================
        # 9) UPSERT fundamentals (Extended format only)
        # ==========================================
        if is_extended and hasattr(item, 'fundamentals') and item.fundamentals:
            fund = item.fundamentals

            # 9a) Company Profile (ticker PK, non-time-series)
            if fund.profile:
                profile_obj = db.query(CompanyProfile).filter(
                    CompanyProfile.ticker == ticker
                ).first()
                if profile_obj:
                    for field in ['long_name', 'industry', 'website', 'country', 'employees', 'summary']:
                        val = getattr(fund.profile, field, None)
                        if val is not None:
                            setattr(profile_obj, field, val)
                else:
                    profile_obj = CompanyProfile(
                        ticker=ticker,
                        **fund.profile.model_dump(exclude_none=True)
                    )
                    db.add(profile_obj)

            # 9b) Key Metrics (date + ticker PK, time-series)
            if fund.metrics:
                metrics_obj = db.query(TickerKeyMetrics).filter(
                    TickerKeyMetrics.ticker == ticker,
                    TickerKeyMetrics.date == score_date,
                ).first()
                metrics_data = fund.metrics.model_dump(exclude_none=True)
                if metrics_obj:
                    for k, v in metrics_data.items():
                        setattr(metrics_obj, k, v)
                else:
                    metrics_obj = TickerKeyMetrics(
                        ticker=ticker,
                        date=score_date,
                        **metrics_data
                    )
                    db.add(metrics_obj)

            # 9c) Financials (ticker PK, JSONB)
            if fund.financials:
                fin_obj = db.query(TickerFinancials).filter(
                    TickerFinancials.ticker == ticker
                ).first()
                if fin_obj:
                    fin_obj.latest_quarter = fund.financials.get('latest_quarter')
                    fin_obj.income = fund.financials.get('income')
                    fin_obj.balance_sheet = fund.financials.get('balance_sheet')
                    fin_obj.cash_flow = fund.financials.get('cash_flow')
                else:
                    fin_obj = TickerFinancials(
                        ticker=ticker,
                        latest_quarter=fund.financials.get('latest_quarter'),
                        income=fund.financials.get('income'),
                        balance_sheet=fund.financials.get('balance_sheet'),
                        cash_flow=fund.financials.get('cash_flow'),
                    )
                    db.add(fin_obj)

            # 9d) Dividends (ticker + ex_date PK)
            if fund.dividends and fund.dividends.get('recent'):
                for div in fund.dividends['recent']:
                    div_date = div.get('date')
                    div_amount = div.get('amount')
                    if div_date:
                        ex_date_val = (
                            datetime.strptime(div_date, "%Y-%m-%d").date()
                            if isinstance(div_date, str)
                            else div_date
                        )
                        existing = db.query(TickerDividend).filter(
                            TickerDividend.ticker == ticker,
                            TickerDividend.ex_date == ex_date_val,
                        ).first()
                        if existing:
                            existing.amount = div_amount
                        else:
                            db.add(TickerDividend(
                                ticker=ticker,
                                ex_date=ex_date_val,
                                amount=div_amount,
                            ))

        # ==========================================
        # 10) UPSERT ticker_calendar (Extended format only)
        # ==========================================
        if is_extended and hasattr(item, 'calendar') and item.calendar:
            cal = item.calendar

            next_earn = (
                datetime.strptime(cal.next_earnings_date, "%Y-%m-%d").date()
                if cal.next_earnings_date else None
            )
            next_earn_end = (
                datetime.strptime(cal.next_earnings_date_end, "%Y-%m-%d").date()
                if cal.next_earnings_date_end else None
            )
            ex_div = (
                datetime.strptime(cal.ex_dividend_date, "%Y-%m-%d").date()
                if cal.ex_dividend_date else None
            )
            div_date = (
                datetime.strptime(cal.dividend_date, "%Y-%m-%d").date()
                if cal.dividend_date else None
            )

            earn_est = cal.earnings_estimate or {}
            rev_est = cal.revenue_estimate or {}

            cal_obj = db.query(TickerCalendar).filter(
                TickerCalendar.ticker == ticker,
                TickerCalendar.date == score_date,
            ).first()

            if cal_obj:
                cal_obj.next_earnings_date = next_earn
                cal_obj.next_earnings_date_end = next_earn_end
                cal_obj.earnings_confirmed = cal.earnings_confirmed
                cal_obj.d_day = cal.d_day
                cal_obj.ex_dividend_date = ex_div
                cal_obj.dividend_date = div_date
                cal_obj.earnings_high = earn_est.get('high')
                cal_obj.earnings_low = earn_est.get('low')
                cal_obj.earnings_avg = earn_est.get('avg')
                cal_obj.revenue_high = rev_est.get('high')
                cal_obj.revenue_low = rev_est.get('low')
                cal_obj.revenue_avg = rev_est.get('avg')
            else:
                db.add(TickerCalendar(
                    ticker=ticker, date=score_date,
                    next_earnings_date=next_earn,
                    next_earnings_date_end=next_earn_end,
                    earnings_confirmed=cal.earnings_confirmed,
                    d_day=cal.d_day,
                    ex_dividend_date=ex_div,
                    dividend_date=div_date,
                    earnings_high=earn_est.get('high'),
                    earnings_low=earn_est.get('low'),
                    earnings_avg=earn_est.get('avg'),
                    revenue_high=rev_est.get('high'),
                    revenue_low=rev_est.get('low'),
                    revenue_avg=rev_est.get('avg'),
                ))

        # ==========================================
        # 11) UPSERT ticker_earnings_history (Extended format only)
        # ==========================================
        if is_extended and hasattr(item, 'earnings_history') and item.earnings_history:
            for eh in item.earnings_history:
                earn_date = datetime.strptime(eh.date, "%Y-%m-%d").date()
                eh_obj = db.query(TickerEarningsHistory).filter(
                    TickerEarningsHistory.ticker == ticker,
                    TickerEarningsHistory.earnings_date == earn_date,
                ).first()

                if eh_obj:
                    eh_obj.eps_estimate = eh.eps_estimate
                    eh_obj.reported_eps = eh.reported_eps
                    eh_obj.surprise_pct = eh.surprise_pct
                else:
                    db.add(TickerEarningsHistory(
                        ticker=ticker, earnings_date=earn_date,
                        eps_estimate=eh.eps_estimate,
                        reported_eps=eh.reported_eps,
                        surprise_pct=eh.surprise_pct,
                    ))

        upserted += 1

    db.commit()

    # ----------------------------
    # FCM 알림: score ≥80 or ≤20
    # ----------------------------
    for item in items:
        try:
            is_extended = isinstance(item, ExtendedItemIngest)
            ticker = item.ticker
            score_date = item.date
            if is_extended:
                sv = item.score.value
                sig = item.score.signal
            else:
                sv = item.score
                sig = item.signal
            if sv is not None:
                process_score_notifications(db, score_date, ticker, sv, sig)
        except Exception as e:
            logger.error(f"FCM score error for {item.ticker}: {e}")

    # ----------------------------
    # FCM 알림: 일일 시그널 요약 (전체 사용자, 하루 1회)
    # ----------------------------
    try:
        ingest_date = items[0].date if items else date.today()
        process_daily_summary_notification(db, ingest_date)
    except Exception as e:
        logger.error(f"FCM daily summary error: {e}")
    db.commit()

    # ----------------------------
    # 3년 초과 데이터 자동 삭제 (전체 테이블)
    # ----------------------------
    db.execute(text("DELETE FROM analytics.ticker_scores WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_prices WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_indicators WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_ai_analysis WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_targets WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_trendlines WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_institutions WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_shorts WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_analyst_ratings WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_key_metrics WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_dividends WHERE ex_date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_calendar WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_earnings_history WHERE earnings_date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_defense_lines WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_recommendations WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.execute(text("DELETE FROM analytics.ticker_institutional_holders WHERE date < CURRENT_DATE - INTERVAL '3 years'"))
    db.commit()

    return {
        "status": "ok",
        "received": len(items),
        "upserted": upserted,
    }


# ============================
# 이번 주 실적 일정 Ingest 엔드포인트
# ============================
@router.post("/earnings-week", dependencies=[Depends(verify_api_key)])
def ingest_earnings_week(payload: EarningsWeekIngestPayload, db: Session = Depends(get_db)):
    """
    이번 주 + 다음 주 실적 발표 일정 업로드 (Mac mini → AWS).
    payload의 week_start~week_end 범위만 교체하여 과거 실적 보존.
    3년 초과 데이터 자동 정리.
    """
    ws = datetime.strptime(payload.week_start, "%Y-%m-%d").date()
    # week_end 이후 다음 주 일요일까지 커버 (this+next 2주분)
    we = datetime.strptime(payload.week_end, "%Y-%m-%d").date() + timedelta(days=7)

    deleted = db.query(EarningsWeekEvent).filter(
        EarningsWeekEvent.earnings_date >= ws,
        EarningsWeekEvent.earnings_date <= we,
    ).delete()

    inserted = 0
    for event in payload.events:
        earn_date = datetime.strptime(event.earnings_date, "%Y-%m-%d").date()
        earn_date_end = (
            datetime.strptime(event.earnings_date_end, "%Y-%m-%d").date()
            if event.earnings_date_end else None
        )
        est = event.earnings_estimate
        db.add(EarningsWeekEvent(
            ticker=event.ticker,
            earnings_date=earn_date,
            week=event.week,
            name_ko=event.name_ko,
            name_en=event.name_en,
            earnings_date_end=earn_date_end,
            earnings_confirmed=event.earnings_confirmed,
            d_day=event.d_day,
            eps_estimate_high=est.high,
            eps_estimate_low=est.low,
            eps_estimate_avg=est.avg,
            revenue_estimate=event.revenue_estimate,
            prev_surprise_pct=event.prev_surprise_pct,
            score=event.score,
        ))
        inserted += 1

    # 3년 초과 데이터 정리
    from datetime import timedelta
    cutoff = date.today() - timedelta(days=1095)
    cleaned = db.query(EarningsWeekEvent).filter(
        EarningsWeekEvent.earnings_date < cutoff
    ).delete()
    if cleaned:
        logger.info(f"Earnings cleanup: removed {cleaned} events older than {cutoff}")

    db.commit()

    return {
        "status": "ok",
        "date": payload.date,
        "week_start": payload.week_start,
        "week_end": payload.week_end,
        "deleted_range": deleted,
        "inserted": inserted,
        "cleaned_old": cleaned,
    }


# ============================
# 시장 지수 Ingest 엔드포인트
# ============================
@router.post("/market-indices", dependencies=[Depends(verify_api_key)])
def ingest_market_indices(payload: MarketIndicesIngestPayload, db: Session = Depends(get_db)):
    """
    시장 주요 지수 업로드 (Mac mini → AWS).

    SPY (S&P 500), QQQ (NASDAQ 100), DIA (Dow Jones) 데이터 수신.
    각 지수의 OHLCV + 변동률 + 1년치 스파크라인 차트 데이터 저장.
    """
    ingest_date = datetime.strptime(payload.date, "%Y-%m-%d").date()
    upserted = 0
    chart_points = 0

    for idx in payload.indices:
        # 1) market_indices 테이블 UPSERT
        obj = db.query(MarketIndex).filter(
            MarketIndex.date == ingest_date,
            MarketIndex.code == idx.code,
        ).first()

        if obj:
            obj.name = idx.name
            obj.open = idx.open
            obj.high = idx.high
            obj.low = idx.low
            obj.close = idx.close
            obj.volume = idx.volume
            obj.prev_close = idx.prev_close
            obj.change = idx.change
            obj.change_pct = idx.change_pct
        else:
            db.add(MarketIndex(
                date=ingest_date, code=idx.code, name=idx.name,
                open=idx.open, high=idx.high, low=idx.low,
                close=idx.close, volume=idx.volume,
                prev_close=idx.prev_close,
                change=idx.change, change_pct=idx.change_pct,
            ))
        upserted += 1

        # 2) chart 데이터 bulk UPSERT (스파크라인용)
        for pt in idx.chart:
            pt_date = datetime.strptime(pt.date, "%Y-%m-%d").date()
            chart_obj = db.query(MarketIndexChart).filter(
                MarketIndexChart.code == idx.code,
                MarketIndexChart.date == pt_date,
            ).first()

            if chart_obj:
                chart_obj.close = pt.close
            else:
                db.add(MarketIndexChart(
                    code=idx.code, date=pt_date, close=pt.close,
                ))
            chart_points += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.market_indices "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.execute(text(
        "DELETE FROM analytics.market_index_chart "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted, "chart_points": chart_points}


# ============================
# News Ingest (Mac mini → AWS)
# ============================

@router.post("/news", dependencies=[Depends(verify_api_key)], response_model=NewsIngestResponse)
def ingest_news(payload: NewsIngestPayload, db: Session = Depends(get_db)):
    """
    뉴스 데이터 인제스트 (Mac mini → AWS).

    - title_hash = md5(lower(trim(title))) 로 중복 제거
    - UPSERT: (ticker, date, title_hash) 기준
    - 3년 자동 cleanup
    """
    upserted = 0
    seen = set()  # 배치 내 중복 방지

    for item in payload.items:
        title_hash = hashlib.md5(item.title.lower().strip().encode("utf-8")).hexdigest()
        dedup_key = (item.ticker.upper(), str(item.date), title_hash)
        if dedup_key in seen:
            continue
        seen.add(dedup_key)

        obj = db.query(TickerNews).filter(
            TickerNews.ticker == item.ticker.upper(),
            TickerNews.date == item.date,
            TickerNews.title_hash == title_hash,
        ).first()

        future_event_dict = item.future_event.model_dump() if item.future_event else None

        if obj:
            obj.title = item.title
            obj.source = item.source
            obj.source_url = item.source_url
            obj.published_at = item.published_at
            obj.ai_summary = item.ai_summary
            obj.sentiment_score = item.sentiment_score
            obj.sentiment_grade = item.sentiment_grade
            obj.sentiment_label = item.sentiment_label
            obj.future_event = future_event_dict
            obj.is_breaking = item.is_breaking or False
            obj.is_hot_topic = item.is_hot_topic or False
            obj.hot_topic_category = item.hot_topic_category
            obj.hot_topic_priority = item.hot_topic_priority
            obj.updated_at = datetime.utcnow()
        else:
            db.add(TickerNews(
                date=item.date,
                ticker=item.ticker.upper(),
                title=item.title,
                title_hash=title_hash,
                source=item.source,
                source_url=item.source_url,
                published_at=item.published_at,
                ai_summary=item.ai_summary,
                sentiment_score=item.sentiment_score,
                sentiment_grade=item.sentiment_grade,
                sentiment_label=item.sentiment_label,
                future_event=future_event_dict,
                is_breaking=item.is_breaking or False,
                is_hot_topic=item.is_hot_topic or False,
                hot_topic_category=item.hot_topic_category,
                hot_topic_priority=item.hot_topic_priority,
            ))
        upserted += 1

    db.commit()

    # ----------------------------
    # FCM 알림: bullish/bearish 뉴스
    # ----------------------------
    for item in payload.items:
        if item.sentiment_grade in ("bullish", "bearish"):
            try:
                process_news_notifications(
                    db, item.date, item.ticker.upper(),
                    item.sentiment_grade, item.sentiment_score,
                    item.ai_summary,
                )
            except Exception as e:
                logger.error(f"FCM news error for {item.ticker}: {e}")

    # ----------------------------
    # FCM 알림: 속보 뉴스 (전체 broadcast)
    # ----------------------------
    for item in payload.items:
        if item.is_breaking:
            try:
                process_breaking_news_notification(
                    db, item.date, item.ticker.upper(),
                    item.ai_summary, item.source_url,
                )
            except Exception as e:
                logger.error(f"FCM breaking news error for {item.ticker}: {e}")

    # FCM: 호재 뉴스 급상승 종목 감지 (배치)
    ingested_tickers = list(set(item.ticker.upper() for item in payload.items))
    try:
        process_bullish_surge_notifications(db, date.today(), ingested_tickers)
    except Exception as e:
        logger.error(f"FCM bullish surge error: {e}")
    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.ticker_news "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return NewsIngestResponse(upserted=upserted, total=len(payload.items))


# ============================
# 예약 브로드캐스트 알림 트리거 (Mac mini → AWS)
# ============================

@router.post("/notifications/trigger", dependencies=[Depends(verify_api_key)])
def trigger_scheduled_notification(
    payload: ScheduledNotificationRequest,
    db: Session = Depends(get_db),
):
    """
    예약 브로드캐스트 알림 트리거 (Mac mini cron → AWS FastAPI).

    notification_type: MORNING_BRIEFING | CLOSING_REPORT | MARKET_OPEN
    """
    ntype = payload.notification_type
    today = date.today()

    try:
        if ntype == "MORNING_BRIEFING":
            process_morning_briefing(db)
        elif ntype == "CLOSING_REPORT":
            process_closing_report(db, today)
        elif ntype == "MARKET_OPEN":
            process_market_open(db, today)

        db.commit()
        return {"status": "ok", "notification_type": ntype, "date": str(today)}

    except Exception as e:
        logger.error(f"Scheduled notification error ({ntype}): {e}")
        return {"status": "error", "notification_type": ntype, "detail": str(e)}


# ============================
# 회원탈퇴 사유 저장 (Flutter → AWS)
# ============================

@router.post("/withdrawal", response_model=WithdrawalResponse)
def save_withdrawal_reason(payload: WithdrawalRequest, db: Session = Depends(get_db)):
    """
    회원탈퇴 사유 저장 (Flutter 앱에서 직접 호출, API key 불필요).

    탈퇴 사유를 analytics.account_withdrawals에 INSERT하여
    관리자가 나중에 확인할 수 있도록 한다.
    """
    withdrawal = AccountWithdrawal(
        user_email=payload.user_email,
        user_nickname=payload.user_nickname,
        reason=payload.reason,
    )
    db.add(withdrawal)
    db.commit()
    db.refresh(withdrawal)

    logger.info(f"Withdrawal reason saved: {payload.user_email} (id={withdrawal.id})")

    return WithdrawalResponse(message="saved", id=withdrawal.id)


# ============================
# 월별 이벤트 캘린더 Ingest (Mac mini → AWS)
# ============================

@router.post("/calendar", dependencies=[Depends(verify_api_key)])
def ingest_calendar(payload: MarketCalendarIngestPayload, db: Session = Depends(get_db)):
    """
    월별 이벤트 캘린더 업로드 (Mac mini → AWS).

    FOMC, 연준 연설, 옵션 만기, 경제지표 발표, 실적, 컨퍼런스,
    배당, 제품 출시, 주주총회 등 이벤트를 UPSERT.
    title/description은 "ko|||en|||zh|||ja|||es" 다국어 패킹 형태.
    """
    upserted = 0
    for item in payload.items:
        event_date = datetime.strptime(item.date, "%Y-%m-%d").date()
        existing = db.query(MarketCalendarEvent).filter(MarketCalendarEvent.id == item.id).first()

        if existing:
            existing.event_date = event_date
            existing.event_type = item.event_type
            existing.title = item.title
            existing.description = item.description
            existing.ticker = item.ticker
            existing.importance = item.importance
            existing.source = item.source
        else:
            db.add(MarketCalendarEvent(
                id=item.id,
                event_date=event_date,
                event_type=item.event_type,
                title=item.title,
                description=item.description,
                ticker=item.ticker,
                importance=item.importance,
                source=item.source,
            ))
        upserted += 1

    # 3년 초과 데이터 정리
    from datetime import timedelta
    cutoff = date.today() - timedelta(days=1095)
    deleted = db.query(MarketCalendarEvent).filter(
        MarketCalendarEvent.event_date < cutoff
    ).delete()
    if deleted:
        logger.info(f"Calendar cleanup: removed {deleted} events older than {cutoff}")

    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================================================
# Phase 1: AI 투자 브레인 — Internal Ingest Endpoints
# ============================================================

# ============================
# 포트폴리오 AI 의견 Ingest (맥미니 → AWS)
# ============================
@router.post("/portfolio-advice", dependencies=[Depends(verify_api_key)])
def ingest_portfolio_advice(
    payload: PortfolioAdviceIngestPayload,
    db: Session = Depends(get_db),
):
    """
    맥미니가 생성한 종목별 AI 의견 업로드.

    UPSERT: (user_id, ticker, date) 기준.
    맥미니 RT-ADVICE 필드 매핑:
      - ai_prob → confidence
      - advice.message → summary
      - advice.details → reasons (bullish/bearish 추출)
      - advice 전체 → reasons에 보존
    None이 아닌 값만 업데이트 (instant advice 기존 데이터 보호).
    """
    upserted = 0
    for item in payload.items:
        # --- 맥미니 필드 → DB 필드 매핑 ---
        confidence = item.confidence or item.ai_prob
        summary = item.summary
        reasons = item.reasons
        target_action = item.target_action

        # advice 중첩 객체에서 summary/reasons 추출
        if item.advice:
            adv = item.advice
            if not summary:
                summary = adv.get('message')
            if not reasons:
                details = adv.get('details') or {}
                reasons = {}
                # HOLD 등에서 bullish/bearish reasons 추출
                if 'bullish_reasons' in details:
                    reasons['bullish'] = details['bullish_reasons']
                if 'bearish_reasons' in details:
                    reasons['bearish'] = details['bearish_reasons']
                # advice 메타 정보 보존
                reasons['action'] = adv.get('action')
                reasons['priority'] = adv.get('priority')
                reasons['reason'] = adv.get('reason')
                reasons['details'] = details

        obj = db.query(PortfolioAdvice).filter(
            PortfolioAdvice.user_id == item.user_id,
            PortfolioAdvice.ticker == item.ticker.upper(),
            PortfolioAdvice.date == item.date,
        ).first()

        if obj:
            # None이 아닌 값만 업데이트 (instant advice 보호)
            if item.signal is not None:
                obj.signal = item.signal
            if confidence is not None:
                obj.confidence = confidence
            if summary is not None:
                obj.summary = summary
            if reasons:
                obj.reasons = reasons
            if target_action is not None:
                obj.target_action = target_action
        else:
            db.add(PortfolioAdvice(
                user_id=item.user_id,
                ticker=item.ticker.upper(),
                date=item.date,
                signal=item.signal,
                confidence=confidence,
                summary=summary,
                reasons=reasons,
                target_action=target_action,
            ))
        upserted += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.portfolio_advice "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================
# 포트폴리오 P&L 요약 Ingest (맥미니 → AWS)
# ============================
@router.post("/portfolio-summary", dependencies=[Depends(verify_api_key)])
def ingest_portfolio_summary(
    payload: PortfolioSummaryIngestPayload,
    db: Session = Depends(get_db),
):
    """
    맥미니가 계산한 유저별 일일 P&L 요약 업로드.

    UPSERT: (user_id, date) 기준.
    맥미니 RT-SUMMARY 필드 매핑:
      - periods.total → total_value, total_cost, total_pnl, total_pnl_pct
      - periods.today → day_pnl, day_pnl_pct
      - periods 원본 → periods 컬럼에 보존
      - trade_history → trade_history 컬럼에 보존
    realized_pnl: SELL 핸들러가 설정한 기존 값이 있으면 보존.
    """
    upserted = 0
    for item in payload.items:
        # periods → flat 필드 변환
        if item.periods and not item.total_value:
            total_period = item.periods.get('total') or {}
            today_period = item.periods.get('today') or {}
            item.total_value = total_period.get('end_value')
            item.total_cost = total_period.get('start_value')
            item.total_pnl = total_period.get('pnl_amount')
            item.total_pnl_pct = total_period.get('pnl_pct')
            item.day_pnl = today_period.get('pnl_amount')
            item.day_pnl_pct = today_period.get('pnl_pct')

        obj = db.query(PortfolioSummary).filter(
            PortfolioSummary.user_id == item.user_id,
            PortfolioSummary.date == item.date,
        ).first()

        if obj:
            if item.total_value is not None:
                obj.total_value = item.total_value
            if item.total_cost is not None:
                obj.total_cost = item.total_cost
            if item.total_pnl is not None:
                obj.total_pnl = item.total_pnl
            if item.total_pnl_pct is not None:
                obj.total_pnl_pct = item.total_pnl_pct
            if item.day_pnl is not None:
                obj.day_pnl = item.day_pnl
            if item.day_pnl_pct is not None:
                obj.day_pnl_pct = item.day_pnl_pct
            if item.holdings_detail is not None:
                obj.holdings_detail = item.holdings_detail
            if item.ai_summary is not None:
                obj.ai_summary = item.ai_summary
            if item.ai_recommendations is not None:
                obj.ai_recommendations = item.ai_recommendations
            # realized_pnl: 기존 non-zero 값 보존 (SELL 핸들러 우선)
            if item.realized_pnl is not None:
                if not (obj.realized_pnl and obj.realized_pnl != 0
                        and item.realized_pnl == 0):
                    obj.realized_pnl = item.realized_pnl
            # 새 컬럼
            if item.periods is not None:
                obj.periods = item.periods
            if item.trade_history is not None:
                obj.trade_history = item.trade_history
        else:
            db.add(PortfolioSummary(
                user_id=item.user_id,
                date=item.date,
                total_value=item.total_value,
                total_cost=item.total_cost,
                total_pnl=item.total_pnl,
                total_pnl_pct=item.total_pnl_pct,
                day_pnl=item.day_pnl,
                day_pnl_pct=item.day_pnl_pct,
                holdings_detail=item.holdings_detail,
                ai_summary=item.ai_summary,
                ai_recommendations=item.ai_recommendations,
                realized_pnl=item.realized_pnl,
                periods=item.periods,
                trade_history=item.trade_history,
            ))
        upserted += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.portfolio_summary "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================
# 알림 Ingest (맥미니 → AWS)
# ============================
@router.post("/alerts", dependencies=[Depends(verify_api_key)])
def ingest_alerts(
    payload: AlertsIngestPayload,
    db: Session = Depends(get_db),
):
    """
    맥미니가 생성한 유저 알림 업로드.

    INSERT only (알림은 중복 허용, 시간순 누적).
    FCM push 동시 발송.
    """
    inserted = 0
    for item in payload.items:
        db.add(UserAlert(
            user_id=item.user_id,
            ticker=item.ticker.upper() if item.ticker else None,
            alert_type=item.alert_type,
            title=item.title,
            message=item.message,
            priority=item.priority,
            data=item.data,
        ))
        inserted += 1

    db.commit()

    # TODO: FCM push 발송 연동 (기존 fcm_service 패턴 재사용)
    # for item in payload.items:
    #     try:
    #         process_alert_notification(db, item)
    #     except Exception as e:
    #         logger.error(f"FCM alert error for user {item.user_id}: {e}")

    return {"status": "ok", "inserted": inserted}


# ============================
# 환율 Ingest (맥미니 → AWS)
# ============================
@router.post("/exchange-rate", dependencies=[Depends(verify_api_key)])
def ingest_exchange_rate(
    payload: ExchangeRateIngestPayload,
    db: Session = Depends(get_db),
):
    """
    일별 환율 (USD/KRW) 업로드.

    UPSERT: date 기준.
    """
    upserted = 0
    for item in payload.items:
        obj = db.query(ExchangeRate).filter(ExchangeRate.date == item.date).first()
        if obj:
            obj.usd_krw = item.usd_krw
            obj.source = item.source
        else:
            db.add(ExchangeRate(
                date=item.date,
                usd_krw=item.usd_krw,
                source=item.source,
            ))
        upserted += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.exchange_rates "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================
# 유저 포트폴리오 벌크 조회 (맥미니 ← AWS)
# ============================
@router.get(
    "/users/portfolios",
    dependencies=[Depends(verify_api_key)],
    response_model=list[UserPortfolioInternal],
)
def get_all_user_portfolios(
    type: str | None = None,
    db: Session = Depends(get_db),
):
    """
    전체 유저 포트폴리오 벌크 조회 (맥미니가 AI 분석에 사용).

    - type=HOLDING: 보유 종목만
    - type=WATCHLIST: 관심 종목만
    - type 미지정: 전체
    """
    q = db.query(UserPortfolio)
    if type:
        q = q.filter(UserPortfolio.type == type.upper())
    return q.all()


# ============================
# 유저 거래내역 증분 조회 (맥미니 ← AWS)
# ============================
@router.get(
    "/users/transactions",
    dependencies=[Depends(verify_api_key)],
)
def get_recent_transactions(
    since: str | None = None,
    db: Session = Depends(get_db),
):
    """
    최근 거래내역 증분 조회 (맥미니가 P&L 계산에 사용).

    since: ISO timestamp (e.g., "2026-03-08T00:00:00") — 이후 생성된 것만 반환.
    """
    from app.models import UserTransaction

    q = db.query(UserTransaction)
    if since:
        since_dt = datetime.fromisoformat(since)
        q = q.filter(UserTransaction.created_at >= since_dt)
    q = q.order_by(UserTransaction.created_at.asc())

    rows = q.all()
    return [
        {
            "id": r.id, "user_id": r.user_id, "ticker": r.ticker,
            "type": r.type, "shares": r.shares, "price": r.price,
            "date": str(r.date), "created_at": str(r.created_at),
        }
        for r in rows
    ]


# ============================
# AI 시그널 Ingest (맥미니 → AWS)
# ============================
@router.post("/ai-signals", dependencies=[Depends(verify_api_key)])
def ingest_ai_signals(
    payload: AISignalsIngestPayload,
    db: Session = Depends(get_db),
):
    """
    맥미니가 생성한 종목별 AI 시그널 업로드.

    UPSERT: (ticker, date) 기준.
    """
    upserted = 0
    for item in payload.items:
        ticker_upper = item.ticker.upper()
        obj = db.query(AISignal).filter(
            AISignal.ticker == ticker_upper,
            AISignal.date == item.date,
        ).first()

        if obj:
            obj.signal = item.signal
            obj.confidence = item.confidence
            obj.price_at_signal = item.price_at_signal
            obj.target_price = item.target_price
            obj.stop_loss_price = item.stop_loss_price
            obj.reasoning = item.reasoning
        else:
            db.add(AISignal(
                ticker=ticker_upper,
                date=item.date,
                signal=item.signal,
                confidence=item.confidence,
                price_at_signal=item.price_at_signal,
                target_price=item.target_price,
                stop_loss_price=item.stop_loss_price,
                reasoning=item.reasoning,
            ))
        upserted += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.ai_signals "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================
# AI 메시지 Ingest (맥미니 → AWS)
# ============================
@router.post("/ai-messages", dependencies=[Depends(verify_api_key)])
def ingest_ai_messages(
    payload: AIMessagesIngestPayload,
    db: Session = Depends(get_db),
):
    """
    맥미니가 생성한 AI 메시지 업로드.

    같은 (type, date, user_id) 조합이면 UPSERT, 아니면 INSERT.
    user_id=NULL인 전체 브리핑도 지원.
    """
    upserted = 0
    for item in payload.items:
        # user_id가 NULL인 경우도 있으므로 IS NULL 처리
        if item.user_id is not None:
            obj = db.query(AIMessage).filter(
                AIMessage.type == item.type,
                AIMessage.date == item.date,
                AIMessage.user_id == item.user_id,
            ).first()
        else:
            obj = db.query(AIMessage).filter(
                AIMessage.type == item.type,
                AIMessage.date == item.date,
                AIMessage.user_id.is_(None),
            ).first()

        if obj:
            obj.messages = item.messages
        else:
            db.add(AIMessage(
                type=item.type,
                date=item.date,
                user_id=item.user_id,
                messages=item.messages,
            ))
        upserted += 1

    db.commit()

    # 3년 cleanup
    db.execute(text(
        "DELETE FROM analytics.ai_messages "
        "WHERE date < CURRENT_DATE - INTERVAL '3 years'"
    ))
    db.commit()

    return {"status": "ok", "upserted": upserted}


# ============================================================
# 실시간 분석 요청 큐 (맥미니 ↔ AWS)
# ============================================================

@router.get(
    "/analysis-queue",
    dependencies=[Depends(verify_api_key)],
    response_model=list[AnalysisRequestResponse],
)
def get_analysis_queue(
    status: str = "PENDING",
    limit: int = 20,
    db: Session = Depends(get_db),
):
    """
    맥미니가 10초 폴링으로 PENDING 분석 요청 조회.

    - status=PENDING (기본): 아직 처리 안 된 요청 (updated_at + 5분 경과 후에만 반환)
    - status=PROCESSING: 현재 처리 중인 요청
    - limit: 한 번에 가져올 최대 개수 (기본 20)
    """
    filters = [AnalysisRequest.status == status.upper()]

    # PENDING 조회 시 5분 쿨다운: 유저가 종목을 천천히 입력해도 모아서 1회만 분석
    if status.upper() == "PENDING":
        cooldown = datetime.utcnow() - timedelta(minutes=5)
        filters.append(AnalysisRequest.updated_at <= cooldown)

    rows = (
        db.query(AnalysisRequest)
        .filter(*filters)
        .order_by(AnalysisRequest.created_at.asc())
        .limit(limit)
        .all()
    )
    return rows


@router.post(
    "/analysis-queue/{request_id}/processing",
    dependencies=[Depends(verify_api_key)],
)
def mark_analysis_processing(
    request_id: int,
    db: Session = Depends(get_db),
):
    """
    맥미니가 분석 시작 시 PROCESSING 상태로 마킹.

    started_at 타임스탬프도 함께 기록.
    """
    obj = db.query(AnalysisRequest).filter(
        AnalysisRequest.id == request_id,
    ).first()

    if not obj:
        raise HTTPException(status_code=404, detail="Request not found")

    obj.status = "PROCESSING"
    obj.started_at = datetime.utcnow()
    db.commit()

    return {"status": "ok", "request_id": request_id}


@router.post(
    "/analysis-queue/{request_id}/complete",
    dependencies=[Depends(verify_api_key)],
)
def mark_analysis_complete(
    request_id: int,
    body: AnalysisQueueCompleteRequest = None,
    db: Session = Depends(get_db),
):
    """
    맥미니가 분석 완료 시 COMPLETED 상태로 마킹.

    completed_at 타임스탬프 + 결과 요약 기록.
    """
    obj = db.query(AnalysisRequest).filter(
        AnalysisRequest.id == request_id,
    ).first()

    if not obj:
        raise HTTPException(status_code=404, detail="Request not found")

    obj.status = "COMPLETED"
    obj.completed_at = datetime.utcnow()
    if body and body.result_summary:
        obj.result_summary = body.result_summary
    db.commit()

    # FCM: AI 분석 완료 알림 (포트폴리오 전체)
    try:
        send_portfolio_advice_notification(db, obj.user_id)
    except Exception as e:
        logger.warning(f"Portfolio advice FCM failed: request={request_id}, err={e}")

    return {"status": "ok", "request_id": request_id}


@router.post(
    "/analysis-queue/{request_id}/fail",
    dependencies=[Depends(verify_api_key)],
)
def mark_analysis_failed(
    request_id: int,
    body: AnalysisQueueCompleteRequest = None,
    db: Session = Depends(get_db),
):
    """
    맥미니가 분석 실패 시 FAILED 상태로 마킹.
    """
    obj = db.query(AnalysisRequest).filter(
        AnalysisRequest.id == request_id,
    ).first()

    if not obj:
        raise HTTPException(status_code=404, detail="Request not found")

    obj.status = "FAILED"
    obj.completed_at = datetime.utcnow()
    if body and body.result_summary:
        obj.result_summary = body.result_summary
    db.commit()

    return {"status": "ok", "request_id": request_id}
