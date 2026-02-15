from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date as DateType, timedelta
from typing import Optional, List

from app.database import get_db
from app.models import MacroIndicator, MacroChartData
from app.schemas import (
    MacroIndicatorsResponse, MacroIndicatorResponse,
    MacroSignalsResponse, MacroSignalResponse,
    MacroChartResponse, MacroChartPointResponse,
)

router = APIRouter()

# Fixed display order for FRED indicators
INDICATOR_ORDER = ["FEDFUNDS", "DGS10", "DGS2", "T10Y2Y", "VIXCLS", "CPIAUCSL", "UNRATE"]

# Signal codes (시장레이더/머니프린팅)
SIGNAL_CODES = {"yield_curve", "m2_liquidity"}


@router.get("/indicators", response_model=MacroIndicatorsResponse)
def get_macro_indicators(
    date: Optional[DateType] = Query(None, description="Date (default: latest)"),
    db: Session = Depends(get_db),
):
    """거시경제 지표 조회 (date=None → 최신)"""
    target_date = date
    if target_date is None:
        target_date = db.query(func.max(MacroIndicator.date)).filter(
            MacroIndicator.source != 'SIGNAL'
        ).scalar()
    if target_date is None:
        return MacroIndicatorsResponse(date="", indicators=[])

    rows = db.query(MacroIndicator).filter(
        MacroIndicator.date == target_date,
        MacroIndicator.source != 'SIGNAL',
    ).all()

    # Sort by fixed order
    rows_dict = {r.indicator_code: r for r in rows}
    sorted_rows = [rows_dict[code] for code in INDICATOR_ORDER if code in rows_dict]
    for r in rows:
        if r.indicator_code not in INDICATOR_ORDER:
            sorted_rows.append(r)

    return MacroIndicatorsResponse(
        date=str(target_date),
        indicators=[
            MacroIndicatorResponse(
                indicator_code=r.indicator_code,
                indicator_name=r.indicator_name,
                value=r.value,
                observation_date=str(r.observation_date) if r.observation_date else None,
                previous_value=r.previous_value,
                change_pct=r.change_pct,
                risk_level=r.risk_level,
                liquidity_status=r.liquidity_status,
                signal_message=r.signal_message,
            )
            for r in sorted_rows
        ],
    )


@router.get("/signals", response_model=MacroSignalsResponse)
def get_macro_signals(
    date: Optional[DateType] = Query(None, description="Date (default: latest)"),
    db: Session = Depends(get_db),
):
    """시장레이더/머니프린팅 신호 조회 (date=None → 최신)"""
    target_date = date
    if target_date is None:
        target_date = db.query(func.max(MacroIndicator.date)).filter(
            MacroIndicator.source == 'SIGNAL'
        ).scalar()
    if target_date is None:
        return MacroSignalsResponse(date="", signals=[])

    rows = db.query(MacroIndicator).filter(
        MacroIndicator.date == target_date,
        MacroIndicator.source == 'SIGNAL',
    ).all()

    return MacroSignalsResponse(
        date=str(target_date),
        signals=[
            MacroSignalResponse(
                signal_code=r.indicator_code,
                value=r.value,
                risk_level=r.risk_level,
                liquidity_status=r.liquidity_status,
                message=r.signal_message,
                date=str(r.date),
            )
            for r in rows
        ],
    )


@router.get("/charts", response_model=MacroChartResponse)
def get_macro_chart(
    series: str = Query(..., description="Series ID (e.g., t10y2y, m2_growth)"),
    days: int = Query(365, description="Number of days of data (default: 365)"),
    db: Session = Depends(get_db),
):
    """매크로 차트 시계열 데이터 조회"""
    from_date = DateType.today() - timedelta(days=days)

    rows = db.query(MacroChartData).filter(
        MacroChartData.series_id == series,
        MacroChartData.date >= from_date,
    ).order_by(MacroChartData.date.asc()).all()

    return MacroChartResponse(
        series_id=series,
        count=len(rows),
        data=[
            MacroChartPointResponse(
                date=str(r.date),
                value=r.value,
            )
            for r in rows
        ],
    )
