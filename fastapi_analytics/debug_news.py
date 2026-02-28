"""뉴스 sentiment_score 분포 진단"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
from sqlalchemy import create_engine, text

engine = create_engine(os.getenv("DATABASE_ANALYTICS_URL"))
with engine.connect() as conn:
    # 전체 분포
    r = conn.execute(text("""
        SELECT sentiment_grade, MIN(sentiment_score), MAX(sentiment_score),
               AVG(sentiment_score)::int, COUNT(*)
        FROM analytics.ticker_news WHERE date >= CURRENT_DATE - 7
        GROUP BY 1 ORDER BY 1
    """))
    print("=== 7일간 sentiment 분포 ===")
    for row in r.fetchall():
        print(f"  {row[0]:10s} | min={row[1]:4d} max={row[2]:4d} avg={row[3]:4d} | count={row[4]}")

    # bullish 구간별
    print("\n=== bullish 점수 구간 ===")
    for threshold in [90, 85, 80, 75, 70]:
        r = conn.execute(text(
            "SELECT COUNT(*) FROM analytics.ticker_news "
            "WHERE date >= CURRENT_DATE - 7 AND sentiment_grade = 'bullish' "
            "AND sentiment_score >= :t"
        ), {"t": threshold})
        print(f"  >= {threshold}: {r.scalar()} articles")

    # bearish 구간별
    print("\n=== bearish 점수 구간 ===")
    for threshold in [-70, -75, -80, -85, -90]:
        r = conn.execute(text(
            "SELECT COUNT(*) FROM analytics.ticker_news "
            "WHERE date >= CURRENT_DATE - 7 AND sentiment_grade = 'bearish' "
            "AND sentiment_score <= :t"
        ), {"t": threshold})
        print(f"  <= {threshold}: {r.scalar()} articles")

    # 현재 알림 조건(bullish>=85 OR bearish<=-85) 충족 샘플
    print("\n=== 알림 조건 충족 샘플 (최근 5건) ===")
    r = conn.execute(text("""
        SELECT date, ticker, sentiment_grade, sentiment_score, LEFT(title, 60)
        FROM analytics.ticker_news
        WHERE date >= CURRENT_DATE - 7
          AND ((sentiment_grade = 'bullish' AND sentiment_score >= 85)
            OR (sentiment_grade = 'bearish' AND sentiment_score <= -85))
        ORDER BY date DESC, ABS(sentiment_score) DESC
        LIMIT 5
    """))
    for row in r.fetchall():
        print(f"  {row[0]} | {row[1]:6s} | {row[2]:7s} {row[3]:4d} | {row[4]}")
