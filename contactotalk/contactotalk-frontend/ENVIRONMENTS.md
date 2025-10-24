# Contactotalk 환경 설정 가이드

## 🎯 환경 구분

Contactotalk는 두 가지 개발 환경을 지원합니다:

| 환경 | 설명 | 사용 시나리오 |
|------|------|--------------|
| **로컬 (LOCAL)** | 로컬 머신에서 백엔드와 프론트엔드 모두 실행 | 일반적인 로컬 개발, 빠른 테스트 |
| **AWS 연결 (REMOTE)** | 로컬 프론트엔드에서 AWS 백엔드 연결 | AWS 서버 데이터로 테스트, 프로덕션 환경 시뮬레이션 |

## 📁 환경 파일 구조

```
contactotalk-frontend/
├── .env.local          # 현재 사용 중인 환경 (Git 무시됨)
├── .env.aws            # AWS 연결 설정 (참고용)
└── .env.local.example  # 예제 파일
```

## 🏠 로컬 개발 환경 (기본)

### 설정
**파일**: `.env.local`
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_WS_URL=ws://localhost:8001/ws
```

### 구성요소
- **프론트엔드**: `http://localhost:3000` (Next.js)
- **백엔드 API**: `http://localhost:8000` (Django)
- **WebSocket**: `ws://localhost:8001` (Django Channels)

### 시작 방법
```bash
# 1. 백엔드 시작 (터미널 1)
cd contactotalk
python manage.py runserver

# 2. 프론트엔드 시작 (터미널 2)
cd contactotalk-frontend
./restart-dev.sh
```

### 장점
- 빠른 개발 사이클
- 오프라인 작업 가능
- 자유로운 데이터 수정
- 백엔드 디버깅 용이

### 단점
- 로컬 데이터 설정 필요
- AWS 데이터와 동기화 안됨

## ☁️ AWS 연결 환경

### 설정
**파일**: `.env.local` (`.env.aws`에서 복사)
```bash
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

### 구성요소
- **프론트엔드**: `http://localhost:3000` (로컬 Next.js)
- **백엔드 API**: `http://43.200.129.55:8000` (AWS Django)
- **WebSocket**: `ws://43.200.129.55:8001` (AWS Channels)

### 시작 방법
```bash
# 1. AWS 환경으로 전환
cd contactotalk-frontend
cp .env.aws .env.local

# 2. 프론트엔드 재시작
./restart-dev.sh
```

### 장점
- 실제 프로덕션 데이터 사용
- 백엔드 설정/실행 불필요
- 다른 개발자와 데이터 공유

### 단점
- 인터넷 연결 필수
- 백엔드 디버깅 불가
- 데이터 수정 시 다른 개발자에게 영향

## 🔄 환경 전환 방법

### 로컬 → AWS 연결
```bash
cd contactotalk-frontend
cp .env.aws .env.local
./restart-dev.sh
```

### AWS 연결 → 로컬
```bash
cd contactotalk-frontend
# .env.local 파일 수정 (localhost로 변경)
# 또는 초기화:
cat > .env.local << 'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_WS_URL=ws://localhost:8001/ws
EOF
./restart-dev.sh
```

## 🔍 현재 환경 확인

### 방법 1: restart-dev.sh 실행
```bash
./restart-dev.sh
```
출력 예시:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 현재 환경 설정:
🏠 로컬 개발 환경 (LOCAL)
   → 로컬 Django 백엔드를 사용합니다

백엔드 URL:
  API: http://localhost:8000/api
  WebSocket: ws://localhost:8001/ws
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 방법 2: 환경변수 파일 확인
```bash
cat .env.local
```

### 방법 3: 브라우저 개발자 도구
```javascript
// Console에서 실행
console.log(process.env.NEXT_PUBLIC_API_URL)
```

## ⚠️ 중요 주의사항

### 1. 환경 변경 후 반드시 재시작
```bash
./restart-dev.sh  # 필수!
```
Next.js는 환경변수를 시작 시점에만 로드합니다.

### 2. .env.local은 Git에 포함되지 않음
각 개발자가 자신의 환경에 맞게 설정해야 합니다.

### 3. 데이터 불일치
로컬 DB와 AWS DB는 별개입니다. 환경 전환 시 데이터가 다를 수 있습니다.

### 4. 포트 충돌
로컬 환경에서는 Django(8000), Channels(8001), Next.js(3000) 포트가 모두 사용됩니다.

## 🐛 문제 해결

### 로그인이 안돼요
```bash
# 1. 현재 환경 확인
cat .env.local

# 2. 백엔드가 실행 중인지 확인
# 로컬 환경: curl http://localhost:8000/api/accounts/interests/
# AWS 환경: curl http://43.200.129.55:8000/api/accounts/interests/

# 3. 프론트엔드 재시작
./restart-dev.sh
```

### 관심사 목록이 안보여요
```bash
# 로컬 환경인 경우
python manage.py shell << 'EOF'
from accounts.models import Interest
print(f"관심사 개수: {Interest.objects.count()}")
EOF

# 0개면 데이터 초기화 필요
```

### 어느 환경을 사용 중인지 모르겠어요
```bash
./restart-dev.sh
# 환경 정보가 색상으로 표시됩니다:
# 🏠 녹색 = 로컬
# ☁️  노란색 = AWS 연결
```

## 📚 관련 문서

- [DEVELOPMENT.md](./DEVELOPMENT.md) - 개발 가이드
- [README.md](./README.md) - 프로젝트 개요
- [DEPLOYMENT.md](../contactotalk/DEPLOYMENT.md) - 배포 가이드
