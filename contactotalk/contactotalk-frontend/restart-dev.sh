#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 프론트엔드 재시작 중...${NC}"

# 모든 node 프로세스 종료
echo "📋 Node 프로세스 종료 중..."
killall node 2>/dev/null && echo -e "${GREEN}✓ Node 프로세스 종료 완료${NC}" || echo "Node 프로세스 없음"

# 잠시 대기
sleep 2

# 환경변수 확인 및 환경 판별
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 현재 환경 설정:${NC}"
if [ -f .env.local ]; then
    API_URL=$(grep NEXT_PUBLIC_API_URL .env.local | cut -d '=' -f2)
    WS_URL=$(grep NEXT_PUBLIC_WS_URL .env.local | cut -d '=' -f2)

    # 환경 판별
    if [[ "$API_URL" == *"localhost"* ]] || [[ "$API_URL" == *"127.0.0.1"* ]]; then
        echo -e "${GREEN}🏠 로컬 개발 환경 (LOCAL)${NC}"
        echo -e "${GREEN}   → 로컬 Django 백엔드를 사용합니다${NC}"
    else
        echo -e "${YELLOW}☁️  AWS 연결 환경 (REMOTE)${NC}"
        echo -e "${YELLOW}   → AWS 프로덕션 서버를 사용합니다${NC}"
    fi

    echo -e "\n${CYAN}백엔드 URL:${NC}"
    echo -e "  API: ${API_URL}"
    echo -e "  WebSocket: ${WS_URL}"
else
    echo -e "${RED}⚠️  .env.local 파일이 없습니다!${NC}"
    echo -e "${RED}   환경변수를 설정해주세요.${NC}"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# 개발 서버 시작
echo -e "${BLUE}🚀 개발 서버 시작...${NC}"
npm run dev
