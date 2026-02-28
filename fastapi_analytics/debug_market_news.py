"""MARKET 뉴스 알림 현황 진단"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
from sqlalchemy import create_engine, text

engine = create_engine(os.getenv("DATABASE_ANALYTICS_URL"))
with engine.connect() as conn:
    r = conn.execute(text("SELECT COUNT(*) FROM analytics.ticker_news WHERE ticker = 'MARKET'"))
    print(f"MARKET 뉴스 전체: {r.scalar()}")

    r = conn.execute(text("SELECT COUNT(*) FROM analytics.ticker_news WHERE ticker = 'MARKET' AND date >= CURRENT_DATE - 7"))
    print(f"MARKET 뉴스 7일: {r.scalar()}")

    r = conn.execute(text("SELECT COUNT(*) FROM analytics.ticker_news WHERE ticker = 'MARKET' AND date >= CURRENT_DATE - 7 AND sentiment_grade = 'bullish' AND sentiment_score >= 85"))
    print(f"MARKET bullish>=85 (7일): {r.scalar()}")

    r = conn.execute(text("SELECT COUNT(*) FROM analytics.ticker_news WHERE ticker = 'MARKET' AND date >= CURRENT_DATE - 7 AND sentiment_grade = 'bearish' AND sentiment_score <= -85"))
    print(f"MARKET bearish<=-85 (7일): {r.scalar()}")

    print("\n=== 조건 충족 MARKET 뉴스 샘플 ===")
    r = conn.execute(text("""
        SELECT date, sentiment_grade, sentiment_score, LEFT(title, 70)
        FROM analytics.ticker_news
        WHERE ticker = 'MARKET' AND date >= CURRENT_DATE - 7
          AND ((sentiment_grade = 'bullish' AND sentiment_score >= 85)
            OR (sentiment_grade = 'bearish' AND sentiment_score <= -85))
        ORDER BY date DESC LIMIT 10
    """))
    rows = r.fetchall()
    if not rows:
        print("  (없음)")
    for row in rows:
        print(f"  {row[0]} | {row[1]:7s} {row[2]:4d} | {row[3]}")
