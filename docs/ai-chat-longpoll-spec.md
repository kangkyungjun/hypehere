# AI 채팅 — Tier 2 Long-Poll 스펙 (Phase B / 최적화)

> 대상: Amazon 서버팀 (+ 맥미니팀 소규모 후속)
> 목적: 채팅 **첫 메시지 픽업 지연 ~5초 → ~0초** + 유휴 요청량 ~60% 감소
> 적용: 기존 `GET /api/v1/internal/ingest/analysis-queue` (맥미니가 이미 폴링 중)
> 선행조건: **Phase A(서버 브리지, `docs/ai-chat-server-bridge.md`) 배포 후** 진행. 없어도 채팅은 동작하며, 이건 체감속도 최적화임.

## 1. 목적 & 효과

현재 맥미니는 이 큐를 short-poll(유휴 10초)로 긁어가므로, 첫 메시지 픽업까지 최대 10초(평균 5초) 대기. Long-poll로 바꾸면:

| 항목 | 현재(short-poll) | Long-poll 후 |
|---|---|---|
| 첫 메시지 픽업 지연 | 평균 5초 (최대 10초) | ~0초 (요청 즉시 반환) |
| 유휴 시 요청량 | 6 GET/분 (24/7) | ~2.4 GET/분 (25초마다 1회) |
| 서버 부하 | 빈 응답 다수 | 커넥션 홀드(워커 1개 점유) |

## 2. 인터페이스 변경 (하위호환 / 비파괴)

**요청 — 쿼리 파라미터 `wait` 추가 (옵션):**
```
GET /api/v1/internal/ingest/analysis-queue?status=PENDING&wait=25
Header: X-API-Key: <기존 내부키>
```
- `wait` (정수, 초): 서버가 빈 큐일 때 최대 이만큼 커넥션을 홀드.
- `wait` 생략 또는 `0` → **현재와 100% 동일**(즉시 반환). ← 비파괴 핵심.

**응답 — 형식 변경 없음:**
```json
{ "items": [ { "id": "...", "user_id": "...", "request_type": "CHAT", "trigger_data": {} } ] }
```
- PENDING 있으면 즉시 반환. 없으면 `wait`초 홀드 후 빈 배열 `{"items": []}` 200 반환.

## 3. 서버 동작 알고리즘 (의사코드)

```
on GET analysis-queue?status=PENDING&wait=W:
    deadline = now + min(W, WAIT_MAX)            # WAIT_MAX=25 권장
    loop:
        items = query_pending(status=PENDING)    # 기존 쿼리 그대로
        if items:           return 200 {items}    # 즉시 반환
        if now >= deadline: return 200 {items:[]}  # 타임아웃 → 빈 응답
        wake = wait_for_enqueue_event(timeout=min(0.5~1s, deadline-now))
        # wake: 신규 enqueue 이벤트 or 짧은 sleep 후 재조회
```

**홀드 구현 2방식 (택1):**
- **(A) 이벤트 기반 (권장)**: `POST /chat/messages`가 enqueue할 때 이벤트 발행(asyncio.Event / Redis pub-sub / Postgres NOTIFY) → 홀드 중인 GET이 즉시 깨어남. 진짜 0초 지연.
- **(B) 내부 단축 폴 (간단)**: 홀드 동안 0.5~1초 간격으로 DB 재조회. 구현 쉬움, 지연 ≤1초(충분).

→ 처음엔 **(B)로 빠르게**, 여력되면 **(A)로 고도화** 권장.

## 4. ⚠️ 핵심 주의 2가지 (반드시 검토)

**① 워커 블로킹 — 어디에 구현하느냐가 중요**
- 커넥션을 25초 홀드하면 그 시간 워커 1개가 묶임.
- **FastAPI(async)에 구현 ✅** — `await`로 비동기 홀드, 스레드 안 묶임. **이 방식 강력 권장.**
- **Django 동기워커(gunicorn sync)에 구현 ❌ 위험** — 워커 1개가 25초 통째 점유. 맥미니 단일 폴러라 1개씩이지만, 안전하려면 async 워커(uvicorn/gevent) 또는 Django ASGI 필요.
- analysis-queue가 Django(내부 ingest) 영역이면, **long-poll 변형만 FastAPI(async)로 빼서 제공**하는 것이 가장 깔끔.

**② 리버스 프록시 / ALB idle timeout**
- AWS ALB 기본 idle timeout = 60초, nginx `proxy_read_timeout` 기본 = 60초.
- `wait`는 반드시 이보다 충분히 작아야 함(홀드 중 프록시가 끊으면 502/504). → **`wait=25`, 서버 `WAIT_MAX=25` 캡**(60초 한참 아래).

## 5. 튜닝 파라미터 (권장 기본값)

| 파라미터 | 값 | 의미 |
|---|---|---|
| `wait` (맥미니 요청) | 25s | 홀드 시간 |
| `WAIT_MAX` (서버 캡) | 25s | 클라가 큰 값 줘도 상한 |
| 내부 재조회 간격(B방식) | 0.5~1s | 지연 vs DB부하 |
| 동시 홀드 커넥션 상한 | 4~8 | 폭주 방지(맥미니는 보통 1) |

## 6. 하위호환 & 점진 도입

- `wait` 미지원 서버여도 맥미니는 현재 short-poll로 정상 동작(파라미터 무시).
- 서버가 `wait` 지원 배포 → 맥미니 측 1줄 변경(§7)만 하면 자동 전환. **순차 배포 가능, 동시성 불필요.**

## 7. 맥미니 측 변경 (서버 배포 후 적용 — 소규모)

`deep_bot_queue_poller.py`:
- `_fetch_pending_requests()`: URL에 `&wait=25` 추가 + `requests timeout=10 → 30` (wait보다 커야 함).
- `_poll_loop()`: long-poll 모드에선 GET 자체가 블로킹하므로 루프 끝 `time.sleep()`을 0~0.5초로 축소(즉시 재홀드). 적응형 코드와 양립 — long-poll on이면 sleep 사실상 생략.
- `USE_LONG_POLL = True`로 토글 가능하게.

## 8. 서버팀 체크리스트

- [ ] long-poll 변형을 **FastAPI(async)** 에 구현 (워커 블로킹 회피)
- [ ] `wait` 파라미터 파싱 + `WAIT_MAX=25` 캡
- [ ] 홀드 방식 (A)이벤트 or (B)0.5~1s 재조회 택1
- [ ] `wait=0`/생략 시 기존 즉시반환 보장 (비파괴)
- [ ] ALB/nginx idle timeout > wait 확인 (25 < 60 ✅)
- [ ] 동시 홀드 커넥션 상한 설정

---

**요약:** 기존 GET에 `wait=25` 하나 추가하는 비파괴 확장. 반드시 **FastAPI(async)에 구현**(Django 동기워커에 올리면 워커 점유). 효과는 첫 메시지 지연 ~5초→~0초 + 유휴 요청량 60% 감소. 맥미니는 서버 배포 후 **1줄 수정**으로 전환.

---
관련 문서: Phase A(필수) = [`ai-chat-server-bridge.md`](./ai-chat-server-bridge.md)
