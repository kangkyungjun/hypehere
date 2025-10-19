#!/bin/bash
set -e  # 에러 발생 시 중단

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Contactotalk 배포 시작...${NC}"

# 커밋 메시지 확인
if [ -z "$1" ]; then
    echo -e "${RED}❌ 에러: 커밋 메시지를 입력하세요${NC}"
    echo "사용법: ./deploy/deploy.sh \"커밋 메시지\""
    exit 1
fi

COMMIT_MSG="$1"

echo -e "${BLUE}🔍 로컬 테스트 시작...${NC}"
python manage.py check
echo -e "${GREEN}✓ Django check 통과${NC}"

echo -e "${BLUE}📦 Git commit 및 push...${NC}"
git add .
git status
git commit -m "$COMMIT_MSG" || echo "변경사항이 없거나 이미 커밋됨"
echo -e "${GREEN}✓ Git commit 완료${NC}"

echo -e "${BLUE}🔍 환경 설정 검증...${NC}"
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55 << 'ENVCHECK'
set -e

# 프론트엔드 환경변수 검증
echo "📋 프론트엔드 환경변수 확인..."
cd /home/ubuntu/contactotalk-frontend
if [ ! -f .env.production ]; then
    echo "❌ 에러: .env.production 파일이 없습니다!"
    echo "다음 명령어로 생성하세요:"
    echo "cat > .env.production << 'EOF'"
    echo "NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api"
    echo "NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws"
    echo "EOF"
    exit 1
fi

# API URL 검증
API_URL=$(grep NEXT_PUBLIC_API_URL .env.production | cut -d '=' -f2)
if [[ "$API_URL" != *"43.200.129.55:8000"* ]]; then
    echo "❌ 에러: API URL이 올바르지 않습니다!"
    echo "현재 설정: $API_URL"
    echo "필요 설정: http://43.200.129.55:8000/api"
    exit 1
fi

echo "✅ 환경변수 검증 완료!"
ENVCHECK

echo -e "${BLUE}🌐 AWS 서버 배포 시작...${NC}"
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55 << 'ENDSSH'
set -e
cd /home/ubuntu/contactotalk

echo "📥 코드 가져오기..."
git fetch --all
git reset --hard origin/main || git reset --hard main

echo "🔄 가상환경 활성화..."
source venv/bin/activate

echo "📊 Migration 적용..."
python manage.py migrate

echo "📂 Static 파일 수집..."
python manage.py collectstatic --noinput || true

echo "💾 데이터베이스 백업..."
cp db.sqlite3 db.sqlite3.backup.$(date +%Y%m%d_%H%M%S)

echo "🔄 서버 재시작..."
pkill -f gunicorn || true
pkill -f daphne || true
sleep 2

echo "🚀 Gunicorn 시작..."
nohup gunicorn --config deploy/gunicorn.conf.py contactotalk.wsgi:application > /dev/null 2>&1 &

echo "🚀 Daphne 시작..."
nohup daphne -b 0.0.0.0 -p 8001 contactotalk.asgi:application > /dev/null 2>&1 &

sleep 3
echo "✅ 서버 재시작 완료!"

ENDSSH

echo -e "${GREEN}✅ 배포 완료!${NC}"
echo -e "${BLUE}🌐 웹사이트 확인: http://43.200.129.55:3000${NC}"
