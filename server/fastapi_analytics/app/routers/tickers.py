import re

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, or_, distinct
from typing import List
from app.database import get_db
from app.models import Ticker, TickerScore, TickerChange
from app.schemas import TickerMetadata, TickerChangesResponse

router = APIRouter()

# `.`, `-` and whitespace, for class-share symbol normalization (S3).
_SEPARATORS = re.compile(r"[.\-\s]")


def _strip_separators(value: str) -> str:
    """`BRK.B` / `BRK-B` / `brk b` -> `BRKB`."""
    return _SEPARATORS.sub("", value).upper()


def _ticker_without_separators(column):
    """SQL-side equivalent of :func:`_strip_separators` for a ticker column.

    Done in SQL rather than in Python so the match stays inside the query --
    pulling every ticker out to normalize in the app would turn one indexed
    lookup into a full scan plus transfer.
    """
    return func.replace(
        func.replace(func.replace(column, ".", ""), "-", ""), " ", ""
    )


def _search_clauses(q: str):
    """Build the OR-clauses for a search query.

    Ticker, English name and Korean name as before, plus a separator-stripped
    ticker match so class shares are found however the user types them.

    The normalized clause is why this exists (S3). The app can turn `BRK.B`
    into `BRK-B` on its own, but it **cannot** resolve a separator-less
    `BRKB`: four-letter tickers like `NVDA` and `TSLA` are indistinguishable
    from a contracted class symbol by string shape alone, and guessing
    produced junk queries (`NVD-A`). The database knows which symbols exist,
    so the normalization belongs here.
    """
    clauses = [
        TickerScore.ticker.ilike(f"%{q}%"),
        Ticker.name.ilike(f"%{q}%"),
        Ticker.extra_data['name_ko'].astext.ilike(f"%{q}%"),  # Korean name
    ]

    normalized = _strip_separators(q)
    # Empty after stripping (the user typed only separators): a `%%` pattern
    # would match every ticker, so the clause is left out.
    if normalized:
        clauses.append(
            _ticker_without_separators(TickerScore.ticker).ilike(f"%{normalized}%")
        )
    return clauses


@router.get("/search", response_model=List[TickerMetadata])
def search_tickers(
    q: str = Query(..., min_length=1, description="Search query (ticker or name)"),
    limit: int = Query(20, le=50, ge=1, description="Number of results (max 50)"),
    db: Session = Depends(get_db)
):
    """
    Search tickers by symbol or name.

    **검색 기능** ⭐
    - 심볼 또는 이름으로 검색
    - **실제 분석 대상 종목 기준** (TickerScore 테이블)
    - 메타데이터는 Ticker 테이블과 LEFT JOIN
    - 클래스주 표기 정규화: `BRKB`·`BRK.B`·`brk b` 모두 `BRK-B`를 찾는다 (S3)

    Example:
    ```
    GET /api/v1/tickers/search?q=apple
    ```

    Response:
    ```json
    [
        {
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "category": "Technology"
        }
    ]
    ```
    """
    # Search from actual analyzed tickers (TickerScore) with metadata (Ticker)
    # LEFT JOIN으로 TickerScore에 있는 모든 ticker를 검색하되
    # Ticker 테이블에 메타데이터가 있으면 함께 반환
    results = db.query(
        TickerScore.ticker,
        Ticker.name,
        Ticker.category,
        Ticker.extra_data  # JSONB metadata (contains name_ko)
    ).outerjoin(
        Ticker,
        TickerScore.ticker == Ticker.ticker
    ).filter(
        or_(*_search_clauses(q))
    ).distinct(
        TickerScore.ticker
    ).limit(limit).all()

    # 검색 결과 0개도 정상 응답 (200 OK + 빈 배열)
    return [
        {
            "ticker": r.ticker,
            "name": r.name,
            "name_ko": r.extra_data.get("name_ko") if r.extra_data else None,
            "category": r.category
        }
        for r in results
    ]


# ⚠️ `/{ticker}` **앞에** 둬야 한다. 뒤에 두면 경로 파라미터가
# `/changes` 요청까지 먹어서 ticker="changes" 로 404가 난다.
@router.get("/changes", response_model=TickerChangesResponse)
def get_ticker_changes(db: Session = Depends(get_db)):
    """
    Ticker identity changes — renames and delistings.

    The app stores holdings and watchlists as ticker strings, so when a symbol
    is renamed the position silently stops resolving. This endpoint lets the
    app migrate `old` -> `new` and tell the user why.

    Returns the whole map in one response (tens of rows): the app has to check
    every holding at once, so a per-ticker lookup would mean N requests.

    - `reason: "renamed"` -> `new` is always present; migrate to it.
    - `reason: "delisted"` -> `new` is null; the position has no successor.

    A chain (A -> B, later B -> C) is stored as two rows. Resolve by following
    `new` until the symbol no longer appears as an `old`.
    """
    rows = (
        db.query(TickerChange)
        .order_by(TickerChange.detected_at.desc().nullslast(),
                  TickerChange.old_ticker.asc())
        .all()
    )
    return {"count": len(rows), "changes": rows}


@router.get("/{ticker}", response_model=TickerMetadata)
def get_ticker_info(
    ticker: str,
    db: Session = Depends(get_db)
):
    """
    Get ticker metadata by symbol.

    Example:
    ```
    GET /api/v1/tickers/AAPL
    ```

    Response:
    ```json
    {
        "ticker": "AAPL",
        "name": "Apple Inc.",
        "category": "Technology"
    }
    ```
    """
    result = db.query(Ticker).filter(
        Ticker.ticker == ticker.upper()
    ).first()

    if not result:
        raise HTTPException(
            404,
            f"Ticker not found: {ticker}"
        )

    # Extract name_ko from JSONB metadata and return as dict
    return {
        "ticker": result.ticker,
        "name": result.name,
        "name_ko": result.extra_data.get("name_ko") if result.extra_data else None,
        "category": result.category
    }
