# ConTacToTalk - 글로벌 매칭 & 채팅 플랫폼

전 세계 사람들과 소통하는 매칭 기반 채팅 플랫폼의 프론트엔드

## 주요 기능

### 🔐 인증 시스템
- 이메일/비밀번호 기반 회원가입 및 로그인
- JWT 토큰 기반 인증 with 자동 갱신
- 관심사 선택 (3-10개)
- Protected Routes

### 💬 1:1 채팅 & 매칭
- 관심사 기반 스마트 매칭 시스템
- 실시간 WebSocket 채팅
- 읽음 상태 표시
- 채팅방 나가기

### 👥 오픈 채팅
- 공개/비공개 채팅방 생성
- 카테고리별 분류 (언어교환, 취미, 스터디 등)
- 최대 참여자 수 제한
- 방장 권한 (강퇴 기능)
- 실시간 다중 사용자 채팅

### 📱 SNS 기능
- 게시글 작성 (텍스트 + 이미지 업로드)
- 좋아요 및 댓글 시스템
- 팔로우/언팔로우
- 전체/팔로잉 피드
- 사용자 프로필 페이지

### 🛡️ 신고/관리 시스템
- 게시글/댓글/사용자 신고
- 사용자 차단 기능
- 7가지 신고 사유 (스팸, 괴롭힘, 혐오 발언 등)
- 허위 신고 방지

## 기술 스택

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **HTTP Client**: Axios (with interceptors)
- **Real-time**: WebSocket
- **SEO**: Next.js Metadata API
- **PWA**: manifest.json, Service Worker (준비)

## 시작하기

### 1. 의존성 설치

```bash
npm install
# 또는
yarn install
# 또는
pnpm install
```

### 2. 환경 변수 설정

`.env.local` 파일을 생성하고 다음 내용을 추가하세요:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_WS_URL=ws://localhost:8000/ws
```

### 3. 개발 서버 실행

```bash
npm run dev
# 또는
yarn dev
# 또는
pnpm dev
```

브라우저에서 [http://localhost:3000](http://localhost:3000)을 열어 확인하세요.

## 프로젝트 구조

```
src/
├── app/              # Next.js 페이지 (App Router)
├── components/       # 재사용 가능한 컴포넌트
├── lib/             # 유틸리티 및 라이브러리
│   ├── api/         # API 클라이언트 및 함수
│   └── utils/       # 헬퍼 함수
├── hooks/           # Custom React Hooks
├── store/           # Zustand 스토어
└── types/           # TypeScript 타입 정의
```

## 주요 기능

### 인증
- 로그인/로그아웃
- 회원가입
- JWT 토큰 관리
- 자동 토큰 갱신

### 채팅
- 1:1 실시간 채팅
- 오픈 채팅방
- 매칭 시스템

### SNS
- 게시글 작성/조회
- 댓글 기능
- 좋아요
- 팔로우/언팔로우
- 피드 (추천/팔로잉)

### 프리미엄
- 구독 플랜
- 결제 시스템
- 광고 시스템

## 백엔드 연동

이 프론트엔드는 Django REST Framework 백엔드와 연동됩니다.

백엔드 서버가 `http://localhost:8000`에서 실행 중이어야 합니다.

### API 엔드포인트

- `/api/accounts/` - 인증 및 사용자 관리
- `/api/chat/` - 채팅 및 매칭
- `/api/social/` - SNS 기능
- `/api/moderation/` - 신고 및 관리
- `/api/premium/` - 프리미엄 및 광고

## 개발 가이드

### API 클라이언트 사용

```typescript
import apiClient from '@/lib/api/client';

// GET 요청
const response = await apiClient.get('/endpoint');

// POST 요청
const response = await apiClient.post('/endpoint', data);
```

### 인증 스토어 사용

```typescript
import { useAuthStore } from '@/store/auth';

function MyComponent() {
  const { user, login, logout } = useAuthStore();

  // 로그인
  await login({ email, password });

  // 로그아웃
  await logout();
}
```

## 배포

### Vercel 배포

```bash
npm run build
vercel deploy
```

### 환경 변수 설정

프로덕션 환경에서는 다음 환경 변수를 설정하세요:

- `NEXT_PUBLIC_API_URL`: 백엔드 API URL
- `NEXT_PUBLIC_WS_URL`: WebSocket URL

## 라이선스

© 2025 ConTacToTalk. All rights reserved.
