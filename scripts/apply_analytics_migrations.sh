#!/bin/bash

# Analytics 스키마 SQL 마이그레이션 실행 스크립트
# AWS 서버에서 실행 (django 사용자 권한)
# 사용법: bash scripts/apply_analytics_migrations.sh

set -e

MIGRATIONS_DIR="fastapi_analytics/migrations"

echo "====================================="
echo "  Analytics Schema Migration Runner"
echo "====================================="
echo ""

# .env에서 DB URL 추출
if [ -f "fastapi_analytics/.env" ]; then
    DB_URL=$(grep DATABASE_ANALYTICS_URL fastapi_analytics/.env | cut -d'=' -f2-)
    echo "📦 DB URL found in fastapi_analytics/.env"
else
    echo "❌ fastapi_analytics/.env 파일이 없습니다"
    echo "   DATABASE_ANALYTICS_URL을 직접 입력하세요:"
    read -r DB_URL
fi

# PostgreSQL 연결 정보 파싱 (postgresql://user:pass@host:port/dbname?options=...)
DB_USER=$(echo "$DB_URL" | sed -n 's|postgresql://\([^:]*\):.*|\1|p')
DB_PASS=$(echo "$DB_URL" | sed -n 's|postgresql://[^:]*:\([^@]*\)@.*|\1|p')
DB_HOST=$(echo "$DB_URL" | sed -n 's|postgresql://[^@]*@\([^:]*\):.*|\1|p')
DB_PORT=$(echo "$DB_URL" | sed -n 's|postgresql://[^@]*@[^:]*:\([0-9]*\)/.*|\1|p')
DB_NAME=$(echo "$DB_URL" | sed -n 's|postgresql://[^/]*/\([^?]*\).*|\1|p')

echo "🔗 Host: $DB_HOST:$DB_PORT / DB: $DB_NAME"
echo ""

# 마이그레이션 파일 순서 (의존성 순서대로)
MIGRATION_FILES=(
    "20260217_add_macro_calendar_earnings.sql"
    "20260217_add_macro_signals_charts.sql"
    "20260217_add_dday_columns.sql"
    "20260217_add_defense_recs_holders.sql"
)

export PGPASSWORD="$DB_PASS"

for FILE in "${MIGRATION_FILES[@]}"; do
    FILEPATH="$MIGRATIONS_DIR/$FILE"
    if [ -f "$FILEPATH" ]; then
        echo "🔄 Applying: $FILE ..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$FILEPATH" 2>&1
        echo "   ✅ Done"
        echo ""
    else
        echo "   ⚠️ File not found: $FILEPATH (skipping)"
    fi
done

unset PGPASSWORD

# 테이블 생성 확인
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Verifying created tables..."
export PGPASSWORD="$DB_PASS"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'analytics'
ORDER BY table_name;
"
unset PGPASSWORD

echo ""
echo "✅ 마이그레이션 완료!"
