# ConTacToTalk 개발 현황 및 배포 상태

**작성일**: 2025-10-25
**최종 배포**: AWS EC2 (43.200.129.55)

---

## 📌 최근 업데이트 (2025-10-25)

### Git 커밋 이력
```
9849468 - Add Nginx proxy origin to CORS settings
f648e61 - Fix AWS frontend CORS and social API connection issues
7e27465 - Fix getUserPosts API to use query parameter instead of URL path
d5f31a8 - Fix UserStatsAPIView to use MatchHistory for accurate today_match_count
63508ad - Add open-chats page for profile
```

### 주요 수정 사항

#### 1. MatchHistory 기능 구현 ✅
- **파일**: `chat/models.py`, `chat/views.py`, `accounts/views.py`
- **내용**:
  - 삭제된 채팅방 이력도 보관하는 MatchHistory 모델 추가
  - 최근 5일 매칭 이력 조회 API 구현
  - UserStatsAPIView에서 정확한 매칭 카운트 집계

#### 2. Social API 수정 ✅
- **파일**: `contactotalk-frontend/src/lib/api/social.ts`
- **변경 전**: `/social/users/${userId}/posts/` (존재하지 않는 URL)
- **변경 후**: `/social/posts/?user_id=${userId}` (query parameter 방식)

#### 3. CORS 설정 수정 ✅
- **파일**: `contactotalk/settings.py`
- **추가된 Origins**:
  - `http://43.200.129.55:3000` - AWS Next.js 직접 접속
  - `http://43.200.129.55` - AWS Nginx 프록시 접속

#### 4. Next.js 빌드 환경변수 적용 ✅
- AWS 서버에서 `npm run build` 실행
- `.env.production` 환경변수 빌드에 반영
- 빌드 ID: `Rl-PhB9T6g5mHxCFMy58p`

---

## 🖥️ AWS vs 로컬 환경 차이점

### 1. 환경변수 설정

#### AWS 서버 (.env.production)
```bash
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

#### 로컬 환경 (예상)
```bash
# .env.local 또는 .env.development
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_WS_URL=ws://localhost:8001/ws
```

### 2. 프론트엔드 파일 수정 상태

#### ⚠️ **중요**: AWS 서버만 수정됨!

**수정된 파일**: `contactotalk-frontend/src/lib/api/social.ts`

**AWS 서버 (수정됨)** ✅:
```typescript
export const getUserPosts = async (userId: number, params?: { page?: number }) => {
  const response = await apiClient.get('/social/posts/', {
    params: { ...params, user_id: userId },
  });
  return response.data;
};
```

**로컬 환경 (수정 안됨)** ⚠️:
```typescript
export const getUserPosts = async (userId: number, params?: { page?: number }) => {
  const response = await apiClient.get(`/social/users/${userId}/posts/`, {
    params,
  });
  return response.data;
};
```

### 3. Next.js 빌드 상태

| 항목 | AWS | 로컬 |
|------|-----|------|
| 빌드 상태 | ✅ 최신 빌드 완료 | ❌ 빌드 필요 |
| 환경변수 반영 | ✅ 반영됨 | ⚠️ 미반영 |
| social.ts 수정 | ✅ 반영됨 | ❌ 수정 필요 |

### 4. 서버 구성

#### AWS 배포 구조
```
브라우저 (http://43.200.129.55)
  ↓ 포트 80
Nginx (리버스 프록시)
  ├─ / → localhost:3000 (Next.js)
  └─ /api/ → localhost:8000 (Django)

Django Backend
  ├─ Gunicorn (포트 8000) - 5개 워커
  └─ Daphne (포트 8001) - WebSocket
```

#### 로컬 환경 (예상)
```
브라우저 (http://localhost:3000)
  ↓
Next.js (포트 3000)
  ↓ API 호출
Django Backend
  ├─ Gunicorn/Runserver (포트 8000)
  └─ Daphne (포트 8001)
```

---

## ⚠️ 주의사항 및 동기화 필요 항목

### 1. 프론트엔드 코드 동기화 필요 ⭐ 최우선

**파일**: `contactotalk-frontend/src/lib/api/social.ts`

**로컬에서 수정 필요**:
```typescript
// 108-116라인
export const getUserPosts = async (
  userId: number,
  params?: { page?: number }
): Promise<PaginatedResponse<Post>> => {
  const response = await apiClient.get(`/social/posts/`, {
    params: { ...params, user_id: userId },  // ← 이렇게 수정
  });
  return response.data;
};
```

**방법 1**: AWS에서 복사
```bash
scp -i ~/Downloads/contactotalk-key.pem \
  ubuntu@43.200.129.55:~/contactotalk/contactotalk/contactotalk-frontend/src/lib/api/social.ts \
  /Users/kyungjunkang/PycharmProjects/contactotalk-frontend/src/lib/api/social.ts
```

**방법 2**: 수동 수정
- 위 코드처럼 직접 수정

### 2. 로컬 환경변수 확인 필요

**확인 사항**:
- `.env.local` 또는 `.env.development` 파일 존재 확인
- `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_WS_URL` 설정 확인
- 로컬 Django 서버 포트와 일치하는지 확인

### 3. 로컬 테스트 전 필수 작업

**백엔드 (Django)**:
```bash
cd /Users/kyungjunkang/PycharmProjects/contactotalk
git pull origin main  # 최신 CORS 설정 받기
python manage.py check
python manage.py runserver
```

**프론트엔드 (Next.js)**:
```bash
cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend
# social.ts 수정 후
npm run dev  # 또는 npm run build && npm start
```

### 4. Git 상태 차이

**푸시된 내역 (Backend만)**:
- ✅ Django CORS 설정 수정
- ✅ MatchHistory 모델 및 API
- ✅ UserStatsAPIView 수정

**푸시 안된 내역 (Frontend)**:
- ❌ `social.ts` 수정 - AWS 서버에만 존재
- ❌ Next.js 빌드 파일들

---

## 🚀 다음 배포 시 체크리스트

### Frontend 변경 사항 배포 시

1. **로컬에서 수정**
   ```bash
   cd contactotalk-frontend
   # social.ts 등 파일 수정
   git add .
   git commit -m "Update frontend files"
   git push origin main
   ```

2. **AWS 서버에서 배포**
   ```bash
   cd ~/contactotalk/contactotalk/contactotalk-frontend
   git pull origin main
   npm run build  # ⭐ 필수!
   pkill -f next-server
   npm start &
   ```

### Backend 변경 사항 배포 시

1. **로컬에서 수정**
   ```bash
   cd contactotalk
   # settings.py, models.py 등 수정
   git add .
   git commit -m "Update backend files"
   git push origin main
   ```

2. **AWS 서버에서 배포**
   ```bash
   cd ~/contactotalk/contactotalk
   git pull origin main
   python manage.py migrate  # 모델 변경 시
   pkill -f gunicorn
   gunicorn --config ../deploy/gunicorn.conf.py contactotalk.wsgi:application &
   ```

---

## 📊 현재 서비스 상태 (AWS)

### 실행 중인 서비스

| 서비스 | 포트 | 상태 | 워커/PID |
|--------|------|------|----------|
| Nginx | 80 | ✅ 실행 중 | - |
| Next.js | 3000 | ✅ 실행 중 | PID: 245617 |
| Gunicorn | 8000 | ✅ 실행 중 | 5개 워커 |
| Daphne | 8001 | ✅ 실행 중 | PID: 230029 |

### 테스트 결과 (서버 내부)

| 테스트 항목 | 결과 |
|------------|------|
| Nginx → Next.js | ✅ HTTP 200 |
| Nginx → Django API | ✅ HTTP 200 |
| Django API 직접 | ✅ HTTP 200 |
| Next.js 직접 | ✅ HTTP 200 |

---

## 🔧 문제 해결 이력

### Issue 1: 매칭 리스트 미표시 ✅ 해결
- **증상**: "최근 5일 이내 매칭이 없습니다" 메시지만 표시
- **원인**: ChatRoom 삭제 시 매칭 이력도 함께 삭제됨
- **해결**: MatchHistory 모델 추가 및 시그널 구현

### Issue 2: Social API 404 에러 ✅ 해결
- **증상**: `/social/users/5/posts/` → 404 에러
- **원인**: Backend URL 패턴 불일치
- **해결**: Query parameter 방식으로 변경

### Issue 3: 로그인 Network Error ✅ 해결
- **증상**: 브라우저에서 로그인 시 Network Error
- **원인 1**: Next.js 빌드에 환경변수 미반영
- **원인 2**: CORS에 Nginx 프록시 Origin 누락
- **해결**:
  - Next.js 재빌드로 환경변수 적용
  - CORS에 `http://43.200.129.55` 추가

---

## 📝 추가 참고사항

### 프론트엔드 디렉토리 구조 차이
- **Git 저장소**: `/Users/kyungjunkang/PycharmProjects/contactotalk` (Backend만)
- **로컬 프론트엔드**: `/Users/kyungjunkang/PycharmProjects/contactotalk-frontend` (별도 디렉토리)
- **AWS 프론트엔드**: `~/contactotalk/contactotalk/contactotalk-frontend` (Backend 하위)

### Git 관리 주의점
- Backend: Git으로 관리됨
- Frontend: **별도 디렉토리**이므로 Git 관리 확인 필요
- AWS 서버에서 Frontend 수정 시 → 로컬과 동기화 필수

---

## 🎯 테스트 URL

- **AWS 프론트엔드**: http://43.200.129.55
- **AWS API**: http://43.200.129.55:8000/api
- **로컬 프론트엔드**: http://localhost:3000 (예상)
- **로컬 API**: http://localhost:8000/api (예상)
