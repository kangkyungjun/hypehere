#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 프론트엔드 재시작 중...${NC}"

# 모든 node 프로세스 종료
echo "📋 Node 프로세스 종료 중..."
killall node 2>/dev/null && echo -e "${GREEN}✓ Node 프로세스 종료 완료${NC}" || echo "Node 프로세스 없음"

# 잠시 대기
sleep 2

# 환경변수 확인
echo -e "\n${BLUE}📋 환경변수 확인:${NC}"
if [ -f .env.local ]; then
    echo "NEXT_PUBLIC_API_URL: $(grep NEXT_PUBLIC_API_URL .env.local | cut -d '=' -f2)"
    echo "NEXT_PUBLIC_WS_URL: $(grep NEXT_PUBLIC_WS_URL .env.local | cut -d '=' -f2)"
else
    echo -e "${RED}⚠️  .env.local 파일이 없습니다!${NC}"
fi

# 개발 서버 시작
echo -e "\n${BLUE}🚀 개발 서버 시작...${NC}"
npm run dev
