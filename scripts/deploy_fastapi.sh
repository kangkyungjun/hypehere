#!/bin/bash

# FastAPI Analytics 로컬 → AWS 자동 배포 스크립트
# 사용법: bash scripts/deploy_fastapi.sh "커밋 메시지"

set -e

if [ -z "$1" ]; then
    echo "❌ 에러: 커밋 메시지를 입력해주세요"
    echo "사용법: bash scripts/deploy_fastapi.sh \"커밋 메시지\""
    exit 1
fi

COMMIT_MSG="$1"
AWS_HOST="ubuntu@43.201.45.60"
SSH_KEY="$HOME/Downloads/hypehere-key.pem"

echo "====================================="
echo "  FastAPI Analytics 자동 배포 시스템"
echo "====================================="
echo ""

# Step 1: Git Add & Commit
echo "📝 Step 1: Git Commit..."
git add .
git commit -m "$COMMIT_MSG" || echo "이미 커밋된 변경사항이 있거나 변경사항 없음"

# Step 2: Git Push
echo ""
echo "📤 Step 2: Git Push to origin/master..."
git push origin master

# Step 3: AWS 서버 배포
echo ""
echo "🚀 Step 3: AWS 서버 FastAPI 배포 시작..."
ssh -i "$SSH_KEY" "$AWS_HOST" << 'ENDSSH'
    sudo su - django << 'ENDSU'
        cd hypehere
        bash scripts/update_fastapi.sh
ENDSU
ENDSSH

echo ""
echo "✅ FastAPI 배포 완료!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 API Docs: https://www.hypehere.net/docs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
