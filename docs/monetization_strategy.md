# MarketLens Gold 멤버십 — 유료화 전략 & 구현 가이드

> 최종 업데이트: 2026-04-27

---

## 1. 유료화 전략 개요

### 1-1. 비즈니스 모델

**Freemium + Auto-Renewable Subscription**

```
무료 유저 (regular)                    Gold 멤버십
┌────────────────────┐                ┌────────────────────┐
│ - 보유종목 5개 제한   │   7일 무료 체험  │ - 보유종목 무제한     │
│ - AI 분석 블러 처리   │ ────────────→ │ - AI 분석 완전 공개   │
│ - 광고 표시          │   ₩4,900/월   │ - 광고 제거          │
└────────────────────┘                └────────────────────┘
         ↑                                      │
         │          구독 만료/취소                  │
         └──────────────────────────────────────┘
```

### 1-2. 전환 퍼널

```
앱 설치 → 무료 사용 (제한 경험) → 블러/제한 접촉 → "7일 무료 체험" 클릭
→ 체험 시작 (Gold 즉시 활성화) → 7일간 전체 기능 사용
→ 7일 후 자동 ₩4,900/월 결제 시작 (또는 체험 중 취소 → regular 복귀)
```

**핵심**: 무료 체험은 "결제 장벽"을 극적으로 낮춤. 업계 평균 무료 체험 → 유료 전환율 **40~60%** (바로 유료 전환 대비 3~5배).

---

## 2. 가격 전략

### 2-1. 기본 가격: **월 ₩4,900**

| 국가 | 가격 | 비고 |
|------|------|------|
| **한국** | **₩4,900/월** | 기본 가격 (스타벅스 아메리카노 1잔) |
| 미국 | ~$3.49/월 | Apple/Google 자동 환산 |
| 일본 | ~¥500/월 | 자동 환산 |
| 중국 | ~¥25/월 | 자동 환산 |
| 기타 | 자동 환산 | 스토어가 현지 통화로 자동 설정 |

### 2-2. 가격 근거

| 가격대 | 판단 |
|--------|------|
| ₩3,900 | 너무 저렴, 서비스 가치 훼손 |
| **₩4,900** | **심리적 ₩5,000 벽 아래, 부담 없는 가격대 (추천)** |
| ₩6,500~₩7,500 | 해외 주식 앱 평균 ($4.99), 초기엔 진입장벽 |
| ₩9,900 | 프리미엄 앱 (Seeking Alpha급), 브랜드 인지도 부족 |

### 2-3. 수익 시뮬레이션

| 시나리오 | 유료 유저 수 | 월 매출 | 연 매출 | 실수령 (수수료 후) |
|---------|------------|--------|--------|-----------------|
| 보수적 | 100명 | ₩490,000 | ₩5,880,000 | ~₩4,116,000 |
| 중간 | 500명 | ₩2,450,000 | ₩29,400,000 | ~₩20,580,000 |
| 낙관적 | 2,000명 | ₩9,800,000 | ₩117,600,000 | ~₩82,320,000 |

> Apple/Google 수수료 30%. 1년차 이후 Apple Small Business Program 적용 시 15% (매출 $1M 미만).

### 2-4. 향후 확장 가격

| 상품 | 가격 | 할인율 | 도입 시기 |
|------|------|--------|----------|
| 월간 구독 | ₩4,900/월 | - | **출시 시** |
| 7일 무료 체험 | ₩0 (7일) → ₩4,900/월 | - | **출시 시** |
| 연간 구독 | ₩39,000/년 | 월 대비 34% 할인 | 출시 3~6개월 후 |
| 프로모션 | ₩2,900/첫달 | 41% 할인 | 특별 이벤트 시 |

---

## 3. 7일 무료 체험 — 상세 구현 계획

### 3-1. 무료 체험이란?

```
Day 0: 유저가 "7일 무료 체험 시작" 클릭
       → Apple/Google 결제 정보 등록 (카드 등록만, 과금 없음)
       → 즉시 Gold 활성화

Day 1~6: Gold 기능 전체 사용 가능 (무료)
         → 체험 중 언제든 취소 가능

Day 7: 자동으로 ₩4,900 첫 결제
       → 이후 매월 자동 갱신

※ Day 7 전에 취소하면 → 과금 0원, regular로 복귀
```

**중요**: Apple/Google이 무료 체험 기간과 과금을 자동 관리함. 우리 코드에서 날짜를 직접 계산할 필요 없음.

### 3-2. 현재 코드 상태

| 계층 | 무료 체험 지원 | 상태 |
|------|-------------|------|
| RevenueCat SDK | 지원함 | 코드에서 읽기만 하면 됨 |
| Flutter UI | 미구현 | "7일 무료 체험" 문구/버튼 없음 |
| Flutter Provider | 부분 지원 | 구독 상태는 추적하나 trial 구분 없음 |
| Django Webhook | 부분 지원 | INITIAL_PURCHASE로 처리되나 trial 필드 없음 |
| Django Model | 미구현 | trial 관련 필드 없음 |
| 스토어 콘솔 | 미설정 | Introductory Offer 설정 필요 |

### 3-3. 스토어 콘솔 설정 (코드 아닌 작업)

#### iOS — App Store Connect

1. App Store Connect → **내 앱** → **MarketLens** → **기능** → **구독**
2. `MarketLens Premium` 그룹 → `Gold Monthly` 구독 클릭
3. **구독 가격** 섹션 아래 → **소개 혜택** (Introductory Offers) 클릭
4. **+ 소개 혜택 추가** 클릭:
   - **혜택 유형**: 무료 (Free)
   - **기간**: 1주 (7일)
   - **혜택 적용 대상**: 모든 적격 고객 (신규 구독자에게만 자동 적용)
5. **저장**

> **Apple 규칙**: 같은 구독 그룹에서 1인 1회만 무료 체험 가능. Apple이 자동 관리.

#### Android — Google Play Console

1. Google Play Console → **MarketLens** → **수익 창출** → **구독**
2. `com.marketlens.gold.monthly` 클릭 → `gold-monthly-plan` 요금제 클릭
3. **혜택** 섹션 → **혜택 추가** 클릭
4. **혜택 ID**: `free-trial-7d`
5. **단계 추가**:
   - **유형**: 무료 체험 (Free trial)
   - **기간**: 7일
6. **적격성**: 새 고객 확보 (신규 구독자만)
7. **활성화**

> **Google 규칙**: 같은 앱에서 1인 1회만 무료 체험 가능. Google이 자동 관리.

#### RevenueCat 설정

RevenueCat은 스토어에서 설정한 무료 체험을 **자동으로 감지**함. 별도 설정 불필요.
- RevenueCat 대시보드 → Products → `com.marketlens.gold.monthly` → Intro Pricing이 자동 표시되는지 확인만 하면 됨.

### 3-4. Flutter 코드 변경

#### A. SubscriptionProvider 수정

파일: `lib/providers/subscription_provider.dart`

**추가할 것**:
```dart
// 새로운 상태 변수
bool _isTrialAvailable = false;    // 이 유저에게 무료 체험 가능한지
bool _isOnTrial = false;           // 현재 무료 체험 중인지
String? _trialEndDate;             // 체험 종료 날짜
String? _introPrice;               // "7일 무료 체험" 텍스트 (RevenueCat이 제공)

// getter
bool get isTrialAvailable => _isTrialAvailable;
bool get isOnTrial => _isOnTrial;
String? get trialEndDate => _trialEndDate;
String? get introPrice => _introPrice;
```

**checkStatus() 수정**:
```dart
// RevenueCat에서 Offering 로드 시 introductory price 확인
final offerings = await Purchases.getOfferings();
final monthly = offerings.current?.monthly;
if (monthly != null) {
  final intro = monthly.storeProduct.introductoryPrice;
  if (intro != null && intro.price == 0) {
    _isTrialAvailable = true;
    _introPrice = intro.periodNumberOfUnits.toString() + '일 무료 체험';
  }
}

// 현재 구독이 trial 기간인지 확인
final customerInfo = await Purchases.getCustomerInfo();
final entitlement = customerInfo.entitlements.all['gold_membership'];
if (entitlement != null && entitlement.isActive) {
  // periodType으로 trial 여부 판단
  if (entitlement.periodType == PeriodType.trial) {
    _isOnTrial = true;
    _trialEndDate = entitlement.expirationDate;
  }
}
```

#### B. GoldUpgradeSheet UI 수정

파일: `lib/screens/settings/widgets/gold_upgrade_sheet.dart`

**변경 포인트**:
```
현재:  [구독하기 ₩4,900/월] 버튼
변경:  [7일 무료 체험 시작] 버튼 (체험 가능 시)
       하단에 "체험 후 ₩4,900/월 자동 결제. 언제든 취소 가능." 안내문

현재:  혜택 3개 나열
추가:  "처음 7일은 무료!" 배지 또는 강조 텍스트
```

**변경 후 UI 흐름**:
```
┌─────────────────────────────────┐
│         Gold 멤버십               │
│                                 │
│  ✨ 보유종목 무제한               │
│  🤖 AI 분석 완전 공개             │
│  🚫 광고 완전 제거               │
│                                 │
│  ┌─────────────────────────┐    │
│  │  7일 무료 체험 시작하기    │    │  ← 체험 가능 시
│  └─────────────────────────┘    │
│  체험 후 ₩4,900/월. 언제든 취소.  │
│                                 │
│  이미 구매한 적 있나요? 복원하기    │
│  이용약관 | 개인정보처리방침        │
└─────────────────────────────────┘
```

**체험 불가능 시** (이미 체험 사용한 유저):
```
┌─────────────────────────────────┐
│  ┌─────────────────────────┐    │
│  │  구독하기 ₩4,900/월      │    │  ← 기존과 동일
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

#### C. 체험 중 상태 표시 (Settings 화면)

파일: `lib/screens/settings/settings_screen.dart`

```
현재 Gold 유저 표시:  "Gold 멤버십 · 만료: 2026-05-27"
체험 중 유저 표시:   "Gold 멤버십 (무료 체험 중) · 체험 종료: 2026-05-04"
```

#### D. 로컬라이제이션 추가 키

5개 언어 파일(en, ko, ja, zh, es)에 추가:

| 키 | EN | KO |
|----|----|----|
| `freeTrialStart` | Start 7-day free trial | 7일 무료 체험 시작하기 |
| `freeTrialInfo` | Free for 7 days, then {price}/month. Cancel anytime. | 7일 무료, 이후 {price}/월. 언제든 취소 가능. |
| `onFreeTrial` | Free trial | 무료 체험 중 |
| `trialEndsOn` | Trial ends: {date} | 체험 종료: {date} |
| `trialExpired` | Your free trial has ended | 무료 체험이 종료되었습니다 |

### 3-5. Django 백엔드 변경

#### A. SubscriptionInfo 모델 필드 추가

파일: `backend/accounts/models.py`

```python
# SubscriptionInfo에 추가
is_trial = models.BooleanField(default=False)           # 현재 체험 중?
trial_started_at = models.DateTimeField(null=True, blank=True)  # 체험 시작일
trial_ends_at = models.DateTimeField(null=True, blank=True)     # 체험 종료일
```

#### B. Webhook 핸들러 수정

파일: `backend/accounts/views.py` — `revenuecat_webhook_view()`

```python
# RevenueCat webhook payload에서 trial 정보 추출
# event.subscriber_attributes 또는 event.period_type으로 판단

period_type = event_data.get('period_type', '')  # 'TRIAL' | 'NORMAL' | 'INTRO'

if event_type == 'INITIAL_PURCHASE':
    if period_type == 'TRIAL':
        # 무료 체험 시작
        sub_info.is_trial = True
        sub_info.trial_started_at = purchased_at
        sub_info.trial_ends_at = expiration_at
    else:
        # 일반 구매 또는 체험→유료 전환
        sub_info.is_trial = False

    sub_info.is_active = True
    user.role = 'gold'

elif event_type == 'RENEWAL':
    # 체험 종료 후 첫 결제 = 전환 성공
    sub_info.is_trial = False
    sub_info.is_active = True
```

#### C. 구독 상태 API 응답 수정

파일: `backend/accounts/views.py` — `subscription_status_view()`

```python
# 기존 응답에 trial 정보 추가
response_data = {
    'is_gold': user.role in ['gold', 'manager', 'master'],
    'is_active': sub_info.is_active if sub_info else False,
    'is_trial': sub_info.is_trial if sub_info else False,        # 추가
    'trial_ends_at': sub_info.trial_ends_at if sub_info else None,  # 추가
    'expiration_date': sub_info.expiration_date if sub_info else None,
    'product_id': sub_info.product_id if sub_info else None,
}
```

### 3-6. 무료 체험 흐름 — 전체 시퀀스

```
1. 유저가 GoldUpgradeSheet 열기
   └→ SubscriptionProvider.checkStatus() 호출
   └→ RevenueCat SDK가 introductoryPrice 정보 반환
   └→ isTrialAvailable = true → "7일 무료 체험 시작" 버튼 표시

2. "7일 무료 체험 시작" 탭
   └→ Apple/Google 결제 시트 표시 (카드 정보 입력)
   └→ "₩0 오늘, 7일 후 ₩4,900/월" 문구 (스토어가 자동 표시)
   └→ 유저 확인 → 체험 시작

3. RevenueCat → Django Webhook
   └→ event_type: INITIAL_PURCHASE
   └→ period_type: TRIAL
   └→ Django: user.role = 'gold', is_trial = true

4. 앱에서 Gold 기능 즉시 사용 가능
   └→ Settings에 "무료 체험 중 · 체험 종료: 5/4" 표시

5. 7일 후 (자동)
   └→ Apple/Google이 ₩4,900 결제
   └→ RevenueCat → Django Webhook
   └→ event_type: RENEWAL (또는 INITIAL_PURCHASE with period_type: NORMAL)
   └→ Django: is_trial = false, 정상 Gold 유지

6. 체험 중 취소 시
   └→ 유저: 설정 → 구독 관리 → 취소
   └→ 7일차까지 Gold 유지 (체험 기간은 보장)
   └→ 7일 후 → RevenueCat → EXPIRATION webhook
   └→ Django: role = 'regular', is_active = false
```

---

## 4. 스토어 연동 & 출시 가이드

### 4-1. 전체 아키텍처

```
┌──────────────┐     구매 요청      ┌──────────────────┐
│  Flutter 앱   │ ──────────────→  │  App Store /      │
│  (유저 결제)   │ ←────────────── │  Google Play      │
│              │   결제 결과 반환   │  (실제 과금 처리)   │
└──────┬───────┘                  └────────┬─────────┘
       │                                    │
       │  RevenueCat SDK                    │  Server-to-Server 알림
       │  (purchases_flutter)               │
       │                                    ▼
       │                          ┌──────────────────┐
       │  상태 확인/구매            │   RevenueCat      │
       └─────────────────────→   │   (중계 서버)      │
                                  │   - 구독 상태 관리  │
                                  │   - 체험/갱신/만료  │
                                  └────────┬─────────┘
                                           │
                                           │  Webhook POST
                                           ▼
                                  ┌──────────────────┐
                                  │  Django 백엔드     │
                                  │  (AWS 서버)       │
                                  │  - role 업데이트   │
                                  │  - 구독정보 저장   │
                                  │  - 체험 상태 추적  │
                                  └──────────────────┘
```

### 4-2. 작업 순서 체크리스트

#### Phase A: 스토어 & RevenueCat 설정 (코드 밖 작업)

| # | 작업 | 상세 | 시간 |
|---|------|------|------|
| 1 | RevenueCat 계정 + 프로젝트 생성 | https://app.revenuecat.com → Sign Up → New Project "MarketLens" | 5분 |
| 2 | Entitlement 생성 | Identifier: `gold_membership` (코드에 하드코딩됨) | 2분 |
| 3 | Offering + Package 생성 | default Offering → Monthly 패키지 | 3분 |
| 4 | App Store Connect 구독 상품 | 구독 그룹 `MarketLens Premium` → `Gold Monthly` (ID: `com.marketlens.gold.monthly`) | 10분 |
| 5 | iOS 가격 설정 | ₩4,900/월, 기본 국가: 대한민국 | 5분 |
| **6** | **iOS 소개 혜택 (무료 체험) 설정** | **구독 → 소개 혜택 → 무료 → 1주(7일) → 모든 적격 고객** | **5분** |
| 7 | iOS 구독 현지화 | 한국어/영어/일본어 표시 이름 + 설명 | 5분 |
| 8 | App Store 서버 알림 | 프로덕션 URL = RevenueCat 제공 URL, Version 2 | 3분 |
| 9 | In-App Purchase Key 생성 | .p8 다운로드 + Key ID + Issuer ID 메모 | 10분 |
| 10 | RevenueCat에 Apple 연결 | Bundle ID + .p8 + Key ID + Issuer ID 입력 | 5분 |
| 11 | RevenueCat에 iOS 상품 매핑 | Product: `com.marketlens.gold.monthly` → Offering + Entitlement 연결 | 3분 |
| 12 | RevenueCat iOS API Key 복사 | `appl_xxxx` 형식 | 1분 |
| 13 | Google Play 구독 상품 | ID: `com.marketlens.gold.monthly`, 요금제: `gold-monthly-plan` | 10분 |
| 14 | Android 가격 설정 | ₩4,900/월 | 3분 |
| **15** | **Android 무료 체험 혜택 설정** | **혜택 ID: `free-trial-7d` → 무료 체험 → 7일 → 새 고객** | **5분** |
| 16 | Google Cloud Service Account | JSON 키 다운로드 | 15분 |
| 17 | Google Play 권한 부여 | 서비스 계정에 앱 + 재무 + 주문 관리 권한 | 5분 |
| 18 | RevenueCat에 Google 연결 | Package Name + JSON 업로드 | 5분 |
| 19 | RTDN 설정 | Pub/Sub 주제 입력 | 3분 |
| 20 | RevenueCat에 Android 상품 매핑 | Product + Plan 연결 → Offering + Entitlement | 3분 |
| 21 | RevenueCat Android API Key 복사 | `goog_xxxx` 형식 | 1분 |
| 22 | RevenueCat Webhook 등록 | URL: `https://www.hypehere.net/api/marketlens/accounts/webhook/revenuecat/` + Bearer 토큰 | 5분 |

#### Phase B: 코드 수정 (구현 작업)

| # | 작업 | 파일 | 시간 |
|---|------|------|------|
| 23 | Django SubscriptionInfo에 trial 필드 추가 | `backend/accounts/models.py` | 10분 |
| 24 | Django webhook에 trial 처리 로직 | `backend/accounts/views.py` | 15분 |
| 25 | Django subscription status에 trial 응답 | `backend/accounts/views.py` | 5분 |
| 26 | AWS DB 마이그레이션 | SSH → makemigrations → migrate | 5분 |
| 27 | AWS Webhook Secret 설정 | `/home/django/marketlens/.env` | 3분 |
| 28 | Flutter SubscriptionProvider trial 상태 | `lib/providers/subscription_provider.dart` | 15분 |
| 29 | Flutter GoldUpgradeSheet 체험 UI | `lib/screens/settings/widgets/gold_upgrade_sheet.dart` | 15분 |
| 30 | Flutter Settings 체험 상태 표시 | `lib/screens/settings/settings_screen.dart` | 10분 |
| 31 | 로컬라이제이션 5개 키 × 5개 언어 | `lib/l10n/app_*.arb` (5파일) | 10분 |
| 32 | Flutter .env에 API 키 입력 | `.env` | 2분 |

#### Phase C: 테스트

| # | 작업 | 시간 |
|---|------|------|
| 33 | iOS Sandbox 테스터 생성 + 체험 테스트 | 30분 |
| 34 | Android Internal Test + 체험 테스트 | 30분 |
| 35 | 전체 시나리오 테스트 (아래 체크리스트) | 30분 |

### 4-3. 테스트 체크리스트

| # | 시나리오 | 예상 결과 | OK? |
|---|---------|----------|-----|
| 1 | 무료 체험 시작 | 결제창에 "₩0 오늘, 7일 후 ₩4,900/월" 표시 → Gold 활성화 | ☐ |
| 2 | 체험 중 앱 재시작 | Gold 유지, "무료 체험 중" 표시 | ☐ |
| 3 | 체험 만료 → 첫 결제 | Sandbox 3분 후 → webhook RENEWAL → Gold 유지, is_trial=false | ☐ |
| 4 | 체험 중 취소 | 체험 기간 끝까지 Gold 유지 → 이후 regular 복귀 | ☐ |
| 5 | 체험 이미 사용한 유저 | "구독하기 ₩4,900/월" 버튼 표시 (체험 버튼 안 보임) | ☐ |
| 6 | 일반 구매 (체험 없이) | 즉시 ₩4,900 결제 → Gold 활성화 | ☐ |
| 7 | 자동 갱신 | Sandbox 5분 후 → webhook RENEWAL → Gold 유지 | ☐ |
| 8 | 구독 취소 후 만료 | webhook EXPIRATION → role=regular | ☐ |
| 9 | 구매 복원 | Settings > "구매 복원" → Gold 복원 | ☐ |
| 10 | 비로그인 구매 시도 | "로그인 필요" 안내 | ☐ |
| 11 | 이미 Gold 유저 (Manager/Master) | 구매 버튼 안 보임 | ☐ |
| 12 | 수동 Gold 보호 | admin 수동 승급 Gold → webhook 강등 안 됨 | ☐ |

---

## 5. 앱 심사 제출 시 주의사항

### iOS 심사 필수

1. **구독 약관 표시**: GoldUpgradeSheet에 포함됨 ✅
2. **구매 복원 버튼**: Settings에 포함됨 ✅
3. **무료 체험 안내**: 체험 기간, 이후 가격, 취소 방법 명시 필요
4. **개인정보 처리방침**: 구독 데이터 수집 내용 추가
5. **심사 정보**: 구독 상품에 스크린샷 + Sandbox 테스트 계정 제공

### Google Play 심사 필수

1. **구독 정보 표시**: 가격, 체험 기간, 갱신 주기, 취소 방법 ✅
2. **데이터 보안**: 결제 데이터 수집 표기
3. **무료 체험 명시**: "7일 무료 체험 후 자동 결제" 문구

### 무료 체험 관련 Apple 심사 주의

- **반드시** 체험 기간과 이후 가격을 명확히 표시해야 함
- "7일 무료 체험, 이후 ₩4,900/월 자동 결제. 언제든 취소 가능." 형태
- 체험 시작 전에 이 정보가 보여야 함 (구매 버튼 근처)
- 위반 시 **심사 반려** 사유 됨

---

## 6. 참고 링크

### RevenueCat
- [Quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)
- [App Store Connect 설정](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/app-store-connect-setup-guide)
- [iOS 상품 설정](https://www.revenuecat.com/docs/getting-started/entitlements/ios-products)
- [In-App Purchase Key](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration)
- [Google Play Service Credentials](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials)
- [Android 상품 설정](https://www.revenuecat.com/docs/getting-started/entitlements/android-products)
- [Apple Sandbox 테스트](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store)

### 스토어
- [Apple — 구독 가격 설정](https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/)
- [Apple — Introductory Offers](https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/subscriptions_and_offers/implementing_introductory_offers_in_your_app)
- [Google Play 결제 설정](https://revenuecat.github.io/codelabs/google-play.html)
- [Google Play — Free Trials](https://support.google.com/googleplay/android-developer/answer/140504)
