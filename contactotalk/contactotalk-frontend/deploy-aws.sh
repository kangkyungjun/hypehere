#!/bin/bash

# AWS 프론트엔드 배포 스크립트
# 이 스크립트는 AWS 서버에서 프로덕션 빌드를 실행합니다

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SSH_KEY="~/Downloads/contactotalk-key.pem"
AWS_HOST="ubuntu@43.200.129.55"

echo -e "${BLUE}🚀 AWS 프론트엔드 배포 시작...${NC}"

# 1. 기존 프로세스 종료
echo -e "${YELLOW}1. 기존 프로세스 종료 중...${NC}"
ssh -i $SSH_KEY $AWS_HOST "pkill -9 next; pkill -9 node" 2>/dev/null
sleep 2

# 2. 프로덕션 빌드
echo -e "${YELLOW}2. 프로덕션 빌드 실행 중...${NC}"
ssh -i $SSH_KEY $AWS_HOST "cd /home/ubuntu/contactotalk-frontend && NODE_ENV=production npm run build"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 빌드 성공!${NC}"
else
    echo -e "${RED}❌ 빌드 실패!${NC}"
    exit 1
fi

# 3. 프로덕션 서버 시작
echo -e "${YELLOW}3. 프로덕션 서버 시작 중...${NC}"
ssh -i $SSH_KEY $AWS_HOST "cd /home/ubuntu/contactotalk-frontend && nohup npm start > production.log 2>&1 &"
sleep 3

# 4. 상태 확인
echo -e "${YELLOW}4. 서버 상태 확인 중...${NC}"
ssh -i $SSH_KEY $AWS_HOST "ps aux | grep -E 'next-server' | grep -v grep"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 프로덕션 서버 실행 중!${NC}"
    echo -e "${BLUE}📋 환경 정보:${NC}"
    echo "   - 프론트엔드: http://43.200.129.55:3000"
    echo "   - 백엔드 API: http://43.200.129.55:8000/api"
    echo "   - WebSocket: ws://43.200.129.55:8001/ws"
else
    echo -e "${RED}❌ 서버 시작 실패!${NC}"
    echo "로그 확인: ssh -i $SSH_KEY $AWS_HOST 'tail -50 /home/ubuntu/contactotalk-frontend/production.log'"
    exit 1
fi

echo -e "${GREEN}✅ AWS 배포 완료!${NC}"