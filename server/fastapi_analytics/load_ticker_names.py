#!/usr/bin/env python3
"""Load S&P 500 ticker names from CSV into analytics.tickers table"""

import sys
import csv
from pathlib import Path
from sqlalchemy import create_engine, text
from app.config import settings


def load_ticker_names(csv_path: str):
    """Load ticker names from CSV file into analytics.tickers table"""
    engine = create_engine(settings.DATABASE_ANALYTICS_URL)

    # Read CSV file
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        tickers = list(reader)

    print(f"📊 Found {len(tickers)} tickers in CSV file")

    # Insert/Update into database
    with engine.connect() as conn:
        inserted_count = 0
        updated_count = 0

        for row in tickers:
            ticker = row['ticker']
            name = row['name']

            # Check if ticker already exists
            result = conn.execute(
                text("SELECT ticker FROM analytics.tickers WHERE ticker = :ticker"),
                {'ticker': ticker}
            ).fetchone()

            if result:
                # UPDATE existing record
                conn.execute(text("""
                    UPDATE analytics.tickers
                    SET name = :name, ticker_name = :ticker_name
                    WHERE ticker = :ticker
                """), {
                    'ticker': ticker,
                    'name': name,
                    'ticker_name': name
                })
                updated_count += 1
            else:
                # INSERT new record
                conn.execute(text("""
                    INSERT INTO analytics.tickers (ticker, name, ticker_name)
                    VALUES (:ticker, :name, :ticker_name)
                """), {
                    'ticker': ticker,
                    'name': name,
                    'ticker_name': name
                })
                inserted_count += 1

        conn.commit()
        print(f"✅ Inserted {inserted_count} new tickers")
        print(f"✅ Updated {updated_count} existing tickers")
        print(f"✅ Total: {len(tickers)} ticker names loaded successfully!")


if __name__ == "__main__":
    # CSV file path (command line argument or default)
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    else:
        # Try server path first, then local path
        server_csv = "sp500_ticker_names.csv"
        local_csv = "/Users/kyungjunkang/Documents/marketlens/sp500_ticker_names.csv"

        if Path(server_csv).exists():
            csv_file = server_csv
        elif Path(local_csv).exists():
            csv_file = local_csv
        else:
            print(f"❌ Error: CSV file not found")
            print(f"   Tried: {server_csv}")
            print(f"   Tried: {local_csv}")
            sys.exit(1)

    # Check if file exists
    if not Path(csv_file).exists():
        print(f"❌ Error: CSV file not found at {csv_file}")
        sys.exit(1)

    print(f"📁 Using CSV file: {csv_file}")

    # Load ticker names
    try:
        load_ticker_names(csv_file)
    except Exception as e:
        print(f"❌ Error loading ticker names: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
