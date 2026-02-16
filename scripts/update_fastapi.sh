#!/bin/bash

# FastAPI Analytics AWS 서버 업데이트 스크립트
# 서버에서 실행 (django 사용자 권한)

set -e

echo "====================================="
echo "  FastAPI Analytics 서버 업데이트"
echo "====================================="
echo ""

# Step 1: Git Pull
echo "📥 Step 1: Git Pull..."
git pull origin master

# Step 2: Activate Virtual Environment
echo ""
echo "🐍 Step 2: Activating Virtual Environment..."
source venv/bin/activate

# Step 3: Install FastAPI Dependencies
echo ""
echo "📦 Step 3: Installing FastAPI Dependencies..."
pip install -r fastapi_analytics/requirements.txt

# Step 4: Restart FastAPI Service
echo ""
echo "🔄 Step 4: Restarting FastAPI Service (fastapi-analytics)..."
sudo systemctl restart fastapi-analytics

# Step 5: Check Service Status
echo ""
echo "✅ Step 5: Checking Service Status..."
sudo systemctl status fastapi-analytics --no-pager | head -n 10

echo ""
echo "✅ FastAPI 서버 업데이트 완료!"
echo ""
