# MarketLens 개발 문서

> 최종 업데이트: 2026-05-25
> 현재 버전: 1.3.1+25
> 상태: 활발한 개발 중

---

## 1. 프로젝트 개요

**MarketLens**는 AI 기반 주식 분석 및 투자 인사이트 앱이다. 개인 투자자에게 실시간 주식 데이터, AI 생성 인사이트, 포트폴리오 관리, 커뮤니티 토론 기능을 제공한다.

### 핵심 가치
- AI 기반 종목 스코어링 및 시그널 (Buy/Hold/Sell)
- 실시간 차트 + 기술적 지표
- 포트폴리오 관리 및 AI 조언
- 커뮤니티 기반 종목 토론
- 5개 언어 지원 (한/영/중/일/스페인어)

---

## 2. 기술 스택

### 프론트엔드 (Flutter)
| 항목 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | Flutter / Dart | SDK ^3.8.1 |
| 상태관리 | Provider | ^6.1.2 |
| 차트 | fl_chart | ^0.66.0 |
| HTTP | http | ^1.1.0 |
| 로컬 저장 | shared_preferences | ^2.2.0 |
| 보안 저장 | flutter_secure_storage | ^9.0.0 |
| 푸시알림 | firebase_messaging + flutter_local_notifications | |
| 광고 | google_mobile_ads (AdMob) | ^5.2.0 |
| 구독 | purchases_flutter (RevenueCat) | ^8.0.0 |
| 웹뷰 | webview_flutter | ^4.10.0 |
| 다국어 | flutter_localizations (arb) | |

### 백엔드 (Django)
| 항목 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | Django | 5.1.11 |
| API | Django REST Framework | 3.14.0 |
| 인증 | djangorestframework-simplejwt | 5.2.2 |
| DB | PostgreSQL (운영) / SQLite (개발) | |
| 이메일 | django-ses (AWS SES) | |
| 푸시 | firebase-admin | |
| 문서화 | drf-spectacular (OpenAPI) | |
| 서버 | Gunicorn | |

### 인프라
| 항목 | 상세 |
|------|------|
| 서버 | AWS EC2 (43.201.45.60) |
| API 포트 | 8000 (메인/커뮤니티), 8001 (애널리틱스) |
| iOS 배포 | Fastlane |
| 플랫폼 | iOS, Android, Web, macOS, Linux, Windows |

---

## 3. 프로젝트 구조

```
marketlens/
├── lib/                          # Flutter 앱 소스
│   ├── main.dart                 # 앱 진입점 (Provider 7개 초기화)
│   ├── models/                   # 데이터 모델
│   │   ├── chart_data.dart       # OHLCV 차트 데이터
│   │   ├── stock_score.dart      # AI 종목 스코어
│   │   ├── news_data.dart        # 뉴스 데이터
│   │   ├── portfolio_data.dart   # 포트폴리오 데이터
│   │   └── ...
│   ├── screens/                  # UI 화면 (19개 영역)
│   │   ├── dashboard/            # 메인 대시보드
│   │   ├── ticker_detail/        # 종목 상세
│   │   ├── watchlist/            # 관심종목
│   │   ├── holdings/             # 보유종목
│   │   ├── news/                 # 뉴스 피드
│   │   ├── ai_lens/              # AI 인사이트
│   │   ├── community/            # 커뮤니티
│   │   ├── explore/              # 종목 탐색
│   │   ├── auth/                 # 인증
│   │   ├── earnings/             # 어닝 캘린더
│   │   ├── indexes/              # 시장 지수
│   │   ├── compare/              # 종목 비교
│   │   ├── calendar/             # 이벤트 캘린더
│   │   ├── profile/              # 프로필
│   │   ├── settings/             # 설정
│   │   ├── notifications/        # 알림함
│   │   └── admin/                # 관리자
│   ├── services/                 # API 클라이언트
│   │   ├── analytics_api_client.dart   # 주식/차트 API
│   │   ├── auth_service.dart           # 인증 서비스
│   │   ├── community_api_client.dart   # 커뮤니티 API
│   │   ├── portfolio_api_client.dart   # 포트폴리오 API
│   │   └── notification_service.dart   # FCM 알림
│   ├── providers/                # 상태 관리 (Provider)
│   │   ├── auth_provider.dart
│   │   ├── watchlist_provider.dart
│   │   ├── portfolio_provider.dart
│   │   ├── subscription_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── coach_mark_provider.dart
│   │   └── recent_search_provider.dart
│   ├── widgets/                  # 재사용 위젯
│   │   ├── charts/               # 차트 위젯
│   │   ├── advanced_chart/       # 고급 차트
│   │   ├── ads/                  # AdMob 위젯
│   │   ├── dashboard/            # 대시보드 컴포넌트
│   │   ├── news/                 # 뉴스 위젯
│   │   ├── community/            # 커뮤니티 위젯
│   │   └── common/               # 공통 컴포넌트
│   ├── theme/                    # 디자인 시스템
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_duration.dart
│   │   └── app_shadow.dart
│   ├── l10n/                     # 다국어 리소스 (.arb)
│   ├── utils/                    # 유틸리티
│   └── exceptions/               # 예외 처리
├── backend/                      # Django 백엔드
│   ├── manage.py
│   ├── marketlens_backend/       # 프로젝트 설정
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── accounts/                 # 사용자 관리 앱
│   ├── community/                # 커뮤니티 앱
│   └── moderation/               # 콘텐츠 모더레이션 앱
├── test/                         # 테스트
├── ios/ android/ web/            # 플랫폼별 네이티브
├── fastlane/                     # iOS 배포 자동화
├── assets/                       # 앱 아이콘/이미지
└── docs/                         # 문서
```

---

## 4. API 구조

### Analytics API (포트 8001)
| 엔드포인트 | 기능 |
|-----------|------|
| `/api/v1/charts/{ticker}` | OHLCV 가격, 스코어, 지표, 목표가, 추세선, 기관보유, 공매도 |
| `/api/v1/ticker-scores/` | AI 종목 스코어 목록 |
| `/api/v1/ticker-info/{ticker}` | 종목 정보 (한국어명, 섹터 포함) |
| `/api/v1/news/` | AI 요약 뉴스 + 감성 분석 |
| `/api/v1/macro/` | 매크로 경제 지표 (금리, 국채, VIX, CPI 등) |
| `/api/v1/earnings/` | 어닝 캘린더 |
| `/api/v1/indexes/` | 시장 지수 |
| `/api/v1/treemap/` | 시장 히트맵 |
| `/api/v1/mention-bubble/` | 종목 언급 빈도 |
| `/api/v1/market-events/` | 경제 일정 |

### Community API (포트 8000)
| 엔드포인트 | 기능 |
|-----------|------|
| `POST /api/community/posts/` | 게시글 작성 |
| `GET /api/community/posts/?ticker=AAPL` | 종목별 게시글 조회 |
| `POST /api/community/posts/{id}/comments/` | 댓글 작성 |
| `POST /api/community/posts/{id}/like/` | 게시글 좋아요/취소 |
| `POST /api/community/comments/{id}/like/` | 댓글 좋아요/취소 |

### Auth API (포트 8000)
| 엔드포인트 | 기능 |
|-----------|------|
| `POST /api/accounts/register/` | 회원가입 |
| `POST /api/accounts/login/` | 로그인 (JWT 반환) |
| `POST /api/accounts/password-reset/` | 비밀번호 재설정 |
| `GET/PUT /api/accounts/profile/` | 프로필 조회/수정 |

---

## 5. 주요 기능 모듈

| 모듈 | 설명 | 상태 |
|------|------|------|
| 주식 분석 | OHLCV 차트, AI 스코어, 기술적 지표, 기관보유 추적 | 완료 |
| 포트폴리오 | 보유종목 CRUD, 손익 추적, AI 조언 | 완료 |
| 워치리스트 | 관심종목 관리, 탭 기반 UI | 완료 |
| 뉴스/인사이트 | AI 요약 뉴스, 감성 분석, 핫토픽, 필터링 | 완료 |
| 매크로 경제 | 금리, 국채수익률, VIX, CPI, 실업률 | 완료 |
| 커뮤니티 | 종목별 토론, 댓글/좋아요, 자유 게시판 | 완료 |
| 어닝 캘린더 | 실적 발표 일정, 서프라이즈 | 완료 |
| 시장 지수 | S&P500, NASDAQ, 섹터별 히트맵 | 완료 |
| 알림 시스템 | FCM 푸시, 인앱 알림함, 알림→콘텐츠 네비게이션 | 완료 |
| 수익화 (광고) | AdMob 배너/전면 광고 | 완료 |
| 수익화 (구독) | RevenueCat 인앱 구독 | 구현중 |
| 다국어 | 한/영/중/일/스페인어 | 완료 |
| 디자인 시스템 | 디자인 토큰, 타이포그래피, 색상 체계 | 개선중 |

---

## 6. 업데이트 이력 (Changelog)

### Phase 4 — 모노레포 통합 및 UI 현대화 (2026-05)

**v1.3.1+25** `2026-05-25`
- 기존 contactotalk 레포에 marketlens 코드 통합 (모노레포 전환)
- UI 현대화 및 알림 시스템 강화
- .env 파일 보안 처리 (.gitignore 추가)
- 미사용 contactotalk 코드 제거

### Phase 3 — 포트폴리오 관리 및 알림 고도화 (2026-03 ~ 2026-04)

**v1.3.0** `2026-04-12`
- 포트폴리오 관리 기능 구현 (보유종목 CRUD, 손익 추적)
- 코드 품질 감사 수행
- 알림 → 게시글 네비게이션 연동
- 커뮤니티 API 개선 (post_id 연동, FCM 개선)

**v1.2.0** `2026-03-14`
- 탭 기반 워치리스트 UI 신규 구현
- 포트폴리오 관리 UI 추가
- AI 포트폴리오 조언 기능 추가

### Phase 2 — iOS 출시 준비 및 버그 수정 (2026-02)

**2026-02-28**
- 뉴스 탭 재진입 루프 버그 수정 (모달 방식으로 전환)

**2026-02-27**
- 알림함(Notification Inbox) 기능 추가
- 사용자별 알림 히스토리 구현

**2026-02-19**
- iOS AdMob 초기화 설정 (GADApplicationIdentifier)
- iOS 런치 스크린 MarketLens 브랜딩 교체
- iOS 앱 아이콘 통일 (Android와 동일)
- iOS 최소 지원 버전 13.0 설정

**2026-02-17 ~ 2026-02-18**
- 댓글 좋아요/취소 500 에러 수정
- 댓글 수정 시 HTML 에러 수정 (nested route 추가)
- 백엔드 API를 Flutter 클라이언트 기대값에 맞게 정렬

**2026-02-11**
- 종목 상세 화면에 한국어 종목명 표시
- TickerInfo 모델에 한국어명 필드 추가

### Phase 1 — 초기 MarketLens 전환 (2025-10 ~ 2025-01)

**2025-10** (contactotalk → MarketLens 전환 전 기간)
- CORS 설정 (Flutter Web 지원)
- AWS/로컬 엔드포인트 자동 폴백 시스템
- JWT 인증 및 로그인 호환성 수정
- WebSocket 인증 미들웨어
- 채팅 관련 기능 (이전 프로젝트 잔여)
- 사용자 차단 기능
- 1:1 매칭 기능
- AWS 배포 설정 안정화

**2025-01 ~ 2025-02**
- 프로젝트 초기 커밋들 (타임스탬프 기반 커밋)
- 기본 프로젝트 구조 구축

---

## 7. 진행 중인 작업 및 로드맵

### 진행 중
- **UI/UX 전면 재개발** — `docs/UIUX_IMPROVEMENT_PLAN.md` 참고
  - Phase 1: 디자인 시스템 재정비
  - Phase 2: 핵심 화면 재설계
  - Phase 3: 차트/그래프 전면 개선
  - Phase 4: 모달/필터/상태 화면 통일
  - Phase 5: 전체 QA와 디테일 보정
- **구독 수익화 구현** — `docs/monetization_strategy.md` 참고
  - Gold 멤버십 ₩4,900/월
  - 7일 무료 체험
  - RevenueCat + Flutter + Django 연동

### 계획됨
- **매크로/지정학 뉴스 확장** — `docs/macro_news_collection_plan.md` 참고
  - 가상 티커 도입 ($MACRO, $GEO, $FED, $OIL, $TRADE)
  - 비종목 뉴스 자동 분류 시스템
- CI/CD 파이프라인 구축 (GitHub Actions)
- 테스트 커버리지 확대
- 앱 성능 최적화

---

## 8. 개발 환경 설정

### 사전 요구사항
- Flutter SDK ^3.8.1
- Dart SDK ^3.8.1
- Python 3.8+
- PostgreSQL (운영) 또는 SQLite (로컬 개발)
- Firebase 프로젝트 (FCM용)
- Xcode (iOS 빌드)
- Android Studio (Android 빌드)

### 프론트엔드 실행
```bash
# 의존성 설치
flutter pub get

# 환경변수 설정
cp .env.example .env
# .env 파일에서 API_BASE_URL 수정

# 실행
flutter run                  # 기본 디바이스
flutter run -d chrome        # 웹
flutter run -d ios            # iOS
flutter run -d android        # Android
```

### 백엔드 실행
```bash
cd backend

# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# 환경변수 설정
# .env 파일 생성 (DB, SECRET_KEY, AWS, Firebase 설정)

# 마이그레이션 및 실행
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

### 환경 변수 (.env)
```
# 프론트엔드 (.env)
API_BASE_URL=http://43.201.45.60:8001/api/v1
API_TIMEOUT=30000

# 백엔드 (.env)
SECRET_KEY=...
DEBUG=True
DATABASE_URL=postgresql://user:pass@host:5432/marketlens
AWS_SES_REGION=...
FIREBASE_CREDENTIALS_PATH=...
```

---

## 9. 테스트

### 현재 테스트 현황
```
test/
├── models/
│   ├── chart_data_test.dart
│   ├── portfolio_data_test.dart
│   ├── news_data_test.dart
│   ├── earnings_data_test.dart
│   ├── news_filter_test.dart
│   └── market_event_test.dart
└── utils/
    ├── badge_colors_test.dart
    ├── tax_calculator_test.dart
    ├── multilingual_test.dart
    └── score_mapper_test.dart
```

### 테스트 실행
```bash
# Flutter 테스트
flutter test

# Django 테스트
cd backend
python manage.py test
```

### 보강 필요 영역
- Provider 상태 관리 테스트
- API 클라이언트 통합 테스트
- 위젯 테스트 (주요 화면)
- E2E 테스트

---

## 10. 알려진 기술 부채

| 항목 | 설명 | 우선도 |
|------|------|--------|
| CI/CD 미구축 | GitHub Actions 워크플로우 없음 | 높음 |
| 테스트 커버리지 부족 | Provider, API 클라이언트, 위젯 테스트 부재 | 높음 |
| main.dart 비대 | 1,500+ 줄, 분리 필요 | 중간 |
| 하드코딩된 서버 IP | API URL이 코드에 직접 기입됨 | 중간 |
| Git 태그 없음 | 버전 릴리스 태깅 체계 미수립 | 중간 |
| 이전 프로젝트 잔여 코드 | contactotalk 관련 코드/설정 잔존 가능 | 낮음 |
| 커밋 메시지 불일치 | 초기 커밋은 타임스탬프만 사용 | 낮음 |

---

## 11. 브랜치 및 배포 전략

### 현재 상태
- **브랜치**: `main` 단일 브랜치 운영
- **태그**: 없음
- **배포**: 수동 배포 (EC2 직접, Fastlane iOS)

### 권장 개선사항
- Git Flow 또는 GitHub Flow 도입
- 릴리스 태그 체계: `v1.3.1`, `v1.4.0` 등
- feature 브랜치 → PR → main 머지 워크플로우
- GitHub Actions CI/CD 구축

---

## 12. 관련 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| UI/UX 디자인 재개발 문서 | `docs/UIUX_IMPROVEMENT_PLAN.md` | 전면 디자인 재정비 원칙, 우선순위, 화면별 체크리스트 |
| 수익화 전략 | `docs/monetization_strategy.md` | Gold 구독 모델, RevenueCat 연동 가이드 |
| 매크로 뉴스 수집 계획 | `docs/macro_news_collection_plan.md` | 가상 티커 기반 매크로 뉴스 확장 계획 |
| 본 문서 | `docs/DEVELOPMENT.md` | 프로젝트 현황 및 개발 이력 |

---

## 부록: 의존성 요약

### Flutter 주요 패키지 (pubspec.yaml)
```yaml
provider: ^6.1.2          # 상태관리
http: ^1.1.0              # HTTP 클라이언트
fl_chart: ^0.66.0         # 차트
shared_preferences: ^2.2.0 # 로컬 저장
flutter_secure_storage: ^9.0.0  # 보안 저장
firebase_messaging: ^15.1.6     # 푸시 알림
google_mobile_ads: ^5.2.0      # AdMob
purchases_flutter: ^8.0.0      # RevenueCat 구독
webview_flutter: ^4.10.0       # 웹뷰
image_picker: ^1.0.7           # 이미지 선택
upgrader: ^11.3.0              # 앱 업데이트 체크
url_launcher: ^6.2.5           # URL 열기
flutter_dotenv: ^5.2.1         # 환경변수
```

### Django 주요 패키지 (requirements.txt)
```
Django==5.1.11
djangorestframework==3.14.0
djangorestframework-simplejwt==5.2.2
django-cors-headers==4.2.0
drf-spectacular==0.27.2
psycopg2-binary==2.9.9
firebase-admin==6.2.0
django-ses==4.3.0
gunicorn==23.0.0
Pillow==11.1.0
python-dotenv==1.0.1
```
