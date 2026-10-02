#!/usr/bin/env python3
"""
DAU/WAU/MAU 롤업 — analytics.user_activity_daily → analytics.admin_user_snapshot.

매일 1회 cron(예: 00:10 KST) 실행. 인자로 날짜(YYYY-MM-DD) 주면 그 날, 없으면 'KST 어제'.
  python rollup_active_users.py            # KST 어제
  python rollup_active_users.py 2026-06-19 # 특정일 재집계

정의(리뷰 확정):
- dau = 전체 COUNT(DISTINCT user_id) (platform NULL 포함). android/ios/unknown 은 별도 집계.
  → 단일일엔 dau_android+dau_ios+dau_unknown = dau (PK(date,user_id)=first-touch).
- wau = trailing 7일 distinct, mau = trailing 30일 distinct. stickiness = dau/wau.
  주/월의 platform 분리는 듀얼기기 유저가 양쪽에 겹칠 수 있어 근사(총량은 항상 overall distinct=권위).
- snapshot 에는 활성 컬럼만 컬럼단위 upsert (total/new 등 타 컬럼 무관).
- 활동은 실시간 기록·당일 닫히면 불변 → 지연도착 재집계 불필요(어제 1일만).
- 보존: 롤업 upsert 완료 '후' raw 90일 초과 삭제. 같은 트랜잭션에 묶어 순서 역전 불가.
"""
import os
import sys
from datetime import datetime, timezone, timedelta, date as date_cls

sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy import create_engine, text
from app.config import settings

KST = timezone(timedelta(hours=9))   # 대시보드 전체 일자 경계와 동일(수집/롤업 일치)
RAW_RETENTION_DAYS = 90


def _target_date(argv) -> date_cls:
    if len(argv) > 1:
        return datetime.strptime(argv[1], "%Y-%m-%d").date()
    return (datetime.now(KST) - timedelta(days=1)).date()


def _distinct(conn, start, end, platform=None) -> int:
    sql = (
        "SELECT COUNT(DISTINCT user_id) FROM analytics.user_activity_daily "
        "WHERE date BETWEEN :s AND :e"
    )
    params = {"s": start, "e": end}
    if platform == "unknown":
        sql += " AND platform IS NULL"
    elif platform is not None:
        sql += " AND platform = :p"
        params["p"] = platform
    return conn.execute(text(sql), params).scalar() or 0


def run(d: date_cls) -> None:
    engine = create_engine(settings.DATABASE_ANALYTICS_URL)
    with engine.begin() as conn:   # 단일 트랜잭션: upsert → delete 순서 고정
        # DAU (당일)
        dau = _distinct(conn, d, d)
        dau_a = _distinct(conn, d, d, "android")
        dau_i = _distinct(conn, d, d, "ios")
        dau_u = _distinct(conn, d, d, "unknown")
        # WAU (trailing 7일)
        w0 = d - timedelta(days=6)
        wau = _distinct(conn, w0, d)
        wau_a = _distinct(conn, w0, d, "android")
        wau_i = _distinct(conn, w0, d, "ios")
        # MAU (trailing 30일)
        m0 = d - timedelta(days=29)
        mau = _distinct(conn, m0, d)
        stickiness = (dau / wau) if wau else None

        conn.execute(
            text("""
                INSERT INTO analytics.admin_user_snapshot
                  (date, dau, dau_android, dau_ios, dau_unknown,
                   wau, wau_android, wau_ios, mau, stickiness)
                VALUES
                  (:d, :dau, :da, :di, :du, :wau, :wa, :wi, :mau, :stick)
                ON CONFLICT (date) DO UPDATE SET
                  dau         = EXCLUDED.dau,
                  dau_android = EXCLUDED.dau_android,
                  dau_ios     = EXCLUDED.dau_ios,
                  dau_unknown = EXCLUDED.dau_unknown,
                  wau         = EXCLUDED.wau,
                  wau_android = EXCLUDED.wau_android,
                  wau_ios     = EXCLUDED.wau_ios,
                  mau         = EXCLUDED.mau,
                  stickiness  = EXCLUDED.stickiness
            """),
            {
                "d": d, "dau": dau, "da": dau_a, "di": dau_i, "du": dau_u,
                "wau": wau, "wa": wau_a, "wi": wau_i, "mau": mau,
                "stick": stickiness,
            },
        )

        # 보존: upsert 이후 같은 트랜잭션에서 raw 90일 초과 삭제(순서 역전 불가).
        cutoff = d - timedelta(days=RAW_RETENTION_DAYS - 1)
        conn.execute(
            text("DELETE FROM analytics.user_activity_daily WHERE date < :c"),
            {"c": cutoff},
        )

    print(
        f"✅ rollup {d}: dau={dau} (a{dau_a}/i{dau_i}/u{dau_u}) "
        f"wau={wau} mau={mau} stickiness={stickiness} | raw<{cutoff} purged"
    )


if __name__ == "__main__":
    run(_target_date(sys.argv))
