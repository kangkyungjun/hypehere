# 매크로/지정학 뉴스 수집 확대 — 맥미니 개발 요청서

**작성일**: 2026-04-09
**요청자**: MarketLens Flutter/FastAPI 팀
**대상**: 맥미니 데이터 수집 담당 개발자

---

## 1. 배경 및 문제

현재 맥미니 뉴스 수집 파이프라인은 **종목(ticker) 중심**으로 설계되어 있어, 지정학적 이벤트(예: 이란-미국 휴전, 중국 관세 변동)나 매크로 경제 이슈(예: 금리 결정, 유가 급등)가 수집되지 않거나 누락됩니다.

### 현재 구조
```
맥미니 수집 → 종목별 뉴스 분류 → FastAPI ingest (ticker 필수) → Flutter 표시
```

### 문제점
- `analytics.news` 테이블의 `ticker` 컬럼이 NOT NULL → 종목 없는 뉴스 저장 불가
- 지정학/매크로 뉴스는 특정 종목에 매핑하기 어려움
- 사용자가 "이란-미국 휴전" 같은 글로벌 뉴스를 앱에서 볼 수 없음
- `is_breaking`, `is_hot_topic` 분류가 종목 뉴스에만 적용됨

---

## 2. 요청 사항

### 2-1. 특수 티커 도입

매크로/지정학 뉴스용 가상 티커를 정의하여 기존 파이프라인에 통합:

| 가상 티커 | 용도 | 예시 |
|-----------|------|------|
| `$MACRO` | 거시경제 전반 | 금리 결정, GDP, 고용지표 |
| `$GEO` | 지정학/국제정치 | 전쟁, 휴전, 제재, 외교 |
| `$FED` | 연준/중앙은행 | FOMC, 양적긴축, 금리 발언 |
| `$OIL` | 원자재/에너지 | 유가 급등, OPEC 결정 |
| `$TRADE` | 무역/관세 | 관세 부과, 무역 협정 |

> `$` 접두사를 사용하여 일반 종목 티커와 구분

### 2-2. 뉴스 소스 확장

현재 종목 중심 소스 외에 아래 카테고리를 커버하는 소스 추가:

- **지정학**: Reuters World, AP News International, Al Jazeera
- **매크로 경제**: Fed 공식 사이트, BLS (고용), BEA (GDP)
- **원자재**: EIA (에너지), OPEC 발표
- **무역**: USTR, 주요국 관세 관련 뉴스

### 2-3. 자동 분류 규칙 강화

수집된 매크로/지정학 뉴스에 대해:

```python
# is_breaking 자동 판정 기준 (예시)
BREAKING_KEYWORDS = [
    "ceasefire", "war", "invasion", "sanctions", "emergency",
    "rate cut", "rate hike", "default", "crash", "collapse",
    "휴전", "전쟁", "제재", "긴급", "금리인하", "금리인상", "폭락"
]

# is_hot_topic 자동 판정
HOT_TOPIC_CATEGORIES = {
    "GEOPOLITICAL": ["war", "ceasefire", "sanctions", "treaty", ...],
    "GLOBAL_CRISIS": ["pandemic", "default", "crash", ...],
    "FED_EMERGENCY": ["rate", "FOMC", "QE", "QT", ...],
    "TRADE_WAR": ["tariff", "trade war", "embargo", ...],
}

# hot_topic_priority 기준
# 1 = CRITICAL (전쟁/휴전, 금융위기)
# 2 = HIGH (금리 결정, 주요 제재)
# 3 = MEDIUM (무역 협상, 경제지표)
```

### 2-4. ingest 페이로드 형식

기존 뉴스 ingest 엔드포인트(`POST /api/v1/internal/ingest/news`)를 그대로 사용:

```json
{
  "items": [
    {
      "date": "2026-04-09",
      "ticker": "$GEO",
      "title": "Iran, US agree to ceasefire in nuclear talks",
      "source": "Reuters",
      "source_url": "https://...",
      "published_at": "2026-04-09T14:30:00Z",
      "ai_summary": "ko:이란과 미국이 핵 협상에서 휴전에 합의함...|en:Iran and US agreed...",
      "sentiment_grade": "B",
      "sentiment_label": "positive",
      "is_breaking": true,
      "is_hot_topic": true,
      "hot_topic_category": "GEOPOLITICAL",
      "hot_topic_priority": 1,
      "sector": null
    }
  ]
}
```

> **주의**: `ai_summary`는 기존과 동일하게 `ko:|en:|ja:|zh:|es:` 다국어 packed 형식 사용

---

## 3. FastAPI 측 대응 (이미 준비됨 / 준비 예정)

맥미니에서 위 형식으로 ingest하면 서버 측에서 처리할 항목:

| 항목 | 상태 | 비고 |
|------|------|------|
| `$` 접두사 티커 저장 | **스키마 변경 필요** | ticker 유효성 검사에 `$` 허용 추가 |
| `is_breaking` FCM 발송 | 기존 동작 | `process_breaking_news_notification()` 자동 호출 |
| `is_hot_topic` 표시 | 기존 동작 | `/hot-topics` API에 자동 포함 |
| Flutter `$` 티커 뉴스 표시 | **UI 수정 필요** | 매크로 뉴스 전용 아이콘/스타일 적용 예정 |

---

## 4. 수집 주기 권장

| 카테고리 | 주기 | 근거 |
|----------|------|------|
| 지정학 (전쟁/휴전) | **5분** | 속보성 높음, 시장 즉시 반응 |
| 연준/금리 | **10분** | FOMC 발표 시 집중, 평시 여유 |
| 매크로 지표 | **30분** | 예정된 발표 시간 위주 |
| 무역/관세 | **15분** | 정책 변동 빈도 고려 |

---

## 5. 우선순위

1. **즉시**: `$GEO` 지정학 뉴스 수집 (이란-미국 등 현재 이슈)
2. **단기**: `$FED`, `$MACRO` 경제 이벤트 수집
3. **중기**: `$OIL`, `$TRADE` 원자재/무역 뉴스 수집

---

## 6. 확인 필요 사항

맥미니 개발자에게 확인 요청:

- [ ] 현재 뉴스 소스 목록 및 수집 주기
- [ ] 지정학/매크로 뉴스 소스 추가 가능 여부
- [ ] `is_breaking` 자동 판정 로직 현재 구현 상태
- [ ] AI 요약 생성 시 다국어 packed 형식 적용 현황
- [ ] 예상 개발 기간 및 리소스

---

## 7. 연락처

- FastAPI 엔드포인트 문의: FastAPI/Flutter 팀
- 기존 ingest 스키마 참고: `fastapi_analytics/app/schemas.py` → `NewsIngestItem`
- FCM 발송 로직 참고: `fastapi_analytics/app/services/fcm_service.py` → `process_breaking_news_notification()`
