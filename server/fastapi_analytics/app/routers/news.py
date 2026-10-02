from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime, timedelta
from typing import Optional
from app.database import get_db
from app.models import TickerNews, Ticker
from app.schemas import (
    NewsListResponse, NewsItemResponse, NewsSummaryResponse,
    TickerMentionBubbleResponse, TickerMentionItem,
    NewsSectorsResponse,
)

router = APIRouter()


def _news_row_to_response(r, extra_data, sector) -> NewsItemResponse:
    """Convert a TickerNews row + joined metadata to NewsItemResponse."""
    return NewsItemResponse(
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
        is_breaking=r.is_breaking or False,
        is_hot_topic=r.is_hot_topic or False,
        hot_topic_category=r.hot_topic_category,
        hot_topic_priority=r.hot_topic_priority,
        ticker_name_ko=(extra_data or {}).get('name_ko') if extra_data else None,
        sector=sector,
    )


@router.get("/latest", response_model=NewsListResponse)
def get_latest_news(
    limit: int = Query(3, ge=1, le=50, description="Max items"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    tickers: Optional[str] = Query(None, description="Comma-separated ticker filter (e.g. AAPL,TSLA,MARKET)"),
    sentiment: Optional[str] = Query(None, description="Comma-separated sentiment filter (e.g. bullish,bearish)"),
    sectors: Optional[str] = Query(None, description="Comma-separated sector filter (e.g. Technology,Healthcare)"),
    is_breaking: Optional[bool] = Query(None, description="Filter breaking news only"),
    exclude_market: Optional[bool] = Query(None, description="Exclude MARKET ticker (for Biz category)"),
    db: Session = Depends(get_db),
):
    """
    전체 종목 최신 AI 요약 뉴스 조회 (대시보드용).

    - 필터 파라미터: tickers, sentiment, sectors, is_breaking
    - 정렬: published_at DESC
    - Ticker JOIN으로 한글 회사명(name_ko) 포함
    - 빈 데이터 시 빈 구조 반환 (404 아님)
    """
    base_query = (
        db.query(TickerNews, Ticker.extra_data, Ticker.sector)
        .outerjoin(Ticker, TickerNews.ticker == Ticker.ticker)
    )

    # Apply filters
    if tickers:
        ticker_list = [t.strip().upper() for t in tickers.split(",") if t.strip()]
        if ticker_list:
            base_query = base_query.filter(TickerNews.ticker.in_(ticker_list))

    if sentiment:
        sentiment_list = [s.strip().lower() for s in sentiment.split(",") if s.strip()]
        if sentiment_list:
            base_query = base_query.filter(TickerNews.sentiment_grade.in_(sentiment_list))

    if sectors:
        sector_list = [s.strip() for s in sectors.split(",") if s.strip()]
        if sector_list:
            base_query = base_query.filter(Ticker.sector.in_(sector_list))

    if is_breaking is not None:
        base_query = base_query.filter(TickerNews.is_breaking == is_breaking)

    if exclude_market:
        base_query = base_query.filter(TickerNews.ticker != 'MARKET')

    total = base_query.count()

    rows = (
        base_query
        .order_by(TickerNews.published_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    items = [_news_row_to_response(r, extra_data, sector) for r, extra_data, sector in rows]

    return NewsListResponse(items=items, total=total)


@router.get("/hot-topics", response_model=NewsListResponse)
def get_hot_topics(
    limit: int = Query(5, ge=1, le=20, description="Max items"),
    db: Session = Depends(get_db),
):
    """
    Hot topic 뉴스 조회 (최근 48시간, priority ASC → published_at DESC).

    - is_hot_topic=True인 뉴스만 반환
    - 토스트 오버레이 표시용
    - 빈 데이터 시 빈 구조 반환
    """
    cutoff = datetime.utcnow() - timedelta(hours=48)

    base_query = (
        db.query(TickerNews, Ticker.extra_data, Ticker.sector)
        .outerjoin(Ticker, TickerNews.ticker == Ticker.ticker)
        .filter(
            TickerNews.is_hot_topic == True,
            TickerNews.published_at >= cutoff,
        )
    )

    total = base_query.count()

    rows = (
        base_query
        .order_by(
            TickerNews.hot_topic_priority.asc().nullslast(),
            TickerNews.published_at.desc(),
        )
        .limit(limit)
        .all()
    )

    items = [_news_row_to_response(r, extra_data, sector) for r, extra_data, sector in rows]

    return NewsListResponse(items=items, total=total)


@router.get("/mention-bubble", response_model=TickerMentionBubbleResponse)
def get_mention_bubble(
    hours: int = Query(24, ge=1, le=72, description="Lookback period in hours"),
    limit: int = Query(15, ge=5, le=30, description="Max tickers to return"),
    sectors: Optional[str] = Query(None, description="Comma-separated sector filter"),
    tickers: Optional[str] = Query(None, description="Comma-separated ticker filter"),
    db: Session = Depends(get_db),
):
    """
    최근 N시간 내 가장 많이 언급된 종목 버블 데이터.

    - GROUP BY ticker, COUNT(*), AVG(sentiment_score)
    - Ticker 메타데이터 JOIN (name_ko, sector)
    - sectors/tickers 필터 지원 (카테고리별 버블 연동)
    - 빈 데이터 시 빈 구조 반환 (404 아님)
    """
    cutoff = datetime.utcnow() - timedelta(hours=hours)

    bubble_query = (
        db.query(
            TickerNews.ticker,
            func.count().label('cnt'),
            func.avg(TickerNews.sentiment_score).label('avg_score'),
        )
        .filter(TickerNews.published_at >= cutoff)
        .filter(TickerNews.ticker != 'MARKET')
    )

    # Ticker filter (watchlist)
    if tickers:
        ticker_list = [t.strip().upper() for t in tickers.split(",") if t.strip()]
        if ticker_list:
            bubble_query = bubble_query.filter(TickerNews.ticker.in_(ticker_list))

    # Sector filter (join Ticker table)
    if sectors:
        sector_list = [s.strip() for s in sectors.split(",") if s.strip()]
        if sector_list:
            bubble_query = (
                bubble_query
                .join(Ticker, TickerNews.ticker == Ticker.ticker)
                .filter(Ticker.sector.in_(sector_list))
            )

    rows = (
        bubble_query
        .group_by(TickerNews.ticker)
        .order_by(func.count().desc())
        .limit(limit)
        .all()
    )

    if not rows:
        return TickerMentionBubbleResponse(items=[], period_hours=hours)

    # Ticker metadata JOIN (name_ko, sector)
    tickers = [r.ticker for r in rows]
    meta = {
        t.ticker: t
        for t in db.query(Ticker).filter(Ticker.ticker.in_(tickers)).all()
    }

    items = []
    for r in rows:
        t_meta = meta.get(r.ticker)
        avg = float(r.avg_score) if r.avg_score is not None else 0.0
        dominant = "bullish" if avg > 10 else ("bearish" if avg < -10 else "neutral")
        items.append(TickerMentionItem(
            ticker=r.ticker,
            mention_count=r.cnt,
            name_ko=(t_meta.extra_data or {}).get('name_ko') if t_meta and t_meta.extra_data else None,
            sector=t_meta.sector if t_meta else None,
            dominant_sentiment=dominant,
            avg_sentiment_score=round(avg, 1),
        ))

    return TickerMentionBubbleResponse(items=items, period_hours=hours)


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
    - Ticker JOIN으로 한글 회사명(name_ko) 포함
    - 빈 데이터 시 빈 구조 반환 (404 아님)
    """
    ticker = ticker.upper()

    base_query = db.query(TickerNews).filter(TickerNews.ticker == ticker)

    if from_date:
        base_query = base_query.filter(TickerNews.date >= from_date)
    if to_date:
        base_query = base_query.filter(TickerNews.date <= to_date)

    total = base_query.count()

    # Ticker JOIN for name_ko and sector
    ticker_meta = db.query(Ticker.extra_data, Ticker.sector).filter(Ticker.ticker == ticker).first()
    name_ko = (ticker_meta[0] or {}).get('name_ko') if ticker_meta else None
    ticker_sector = ticker_meta[1] if ticker_meta else None

    rows = (
        base_query
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
            is_breaking=r.is_breaking or False,
            is_hot_topic=r.is_hot_topic or False,
            hot_topic_category=r.hot_topic_category,
            hot_topic_priority=r.hot_topic_priority,
            ticker_name_ko=name_ko,
            sector=ticker_sector,
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


@router.get("/sectors", response_model=NewsSectorsResponse)
def get_available_sectors(db: Session = Depends(get_db)):
    """
    DB에 존재하는 고유 섹터 목록 반환.

    - Ticker 테이블에서 sector IS NOT NULL인 고유값
    - Flutter에서 필터 모달 열 때 캐시하여 사용
    """
    rows = db.query(Ticker.sector).filter(Ticker.sector.isnot(None)).distinct().all()
    return NewsSectorsResponse(sectors=sorted([r[0] for r in rows]))
