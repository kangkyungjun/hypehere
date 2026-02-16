from fastapi import APIRouter, Header, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date, datetime
import logging

from app.database import get_db
from app.models import (
    TickerScore, TickerPrice, TickerIndicator, TickerTarget,
    TickerTrendline, TickerInstitution, TickerShort, TickerAIAnalysis,
    TickerAnalystRating, Ticker,
    CompanyProfile, TickerKeyMetrics, TickerFinancials, TickerDividend,
    MacroIndicator, MacroChartData, TickerCalendar, TickerEarningsHistory,
    TickerDefenseLine, TickerRecommendation, TickerInstitutionalHolder,
    EarningsWeekEvent
)
from app.schemas import (
    IngestPayload, ExtendedItemIngest, MacroIngestPayload,
    EarningsWeekIngestPayload
)
from app.config import settings
from app.utils.trading_calendar import is_trading_day

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
                obj.signal_message = item.message
            else:
                db.add(MacroIndicator(
                    date=ingest_date, indicator_code=code,
                    indicator_name=item.name, observation_date=obs_date,
                    value=item.value, previous_value=previous_value,
                    change_pct=change_pct, source='FRED',
                    risk_level=item.risk_level,
                    signal_message=item.message,
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
                obj.signal_message = sig.message
                obj.liquidity_status = sig.liquidity_status
                obj.previous_value = previous_value
                obj.change_pct = change_pct
            else:
                db.add(MacroIndicator(
                    date=ingest_date, indicator_code=code,
                    value=sig.value,
                    risk_level=sig.risk_level,
                    signal_message=sig.message,
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
    이번 주 실적 발표 일정 업로드 (Mac mini → AWS).

    주 단위 교체: week_start~week_end 범위 기존 데이터 DELETE → INSERT.
    """
    week_start = datetime.strptime(payload.week_start, "%Y-%m-%d").date()
    week_end = datetime.strptime(payload.week_end, "%Y-%m-%d").date()

    # Delete existing data for this week range
    db.query(EarningsWeekEvent).filter(
        EarningsWeekEvent.earnings_date >= week_start,
        EarningsWeekEvent.earnings_date <= week_end,
    ).delete()

    inserted = 0
    for event in payload.events:
        earn_date = datetime.strptime(event.earnings_date, "%Y-%m-%d").date()
        db.add(EarningsWeekEvent(
            ticker=event.ticker,
            earnings_date=earn_date,
            earnings_time=event.earnings_time,
            eps_estimate=event.eps_estimate,
            revenue_estimate=event.revenue_estimate,
            market_cap=event.market_cap,
            sector=event.sector,
            name_en=event.name_en,
            name_ko=event.name_ko,
        ))
        inserted += 1

    db.commit()

    # Cleanup: remove events older than 30 days
    db.execute(text(
        "DELETE FROM analytics.earnings_week_events "
        "WHERE earnings_date < CURRENT_DATE - INTERVAL '30 days'"
    ))
    db.commit()

    return {
        "status": "ok",
        "week_start": payload.week_start,
        "week_end": payload.week_end,
        "inserted": inserted,
    }
