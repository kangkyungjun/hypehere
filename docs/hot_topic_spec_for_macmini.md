# Hot Topic 뉴스 인제스트 스펙 (맥미니 개발용)

## 요약

기존 뉴스 인제스트 API에 **3개 필드**가 추가됩니다.
모두 Optional이라 기존 코드 수정 없이 하위호환됩니다.
Hot topic으로 마킹된 뉴스는 Flutter 앱 상단에 **긴급 토스트**로 표시됩니다.

---

## API 변경사항

### 엔드포인트 (기존과 동일)
```
POST /api/v1/internal/ingest/news
```

### 페이로드 예시

```json
{
  "items": [
    {
      "date": "2026-04-08",
      "ticker": "MARKET",
      "title": "트럼프, 중국에 50% 관세 부과 발표|||Trump Announces 50% Tariffs on China|||特朗普宣布对中国加征50%关税|||トランプ、中国に50%関税を発表|||Trump anuncia aranceles del 50% a China",
      "source": "Reuters",
      "source_url": "https://reuters.com/...",
      "published_at": "2026-04-08T14:30:00Z",
      "ai_summary": "글로벌 무역전쟁 심화 우려가 커지고 있습니다|||Global trade war fears intensify|||全球贸易战担忧加剧|||グローバル貿易戦争の懸念が強まる|||Aumentan los temores de guerra comercial global",
      "sentiment_score": -85,
      "sentiment_grade": "bearish",
      "sentiment_label": "매우 부정적|||Very Negative|||非常负面|||非常にネガティブ|||Muy Negativo",
      "is_breaking": true,

      "is_hot_topic": true,
      "hot_topic_category": "TRADE_WAR",
      "hot_topic_priority": 1
    }
  ]
}
```

### 새 필드 3개

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `is_hot_topic` | `bool` | `false` | Hot topic 여부 |
| `hot_topic_category` | `string` (max 30) | `null` | 아래 카테고리 중 하나 |
| `hot_topic_priority` | `int` (1-3) | `null` | 1=긴급, 2=높음, 3=보통 |

**세 필드 모두 Optional입니다.** 보내지 않으면 기본값 적용.

---

## Hot Topic 카테고리

| 카테고리 | 설명 | 예시 | 기본 priority |
|----------|------|------|:---:|
| `GLOBAL_CRISIS` | 금융위기, 은행 붕괴, 국가 채무위기 | 실리콘밸리은행 파산 | 1 |
| `GEOPOLITICAL` | 전쟁, 군사충돌, 국제제재 | 러시아-우크라이나, 중동 긴장 | 1 |
| `TRADE_WAR` | 관세 부과, 무역제한, 엠바고 | 트럼프 중국 관세 50% | 1 |
| `FED_EMERGENCY` | 긴급 금리 결정, 비정기 QE 발표 | 긴급 FOMC 금리 인하 | 1 |
| `MARKET_CRASH` | 서킷브레이커, 주요 지수 -5% 이상 | S&P 500 -7% 서킷브레이커 | 1 |
| `REGULATORY` | 대형 규제 변경, 반독점 조치 | 구글 반독점 판결 | 2 |
| `EARNINGS_SHOCK` | 대형주 실적 서프라이즈 (>20% 괴리) | 엔비디아 실적 50% 상회 | 2 |
| `SECTOR_SHIFT` | 대형 섹터 로테이션 이벤트 | AI 버블 붕괴 우려 | 3 |

---

## 탐지 규칙 (맥미니에서 구현)

### `is_hot_topic = true` 조건 (OR)

1. **속보 + 강한 감성**: `is_breaking == true AND abs(sentiment_score) > 70`
2. **키워드 탐지** (title 또는 ai_summary에서):
   - 영어: `war`, `tariff`, `crisis`, `crash`, `emergency`, `sanctions`, `collapse`, `circuit breaker`
   - 한국어: `전쟁`, `관세`, `위기`, `폭락`, `긴급`, `제재`, `붕괴`, `서킷브레이커`
3. **동시다발 보도**: 동일 이벤트에 대해 1시간 내 3개 이상 다른 소스에서 보도
4. **시장 전체 영향**: `ticker == "MARKET" AND abs(sentiment_score) > 80`

### Priority 배정 규칙

```python
def assign_priority(category, sentiment_score):
    abs_score = abs(sentiment_score)

    # Priority 1 (긴급): 극단적 감성 또는 최고위험 카테고리
    if abs_score >= 80:
        return 1
    if category in ('GLOBAL_CRISIS', 'GEOPOLITICAL', 'MARKET_CRASH', 'FED_EMERGENCY', 'TRADE_WAR'):
        return 1

    # Priority 2 (높음): 중간 감성 또는 주요 카테고리
    if abs_score >= 60:
        return 2
    if category in ('REGULATORY', 'EARNINGS_SHOCK'):
        return 2

    # Priority 3 (보통): 나머지
    return 3
```

### Category 배정 로직 (참고용)

```python
def detect_category(title, ai_summary, ticker, sentiment_score):
    text = f"{title} {ai_summary}".lower()

    # 키워드 기반 매칭 (우선순위 순)
    if any(kw in text for kw in ['circuit breaker', '서킷브레이커', 'market crash', '폭락']):
        return 'MARKET_CRASH'
    if any(kw in text for kw in ['war', '전쟁', 'military', '군사', 'invasion', '침공']):
        return 'GEOPOLITICAL'
    if any(kw in text for kw in ['tariff', '관세', 'trade war', '무역전쟁', 'embargo', '엠바고']):
        return 'TRADE_WAR'
    if any(kw in text for kw in ['emergency rate', '긴급 금리', 'emergency fed', 'qe']):
        return 'FED_EMERGENCY'
    if any(kw in text for kw in ['bank collapse', '은행 붕괴', 'debt crisis', '채무위기', 'financial crisis', '금융위기']):
        return 'GLOBAL_CRISIS'
    if any(kw in text for kw in ['antitrust', '반독점', 'regulation', '규제']):
        return 'REGULATORY'
    if any(kw in text for kw in ['earnings shock', '실적 서프라이즈', 'beat estimates', 'miss estimates']):
        return 'EARNINGS_SHOCK'
    if any(kw in text for kw in ['sector rotation', '섹터 로테이션']):
        return 'SECTOR_SHIFT'

    return None  # hot topic 아님
```

---

## Flutter 표시 방식

- 앱 뉴스 탭 상단에 **반투명 토스트 오버레이**로 표시
- Priority 1이 가장 위에 표시, 최신순 정렬
- 유저가 X 버튼으로 dismiss 가능 (세션 내)
- 탭하면 뉴스 상세 모달 표시
- 여러 건이면 최상위 1건 + "+N 더보기" 표시
- **hot topic이어도 일반 뉴스 목록에 정상 표시됨** (중복 아님, 토스트는 별도 API)

---

## 서버 API (참고)

맥미니가 직접 호출하는 것은 아니지만, 서버에 새 엔드포인트가 추가되었습니다:

```
GET /api/v1/news/hot-topics?limit=5
```
- `is_hot_topic=true`, 최근 48시간 이내
- `priority ASC → published_at DESC` 정렬
- Flutter가 직접 호출

---

## 테스트 방법

Hot topic 테스트 데이터를 보내서 확인:

```bash
curl -X POST http://43.201.45.60:8001/api/v1/internal/ingest/news \
  -H "X-API-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [{
      "date": "2026-04-08",
      "ticker": "MARKET",
      "title": "[TEST] 트럼프 중국 50% 관세|||[TEST] Trump 50% Tariffs on China|||[TEST]|||[TEST]|||[TEST]",
      "source": "Test",
      "published_at": "2026-04-08T14:30:00Z",
      "ai_summary": "테스트 핫토픽입니다|||Test hot topic|||测试|||テスト|||Prueba",
      "sentiment_score": -85,
      "sentiment_grade": "bearish",
      "sentiment_label": "매우 부정적|||Very Negative|||非常负面|||非常にネガティブ|||Muy Negativo",
      "is_breaking": true,
      "is_hot_topic": true,
      "hot_topic_category": "TRADE_WAR",
      "hot_topic_priority": 1
    }]
  }'
```

서버에서 확인:
```bash
curl http://43.201.45.60:8001/api/v1/news/hot-topics?limit=5
```

---

## 일정

- **서버**: 이미 배포 완료 (3개 필드 추가됨, 하위호환)
- **Flutter**: 이미 구현 완료 (토스트 + 필터)
- **맥미니**: 위 탐지 규칙 구현 후 기존 뉴스 인제스트에 3개 필드 추가해서 보내면 됨

기존에 `is_hot_topic` 없이 보내도 정상 동작합니다 (기본값 `false`).
