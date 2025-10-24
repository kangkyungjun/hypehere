# Contactotalk 운영 가이드

## 🎯 핵심 원칙

**로컬과 AWS는 완전히 다른 운영 방식을 사용합니다!**

| 구분 | 로컬 개발 | AWS 프로덕션 |
|------|-----------|-------------|
| **실행 명령** | `npm run dev` | `npm run build` + `npm start` |
| **모드** | 개발 모드 (development) | 프로덕션 모드 (production) |
| **백엔드** | http://localhost:8000 | http://43.200.129.55:8000 |
| **WebSocket** | ws://localhost:8001 | ws://43.200.129.55:8001 |
| **환경변수** | .env.local (localhost) | .env.local (43.200.129.55) |
| **포트** | 3000 | 3000 |

---

## 🏠 로컬 개발 환경

### 시작 방법

```bash
# 1. 환경 확인
cat .env.local
# localhost가 포함되어 있어야 함

# 2. 백엔드 시작 (터미널 1)
cd /Users/kyungjunkang/PycharmProjects/contactotalk
python manage.py runserver

# 3. 프론트엔드 시작 (터미널 2)
cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend
./restart-dev.sh  # 자동으로 환경 표시
```

### 환경 표시
```
🏠 로컬 개발 환경 (LOCAL)
   → 로컬 Django 백엔드를 사용합니다
```

### 특징
- **Hot Reload**: 코드 수정 시 자동 새로고침
- **개발 도구**: React DevTools, Redux DevTools 사용 가능
- **디버깅**: 소스맵 포함, 에러 메시지 상세
- **API Proxy**: next.config.js의 rewrites 활성화

---

## ☁️ AWS 프로덕션 환경

### 시작 방법

#### 방법 1: 배포 스크립트 사용 (권장)
```bash
cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend
./deploy-aws.sh
```

#### 방법 2: 수동 배포
```bash
# 1. AWS 서버 접속
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55

# 2. 기존 프로세스 종료
pkill -9 next
pkill -9 node

# 3. 프로덕션 빌드
cd /home/ubuntu/contactotalk-frontend
NODE_ENV=production npm run build

# 4. 프로덕션 서버 시작
npm start
# 또는 백그라운드 실행
nohup npm start > production.log 2>&1 &
```

### 환경 확인
```bash
# 환경변수 확인
cat /home/ubuntu/contactotalk-frontend/.env.local

# 올바른 설정:
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

### 특징
- **최적화**: 코드 압축, 번들 최적화
- **성능**: SSR/SSG 활성화, 캐싱 적용
- **보안**: 프로덕션 모드 보안 설정
- **API 직접 호출**: 환경변수의 URL 직접 사용

---

## ⚠️ 중요한 차이점

### 1. next.config.js의 rewrites

```javascript
// 개발 모드에서만 작동
if (process.env.NODE_ENV === 'development') {
  return [{
    source: '/api/:path*',
    destination: 'http://localhost:8000/api/:path*',
  }];
}
```

**영향**:
- 로컬: `/api/*` 요청이 자동으로 localhost:8000으로 프록시
- AWS: 환경변수의 NEXT_PUBLIC_API_URL 직접 사용

### 2. 환경변수 번들링

- **개발 모드**: 환경변수 동적 로드 (재시작 필요)
- **프로덕션 모드**: 빌드 시점에 환경변수 번들에 포함

### 3. 에러 처리

- **개발 모드**: 상세한 에러 스택 표시
- **프로덕션 모드**: 사용자 친화적 에러 페이지

---

## 🚨 문제 해결

### AWS에서 로그인/관심사가 안 될 때

**원인**: 개발 모드로 실행 중 (npm run dev)

**해결**:
```bash
# AWS 서버에서
pkill -9 next
pkill -9 node
cd /home/ubuntu/contactotalk-frontend
NODE_ENV=production npm run build
npm start
```

### 환경변수가 반영되지 않을 때

**로컬**:
```bash
./restart-dev.sh
```

**AWS**:
```bash
# 프로덕션은 반드시 재빌드 필요
npm run build
npm start
```

### API 호출이 실패할 때

1. **환경변수 확인**
```bash
cat .env.local
```

2. **백엔드 상태 확인**
```bash
# 로컬
curl http://localhost:8000/api/accounts/interests/

# AWS
curl http://43.200.129.55:8000/api/accounts/interests/
```

3. **CORS 설정 확인** (백엔드)
```python
# settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://43.200.129.55:3000",
]
```

---

## 📋 체크리스트

### 로컬 개발 시작 전
- [ ] `.env.local`이 localhost를 가리키는지 확인
- [ ] Django 백엔드 실행 중인지 확인
- [ ] `./restart-dev.sh` 실행

### AWS 배포 전
- [ ] 코드 커밋 및 푸시
- [ ] AWS 서버에서 최신 코드 pull
- [ ] `.env.local`이 AWS IP를 가리키는지 확인
- [ ] `NODE_ENV=production` 설정
- [ ] 프로덕션 빌드 실행

### 배포 후
- [ ] 프론트엔드 접속 테스트
- [ ] 로그인 기능 테스트
- [ ] 관심사 목록 확인
- [ ] WebSocket 연결 확인

---

## 🔑 핵심 명령어

### 로컬
```bash
# 개발 서버 시작
npm run dev
./restart-dev.sh

# 환경 전환 (AWS로)
cp .env.aws .env.local
./restart-dev.sh
```

### AWS
```bash
# 프로덕션 배포
./deploy-aws.sh

# 수동 배포
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55
cd /home/ubuntu/contactotalk-frontend
npm run build
npm start

# 로그 확인
tail -f production.log
```

---

## 📊 상태 모니터링

### 프로세스 확인
```bash
# 로컬
ps aux | grep node

# AWS
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55 "ps aux | grep next"
```

### API 테스트
```bash
# 관심사 목록
curl http://43.200.129.55:8000/api/accounts/interests/

# 로그인 엔드포인트
curl -X POST http://43.200.129.55:8000/api/accounts/login/
```

---

## 💡 Best Practices

1. **로컬에서는 항상 개발 모드 사용**
   - Hot reload로 빠른 개발
   - 디버깅 도구 활용

2. **AWS에서는 반드시 프로덕션 모드 사용**
   - 최적화된 성능
   - 보안 강화

3. **환경변수 변경 후**
   - 로컬: `./restart-dev.sh`
   - AWS: 재빌드 필수

4. **배포 전 체크**
   - 로컬에서 충분히 테스트
   - Git에 커밋
   - AWS에서 pull 후 빌드

5. **로그 관리**
   - 로컬: 콘솔 출력
   - AWS: production.log 파일

---

## 🚀 자동화 도구

### deploy-aws.sh
- 자동으로 빌드 및 배포
- 상태 확인 포함
- 에러 처리

### restart-dev.sh
- 환경 자동 감지
- 색상으로 환경 표시
- 프로세스 자동 정리

---

이 가이드를 따르면 로컬과 AWS 환경을 명확히 구분하여 운영할 수 있습니다!