"""FCM 알림 시스템 진단 스크립트"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

from sqlalchemy import create_engine, text

url = os.getenv("DATABASE_ANALYTICS_URL")
engine = create_engine(url)

with engine.connect() as conn:
    # 1) DeviceToken
    r = conn.execute(text("SELECT COUNT(*), SUM(CASE WHEN is_active THEN 1 ELSE 0 END) FROM public.accounts_devicetoken"))
    total, active = r.fetchone()
    print(f"[DeviceToken] total={total}, active={active}")

    # 2) Language
    r = conn.execute(text("SELECT COALESCE(language, 'en') as lang, COUNT(*) FROM public.accounts_devicetoken WHERE is_active = TRUE GROUP BY 1"))
    for row in r.fetchall():
        print(f"  lang={row[0]}: {row[1]}")

    # 3) Firebase
    fb = os.getenv("FIREBASE_CREDENTIALS_PATH", "NOT SET")
    exists = os.path.exists(fb) if fb != "NOT SET" else False
    print(f"[Firebase] path={fb}, exists={exists}")

    # 4) Notification log
    r = conn.execute(text("SELECT date, ticker, signal_type, recipients_count, success_count, failure_count, error_detail FROM analytics.notification_log ORDER BY created_at DESC LIMIT 10"))
    rows = r.fetchall()
    print(f"[NotificationLog] entries={len(rows)}")
    for row in rows:
        print(f"  {row[0]} | {row[1]:6s} | {row[2]:20s} | rcpt={row[3]} ok={row[4]} fail={row[5]} err={row[6]}")

    # 5) Recent scores
    r = conn.execute(text("""
        SELECT date, COUNT(*),
            SUM(CASE WHEN score >= 80 THEN 1 ELSE 0 END),
            SUM(CASE WHEN score <= 20 THEN 1 ELSE 0 END)
        FROM analytics.ticker_scores
        WHERE date >= CURRENT_DATE - 7
        GROUP BY date ORDER BY date DESC
    """))
    print("[RecentScores]")
    for row in r.fetchall():
        print(f"  {row[0]}: total={row[1]}, buy(>=80)={row[2]}, sell(<=20)={row[3]}")

    # 6) Subscriptions
    r = conn.execute(text("SELECT COUNT(*) FROM public.accounts_notificationsubscription WHERE is_active = TRUE"))
    print(f"[Subscriptions] active={r.scalar()}")

    # 7) RateLimit
    r = conn.execute(text("SELECT COUNT(*) FROM public.accounts_notificationratelimit"))
    print(f"[RateLimit] entries={r.scalar()}")

    # 8) NotificationHistory
    r = conn.execute(text("SELECT COUNT(*) FROM public.accounts_notification_history"))
    print(f"[NotificationHistory] entries={r.scalar()}")
