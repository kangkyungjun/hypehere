from fastapi import APIRouter, Header, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import date
import logging

from app.database import get_db
from app.models import (
    TickerScore, TickerPrice, TickerIndicator, TickerTarget,
    TickerTrendline, TickerInstitution, TickerShort, TickerAIAnalysis
)
from app.schemas import IngestPayload, ExtendedItemIngest
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
        else:
            # Simple flat structure (backward compatibility)
            open_price = item.open
            high_price = item.high
            low_price = item.low
            close_price = item.close
            volume = item.volume

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
            bb_width = None  # Not provided in extended format
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
            # Only save if at least one indicator is present
            has_indicators = any([rsi, macd, bb_width])

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
        # 5) UPSERT to ticker_targets (target/stop)
        # ==========================================
        # Note: Targets, trendlines, institutions, and shorts are only
        # available in legacy flat payloads (not in extended nested format).
        # These sections are kept for backward compatibility but will be
        # skipped for extended payloads.
        if not is_extended:
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
            # 6) UPSERT to ticker_trendlines (trendline coefficients)
            # ==========================================
            high_slope = getattr(item, 'high_slope', None)
            low_slope = getattr(item, 'low_slope', None)

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
                    trendline_obj.high_intercept = getattr(item, 'high_intercept', None)
                    trendline_obj.high_r_squared = getattr(item, 'high_r_squared', None)
                    trendline_obj.low_slope = low_slope
                    trendline_obj.low_intercept = getattr(item, 'low_intercept', None)
                    trendline_obj.low_r_squared = getattr(item, 'low_r_squared', None)
                    trendline_obj.trend_period_days = getattr(item, 'trend_period_days', 30)
                else:
                    # Insert new trendline record
                    trendline_obj = TickerTrendline(
                        ticker=ticker,
                        date=score_date,
                        high_slope=high_slope,
                        high_intercept=getattr(item, 'high_intercept', None),
                        high_r_squared=getattr(item, 'high_r_squared', None),
                        low_slope=low_slope,
                        low_intercept=getattr(item, 'low_intercept', None),
                        low_r_squared=getattr(item, 'low_r_squared', None),
                        trend_period_days=getattr(item, 'trend_period_days', 30),
                    )
                    db.add(trendline_obj)

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
    db.commit()

    return {
        "status": "ok",
        "received": len(items),
        "upserted": upserted,
    }
