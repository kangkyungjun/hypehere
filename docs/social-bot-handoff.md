# MarketLens 홍보 자동화 — 가상 매매 페르소나 봇 (맥미니 핸드오프 문서)

## Context (왜 만드는가)

MarketLens 앱 홍보를 위해, **가상의 트레이더 페르소나가 매일 매매일지를 SNS에 올리는 자동화 봇**을 만든다.
컨셉: "오늘 MarketLens 앱에서 본 추천 1·2위를 매수 → 며칠 뒤 목표수익 도달 시 매도 → 총 자산이 불어나는 모습"을 매일 포스팅.
모든 포스트 하단에 iOS/Android 가입 링크를 붙여 앱 유입을 유도한다.

- 1차 목표: **X(트위터)** 1개 페르소나부터. 이후 스레드·인스타 + 다른 페르소나(다른 컨셉·계정)로 확장.
- 실행 환경: **맥미니(24시간)**. 맥북은 실개발용이라 상시 구동 불가.
- 자동화 수준: **생성 → 텔레그램 검토·승인 → 게시** (완전 무인 아님, 초기엔 사람이 1분 승인).
- 모든 상태·이력을 DB에 저장(향후 어드민 대시보드·다중 페르소나 대비).

### 핵심 개념 — "누가 매일 글을 쓰나"
매일 글을 쓰는 것은 **채팅 세션의 Claude가 아니라 LLM API(GPT-4o mini)** 이고, 맥미니 스크립트가 자동으로 호출한다.
맥미니에는 **이미** `analysis_requests` 큐를 폴링해 Claude API를 부르는 워커가 돌고 있으므로(거시 AI 설명·관심종목 AI), 그 옆에 신규 서비스를 얹는다. 사람은 하루 1분 승인만 한다.

---

## 아키텍처

```
[맥미니 cron — 미국장 마감·시세 적재 후 하루 1회 실행]
  1. 시세 확인:   analytics.ticker_prices 오늘자 종가 존재? (없으면=휴장 → 스킵)
  2. 추천 조회:   Django API로 '페르소나 앱 계정'의 오늘 추천 1·2위 read
  3. 매매 판단:   보유중 포지션 매도체크(목표%·기간) + 신규 매수(현금 되면 1주씩)
  4. 상태 갱신:   social.positions / social.account_snapshots 업데이트
  5. 카피 생성:   오늘 사건(매수/매도/스킵/입금)+총자산을 GPT-4o mini에 넘겨 영어 포스트 생성(사건 없으면 현황 1줄)
  6. 규제 필터:   금칙어 검사(수익보장 등) → 걸리면 보류
  7. 검토 큐:     social.posts 에 status=pending 저장
  8. 승인 요청:   텔레그램 봇으로 초안 전송 (Approve/Edit/Skip 버튼)
       ↓ 승인
  9. 게시:        X API v2로 트윗 + 하단 iOS/Android 링크
  10. 로깅:       external_post_id·게시시각 기록
```

핵심 데이터베이스는 **2개**:
- **Django DB** — 추천종목·유저 계정 (`accounts_recommendation`). HTTP API로만 접근.
- **FastAPI analytics Postgres** — 시세(`analytics.ticker_prices`). 맥미니 워커가 직접 DB 연결(`DATABASE_ANALYTICS_URL`).

봇의 상태 테이블은 같은 analytics Postgres에 **신규 `social` 스키마**로 둔다(기존 마이그레이션 패턴 재사용, 워커가 이미 연결됨).

---

## 데이터 소스 (정확한 엔드포인트/테이블)

### 1) 추천 1·2위 — Django REST
- **엔드포인트**: `GET /api/accounts/recommendations/?date=YYYY-MM-DD`
  - 파일: `marketlens/backend/accounts/views.py:1046` `user_recommendations_view()`
  - 인증: 페르소나 계정의 **Token** (`Authorization: Token <persona_token>`)
  - 응답: `recommendations[]` 배열, 각 항목 `rank / ticker / name / name_ko / fit_score / current_price / change_pct / signal`
  - 봇은 `rank==1`, `rank==2` 두 종목만 사용
- 모델: `accounts_recommendation` (`marketlens/backend/accounts/models.py:260`), unique `(user_id, date, ticker)`
- ⚠️ **전제**: 페르소나 계정도 매일 추천이 생성되어야 함. 추천은 맥미니 deep_bot이 유저별로 생성해 `POST /api/v1/internal/ingest/recommendations`로 적재(`views.py:976`). **페르소나 user_id가 이 일일 배치에 포함**되도록 개발자가 확인/추가해야 함.

### 2) 시세(진입가·현재가·매도가) — analytics Postgres 직접 조회
- 테이블: `analytics.ticker_prices` (`marketlens-fastapi-work/app/models.py:49`)
  - `close` = 해당일 종가(= 진입가/현재가/매도가로 사용), `date` PK, `change_pct`
  - 최신가: `SELECT close FROM analytics.ticker_prices WHERE ticker=:t ORDER BY date DESC LIMIT 1`
- 대안(HTTP): `GET /api/v1/charts/{ticker}` 마지막 데이터포인트. **직접 DB 조회를 기본**으로 한다(워커가 이미 연결, 무인증).
- 종목 식별자: **US 티커, 대문자** (AAPL, MSFT 등). 통화 **USD**.

### 진실성 원칙
진입가·매도가·수익률은 **반드시 실제 `ticker_prices.close`로 계산**한다. 숫자를 지어내지 않는다(신뢰도·규제).

---

## 매매 규칙 (확정 파라미터, 상수로 관리 — 튜닝 가능)

```
SEED_CAPITAL      = 1000.00 USD   # 시드 자본
BUY_RANKS         = [1, 2]        # 매일 추천 1·2위 대상
SHARES_PER_BUY    = 1             # 종목당 1주
TARGET_PCT        = +5.0 %        # 목표 수익 도달 시 매도
MAX_HOLD_DAYS     = 10 (거래일)   # 기간 초과 시 손익 무관 청산
ONE_LOT_PER_TICKER = true         # 이미 보유중인 티커는 재매수 스킵
```

**일일 판단 순서** (미국 거래일 기준):
1. **매도 체크** (보유 포지션 전부):
   - 현재수익률 = (오늘종가 − 진입가)/진입가
   - `현재수익률 ≥ TARGET_PCT` → **매도**(오늘 종가)
   - 또는 `보유거래일 ≥ MAX_HOLD_DAYS` → **매도**(손익 무관)
   - 매도 시 현금 += 매도가, 포지션 status=closed, realized_pnl 기록
2. **매수 체크** (추천 1위 → 2위 순):
   - 이미 보유중(open)인 티커면 스킵
   - `현금 ≥ 오늘종가`면 **1주 매수**(진입가=오늘 종가), 현금 −= 진입가
   - `현금 < 오늘종가`면 **못 사고 스킵**(로그 남김)
3. **스냅샷 기록**: 현금 / 보유평가액 / 총자산 / 투입자본 / 총수익률 → `social.account_snapshots`
4. **항상 포스트 1건 생성**: 사건 있으면 매매일지, 없거나 전부 스킵이면 현황 포스트(보유요약+수익률+앱링크 한 줄). 현금부족 스킵도 이벤트로 로깅해 포스트에 반영 가능.

> 수익률 정의: `total_return_pct = (총자산 − 투입자본)/투입자본`, **투입자본 = 시드 + Σ(capital_events 입금)**. 자금 추가는 수익이 아니라 원금 증가로 처리(수익률 왜곡 방지).

---

## DB 스키마 (신규 `social` 스키마 — analytics Postgres)

마이그레이션은 기존 패턴대로 번호매긴 SQL로 추가:
`marketlens-fastapi-work/migrations/0NN_add_social_schema.sql` (`run_migration.py`로 실행).

```sql
CREATE SCHEMA IF NOT EXISTS social;

-- 페르소나(계정) — 다중 페르소나 확장의 중심
CREATE TABLE social.personas (
    id              SERIAL PRIMARY KEY,
    handle          VARCHAR(64) NOT NULL,      -- X 핸들 등
    platform        VARCHAR(20) NOT NULL,      -- 'X' | 'THREADS' | 'INSTAGRAM'
    app_user_id     INTEGER NOT NULL,          -- Django 페르소나 계정 user_id
    investment_style VARCHAR(30),              -- 계정 투자성향(추천 결정)
    language        VARCHAR(8) DEFAULT 'en',
    seed_capital    NUMERIC(12,2) DEFAULT 1000,
    cash_balance    NUMERIC(12,2) DEFAULT 1000,
    target_pct      NUMERIC(5,2) DEFAULT 5.0,
    max_hold_days   INTEGER DEFAULT 10,
    active          BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 가상 포지션(매매 장부)
CREATE TABLE social.positions (
    id           BIGSERIAL PRIMARY KEY,
    persona_id   INTEGER NOT NULL REFERENCES social.personas(id),
    ticker       VARCHAR(10) NOT NULL,
    entry_date   DATE NOT NULL,
    entry_price  NUMERIC(12,4) NOT NULL,
    shares       INTEGER NOT NULL DEFAULT 1,
    status       VARCHAR(10) NOT NULL DEFAULT 'open',  -- open | closed
    exit_date    DATE,
    exit_price   NUMERIC(12,4),
    realized_pnl NUMERIC(12,4),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_positions_open ON social.positions(persona_id, status);

-- 일일 자산 스냅샷(성장 서사·차트용)
CREATE TABLE social.account_snapshots (
    persona_id       INTEGER NOT NULL REFERENCES social.personas(id),
    date             DATE NOT NULL,
    cash             NUMERIC(12,2) NOT NULL,
    holdings_value   NUMERIC(12,2) NOT NULL,
    total_value      NUMERIC(12,2) NOT NULL,
    contributed_capital NUMERIC(12,2) NOT NULL,  -- 시드 + Σ자금추가(원금)
    total_return_pct NUMERIC(7,2) NOT NULL,       -- (total_value-contributed_capital)/contributed_capital
    PRIMARY KEY (persona_id, date)
);

-- 자금 추가/출금 이벤트(텔레그램 명령 기반)
CREATE TABLE social.capital_events (
    id          BIGSERIAL PRIMARY KEY,
    persona_id  INTEGER NOT NULL REFERENCES social.personas(id),
    date        DATE NOT NULL,
    amount      NUMERIC(12,2) NOT NULL,   -- +입금 / -출금
    note        VARCHAR(200),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 포스트 초안·이력(검토 큐 + 감사 로그)
CREATE TABLE social.posts (
    id            BIGSERIAL PRIMARY KEY,
    persona_id    INTEGER NOT NULL REFERENCES social.personas(id),
    date          DATE NOT NULL,
    platform      VARCHAR(20) NOT NULL,
    content       TEXT NOT NULL,
    status        VARCHAR(12) NOT NULL DEFAULT 'pending', -- pending|approved|posted|skipped|failed
    external_post_id VARCHAR(64),
    approved_at   TIMESTAMP,
    posted_at     TIMESTAMP,
    kind          VARCHAR(16) NOT NULL DEFAULT 'daily', -- daily | adhoc
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 일일 포스트만 하루 1건 유니크(adhoc 임의 포스팅은 여러 건 허용)
CREATE UNIQUE INDEX uq_posts_daily
    ON social.posts(persona_id, date, platform) WHERE kind = 'daily';
```

멱등성: cron이 두 번 돌아도 `uq_posts_daily` 부분 유니크 인덱스 + `positions` 당일 매수여부 확인으로 중복 매매/게시 방지. (adhoc 포스트는 예외로 여러 건 허용)

---

## 포스트 생성 (LLM: GPT-4o mini)

- **기존에 쓰던 OpenAI `gpt-4o-mini` 재사용** (`OPENAI_API_KEY`). Claude 아님.
- 하루 **1회** 포스팅 — 이벤트 유무와 무관하게 **항상 1건** 생성:
  - 매수/매도/입금 등 사건 있음 → **매매일지 포스트**
  - 사건 없음 or 현금부족으로 전부 스킵 → **현황 포스트**(보유 요약·수익률·앱 링크 한 줄)
- 입력: 오늘 사건(매수/매도/스킵/입금) + 스냅샷(총자산·수익률·현금·투입자본) + 언어=en.
- 출력: 영어 트윗 본문. **고정 푸터(iOS/Android 링크·면책)는 코드에서 붙임**(모델이 링크를 변형하지 않도록).

**포스트 예시(영어):**
```
📈 MarketLens Paper Portfolio — Day 42

Today's picks from the MarketLens app:
🟢 Bought $AAPL @ $182.45 (rank #1)
🟢 Bought $MSFT @ $410.20 (rank #2)

💰 Sold $NVDA @ $128.30 → +5.4% (+$6.60)

Total value: $1,000 → $1,187 (+18.7%)
Invested: $1,000 · Cash: $47

📲 Get the same picks on MarketLens:
iOS: <app_store_link>   Android: <play_store_link>

*Paper trading, real prices. Not investment advice.*
```

**현황 포스트 예시 (사건 없는 날 / 현금부족 스킵):**
```
📊 MarketLens Paper Portfolio — Day 43

Holding 4 picks from the MarketLens app. No trades today — staying patient.

Total value: $1,187 (+18.7%) · Cash: $47

📲 Follow the same picks on MarketLens:
iOS: <app_store_link>   Android: <play_store_link>

*Paper trading, real prices. Not investment advice.*
```

**규제 필터** (게시 전 필수):
- 금칙어 차단: "guaranteed", "무조건", "수익보장", "risk-free" 등 → 걸리면 status=pending 유지·경고.
- 항상 "Paper trading / Not investment advice" 면책 포함.

---

## 텔레그램 검토·승인 플로우

- 사전: BotFather로 봇 생성 → `TELEGRAM_BOT_TOKEN`, 본인 `TELEGRAM_CHAT_ID` 확보.
- 초안 생성되면 봇이 본인에게 메시지 전송 + 인라인 버튼:
  - **Approve** → `social.posts.status=approved` → 즉시 X 게시
  - **Edit** → 사용자가 수정 텍스트로 답장 → content 교체 후 게시
  - **Skip** → status=skipped, 게시 안 함
- 미승인 상태로 컷오프(예: 게시목표시각 +N시간) 지나면 보류(자동 게시 안 함).
- 구현: `python-telegram-bot` 폴링 또는 webhook. 맥미니라 폴링이 간단.

---

## 명령 기반 유연 대처 (텔레그램 명령)

승인 버튼 외에 **사용자 명령**도 처리한다(데이터·포스팅 양쪽 반영):

- **초안 수정**: 초안에 답장으로 새 텍스트 → `posts.content` 교체 후 게시 (기존 Edit)
- **`/addcash <금액> [메모]`**: 자금 추가 → `social.capital_events` 기록 + `personas.cash_balance` 증가 + 다음 스냅샷의 투입자본 반영. 그날 포스트에 `💵 Added $500 capital` 식으로 노출, 다음 매수부터 늘어난 현금 사용. (음수 금액=출금)
- **`/post <내용>`**: 임의 특정 포스팅. 준 내용으로 adhoc 초안 생성 → Approve/Skip → 게시. `social.posts.kind='adhoc'`로 기록. 일일 포스트와 별개(같은 날 공존 가능).
- **`/status`**: 현재 포트폴리오 요약 확인(게시 안 함).

모든 명령 결과는 DB에 남겨 감사 가능하게 하고, `/post`·수정본도 규제 필터를 태운다(기본값).

---

## X(트위터) 게시

- 라이브러리: `tweepy` (X API v2, `create_tweet`).
- 사전: 페르소나 핸들용 X 개발자 앱 → API key/secret + access token/secret.
- 무료 티어 write 월 ~500건 → 하루 1~2건 충분(유료 불필요).
- 게시 성공 시 tweet id를 `external_post_id`에 저장.

---

## 다중 페르소나 확장 설계 (미리 반영)

모든 테이블이 `persona_id` FK 중심 → 페르소나 추가 = `social.personas` row 추가 + 해당 앱 계정/X앱/텔레그램 타깃만 등록.
- 페르소나마다 다른 **투자성향(app account)** → 다른 추천 → 다른 포트폴리오 서사.
- 플랫폼별 카피 톤은 `platform` 분기로 프롬프트만 다르게(스레드=대화체, 인스타=해시태그). 코어 로직은 공유.
- 시크릿은 페르소나별로 `.env`/시크릿 스토어에 분리(`persona_<id>_X_TOKEN` 등).

---

## 사전 준비물 (코드로 못 하는 것 — 사용자/개발자 수동)

1. **페르소나 앱 계정 생성**: MarketLens에 봇 전용 계정 → 투자성향 설정 → 로그인 토큰 확보. **일일 추천 배치에 이 user_id 포함 확인**(deep_bot).
2. **X 개발자 앱**: 페르소나 핸들용 → API 자격증명 4종.
3. **텔레그램 봇**: BotFather → 토큰 + 본인 chat_id.
4. **앱 스토어 링크 확정**: iOS/Android URL(포스트 푸터 고정값).
5. `OPENAI_API_KEY`: 기존에 쓰던 GPT-4o mini 키 재사용.

---

## 단계별 구현 로드맵

- **Phase 0 — 스키마/설정**: `social` 스키마 마이그레이션 적용, 페르소나 1개 seed row, `.env` 자격증명 세팅.
- **Phase 1 — 코어 파이프라인(게시 없이)**: 추천 조회 → 시세 조회 → 매매 판단 → positions/snapshots 갱신 → 포스트 생성(GPT-4o mini, 사건 없으면 현황 1줄) → 규제 필터 → `social.posts`(pending) 저장. **여기까지 X/텔레그램 없이 로컬 테스트 가능**.
- **Phase 2 — 텔레그램 승인·명령**: 초안 전송 + Approve/Edit/Skip, 명령(`/addcash`·`/post`·`/status`) 처리.
- **Phase 3 — X 게시**: 승인 시 tweepy로 트윗 + 로깅.
- **Phase 4 — cron 상시화**: 미국장 마감·시세적재 이후 하루 1회 실행(launchd/cron). 휴장·실패·재시도·알림 처리.
- **Phase 5 — 확장**: 스레드/인스타 어댑터, 2번째 페르소나, (선택) 이미지 카드.

---

## 코드 위치 제안

- 신규 서비스: 맥미니에 `marketlens-social-bot/` (독립 파이썬 프로젝트). analytics Postgres는 `DATABASE_ANALYTICS_URL`로 재사용.
- 마이그레이션 SQL만 `marketlens-fastapi-work/migrations/`에 번호매겨 추가.
- (선택·후순위) 어드민에서 페르소나 성과 보려면 FastAPI에 read 라우터 추가.

---

## 검증 (End-to-End)

1. **Phase 1 단위**: 특정 과거 날짜로 파이프라인을 수동 실행 → `social.positions`에 진입 기록, `account_snapshots` 값이 손계산과 일치하는지 확인. 며칠치를 순차 실행해 매도 트리거(+5%/10일) 동작 확인.
2. **진실성 검증**: 임의 종목의 진입가·매도가가 `analytics.ticker_prices.close`와 일치하는지 대조.
3. **멱등성**: 같은 날짜로 두 번 실행 → 중복 매수/중복 post row 없는지 확인.
4. **규제 필터**: 금칙어 포함 문장 주입 → 보류 처리되는지.
5. **텔레그램**: 초안 수신 + Approve/Skip 반영 확인.
6. **X**: 테스트 계정으로 실제 트윗 1건 게시 → tweet id 저장 확인, 푸터 링크 정상.
7. **휴장일**: 주말 날짜로 실행 → 시세 없음 감지 후 스킵.
8. **매일 최소 1건**: 매수·매도 없는 날에도 현황 포스트 1건 생성되는지.
9. **자금 추가**: `/addcash 500` → `capital_events`·`cash_balance`·스냅샷 투입자본 반영, 다음 포스트에 노출.
10. **임의 포스팅**: `/post ...` → adhoc 초안 생성·게시, 일일 포스트와 별개로 기록.

---

## 열린 항목(구현 중 결정)
- 게시 정확 시각(미국장 마감 직후 vs 저녁 ET) — 초기 엔게이지먼트 보며 조정.
- 통화 표기(USD 단독 vs KRW 병기).
- adhoc 포스트 규제 필터 적용 여부(기본: 적용).
