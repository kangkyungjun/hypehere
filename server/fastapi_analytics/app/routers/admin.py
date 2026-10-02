"""
어드민 대시보드 (Master 전용).

⚠️ 전 엔드포인트 get_master_user 게이트 — Master 외(매니저 포함) 403.
- GET /api/v1/admin/dashboard/summary       : 유저/활성·다운로드·admob·pnl 요약(JOIN)
- GET /api/v1/admin/dashboard/users?range=30d: DAU/WAU/stickiness/new_users 시계열

데이터 소스:
- users/활성지표 = analytics.admin_user_snapshot (롤업 단독 소유)
- downloads      = analytics.admin_install_daily (맥미니 ingest)
- admob          = analytics.admin_admob_daily   (맥미니 ingest)
- pnl            = 소스 미정 → 현재 null (추후 별도)
TZ는 대시보드 전체와 동일 KST(롤업/수집기 일치).
"""
import json
import logging
from datetime import datetime, timezone, timedelta, date as Date
from decimal import Decimal

from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.auth import get_master_user
from app.schemas import (
    ManagementRecordIn,
    ManagementRecordUpdate,
    DisposalEntryIn,
    SubTaskIn,
    SubTaskPatch,
    BulkManagementRecordsIn,
    BulkSubTasksIn,
    SubTaskCommentIn,
    SubTaskReorderIn,
)

logger = logging.getLogger(__name__)
router = APIRouter()

KST = timezone(timedelta(hours=9))


def _today_kst():
    return datetime.now(KST).date()


@router.get("/dashboard/summary", dependencies=[Depends(get_master_user)])
def dashboard_summary(db: Session = Depends(get_db)):
    """Master 전용 — 최신 스냅샷 + 다운로드/admob 집계 요약."""
    today = _today_kst()
    month_start = today.replace(day=1)

    # ── 유저/활성 지표: 최신 스냅샷 1행 ──
    snap = db.execute(
        text("""
            SELECT date, total_users, android_users, ios_users, new_users_today,
                   dau, dau_android, dau_ios, wau, wau_android, wau_ios,
                   mau, stickiness
            FROM analytics.admin_user_snapshot
            ORDER BY date DESC LIMIT 1
        """)
    ).mappings().fetchone()

    users = {
        "total": (snap and snap["total_users"]) or 0,
        "android": (snap and snap["android_users"]) or 0,
        "ios": (snap and snap["ios_users"]) or 0,
        "new_today": (snap and snap["new_users_today"]) or 0,
        "dau": (snap and snap["dau"]) or 0,
        "dau_android": (snap and snap["dau_android"]) or 0,
        "dau_ios": (snap and snap["dau_ios"]) or 0,
        "wau": (snap and snap["wau"]) or 0,
        "wau_android": (snap and snap["wau_android"]) or 0,
        "wau_ios": (snap and snap["wau_ios"]) or 0,
        "mau": (snap and snap["mau"]) or 0,
        "stickiness": (snap and snap["stickiness"]) or 0.0,
    }

    # ── 다운로드(installs) ──
    dl = db.execute(
        text("""
            SELECT
              COALESCE(SUM(installs), 0) AS total,
              COALESCE(SUM(installs) FILTER (WHERE platform = 'android'), 0) AS android,
              COALESCE(SUM(installs) FILTER (WHERE platform = 'ios'), 0) AS ios,
              COALESCE(SUM(installs) FILTER (WHERE date = :today), 0) AS today
            FROM analytics.admin_install_daily
        """),
        {"today": today},
    ).mappings().fetchone()
    downloads = {
        "total": dl["total"], "android": dl["android"],
        "ios": dl["ios"], "today": dl["today"],
    }

    # ── AdMob 수익 ──
    ad = db.execute(
        text("""
            SELECT
              COALESCE(SUM(revenue_usd) FILTER (WHERE date = :today), 0) AS rev_today,
              COALESCE(SUM(impressions) FILTER (WHERE date = :today), 0) AS imp_today,
              COALESCE(SUM(revenue_usd) FILTER (WHERE date >= :mstart), 0) AS rev_mtd
            FROM analytics.admin_admob_daily
        """),
        {"today": today, "mstart": month_start},
    ).mappings().fetchone()
    imp_today = ad["imp_today"] or 0
    rev_today = float(ad["rev_today"] or 0)
    ecpm = round(rev_today / imp_today * 1000, 4) if imp_today else 0.0
    admob = {
        "revenue_today_usd": round(rev_today, 2),
        "impressions_today": imp_today,
        "ecpm": ecpm,
        "revenue_mtd_usd": round(float(ad["rev_mtd"] or 0), 2),
    }

    return {
        "as_of": str(snap["date"]) if snap else str(today),
        "users": users,
        "downloads": downloads,
        "admob": admob,
        "pnl_mtd": {"income_usd": None, "expense_usd": None, "net_usd": None},
    }


@router.get("/dashboard/users", dependencies=[Depends(get_master_user)])
def dashboard_users(
    range: str = Query("30d", description="예: 30d, 7d, 90d"),
    db: Session = Depends(get_db),
):
    """Master 전용 — DAU/WAU/stickiness/new_users 시계열."""
    # range 파싱(숫자만, 1~365일)
    digits = "".join(ch for ch in range if ch.isdigit())
    days = max(1, min(int(digits) if digits else 30, 365))
    start = _today_kst() - timedelta(days=days - 1)

    rows = db.execute(
        text("""
            SELECT date, dau, dau_android, dau_ios,
                   wau, wau_android, wau_ios, mau, stickiness, new_users_today
            FROM analytics.admin_user_snapshot
            WHERE date >= :start
            ORDER BY date ASC
        """),
        {"start": start},
    ).mappings().fetchall()

    return [
        {
            "date": str(r["date"]),
            "dau": r["dau"] or 0,
            "dau_android": r["dau_android"] or 0,
            "dau_ios": r["dau_ios"] or 0,
            "wau": r["wau"] or 0,
            "wau_android": r["wau_android"] or 0,
            "wau_ios": r["wau_ios"] or 0,
            "mau": r["mau"] or 0,
            "stickiness": r["stickiness"] or 0.0,
            "new_users": r["new_users_today"] or 0,
        }
        for r in rows
    ]


# ============================================================
# 경영·운영 관리 기록 (Master 전용 CRUD) + 자산 등록번호 + 백업 export
# ============================================================

_REC_COLS = (
    "id, kind, category, title, content, amount, currency, direction, "
    "occurred_on, status, recurring, asset_no, asset_type, quantity, vendor, "
    "disposal_history, sub_tasks, "
    "is_deleted, created_by, created_at, updated_at"
)


def _rec(r) -> dict:
    """행(mapping) → JSON 직렬화(날짜·Decimal 변환). JSONB는 dict/list 그대로."""
    out = {}
    for k, v in dict(r).items():
        if isinstance(v, (datetime, Date)):
            out[k] = v.isoformat()
        elif isinstance(v, Decimal):
            out[k] = float(v)
        else:
            out[k] = v
    return out


def _json_dumps(obj) -> str:
    """JSONB 바인딩용 — datetime/date 도 처리."""
    def default(o):
        if isinstance(o, (datetime, Date)):
            return o.isoformat()
        if isinstance(o, Decimal):
            return float(o)
        raise TypeError(f"Unserializable: {type(o)}")
    return json.dumps(obj, ensure_ascii=False, default=default)


def _gen_asset_no(db: Session, asset_type: str | None, year: int) -> str:
    """등록번호 규칙: {AST|SUP}-{연도}-{4자리 일련번호}. (유형,연도)별 max+1."""
    prefix = "SUP" if asset_type == "consumable" else "AST"
    row = db.execute(
        text(
            "SELECT asset_no FROM analytics.management_records "
            "WHERE asset_no LIKE :p ORDER BY asset_no DESC LIMIT 1"
        ),
        {"p": f"{prefix}-{year}-%"},
    ).fetchone()
    nxt = 1
    if row and row[0]:
        try:
            nxt = int(str(row[0]).rsplit("-", 1)[-1]) + 1
        except (ValueError, IndexError):
            nxt = 1
    return f"{prefix}-{year}-{nxt:04d}"


@router.get("/ops/records", dependencies=[Depends(get_master_user)])
def ops_list(
    kind: str = Query(None),
    category: str = Query(None),
    db: Session = Depends(get_db),
):
    """기록 목록(필터: kind, category). 최신순."""
    where, params = ["NOT is_deleted"], {}
    if kind:
        where.append("kind = :kind")
        params["kind"] = kind
    if category:
        where.append("category = :category")
        params["category"] = category
    rows = db.execute(
        text(
            f"SELECT {_REC_COLS} FROM analytics.management_records "
            f"WHERE {' AND '.join(where)} "
            "ORDER BY occurred_on DESC NULLS LAST, id DESC"
        ),
        params,
    ).mappings().fetchall()
    return [_rec(r) for r in rows]


@router.post("/ops/records", dependencies=[Depends(get_master_user)])
def ops_create(
    body: ManagementRecordIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """기록 생성. kind='asset'이면 등록번호 자동 생성."""
    asset_no = None
    if body.kind == "asset":
        year = (body.occurred_on or _today_kst()).year
        asset_no = _gen_asset_no(db, body.asset_type, year)
    row = db.execute(
        text(
            "INSERT INTO analytics.management_records "
            "(kind, category, title, content, amount, currency, direction, "
            " occurred_on, status, recurring, asset_no, asset_type, quantity, "
            " vendor, created_by) "
            "VALUES (:kind,:category,:title,:content,:amount,:currency,:direction,"
            " :occurred_on,:status,:recurring,:asset_no,:asset_type,:quantity,"
            " :vendor,:uid) "
            f"RETURNING {_REC_COLS}"
        ),
        {
            "kind": body.kind, "category": body.category, "title": body.title,
            "content": body.content, "amount": body.amount,
            "currency": body.currency, "direction": body.direction,
            "occurred_on": body.occurred_on, "status": body.status,
            "recurring": body.recurring, "asset_no": asset_no,
            "asset_type": body.asset_type, "quantity": body.quantity,
            "vendor": body.vendor, "uid": user_id,
        },
    ).mappings().fetchone()
    db.commit()
    return _rec(row)


@router.post("/ops/records/bulk", dependencies=[Depends(get_master_user)])
def ops_create_bulk(
    body: BulkManagementRecordsIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """글(record) 여러 건을 한 트랜잭션으로 등록. 1건이라도 실패하면 전체 롤백.
    asset_no 시퀀스는 INSERT마다 _gen_asset_no로 재계산하여 충돌 없이 발급.
    items: 1~200 사이."""
    items_in = body.items or []
    if not items_in:
        raise HTTPException(status_code=400, detail="items is empty")
    if len(items_in) > 200:
        raise HTTPException(status_code=400, detail="too many items (max 200)")

    created: list[dict] = []
    try:
        for it in items_in:
            asset_no = None
            if it.kind == "asset":
                year = (it.occurred_on or _today_kst()).year
                asset_no = _gen_asset_no(db, it.asset_type, year)
            row = db.execute(
                text(
                    "INSERT INTO analytics.management_records "
                    "(kind, category, title, content, amount, currency, direction, "
                    " occurred_on, status, recurring, asset_no, asset_type, quantity, "
                    " vendor, created_by) "
                    "VALUES (:kind,:category,:title,:content,:amount,:currency,:direction,"
                    " :occurred_on,:status,:recurring,:asset_no,:asset_type,:quantity,"
                    " :vendor,:uid) "
                    f"RETURNING {_REC_COLS}"
                ),
                {
                    "kind": it.kind, "category": it.category, "title": it.title,
                    "content": it.content, "amount": it.amount,
                    "currency": it.currency, "direction": it.direction,
                    "occurred_on": it.occurred_on, "status": it.status,
                    "recurring": it.recurring, "asset_no": asset_no,
                    "asset_type": it.asset_type, "quantity": it.quantity,
                    "vendor": it.vendor, "uid": user_id,
                },
            ).mappings().fetchone()
            created.append(_rec(row))
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {"created": len(created), "items": created}


@router.patch("/ops/records/{rid}", dependencies=[Depends(get_master_user)])
def ops_update(
    rid: int,
    body: ManagementRecordUpdate,
    db: Session = Depends(get_db),
):
    """부분 수정. 보낸 필드만 갱신(kind/asset_no 불변)."""
    fields = body.model_dump(exclude_unset=True)
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    sets = ", ".join(f"{k} = :{k}" for k in fields)
    fields["rid"] = rid
    row = db.execute(
        text(
            f"UPDATE analytics.management_records SET {sets}, "
            "updated_at = CURRENT_TIMESTAMP WHERE id = :rid "
            f"RETURNING {_REC_COLS}"
        ),
        fields,
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")
    db.commit()
    return _rec(row)


@router.delete("/ops/records/{rid}", dependencies=[Depends(get_master_user)])
def ops_delete(rid: int, db: Session = Depends(get_db)):
    """소프트 삭제 — is_deleted=TRUE (휴지통·증분백업 삭제전파)."""
    res = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    )
    db.commit()
    if res.rowcount == 0:
        raise HTTPException(status_code=404, detail="Record not found")
    return {"status": "ok", "deleted": rid}


@router.get("/ops/summary", dependencies=[Depends(get_master_user)])
def ops_summary(month: str = Query(None), db: Session = Depends(get_db)):
    """월 P&L 요약(KRW, finance만): 수익/지출/배당/순익."""
    if month:
        y, m = map(int, month.split("-"))
        start = Date(y, m, 1)
    else:
        start = _today_kst().replace(day=1)
    nxt = (start + timedelta(days=32)).replace(day=1)
    row = db.execute(
        text("""
            SELECT
              COALESCE(SUM(amount) FILTER (WHERE direction='in'),0) AS income,
              COALESCE(SUM(amount) FILTER (WHERE direction='out' AND category <> '배당'),0) AS expense,
              COALESCE(SUM(amount) FILTER (WHERE category='배당'),0) AS dividend
            FROM analytics.management_records
            WHERE kind='finance' AND NOT is_deleted
              AND occurred_on >= :s AND occurred_on < :e
        """),
        {"s": start, "e": nxt},
    ).mappings().fetchone()
    income = float(row["income"])
    expense = float(row["expense"])
    dividend = float(row["dividend"])
    return {
        "month": str(start)[:7],
        "currency": "KRW",
        "income": income,
        "expense": expense,
        "dividend": dividend,
        "net": income - expense - dividend,
    }


@router.get("/ops/monthly", dependencies=[Depends(get_master_user)])
def ops_monthly(months: int = Query(12), db: Session = Depends(get_db)):
    """월별 수익/지출/배당/순익 시계열(최근 N개월, KRW) — 한눈에 보기용. 최대 84개월(7년)."""
    months = max(1, min(months, 84))
    cur = _today_kst().replace(day=1)
    first_idx = (cur.year * 12 + (cur.month - 1)) - (months - 1)
    first = Date(first_idx // 12, first_idx % 12 + 1, 1)

    rows = db.execute(
        text("""
            SELECT to_char(date_trunc('month', occurred_on), 'YYYY-MM') AS ym,
              COALESCE(SUM(amount) FILTER (WHERE direction='in'),0) AS income,
              COALESCE(SUM(amount) FILTER (WHERE direction='out' AND category<>'배당'),0) AS expense,
              COALESCE(SUM(amount) FILTER (WHERE category='배당'),0) AS dividend
            FROM analytics.management_records
            WHERE kind='finance' AND NOT is_deleted AND occurred_on >= :first
            GROUP BY 1
        """),
        {"first": first},
    ).mappings().fetchall()
    by = {r["ym"]: r for r in rows}

    out = []
    for i in range(months):
        idx = first_idx + i
        ym = f"{idx // 12:04d}-{idx % 12 + 1:02d}"
        r = by.get(ym)
        inc = float(r["income"]) if r else 0.0
        exp = float(r["expense"]) if r else 0.0
        div = float(r["dividend"]) if r else 0.0
        out.append({
            "month": ym, "income": inc, "expense": exp,
            "dividend": div, "net": inc - exp - div,
        })
    return {"currency": "KRW", "months": out}


# ── 자산: 처분/상태변경 이력 누적 (불용처분/폐기/사용중↔대기 등) ──

def _resolve_actor(db: Session, user_id: int) -> tuple[str, str]:
    """Django accounts_user에서 닉네임·role을 조회해 (nickname, role) 반환.
    실패 시 안전한 fallback("", "")."""
    try:
        row = db.execute(
            text(
                "SELECT nickname, role FROM public.accounts_user WHERE id = :uid"
            ),
            {"uid": user_id},
        ).fetchone()
        if row:
            return (row[0] or "", (row[1] or "").lower())
    except Exception:
        logger.exception("actor lookup failed user_id=%s", user_id)
    return ("", "")


@router.post(
    "/ops/records/{rid}/disposal",
    dependencies=[Depends(get_master_user)],
)
def ops_add_disposal(
    rid: int,
    body: DisposalEntryIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """자산 처분/상태변경 이력 추가. 본문 status가 있으면 status도 동시 갱신."""
    row = db.execute(
        text(
            "SELECT status, kind, disposal_history "
            "FROM analytics.management_records WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")
    if row["kind"] != "asset":
        raise HTTPException(status_code=400, detail="Disposal only allowed on asset records")

    nick, role = _resolve_actor(db, user_id)
    entry = {
        "kind": body.kind,
        "date": body.date.isoformat() if body.date else _today_kst().isoformat(),
        "reason": body.reason or "",
        "from_status": row["status"],
        "to_status": body.to_status,
        "by_user_id": user_id,
        "by_nickname": nick,
        "by_role": role,
        "at": datetime.now(KST).isoformat(),
    }
    new_status = body.to_status if body.to_status else row["status"]
    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET disposal_history = COALESCE(disposal_history, '[]'::jsonb) || :entry::jsonb, "
            "    status = :status, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"entry": _json_dumps(entry), "status": new_status, "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


# ── 계획: 체크리스트(서브태스크) CRUD ──

def _next_subtask_id(items: list) -> int:
    mx = 0
    for it in items or []:
        try:
            v = int(it.get("id") or 0)
            if v > mx:
                mx = v
        except Exception:
            continue
    return mx + 1


def _next_comment_id(comments: list) -> int:
    mx = 0
    for c in comments or []:
        try:
            v = int(c.get("id") or 0)
            if v > mx:
                mx = v
        except Exception:
            continue
    return mx + 1


@router.post(
    "/ops/records/{rid}/subtasks",
    dependencies=[Depends(get_master_user)],
)
def ops_add_subtask(
    rid: int,
    body: SubTaskIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """체크리스트 항목 추가. 작성자(by) 자동 스냅샷."""
    row = db.execute(
        text(
            "SELECT kind, sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")
    if row["kind"] != "plan":
        raise HTTPException(status_code=400, detail="Sub-tasks only allowed on plan records")

    nick, role = _resolve_actor(db, user_id)
    items = list(row["sub_tasks"] or [])
    item = {
        "id": _next_subtask_id(items),
        "title": body.title.strip(),
        "done": False,
        "assignee": (body.assignee or "").strip() or None,
        "created_by_id": user_id,
        "created_by_nickname": nick,
        "created_by_role": role,
        "created_at": datetime.now(KST).isoformat(),
        "done_by_id": None,
        "done_by_nickname": None,
        "done_at": None,
    }
    items.append(item)
    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.post(
    "/ops/records/{rid}/subtasks/bulk",
    dependencies=[Depends(get_master_user)],
)
def ops_add_subtasks_bulk(
    rid: int,
    body: BulkSubTasksIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """체크리스트 N개를 한 트랜잭션으로 추가. plan 글에만 허용.
    titles 빈 줄/공백은 자동 스킵. 공통 담당자(선택)."""
    titles = [t.strip() for t in (body.titles or []) if t and t.strip()]
    if not titles:
        raise HTTPException(status_code=400, detail="titles is empty")
    if len(titles) > 200:
        raise HTTPException(status_code=400, detail="too many titles (max 200)")

    row = db.execute(
        text(
            "SELECT kind, sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")
    if row["kind"] != "plan":
        raise HTTPException(
            status_code=400, detail="Sub-tasks only allowed on plan records"
        )

    nick, role = _resolve_actor(db, user_id)
    items = list(row["sub_tasks"] or [])
    assignee = (body.assignee or "").strip() or None
    now_iso = datetime.now(KST).isoformat()
    next_id = _next_subtask_id(items)
    for title in titles:
        items.append({
            "id": next_id,
            "title": title,
            "done": False,
            "assignee": assignee,
            "created_by_id": user_id,
            "created_by_nickname": nick,
            "created_by_role": role,
            "created_at": now_iso,
            "done_by_id": None,
            "done_by_nickname": None,
            "done_at": None,
        })
        next_id += 1

    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.patch(
    "/ops/records/{rid}/subtasks/{sid}",
    dependencies=[Depends(get_master_user)],
)
def ops_patch_subtask(
    rid: int,
    sid: int,
    body: SubTaskPatch,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """체크리스트 항목 수정/완료토글. done=True 전환 시 처리자 스냅샷."""
    row = db.execute(
        text(
            "SELECT sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")

    items = list(row["sub_tasks"] or [])
    target = None
    for it in items:
        if int(it.get("id") or 0) == sid:
            target = it
            break
    if target is None:
        raise HTTPException(status_code=404, detail="Subtask not found")

    if body.title is not None:
        target["title"] = body.title.strip()
    if body.assignee is not None:
        target["assignee"] = body.assignee.strip() or None

    # 상태 변경 — done(bool) 또는 status(enum) 둘 중 하나만 와도 OK. 둘 다 오면 status 우선.
    new_status = None
    if body.status is not None:
        if body.status not in ("todo", "in_progress", "done", "failed", "blocked"):
            raise HTTPException(status_code=400, detail="invalid status")
        new_status = body.status
    elif body.done is not None:
        # 구버전 클라이언트(done만 보냄) 호환 — done=false 면 todo로 되돌림.
        new_status = "done" if body.done else "todo"

    if new_status is not None:
        was_done = bool(target.get("done")) or target.get("status") == "done"
        target["status"] = new_status
        target["done"] = (new_status == "done")
        # done 전환 시 처리자 스냅샷, 해제 시 정리
        if new_status == "done" and not was_done:
            nick, role = _resolve_actor(db, user_id)
            target["done_by_id"] = user_id
            target["done_by_nickname"] = nick
            target["done_by_role"] = role
            target["done_at"] = datetime.now(KST).isoformat()
        elif new_status != "done" and was_done:
            target["done_by_id"] = None
            target["done_by_nickname"] = None
            target["done_at"] = None

    # 실패/보류 사유(선택). 빈 문자열로 명시적 클리어 가능.
    if body.resolution_note is not None:
        target["resolution_note"] = body.resolution_note.strip() or None

    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.delete(
    "/ops/records/{rid}/subtasks/{sid}",
    dependencies=[Depends(get_master_user)],
)
def ops_delete_subtask(
    rid: int,
    sid: int,
    db: Session = Depends(get_db),
):
    """체크리스트 항목 삭제."""
    row = db.execute(
        text(
            "SELECT sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")

    items = [it for it in (row["sub_tasks"] or []) if int(it.get("id") or 0) != sid]
    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


# ── SubTask 코멘트(진행 현황 스레드) ──

@router.post(
    "/ops/records/{rid}/subtasks/{sid}/comments",
    dependencies=[Depends(get_master_user)],
)
def ops_add_subtask_comment(
    rid: int,
    sid: int,
    body: SubTaskCommentIn,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """SubTask에 진행 현황 코멘트 추가. 작성자 스냅샷 자동.
    `body`는 공백 제거 후 길이 1~2000."""
    text_body = (body.body or "").strip()
    if not text_body:
        raise HTTPException(status_code=400, detail="empty body")
    if len(text_body) > 2000:
        raise HTTPException(status_code=400, detail="body too long (max 2000)")

    row = db.execute(
        text(
            "SELECT sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")

    items = list(row["sub_tasks"] or [])
    target = next((it for it in items if int(it.get("id") or 0) == sid), None)
    if target is None:
        raise HTTPException(status_code=404, detail="Subtask not found")

    nick, role = _resolve_actor(db, user_id)
    comments = list(target.get("comments") or [])
    comments.append({
        "id": _next_comment_id(comments),
        "body": text_body,
        "by_user_id": user_id,
        "by_nickname": nick,
        "by_role": role,
        "at": datetime.now(KST).isoformat(),
    })
    target["comments"] = comments

    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.delete(
    "/ops/records/{rid}/subtasks/{sid}/comments/{cid}",
    dependencies=[Depends(get_master_user)],
)
def ops_delete_subtask_comment(
    rid: int,
    sid: int,
    cid: int,
    user_id: int = Depends(get_master_user),
    db: Session = Depends(get_db),
):
    """SubTask 코멘트 삭제. 모든 ops 라우트가 Master 게이트라 별도 본인 체크는 불필요
    (작성자 = Master). 추후 manager/일반에게 코멘트 권한을 열 경우 본인 가드 추가."""
    row = db.execute(
        text(
            "SELECT sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")

    items = list(row["sub_tasks"] or [])
    target = next((it for it in items if int(it.get("id") or 0) == sid), None)
    if target is None:
        raise HTTPException(status_code=404, detail="Subtask not found")

    before = list(target.get("comments") or [])
    after = [c for c in before if int(c.get("id") or 0) != cid]
    if len(after) == len(before):
        raise HTTPException(status_code=404, detail="Comment not found")
    target["comments"] = after

    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(items), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.post(
    "/ops/records/{rid}/subtasks/reorder",
    dependencies=[Depends(get_master_user)],
)
def ops_reorder_subtasks(
    rid: int,
    body: SubTaskReorderIn,
    db: Session = Depends(get_db),
):
    """드래그 후 신규 항목 순서로 sub_tasks 배열을 재배치.
    body.order에 누락된 id가 있으면 기존 순서대로 뒤에 append (안전 폴백)."""
    row = db.execute(
        text(
            "SELECT sub_tasks FROM analytics.management_records "
            "WHERE id = :rid AND NOT is_deleted"
        ),
        {"rid": rid},
    ).mappings().fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Record not found")

    items = list(row["sub_tasks"] or [])
    by_id = {int(it.get("id") or 0): it for it in items}
    ordered: list[dict] = []
    seen: set[int] = set()
    for sid in body.order or []:
        it = by_id.get(int(sid))
        if it is not None and int(sid) not in seen:
            ordered.append(it)
            seen.add(int(sid))
    # 누락된 항목은 기존 순서로 뒤에 붙여 보존.
    for it in items:
        sid = int(it.get("id") or 0)
        if sid not in seen:
            ordered.append(it)

    updated = db.execute(
        text(
            "UPDATE analytics.management_records "
            "SET sub_tasks = :items::jsonb, updated_at = CURRENT_TIMESTAMP "
            f"WHERE id = :rid RETURNING {_REC_COLS}"
        ),
        {"items": _json_dumps(ordered), "rid": rid},
    ).mappings().fetchone()
    db.commit()
    return _rec(updated)


@router.get("/ops/category-breakdown", dependencies=[Depends(get_master_user)])
def ops_category_breakdown(
    month: str = Query(None, description="YYYY-MM (미지정 시 현재월)"),
    db: Session = Depends(get_db),
):
    """월별 finance 기록을 카테고리별로 합산.
    응답:
        {
          month, currency,
          income:  [{category, amount, share}, …],  # direction='in' (전부)
          expense: [{category, amount, share}, …],  # direction='out' AND category!='배당'
          dividend: amount
        }
    share = 각 그룹 합계 대비 비중(0~1).  카테고리는 amount DESC 정렬.
    """
    if month:
        y, m = map(int, month.split("-"))
        start = Date(y, m, 1)
    else:
        start = _today_kst().replace(day=1)
    nxt = (start + timedelta(days=32)).replace(day=1)

    rows = db.execute(
        text("""
            SELECT direction, category,
                   COALESCE(SUM(amount), 0) AS total
            FROM analytics.management_records
            WHERE kind='finance' AND NOT is_deleted
              AND occurred_on >= :s AND occurred_on < :e
            GROUP BY direction, category
        """),
        {"s": start, "e": nxt},
    ).mappings().fetchall()

    income, expense = [], []
    dividend = 0.0
    for r in rows:
        amt = float(r["total"] or 0)
        if amt == 0:
            continue
        if r["category"] == "배당":
            dividend += amt
            continue
        item = {"category": r["category"], "amount": amt}
        if r["direction"] == "in":
            income.append(item)
        else:
            expense.append(item)

    def _with_share(items: list) -> list:
        s = sum(i["amount"] for i in items) or 0
        items.sort(key=lambda x: x["amount"], reverse=True)
        for i in items:
            i["share"] = round(i["amount"] / s, 4) if s else 0.0
        return items

    return {
        "month": str(start)[:7],
        "currency": "KRW",
        "income": _with_share(income),
        "expense": _with_share(expense),
        "dividend": dividend,
    }


@router.get("/ops/export", dependencies=[Depends(get_master_user)])
def ops_export(db: Session = Depends(get_db)):
    """전체 기록 JSON 덤프 — 백업용(맥미니가 주기적으로 pull해 로컬 보관)."""
    rows = db.execute(
        text(f"SELECT {_REC_COLS} FROM analytics.management_records ORDER BY id")
    ).mappings().fetchall()
    return {
        "exported_at": datetime.now(KST).isoformat(),
        "count": len(rows),
        "records": [_rec(r) for r in rows],
    }
