# S1 — `data_quality` 저장 + 조회 노출 (적용 완료)

> 대상 서버: EC2 `43.201.45.60` · `/home/django/fastapi_analytics`
> 서비스: `fastapi-analytics.service` (uvicorn `app.main:app` :8001)
> DB: RDS Postgres `hypehere` · 스키마 `analytics`
>
> ✅ **2026-10-02 적용 완료.** 마이그레이션 + 코드 4곳 + 조회 노출까지 끝내고
> 서비스를 재시작했다. 아래는 적용된 내용 그대로다.
>
> 남은 것은 **맥미니 재업로드 하나뿐이다.** 요청은 보냈다(2026-10-02).
> 저장된 9/30·10/1 행은 마이그레이션 이전 것이라 NULL이고, 조회에서 `full`로
> 환산되어 나간다 — 즉 FDXF가 아직 `probability 0.5 + full`이다. 재업로드가
> 들어와야 `limited`로 바뀐다.
>
> 서버 운영 절차(접속·배포·마이그레이션 실행법, 밟았던 함정)는
> `docs/server/AWS_SERVER_OPERATIONS.md`에 따로 정리했다.

---

## 1. 현황 확인 결과

```
analytics.ticker_scores 컬럼
  ticker         character varying
  date           date
  score          double precision
  signal         character varying
  calculated_at  timestamp without time zone

최신일 2026-10-01 · 총 215,314행
```

**`data_quality` 관련 컬럼이 하나도 없다.** 맥미니 추정대로 서버가 200으로
받고 **버리고 있다.**

스키마상으로도 확인된다 — `ExtendedItemIngest`(schemas.py:732)에
`data_quality` 필드가 없고, Pydantic 기본 설정은 모르는 필드를 무시한다.

저장 로직은 `internal_ingest.py:374-396`에서 `TickerScore`를 upsert하는데
`score`·`signal`만 쓴다.

---

## 2. 적용된 변경

### ① DB 마이그레이션

```sql
-- analytics.ticker_scores에 data_quality 3컬럼 추가
-- NULL 허용: 과거 215,314행은 NULL로 남고, 조회에서 full로 환산한다.
ALTER TABLE analytics.ticker_scores
  ADD COLUMN IF NOT EXISTS analysis_mode VARCHAR(10),
  ADD COLUMN IF NOT EXISTS history_days  INTEGER,
  ADD COLUMN IF NOT EXISTS ai_available  BOOLEAN;

COMMENT ON COLUMN analytics.ticker_scores.analysis_mode IS
  'full | limited. NULL = 과거 데이터(= full로 간주)';
COMMENT ON COLUMN analytics.ticker_scores.history_days IS
  '분석에 쓴 거래일 수. limited 종목의 상장 경과일';
```

**컬럼 추가를 택한 이유**: JSON 컬럼도 가능하지만, S2(stale 판정)에서
`analysis_mode`로 필터링할 일이 생기고 조회 응답에 매번 들어가므로
인덱싱·질의가 쉬운 컬럼이 낫다. 3개뿐이라 폭도 문제없다.

### ② `app/models.py` — `TickerScore` (6~28행)

```python
     score = Column(Float, nullable=False)
     signal = Column(String(20))  # BUY, SELL, HOLD (supports Korean signals)
+
+    # data_quality (2026-10-01~). 맥미니가 item 최상위로 보낸다.
+    # NULL = 과거 데이터. 조회에서 full로 환산하므로 앱은 분기하지 않는다.
+    analysis_mode = Column(String(10))   # 'full' | 'limited'
+    history_days = Column(Integer)       # 분석에 쓴 거래일 수
+    ai_available = Column(Boolean)       # analysis_mode == 'full' 과 동일
+
     calculated_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))
```

`Integer`·`Boolean` import 확인 필요(이미 다른 모델이 쓰고 있으면 불필요).

### ③ `app/schemas.py` — 수신 스키마

`ExtendedItemIngest`(732행) 위에 추가:

```python
class DataQualityIngest(BaseModel):
    """
    분석 품질 메타 (맥미니 2026-10-01~).

    limited = 상장 40~119거래일인 신규상장·분사 종목. AI 예측이 빠지고
    기술지표·수급·애널리스트·뉴스만으로 점수를 낸다. probability가 0.5로
    고정되어 오므로, 앱이 그걸 "AI 50%"로 그리지 않게 하려면 이 필드가
    조회 응답까지 전달되어야 한다.
    """
    analysis_mode: Optional[str] = Field(None, description="full | limited")
    history_days: Optional[int] = Field(None, description="분석에 쓴 거래일 수")
    ai_available: Optional[bool] = Field(None, description="analysis_mode == 'full'")
```

`ExtendedItemIngest`에 필드 추가(759행 `classification` 다음):

```python
     classification: Optional[ClassificationData] = Field(None, description="Peter Lynch classification")
+    data_quality: Optional[DataQualityIngest] = Field(None, description="분석 품질 메타 (없으면 full로 간주)")
```

`SimpleItemIngest`에는 **넣지 않는다.** 맥미니는 extended 형식만 보낸다.

### ④ `app/routers/internal_ingest.py` — 저장 (374~396행)

```python
         # Process score (always present in both formats)
+        # data_quality는 extended 형식에만 있다. 없으면 full로 간주한다
+        # (맥미니 스펙: "필드가 없으면 full로 간주해 주세요").
+        dq = getattr(item, 'data_quality', None) if is_extended else None
+        analysis_mode = (dq.analysis_mode if dq and dq.analysis_mode else 'full')
+        history_days = dq.history_days if dq else None
+        ai_available = (
+            dq.ai_available if dq and dq.ai_available is not None
+            else analysis_mode == 'full'
+        )
+
         score_obj = (
             db.query(TickerScore)
             ...
         if score_obj:
             # Update existing score record
             score_obj.score = score_value
             score_obj.signal = signal
+            score_obj.analysis_mode = analysis_mode
+            score_obj.history_days = history_days
+            score_obj.ai_available = ai_available
         else:
             # Insert new score record
             score_obj = TickerScore(
                 ticker=ticker,
                 date=score_date,
                 score=score_value,
                 signal=signal,
+                analysis_mode=analysis_mode,
+                history_days=history_days,
+                ai_available=ai_available,
             )
```

### ⑤ 조회 응답 노출

조회 라우터(`routers/scores.py`·`tickers.py`·`charts`)에서 `TickerScore`를
내려주는 지점에 추가:

```python
"data_quality": {
    "analysis_mode": row.analysis_mode or "full",
    "history_days": row.history_days,
    "ai_available": row.ai_available if row.ai_available is not None else True,
}
```

**NULL을 여기서 `full`로 환산한다.** 맥미니 제안대로 앱이 분기하지 않아도
되고, 과거 215,314행을 백필할 필요도 없다.

**적용 결과** — `TickerScore`를 내려주는 경로를 전부 훑고 두 곳에 넣었다.

| 경로 | 조치 |
|---|---|
| `GET /api/v1/charts/{ticker}` | `data[]` 각 포인트에 `data_quality` (앱의 AI 블록이 읽는 곳) |
| `GET /api/v1/scores/{ticker}` | `scores[]` 각 항목에 `data_quality` |
| `/scores/top`·`/market/*` 목록 | **의도적으로 넣지 않음** |

NULL→`full` 환산은 **한 곳에만** 둔다 — 새로 만든
`app/utils/data_quality.py::data_quality_dict()`. 읽기 경로가 늘어도 환산
규칙이 갈라지지 않게 하려는 것이고, S2(stale 판정)도 이걸 쓴다.

목록 엔드포인트를 뺀 이유: 그 응답들은 `score`·`signal`만 보여주고
`ai_probability`를 안 내려준다. 즉 **거짓 AI 숫자가 생길 자리가 없다.**
각 응답 스키마에 필드를 더하고 네 군데 쿼리의 select 목록을 바꾸는 비용에
비해 지금 얻는 게 없다. S2에서 `analysis_mode`로 필터링할 때 함께 넣는다.

`TickerScoreResponse`는 `from_attributes`로 ORM을 그대로 받는데,
`data_quality`는 플랫 컬럼 3개에서 **조립해야 하는 중첩 객체**라
자동 매핑이 안 된다. 그래서 `scores.py`에서 dict를 명시적으로 만든다.

---

## 3. 검증 절차

1. 마이그레이션 적용 → 컬럼 3개 생성 확인
2. 서비스 재시작 (`sudo systemctl restart fastapi-analytics`)
3. 맥미니에 재업로드 요청 (9/30·10/1분, 즉시 전송 가능하다고 회신받음)
4. 확인 질의:

```sql
SELECT ticker, date, analysis_mode, history_days, ai_available
FROM analytics.ticker_scores
WHERE date = (SELECT MAX(date) FROM analytics.ticker_scores)
  AND ticker IN ('FDXF','HONA','SPCX','AAPL');
```

기대: FDXF·HONA·SPCX = `limited`, AAPL = `full`

5. 조회 API 확인:
```
GET https://hypehere.net/api/v1/tickers/FDXF   → data_quality.analysis_mode == "limited"
GET https://hypehere.net/api/v1/tickers/AAPL   → "full"
```

6. 앱 쪽 후속: `lib/utils/limited_analysis.dart`(임시 접두사 판별)를
   **통째로 삭제**하고 `analysis_mode == 'limited'`로 교체.

---

## 4. 롤백

```sql
ALTER TABLE analytics.ticker_scores
  DROP COLUMN IF EXISTS analysis_mode,
  DROP COLUMN IF EXISTS history_days,
  DROP COLUMN IF EXISTS ai_available;
```

코드는 수정 전 백업(`_<파일>.bak.<timestamp>`)으로 되돌린다.

---

## 5. 별건 — 이 서버는 git 저장소가 아니다 (일부 해소)

> 2026-10-02: 서버 소스를 `server/fastapi_analytics/`로 떠와 커밋했다(`6c19c26`).
> 레포에 정본 비교 대상이 생겼으므로 패치 전 해시 비교가 가능해졌다.
> 다만 **서버 자체는 여전히 git이 아니다** — 아래 내용은 그대로 유효하다.

```
$ git -C /home/django/fastapi_analytics remote -v
→ git 저장소 아님
```

`app/` 에 수동 백업이 **9개** 쌓여 있다
(`_schemas.py.bak.20260628_165435` 등, 일부는 `root` 소유라 django가 못 지움).
롤백 수단이 백업 파일뿐이라 생긴 결과다.

이번 작업과 별개로 **한 번은 git에 올려야 한다.** 올려두면 패치 적용이
`git apply` + `git revert`로 끝나고, 지금처럼 "어느 백업이 어느 시점인지"를
파일명으로 추적할 필요가 없다.

---

## 6. 적용 기록 (2026-10-02)

| 단계 | 결과 |
|---|---|
| 백업 | `app/_models.py.bak.20261002`, `_schemas.py.bak.20261002`, `app/routers/_internal_ingest.py.bak.20261002` |
| 마이그레이션 | 컬럼 3개 생성 확인 (`analysis_mode`/`history_days`/`ai_available`, 전부 nullable) |
| 코드 | `models.py` · `schemas.py` · `routers/internal_ingest.py` · `routers/charts.py` · `routers/scores.py` + 신규 `utils/data_quality.py` |
| 배포 | rsync → `systemctl restart fastapi-analytics` → `is-active=active`, `/health` 200 |
| 조회 검증 | `scores/AAPL`·`scores/FDXF`·`charts/FDXF` 모두 `data_quality` 포함, NULL→`full` 환산 동작 |
| 맥미니 요청 | 9/30·10/1 재업로드 요청 전송 |

### 마이그레이션 실행 시 밟은 함정 두 개

1. **psql에 URL을 그대로 못 준다.**
   `psql: error: extra key/value separator "=" in URI query parameter: "options"`
   — `DATABASE_ANALYTICS_URL`의 `options=` 파라미터를 psql URI 파서가 거부한다.
   SQLAlchemy 엔진(`app.database.engine`)으로 우회했다.
2. **`cd`만으로는 `app` 모듈을 못 찾는다.**
   스크립트가 `/tmp`에 있으면 `sys.path[0]`이 `/tmp`다.
   `PYTHONPATH=/home/django/fastapi_analytics`를 명시해야 한다.

둘 다 `docs/server/AWS_SERVER_OPERATIONS.md` §3에 절차로 옮겨 적었다.

### 남은 앱 작업 (재업로드 확인 후)

`lib/utils/limited_analysis.dart`를 **통째로 삭제**하고
`analysis_mode == 'limited'`로 교체한다. `test/limited_analysis_test.dart`의
`limited 임시 판별` 그룹도 같이 지우고, 팩 문자열 그룹은 남긴다.
