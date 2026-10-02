#!/usr/bin/env python3
"""
Run database migrations
"""
import sys
import os
from pathlib import Path

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from sqlalchemy import create_engine, text
from app.config import settings

def run_migration(migration_file):
    """Execute migration SQL from file"""
    engine = create_engine(settings.DATABASE_ANALYTICS_URL)

    # Read migration SQL
    migration_path = Path(__file__).parent / "migrations" / migration_file
    with open(migration_path, 'r') as f:
        migration_sql = f.read()

    # Execute
    with engine.connect() as conn:
        conn.execute(text(migration_sql))
        conn.commit()
        print(f"✅ Migration {migration_file} completed successfully!")

def run_all_migrations():
    """Run all migrations in order"""
    migrations = [
        "001_add_ticker_prices.sql",
        "002_add_chart_tables.sql",
    ]

    for migration_file in migrations:
        migration_path = Path(__file__).parent / "migrations" / migration_file
        if migration_path.exists():
            print(f"\n🔄 Running migration: {migration_file}")
            run_migration(migration_file)
        else:
            print(f"⚠️  Migration file not found: {migration_file}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Run specific migration
        run_migration(sys.argv[1])
    else:
        # Run all migrations
        run_all_migrations()
        print("\n✅ All migrations completed!")
