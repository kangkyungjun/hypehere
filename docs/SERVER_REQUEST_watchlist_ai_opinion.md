# [서버 요청] 관심종목 하단 "AI 의견" 신규 기능 — 스펙 확정 요청

> **개인화(user_id 포함) 확정본.** 아래를 그대로 서버 개발자에게 전달하면 됩니다.

앱 관심종목(watchlist) 목록에서 각 종목 하단에 **AI 의견(서술형 코멘트)** 을 노출하는 신규 기능입니다.
맥미니가 **관심종목 전용·유저 개인화 AI 의견**을 생성해 서버에 올리고, 앱이 관심종목 화면에서 읽어 표시하는 구조입니다.

> ※ 기존 종목 상세의 공통 AI 코멘트(`/ingest/scores` 의 `ai_analysis.summary`/`final_comment`)와는 **별개**입니다.
> 그건 유저 무관 전 종목 공통이고, 이건 유저의 관심 맥락(목표 매수가·관심등록일 등)을 반영한 **개인화 의견**입니다.

## 데이터 흐름 (목표)

```
서버 ─(관심종목 목록 공급)→ 맥미니(개인화 AI 의견 생성)
     ─ POST /ingest/watchlist-opinion → 서버 저장 → 앱 GET
```

---

## ★ 요청 0 (필수 선행) — 관심종목이 지금 맥미니로 안 들어옵니다

현재 맥미니의 `local_watchlist` 가 **0건**입니다. 유저가 뭘 관심등록했는지 몰라 의견 생성 자체가 불가합니다.

**원인**
- 맥미니가 호출하는 `GET https://hypehere.net/api/v1/internal/users/portfolios` 가 **HTTP 404**
  (holdings+watchlist 풀 동기화 엔드포인트 미배포/경로불일치)
- 큐 푸시(`analysis-queue` 의 `PORTFOLIO_CHANGE`)는 holdings만 전달, watchlist는 미포함

**→ (권장)** 위 GET 엔드포인트를 아래 형식으로 **watchlist 포함**해 200 응답하도록 복구해 주세요.
맥미니는 이미 이 응답을 파싱해 저장하는 코드가 있어, **서버만 복구되면 앱 수정 없이 바로 동작**합니다.

```json
{
  "holdings": [
    { "user_id": "12", "ticker": "AAPL", "buy_price": 150.0, "buy_date": "2026-01-15", "quantity": 10, "status": "HOLDING" }
  ],
  "watchlist": [
    { "user_id": "12", "ticker": "NVDA", "added_date": "2026-02-01", "target_buy_price": 700.0, "ai_alert_enabled": true }
  ]
}
```

(실시간성이 필요하면 큐 푸시에 watchlist 변경을 싣는 방식도 가능하나, **앱·서버 양쪽 수정** 필요. 어느 쪽으로 갈지 회신 요청.)

---

## ■ 요청 1 — ingest 엔드포인트 신설 (맥미니 → 서버)

기존 ingest 들과 동일 컨벤션으로 신설 부탁드립니다.

- **엔드포인트:** `POST /api/v1/internal/ingest/watchlist-opinion` (경로명 확정 요청)
- **헤더:** `X-API-Key: <ANALYTICS_API_KEY>`
- **바디:** `{"items": [ ... ]}` (배치 30건/요청)
- **응답:** `{"status":"ok","upserted": N}`
- **UPSERT 키:** `(user_id, ticker, date)` — 유저·종목·일자별 1건 (개인화 확정)

**item 필드**

```json
{
  "user_id": "12",
  "ticker": "NVDA",
  "date": "2026-07-02",
  "opinion": "관심 등록가 $700 대비 현재 +8%. 단기 과열이나...|||English seg|||中文|||日本語|||Español",
  "stance": "HOLD",
  "confidence": 0.72,
  "target_buy_price": 700.0
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `user_id` | string | 유저 id |
| `ticker` | string | 종목 |
| `date` | YYYY-MM-DD | 분석 기준 거래일 |
| `opinion` | string | 핵심 서술 텍스트. 다국어 `ko\|\|\|en\|\|\|zh\|\|\|ja\|\|\|es` 5세그먼트 (기존 `final_comment` 와 동일 포맷) |
| `stance` | string | BUY/HOLD/SELL (선택) |
| `confidence` | float 0~1 | 신뢰도 (선택) |
| `target_buy_price` | float | 참고용 에코 (선택) |

- `opinion` 이 비면(NULL/`''`) 앱에 안 뜨게 처리 부탁드립니다 (기존 portfolio-advice summary 게이트와 동일 규칙).

---

## ■ 요청 2 — 읽기 API 신설 (앱 → 서버)

앱 관심종목 화면이 종목별 최신 AI 의견을 가져오는 API. 설계 부탁드립니다.

- 예: `GET /api/v1/watchlist/opinion?lang=ko` (유저 토큰 인증)
- 응답: 유저 관심종목별 `opinion` 이 비지 않은 **최신 date 1건씩**

```json
{ "items": [ { "ticker": "NVDA", "date": "2026-07-02", "opinion": "...", "stance": "HOLD", "confidence": 0.72 } ] }
```

- 다국어: `opinion` 은 `|||` 5세그먼트 저장 → 읽기 시 **lang 세그먼트만 추출**해 내려줄지, **원문 그대로** 내려주고 앱이 분리할지 컨벤션 회신 부탁드립니다.

---

## ■ 요청 3 — 서버 테이블 (신규)

```sql
CREATE TABLE watchlist_opinion (
  user_id          VARCHAR,
  ticker           VARCHAR,
  date             DATE,
  opinion          TEXT,          -- 다국어 ||| 5세그먼트
  stance           VARCHAR NULL,
  confidence       FLOAT NULL,
  target_buy_price FLOAT NULL,
  updated_at       TIMESTAMP,
  PRIMARY KEY (user_id, ticker, date)
);
```

---

## ■ 맥미니측 담당 (요청 0 해결 후 구현)

- 유저별 관심종목에 대해 기술지표/LSTM/뉴스/거시 + 관심 맥락(목표 매수가 대비, 관심등록 이후 수익)을 반영한 개인화 의견 생성
- 다국어 5세그먼트로 `opinion` 생성 → `/ingest/watchlist-opinion` 배치 업로드
- 갱신 주기: 매일 1회 배치(장 마감 분석 직후) 제안

---

## ■ 회신 필요 항목

1. **[전제]** 관심종목 공급: `GET .../users/portfolios` 404 복구(권장) vs 큐 푸시 확장 — 어느 쪽?
2. ingest 경로명 `/ingest/watchlist-opinion` 확정 여부
3. 읽기 API 계약: 경로·인증·최신date 서빙·`opinion` 빈값 게이트·다국어(lang 추출 vs 원문)
4. 선택 필드(`stance`/`confidence`/`target_buy_price`) 채택 여부
5. 테이블 스키마 승인

**우선순위:** 1차 = 요청 0(블로커) → 2차 = 요청 1·3 → 3차 = 요청 2 + 앱 표시
