#!/bin/bash

# HypeHere AWS 서버 업데이트 스크립트
# 서버에서 실행되는 스크립트 (django 사용자 권한으로 실행)

set -e  # 에러 발생 시 즉시 중단

echo "====================================="
echo "  HypeHere 서버 업데이트"
echo "====================================="
echo ""

# Step 1: Git Pull
echo "📥 Step 1: Git Pull..."
git pull origin master

# Step 2: Activate Virtual Environment
echo ""
echo "🐍 Step 2: Activating Virtual Environment..."
source venv/bin/activate

# Step 3: Install Dependencies (if requirements.txt changed)
echo ""
echo "📦 Step 3: Installing Dependencies..."
pip install -r requirements.txt

# Step 4: Run Migrations
echo ""
echo "🔄 Step 4: Running Django Migrations..."
python manage.py migrate

# Step 5: Collect Static Files
echo ""
echo "📁 Step 5: Collecting Static Files..."
python manage.py collectstatic --noinput

# Step 6: Restart Django Service
echo ""
echo "🔄 Step 6: Restarting Django Service (hypehere)..."
sudo systemctl restart hypehere

# Step 7: Check Service Status
echo ""
echo "✅ Step 7: Checking Service Status..."
sudo systemctl status hypehere --no-pager | head -n 10

echo ""
echo "✅ 서버 업데이트 완료!"
echo ""
