from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from app.database import get_db
from app.models import TickerNews
from app.schemas import NewsListResponse, NewsItemResponse, NewsSummaryResponse

router = APIRouter()


@router.get("/", response_model=NewsListResponse)
def get_news(
    ticker: str = Query(..., description="Ticker symbol"),
    from_date: date = Query(None, alias="from", description="Start date"),
    to_date: date = Query(None, alias="to", description="End date"),
    limit: int = Query(20, ge=1, le=100, description="Max items"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    db: Session = Depends(get_db),
):
    """
    종목별 뉴스 목록 조회.

    - 정렬: published_at DESC
    - 빈 데이터 시 빈 구조 반환 (404 아님)
    """
    ticker = ticker.upper()

    query = db.query(TickerNews).filter(TickerNews.ticker == ticker)

    if from_date:
        query = query.filter(TickerNews.date >= from_date)
    if to_date:
        query = query.filter(TickerNews.date <= to_date)

    total = query.count()

    rows = (
        query
        .order_by(TickerNews.published_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    items = [
        NewsItemResponse(
            date=r.date,
            ticker=r.ticker,
            title=r.title,
            source=r.source,
            source_url=r.source_url,
            published_at=r.published_at,
            ai_summary=r.ai_summary,
            sentiment_score=r.sentiment_score,
            sentiment_grade=r.sentiment_grade,
            sentiment_label=r.sentiment_label,
            future_event=r.future_event,
        )
        for r in rows
    ]

    return NewsListResponse(items=items, total=total)


@router.get("/summary", response_model=NewsSummaryResponse)
def get_news_summary(
    ticker: str = Query(..., description="Ticker symbol"),
    target_date: date = Query(None, alias="date", description="Target date (default: latest)"),
    db: Session = Depends(get_db),
):
    """
    종목별 뉴스 감성 요약.

    - bullish / neutral / bearish 건수 + 평균 점수
    - 빈 데이터 시 빈 구조 반환 (404 아님)
    """
    ticker = ticker.upper()

    if target_date is None:
        target_date = db.query(func.max(TickerNews.date)).filter(
            TickerNews.ticker == ticker
        ).scalar()

    if target_date is None:
        return NewsSummaryResponse(ticker=ticker)

    rows = db.query(TickerNews).filter(
        TickerNews.ticker == ticker,
        TickerNews.date == target_date,
    ).all()

    if not rows:
        return NewsSummaryResponse(ticker=ticker, date=target_date)

    bullish = sum(1 for r in rows if r.sentiment_grade == "bullish")
    neutral = sum(1 for r in rows if r.sentiment_grade == "neutral")
    bearish = sum(1 for r in rows if r.sentiment_grade == "bearish")
    avg_score = round(sum(r.sentiment_score for r in rows) / len(rows), 1)

    return NewsSummaryResponse(
        ticker=ticker,
        date=target_date,
        total_articles=len(rows),
        bullish=bullish,
        neutral=neutral,
        bearish=bearish,
        avg_score=avg_score,
    )
