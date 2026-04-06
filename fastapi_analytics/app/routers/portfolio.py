"""
Portfolio CRUD router (Flutter ↔ Server).

All endpoints require Django Token authentication.
Handles holdings, watchlist, transactions, advice, summary, exchange rates.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.orm.attributes import flag_modified
from datetime import date, datetime
from typing import List, Optional
import json
import logging

from app.database import get_db
from app.auth import get_current_user
from app.models import (
    UserPortfolio, UserTransaction, PortfolioAdvice,
    PortfolioSummary, ExchangeRate, AnalysisRequest,
)
from app.schemas import (
    PortfolioHoldingCreate, PortfolioHoldingResponse,
    WatchlistItemCreate, WatchlistItemResponse, WatchlistBulkSync,
    TransactionCreate, TransactionResponse,
    PortfolioAdviceResponse, PortfolioSummaryResponse,
    ExchangeRateResponse,
    AnalysisStatusResponse,
)

# Time remaining templates for instant advice (multilingual |||‑packed)
_INSTANT_ADVICE_TEMPLATES = {
    # Order: Ko|||En|||Zh|||Ja|||Es (맥미니와 동일)
    "summary_with_data": (
        "즉시 분석: 현재 AI 점수 {score}점, 시그널 {signal}. "
        "상세 포트폴리오 분석이 곧 업데이트됩니다!"
        "|||"
        "Quick analysis: AI score {score}, signal {signal}. "
        "Detailed portfolio analysis will be updated shortly!"
        "|||"
        "即时分析：AI评分{score}分，信号{signal}。"
        "详细组合分析即将更新！"
        "|||"
        "即座分析：AIスコア{score}点、シグナル{signal}。"
        "詳細なポートフォリオ分析はまもなく更新されます！"
        "|||"
        "Análisis rápido: puntuación AI {score}, señal {signal}. "
        "¡El análisis detallado se actualizará en breve!"
    ),
    "summary_no_data": (
        "새로 추가된 종목입니다. 상세 AI 분석이 곧 제공됩니다. 기대해주세요!"
        "|||"
        "Newly added stock. Detailed AI analysis coming shortly. Stay tuned!"
        "|||"
        "新添加的股票。详细AI分析即将提供，敬请期待！"
        "|||"
        "新しく追加された銘柄です。詳細なAI分析はまもなく提供されます。お楽しみに！"
        "|||"
        "Acción recién añadida. ¡El análisis detallado llegará en breve!"
    ),
}

logger = logging.getLogger(__name__)

router = APIRouter()


def _generate_instant_advice(
    db: Session, user_id: int, ticker: str,
) -> Optional[PortfolioAdviceResponse]:
    """
    기존 DB 데이터(scores, ai_analysis, targets, prices)를 SELECT하여
    즉시 PortfolioAdvice 레코드를 생성.

    - 비용: $0 (DB SELECT만, 외부 API 없음)
    - 맥미니 관여 없음
    - 데이터 없으면 "새 종목" 안내 메시지 반환
    """
    today = date.today()

    row = db.execute(text("""
        SELECT
            ts.score, ts.signal,
            ta.probability, ta.summary,
            ta.bullish_reasons, ta.bearish_reasons, ta.final_comment,
            tt.target_price, tt.stop_loss,
            tp.close AS current_price
        FROM analytics.tickers t
        LEFT JOIN LATERAL (
            SELECT score, signal FROM analytics.ticker_scores
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) ts ON true
        LEFT JOIN LATERAL (
            SELECT probability, summary, bullish_reasons, bearish_reasons, final_comment
            FROM analytics.ticker_ai_analysis
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) ta ON true
        LEFT JOIN LATERAL (
            SELECT target_price, stop_loss FROM analytics.ticker_targets
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) tt ON true
        LEFT JOIN LATERAL (
            SELECT close FROM analytics.ticker_prices
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) tp ON true
        WHERE t.ticker = :ticker
    """), {"ticker": ticker}).fetchone()

    has_data = row is not None and row.score is not None

    if has_data:
        signal = row.signal or "HOLD"
        confidence = row.probability
        score_val = row.score

        # Build reasons from ai_analysis
        reasons = {}
        if row.bullish_reasons:
            reasons["bullish"] = row.bullish_reasons
        if row.bearish_reasons:
            reasons["bearish"] = row.bearish_reasons

        # Build target_action from targets (Ko|||En|||Zh|||Ja|||Es)
        target_action = None
        if row.target_price or row.stop_loss:
            tp, sl = row.target_price, row.stop_loss
            langs = []  # [ko, en, zh, ja, es] 각 언어별 완전한 문자열
            for tpl_target, tpl_stop in [
                ("목표가 ${tp}", "손절가 ${sl}"),
                ("Target ${tp}", "Stop-loss ${sl}"),
                ("目标价 ${tp}", "止损价 ${sl}"),
                ("目標値 ${tp}", "損切り ${sl}"),
                ("Precio objetivo ${tp}", "Stop-loss ${sl}"),
            ]:
                parts = []
                if tp:
                    parts.append(tpl_target.replace("${tp}", f"${tp:.2f}"))
                if sl:
                    parts.append(tpl_stop.replace("${sl}", f"${sl:.2f}"))
                langs.append(" / ".join(parts))
            target_action = "|||".join(langs)

        summary = _INSTANT_ADVICE_TEMPLATES["summary_with_data"].format(
            score=f"{score_val:.0f}", signal=signal,
        )
    else:
        signal = None
        confidence = None
        score_val = None
        reasons = None
        target_action = None
        summary = _INSTANT_ADVICE_TEMPLATES["summary_no_data"]

    # UPSERT into portfolio_advice (user_id, ticker, date=today)
    db.execute(text("""
        INSERT INTO analytics.portfolio_advice
            (user_id, ticker, date, signal, confidence, summary, reasons, target_action)
        VALUES (:uid, :ticker, :dt, :signal, :confidence, :summary, :reasons, :target_action)
        ON CONFLICT (user_id, ticker, date) DO UPDATE SET
            signal = EXCLUDED.signal,
            confidence = EXCLUDED.confidence,
            summary = EXCLUDED.summary,
            reasons = EXCLUDED.reasons,
            target_action = EXCLUDED.target_action
    """), {
        "uid": user_id, "ticker": ticker, "dt": today,
        "signal": signal, "confidence": confidence,
        "summary": summary,
        "reasons": json.dumps(reasons) if reasons else None,
        "target_action": target_action,
    })
    db.commit()

    return PortfolioAdviceResponse(
        ticker=ticker,
        date=today,
        signal=signal,
        confidence=confidence,
        summary=summary,
        reasons=reasons,
        target_action=target_action,
        current_price=row.current_price if has_data else None,
        score=score_val,
    )


# ============================================================
# Holdings CRUD (보유 종목)
# ============================================================

@router.get("/holdings", response_model=List[PortfolioHoldingResponse])
def get_holdings(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 보유 종목 목록 (최신 가격/점수 포함)"""
    rows = db.execute(text("""
        SELECT
            p.ticker, p.shares, p.avg_price, p.notes,
            p.created_at, p.updated_at,
            t.name, t.metadata->>'name_ko' AS name_ko,
            tp.close AS current_price, tp.change_pct,
            ts.score, ts.signal
        FROM analytics.user_portfolios p
        LEFT JOIN analytics.tickers t ON t.ticker = p.ticker
        LEFT JOIN LATERAL (
            SELECT close, change_pct FROM analytics.ticker_prices
            WHERE ticker = p.ticker ORDER BY date DESC LIMIT 1
        ) tp ON true
        LEFT JOIN LATERAL (
            SELECT score, signal FROM analytics.ticker_scores
            WHERE ticker = p.ticker ORDER BY date DESC LIMIT 1
        ) ts ON true
        WHERE p.user_id = :uid AND p.type = 'HOLDING'
        ORDER BY p.created_at DESC
    """), {"uid": user_id}).fetchall()

    return [PortfolioHoldingResponse(
        ticker=r.ticker, shares=r.shares, avg_price=r.avg_price,
        notes=r.notes, created_at=r.created_at, updated_at=r.updated_at,
        name=r.name, name_ko=r.name_ko,
        current_price=r.current_price, change_pct=r.change_pct,
        score=r.score, signal=r.signal,
    ) for r in rows]


@router.post("/holdings", response_model=PortfolioHoldingResponse)
def add_or_update_holding(
    body: PortfolioHoldingCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """보유 종목 추가/수정 (UPSERT) + 즉시 AI 의견 생성"""
    ticker = body.ticker.upper()
    obj = db.query(UserPortfolio).filter(
        UserPortfolio.user_id == user_id,
        UserPortfolio.ticker == ticker,
    ).first()

    if obj:
        obj.type = 'HOLDING'
        obj.shares = body.shares
        obj.avg_price = body.avg_price
        obj.notes = body.notes
        obj.updated_at = datetime.utcnow()
    else:
        obj = UserPortfolio(
            user_id=user_id, ticker=ticker, type='HOLDING',
            shares=body.shares, avg_price=body.avg_price, notes=body.notes,
        )
        db.add(obj)

    db.commit()

    # Fetch enriched data (price, score) via LATERAL JOIN
    enriched = db.execute(text("""
        SELECT
            t.name, t.metadata->>'name_ko' AS name_ko,
            tp.close AS current_price, tp.change_pct,
            ts.score, ts.signal
        FROM analytics.tickers t
        LEFT JOIN LATERAL (
            SELECT close, change_pct FROM analytics.ticker_prices
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) tp ON true
        LEFT JOIN LATERAL (
            SELECT score, signal FROM analytics.ticker_scores
            WHERE ticker = :ticker ORDER BY date DESC LIMIT 1
        ) ts ON true
        WHERE t.ticker = :ticker
    """), {"ticker": ticker}).fetchone()

    # Generate instant advice from existing DB data
    try:
        instant = _generate_instant_advice(db, user_id, ticker)
    except Exception as e:
        logger.warning(f"Instant advice generation failed for {ticker}: {e}")
        instant = None

    # Create or merge analysis request for Mac mini real-time AI analysis
    # If a PENDING request already exists for this user, merge the new change
    # into it so Mac mini processes all recent changes in one batch.
    request_id = None
    try:
        # Fetch all current holdings so Mac mini can populate local DB
        all_holdings = db.query(UserPortfolio).filter(
            UserPortfolio.user_id == user_id,
            UserPortfolio.type == 'HOLDING',
        ).all()
        holdings_list = [
            {"ticker": h.ticker, "shares": float(h.shares), "avg_price": float(h.avg_price)}
            for h in all_holdings
        ]

        existing_req = db.query(AnalysisRequest).filter(
            AnalysisRequest.user_id == user_id,
            AnalysisRequest.status == 'PENDING',
            AnalysisRequest.request_type == 'PORTFOLIO_CHANGE',
        ).first()

        if existing_req:
            changes = existing_req.trigger_data.get("changes", [])
            # Migrate old single-ticker format to changes list
            if not changes and "ticker" in existing_req.trigger_data:
                changes.append({
                    "ticker": existing_req.trigger_data["ticker"],
                    "action": existing_req.trigger_data.get("action", "ADD_HOLDING"),
                    "shares": existing_req.trigger_data.get("shares"),
                    "avg_price": existing_req.trigger_data.get("avg_price"),
                })
            changes.append({
                "ticker": ticker,
                "action": "ADD_HOLDING",
                "shares": body.shares,
                "avg_price": body.avg_price,
            })
            existing_req.trigger_data = {"changes": changes, "holdings": holdings_list}
            existing_req.updated_at = datetime.utcnow()
            flag_modified(existing_req, "trigger_data")
            db.commit()
            request_id = existing_req.id
            logger.info(f"Analysis request merged: id={request_id}, user={user_id}, ticker={ticker}, total_changes={len(changes)}")
        else:
            analysis_req = AnalysisRequest(
                user_id=user_id,
                request_type="PORTFOLIO_CHANGE",
                trigger_data={
                    "changes": [{
                        "ticker": ticker,
                        "action": "ADD_HOLDING",
                        "shares": body.shares,
                        "avg_price": body.avg_price,
                    }],
                    "holdings": holdings_list,
                },
            )
            db.add(analysis_req)
            db.commit()
            db.refresh(analysis_req)
            request_id = analysis_req.id
            logger.info(f"Analysis request created: id={request_id}, user={user_id}, ticker={ticker}")
    except Exception as e:
        logger.warning(f"Analysis request creation failed for {ticker}: {e}")

    return PortfolioHoldingResponse(
        ticker=ticker, shares=obj.shares, avg_price=obj.avg_price,
        notes=obj.notes, created_at=obj.created_at, updated_at=obj.updated_at,
        name=enriched.name if enriched else None,
        name_ko=enriched.name_ko if enriched else None,
        current_price=enriched.current_price if enriched else None,
        change_pct=enriched.change_pct if enriched else None,
        score=enriched.score if enriched else None,
        signal=enriched.signal if enriched else None,
        instant_advice=instant,
        request_id=request_id,
    )


@router.delete("/holdings/{ticker}")
def delete_holding(
    ticker: str,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """보유 종목 삭제"""
    deleted = db.query(UserPortfolio).filter(
        UserPortfolio.user_id == user_id,
        UserPortfolio.ticker == ticker.upper(),
        UserPortfolio.type == 'HOLDING',
    ).delete()
    db.commit()
    return {"deleted": deleted}


# ============================================================
# Watchlist CRUD (관심 종목)
# ============================================================

@router.get("/watchlist", response_model=List[WatchlistItemResponse])
def get_watchlist(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 관심 종목 목록 (최신 가격/점수 포함)"""
    rows = db.execute(text("""
        SELECT
            p.ticker, p.notes, p.created_at,
            t.name, t.metadata->>'name_ko' AS name_ko,
            tp.close AS current_price, tp.change_pct,
            ts.score, ts.signal
        FROM analytics.user_portfolios p
        LEFT JOIN analytics.tickers t ON t.ticker = p.ticker
        LEFT JOIN LATERAL (
            SELECT close, change_pct FROM analytics.ticker_prices
            WHERE ticker = p.ticker ORDER BY date DESC LIMIT 1
        ) tp ON true
        LEFT JOIN LATERAL (
            SELECT score, signal FROM analytics.ticker_scores
            WHERE ticker = p.ticker ORDER BY date DESC LIMIT 1
        ) ts ON true
        WHERE p.user_id = :uid AND p.type = 'WATCHLIST'
        ORDER BY p.created_at DESC
    """), {"uid": user_id}).fetchall()

    return [WatchlistItemResponse(
        ticker=r.ticker, notes=r.notes, created_at=r.created_at,
        name=r.name, name_ko=r.name_ko,
        current_price=r.current_price, change_pct=r.change_pct,
        score=r.score, signal=r.signal,
    ) for r in rows]


@router.post("/watchlist", response_model=WatchlistItemResponse)
def add_watchlist_item(
    body: WatchlistItemCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """관심 종목 추가"""
    ticker = body.ticker.upper()
    existing = db.query(UserPortfolio).filter(
        UserPortfolio.user_id == user_id,
        UserPortfolio.ticker == ticker,
    ).first()

    if existing:
        if existing.type == 'WATCHLIST':
            return WatchlistItemResponse(ticker=ticker, notes=existing.notes, created_at=existing.created_at)
        # Already a HOLDING — keep as holding, don't downgrade
        return WatchlistItemResponse(ticker=ticker, notes=existing.notes, created_at=existing.created_at)

    obj = UserPortfolio(
        user_id=user_id, ticker=ticker, type='WATCHLIST', notes=body.notes,
    )
    db.add(obj)
    db.commit()
    return WatchlistItemResponse(ticker=ticker, notes=obj.notes, created_at=obj.created_at)


@router.delete("/watchlist/{ticker}")
def remove_watchlist_item(
    ticker: str,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """관심 종목 삭제"""
    deleted = db.query(UserPortfolio).filter(
        UserPortfolio.user_id == user_id,
        UserPortfolio.ticker == ticker.upper(),
        UserPortfolio.type == 'WATCHLIST',
    ).delete()
    db.commit()
    return {"deleted": deleted}


@router.post("/watchlist/sync")
def sync_watchlist(
    body: WatchlistBulkSync,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Watchlist 벌크 동기화 (SharedPreferences → Server 마이그레이션).

    기존 로컬 watchlist를 서버로 1회 마이그레이션할 때 사용.
    이미 존재하는 종목은 건너뜀 (HOLDING 유지).
    """
    added = 0
    for ticker in body.tickers:
        ticker = ticker.upper()
        existing = db.query(UserPortfolio).filter(
            UserPortfolio.user_id == user_id,
            UserPortfolio.ticker == ticker,
        ).first()
        if not existing:
            db.add(UserPortfolio(
                user_id=user_id, ticker=ticker, type='WATCHLIST',
            ))
            added += 1

    db.commit()
    return {"synced": added, "total": len(body.tickers)}


# ============================================================
# Transactions CRUD (거래 이력)
# ============================================================

@router.post("/transactions", response_model=TransactionResponse)
def add_transaction(
    body: TransactionCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """거래 기록 추가 (BUY/SELL)"""
    txn = UserTransaction(
        user_id=user_id,
        ticker=body.ticker.upper(),
        type=body.type,
        shares=body.shares,
        price=body.price,
        date=body.date,
        notes=body.notes,
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)

    # SELL 시 실현 손익 계산 → 트랜잭션 자체에 저장 (원본)
    if body.type.upper() == 'SELL':
        holding = db.query(UserPortfolio).filter(
            UserPortfolio.user_id == user_id,
            UserPortfolio.ticker == body.ticker.upper(),
            UserPortfolio.type == 'HOLDING',
        ).first()
        if holding and holding.avg_price is not None:
            rpnl = (body.price - holding.avg_price) * body.shares
            # 트랜잭션 자체에 realized_pnl 저장 (원본 — 실패 시 500)
            txn.realized_pnl = rpnl
            db.commit()
            logger.info(f"Realized P&L saved to txn: user={user_id}, ticker={body.ticker}, pnl={rpnl:.2f}")

            # portfolio_summary에도 기록 (보조, 실패해도 무관)
            try:
                today = date.today()
                summary = db.query(PortfolioSummary).filter(
                    PortfolioSummary.user_id == user_id,
                    PortfolioSummary.date == today,
                ).first()
                if summary:
                    summary.realized_pnl = (summary.realized_pnl or 0) + rpnl
                else:
                    db.add(PortfolioSummary(
                        user_id=user_id,
                        date=today,
                        realized_pnl=rpnl,
                    ))
                db.commit()
            except Exception as e:
                logger.warning(f"Portfolio summary realized_pnl sync failed: {e}")
        else:
            logger.warning(f"SELL realized_pnl skip: holding not found or avg_price is None "
                           f"(user={user_id}, ticker={body.ticker})")

    return txn


@router.get("/transactions", response_model=List[TransactionResponse])
def get_transactions(
    ticker: Optional[str] = Query(None, description="필터: 특정 종목만"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 거래 이력 조회 (최신순)"""
    q = db.query(UserTransaction).filter(UserTransaction.user_id == user_id)
    if ticker:
        q = q.filter(UserTransaction.ticker == ticker.upper())
    q = q.order_by(UserTransaction.date.desc(), UserTransaction.id.desc())
    return q.offset(offset).limit(limit).all()


@router.delete("/transactions/{txn_id}")
def delete_transaction(
    txn_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """거래 기록 삭제"""
    deleted = db.query(UserTransaction).filter(
        UserTransaction.id == txn_id,
        UserTransaction.user_id == user_id,
    ).delete()
    db.commit()
    return {"deleted": deleted}


# ============================================================
# Analysis Status (실시간 분석 상태 폴링)
# ============================================================

@router.get("/analysis-status", response_model=AnalysisStatusResponse)
def get_analysis_status(
    request_id: int = Query(..., description="분석 요청 ID"),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Flutter가 폴링하여 맥미니 AI 분석 진행 상태 확인"""
    row = db.query(AnalysisRequest).filter(
        AnalysisRequest.id == request_id,
        AnalysisRequest.user_id == user_id,
    ).first()

    if not row:
        return AnalysisStatusResponse(
            request_id=request_id,
            status="NOT_FOUND",
        )

    return AnalysisStatusResponse(
        request_id=row.id,
        status=row.status,
        result_summary=row.result_summary,
        created_at=row.created_at,
        completed_at=row.completed_at,
    )


# ============================================================
# Portfolio Advice (AI 의견 조회)
# ============================================================

@router.get("/advice", response_model=List[PortfolioAdviceResponse])
def get_advice(
    target_date: Optional[date] = Query(None, alias="date", description="조회일 (기본: 최신)"),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 종목 AI 의견 조회"""
    if target_date:
        rows = db.query(PortfolioAdvice).filter(
            PortfolioAdvice.user_id == user_id,
            PortfolioAdvice.date == target_date,
        ).all()
    else:
        # summary가 있는 최신 날짜 우선
        latest = db.execute(text(
            "SELECT MAX(date) FROM analytics.portfolio_advice "
            "WHERE user_id = :uid AND summary IS NOT NULL AND summary != ''"
        ), {"uid": user_id}).scalar()
        # fallback: summary 없어도 최신 날짜
        if not latest:
            latest = db.execute(text(
                "SELECT MAX(date) FROM analytics.portfolio_advice WHERE user_id = :uid"
            ), {"uid": user_id}).scalar()
        if not latest:
            return []
        rows = db.query(PortfolioAdvice).filter(
            PortfolioAdvice.user_id == user_id,
            PortfolioAdvice.date == latest,
        ).all()

    return [PortfolioAdviceResponse(
        ticker=r.ticker, date=r.date, signal=r.signal,
        confidence=r.confidence, summary=r.summary,
        reasons=r.reasons, target_action=r.target_action,
    ) for r in rows]


# ============================================================
# Portfolio Summary (P&L 요약 조회)
# ============================================================

@router.get("/summary", response_model=PortfolioSummaryResponse)
def get_summary(
    target_date: Optional[date] = Query(None, alias="date", description="조회일 (기본: 최신)"),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """내 포트폴리오 P&L 요약 조회"""
    if target_date:
        row = db.query(PortfolioSummary).filter(
            PortfolioSummary.user_id == user_id,
            PortfolioSummary.date == target_date,
        ).first()
    else:
        # ── 실시간 계산 (target_date 없을 때) ──

        # 1) 보유 종목 + 최신 가격 조회
        holdings_rows = db.execute(text("""
            SELECT p.ticker, p.shares, p.avg_price,
                   tp.close AS current_price, tp.change_pct
            FROM analytics.user_portfolios p
            LEFT JOIN LATERAL (
                SELECT close, change_pct FROM analytics.ticker_prices
                WHERE ticker = p.ticker ORDER BY date DESC LIMIT 1
            ) tp ON true
            WHERE p.user_id = :uid AND p.type = 'HOLDING'
              AND COALESCE(p.shares, 0) > 0
        """), {"uid": user_id}).fetchall()

        # 2) 실시간 P&L 계산
        total_value = 0.0
        total_cost = 0.0
        day_pnl = 0.0
        holdings_detail = []

        for h in holdings_rows:
            price = h.current_price or 0
            shares = h.shares or 0
            avg = h.avg_price or 0
            cv = price * shares
            cb = avg * shares

            total_value += cv
            total_cost += cb

            if h.change_pct and price:
                prev = price / (1 + h.change_pct / 100)
                day_pnl += (price - prev) * shares

            holdings_detail.append({
                "ticker": h.ticker, "shares": shares,
                "avg_price": avg, "current_price": price,
                "pnl": round(cv - cb, 2),
                "pnl_pct": round((cv - cb) / cb * 100, 2) if cb > 0 else 0,
            })

        total_pnl = total_value - total_cost
        total_pnl_pct = (total_pnl / total_cost * 100) if total_cost > 0 else 0
        day_pnl_pct = (day_pnl / (total_value - day_pnl) * 100) if (total_value - day_pnl) > 0 else 0

        # 3) 누적 실현손익 — user_transactions가 원본 (더 신뢰)
        realized_sum = db.execute(text(
            "SELECT COALESCE(SUM(realized_pnl), 0) "
            "FROM analytics.user_transactions "
            "WHERE user_id = :uid AND type = 'SELL' AND realized_pnl IS NOT NULL"
        ), {"uid": user_id}).scalar() or 0

        # 4) AI 데이터 보충 (맥미니가 넣은 최신 레코드)
        ai_row = db.query(PortfolioSummary).filter(
            PortfolioSummary.user_id == user_id,
            PortfolioSummary.ai_summary.isnot(None),
            PortfolioSummary.ai_summary != '',
        ).order_by(PortfolioSummary.date.desc()).first()

        latest_row = db.query(PortfolioSummary).filter(
            PortfolioSummary.user_id == user_id,
        ).order_by(PortfolioSummary.date.desc()).first()

        # 5) 응답 조립
        return PortfolioSummaryResponse(
            date=date.today(),
            total_value=round(total_value, 2),
            total_cost=round(total_cost, 2),
            total_pnl=round(total_pnl, 2),
            total_pnl_pct=round(total_pnl_pct, 2),
            day_pnl=round(day_pnl, 2),
            day_pnl_pct=round(day_pnl_pct, 2),
            holdings_detail=holdings_detail or None,
            realized_pnl=round(realized_sum, 2),
            ai_summary=ai_row.ai_summary if ai_row else None,
            ai_recommendations=ai_row.ai_recommendations if ai_row else None,
            periods=latest_row.periods if latest_row else None,
            trade_history=latest_row.trade_history if latest_row else None,
        )

    if not row:
        # Return empty summary (never 404)
        return PortfolioSummaryResponse(date=target_date or date.today())

    return row


# ============================================================
# Exchange Rate (환율 조회)
# ============================================================

@router.get("/exchange-rate", response_model=ExchangeRateResponse)
def get_exchange_rate(
    target_date: Optional[date] = Query(None, alias="date"),
    db: Session = Depends(get_db),
    # No auth required — public data
):
    """최신 환율 조회 (USD/KRW)"""
    if target_date:
        row = db.query(ExchangeRate).filter(ExchangeRate.date == target_date).first()
    else:
        row = db.query(ExchangeRate).order_by(ExchangeRate.date.desc()).first()

    if not row:
        return ExchangeRateResponse(date=target_date or date.today(), usd_krw=0)

    return row
