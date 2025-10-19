# Contactotalk 프론트엔드 개발 가이드

## 🚀 빠른 시작

### 개발 서버 시작
```bash
npm run dev
```

서버가 실행되면:
- 프론트엔드: http://localhost:3000
- 백엔드 API: http://43.200.129.55:8000/api
- WebSocket: ws://43.200.129.55:8001/ws

## ⚠️ 중요: 환경변수 관리

### Next.js 환경변수의 특징

**핵심 개념**: Next.js는 환경변수를 **빌드 시점** 또는 **서버 시작 시점**에만 로드합니다.

실행 중인 개발 서버는 환경변수 파일(`.env.local`)이 변경되어도 이전 값을 계속 사용합니다.

### 환경변수 변경 후 필수 작업

**문제 상황**:
```bash
# .env.local 파일을 수정했는데...
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api  # 변경함

# 하지만 브라우저에서는 여전히 이전 값 사용!
# 결과: 로그인 실패 (401 에러), API 호출 실패
```

**해결책**: 프론트엔드 재시작
```bash
# 방법 1: 자동 재시작 스크립트 (권장)
./restart-dev.sh

# 방법 2: 수동 재시작
killall node
npm run dev
```

### 재시작이 필요한 경우

- ✅ `.env.local` 파일 수정 후
- ✅ `git pull`로 환경변수 변경사항을 받은 후
- ✅ API URL 또는 WebSocket URL 변경 후
- ✅ 로그인이나 API 호출이 갑자기 안될 때
- ✅ 환경변수 관련 문제가 의심될 때

### 환경변수 확인 방법

**현재 설정 확인**:
```bash
# .env.local 파일 내용 확인
cat .env.local

# 또는 restart-dev.sh 실행 시 자동으로 확인됨
./restart-dev.sh
```

**올바른 설정**:
```bash
# API URL - AWS Production Server
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api

# WebSocket URL - AWS Production Server
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

## 🔧 개발 워크플로우

### 1. 코드 변경 작업

```bash
# 1. 최신 코드 받기
git pull origin main

# 2. 환경변수 확인 (.env.local이 변경되었나?)
cat .env.local

# 3. 환경변수가 변경되었다면 프론트엔드 재시작
./restart-dev.sh

# 4. 개발 시작
# 코드 수정, 테스트...
```

### 2. 환경변수 변경 작업

```bash
# 1. .env.local 파일 수정
nano .env.local  # 또는 원하는 에디터 사용

# 2. 반드시 프론트엔드 재시작!
./restart-dev.sh

# 3. 브라우저 새로고침
# 이제 새로운 환경변수가 적용됨
```

### 3. Git Pull 후 체크리스트

```bash
# 1. Pull 실행
git pull origin main

# 2. 환경변수 파일 변경 여부 확인
git diff HEAD@{1} .env.local

# 3. 변경되었다면 재시작
./restart-dev.sh

# 4. package.json 변경되었다면 의존성 재설치
npm install
```

## 🐛 문제 해결 가이드

### 로그인이 안돼요 (401 에러)

**증상**:
- 로그인 페이지에서 401 Unauthorized 에러
- 브라우저 콘솔에 `AxiosError: Request failed with status code 401`

**진단 순서**:

1. **환경변수 확인** (가장 흔한 원인!)
   ```bash
   cat .env.local
   # NEXT_PUBLIC_API_URL이 http://43.200.129.55:8000/api인지 확인
   ```

2. **프론트엔드 재시작**
   ```bash
   ./restart-dev.sh
   ```

3. **백엔드 서버 확인**
   ```bash
   curl http://43.200.129.55:8000/api/accounts/login/
   # 400 Bad Request면 서버 정상 (인증 정보 없어서 400)
   # Connection refused면 서버 문제
   ```

4. **브라우저 캐시 삭제**
   - Chrome: Cmd+Shift+Delete
   - 쿠키와 캐시 모두 삭제

### 관심사 목록이 안보여요

**증상**:
- 회원가입 페이지에서 관심사 목록이 비어있음

**해결 순서**:

1. **프론트엔드 재시작** (환경변수 문제일 수 있음)
   ```bash
   ./restart-dev.sh
   ```

2. **API 직접 확인**
   ```bash
   curl http://43.200.129.55:8000/api/accounts/interests/
   # 191개의 관심사 목록이 나와야 함
   ```

3. **브라우저 네트워크 탭 확인**
   - F12 → Network 탭
   - `/api/accounts/interests/` 요청 확인
   - 요청 URL이 올바른지 확인

### WebSocket 연결이 안돼요

**증상**:
- 채팅이 안됨
- 실시간 업데이트가 안됨
- 브라우저 콘솔에 WebSocket 에러

**해결 방법**:

1. **환경변수 확인**
   ```bash
   cat .env.local
   # NEXT_PUBLIC_WS_URL이 ws://43.200.129.55:8001/ws인지 확인
   ```

2. **프론트엔드 재시작**
   ```bash
   ./restart-dev.sh
   ```

3. **WebSocket 서버 확인**
   ```bash
   ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55
   ps aux | grep daphne
   # Daphne 프로세스가 실행 중인지 확인
   ```

### 개발 서버가 시작이 안돼요

**증상**:
- `npm run dev` 실행 시 에러
- 포트가 이미 사용 중이라는 메시지

**해결 방법**:

1. **기존 Node 프로세스 종료**
   ```bash
   killall node
   # 또는
   ./restart-dev.sh
   ```

2. **포트 3000 사용 중인 프로세스 확인**
   ```bash
   lsof -ti:3000 | xargs kill -9
   ```

3. **node_modules 재설치** (필요한 경우)
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

## 📋 체크리스트

### 매일 개발 시작 전
- [ ] `git pull origin main`으로 최신 코드 받기
- [ ] `.env.local` 파일 변경 여부 확인
- [ ] 변경되었다면 `./restart-dev.sh` 실행
- [ ] 브라우저에서 로그인 테스트

### 환경변수 변경 시
- [ ] `.env.local` 파일 수정
- [ ] `./restart-dev.sh` 실행
- [ ] 브라우저 새로고침
- [ ] 로그인 및 API 호출 테스트

### 문제 발생 시
- [ ] 환경변수 확인 (`cat .env.local`)
- [ ] 프론트엔드 재시작 (`./restart-dev.sh`)
- [ ] 백엔드 서버 상태 확인
- [ ] 브라우저 캐시 삭제
- [ ] 에러 로그 확인 (브라우저 콘솔)

## 🔗 관련 문서

- [배포 가이드](../contactotalk/DEPLOYMENT.md) - 프로덕션 배포 방법
- [README](./README.md) - 프로젝트 개요 및 설정

## 📞 문제가 계속되면?

1. 브라우저 콘솔 로그 확인
2. 터미널 에러 메시지 확인
3. 백엔드 서버 로그 확인
4. 개발팀에 문의

## 💡 팁

### 환경변수 자동 확인 습관화
```bash
# 개발 서버 시작 전 항상 확인
cat .env.local && npm run dev
```

### 재시작 스크립트 단축키 설정 (선택사항)
```bash
# .bashrc 또는 .zshrc에 추가
alias restart-front='cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend && ./restart-dev.sh'

# 이제 어디서든 실행 가능
restart-front
```

### Git Hook 설정 (선택사항)
```bash
# .git/hooks/post-merge 파일 생성
#!/bin/bash
if git diff HEAD@{1} --name-only | grep -q ".env.local"; then
    echo "⚠️  .env.local 파일이 변경되었습니다!"
    echo "프론트엔드를 재시작하세요: ./restart-dev.sh"
fi
```

## 🎯 핵심 원칙

1. **환경변수 변경 = 재시작 필수**
2. **의심스러우면 재시작**
3. **Git pull 후에는 환경변수 확인**
4. **로그인 안되면 환경변수부터 확인**

이 원칙들을 따르면 대부분의 개발 환경 문제를 예방할 수 있습니다!
