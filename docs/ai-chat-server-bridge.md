# AI 멀티턴 채팅 — 서버 브리지 스펙 (서버 개발자용)

> 대상: analytics 서버(`API_BASE_URL` = `https://www.hypehere.net`) 개발자
> 작성 근거: Flutter 앱 실제 코드(`lib/services/chat_api_client.dart`, `lib/providers/chat_provider.dart`) + 맥미니 CHAT 분기 계약
> 상태(2026-06-12): **앱·맥미니 완료. 이 브리지만 미배포** — 현재 `/api/v1/chat/*` 호출 시 404.
> 후속(선택): 첫 응답 지연 최적화 = [`ai-chat-longpoll-spec.md`](./ai-chat-longpoll-spec.md) (Phase B, 이 문서 배포 후).

## 0. 한눈에

앱과 맥미니는 둘 다 끝났습니다. 서버는 **공개 chat API 2~3개를, 맥미니가 이미 쓰는 내부 큐(`analysis-queue` + `ai-messages`)로 중계(bridge)** 만 하면 됩니다. **새 큐·새 인프라 불필요** — 포트폴리오 자문이 매일 쓰는 검증된 채널에 올라타기만 하면 됩니다.

```
[앱]  POST /api/v1/chat/messages                       ← ✅ 완성
      GET  /api/v1/chat/conversations/{id}/messages    ← ✅ 완성 (폴링)
      GET  /api/v1/chat/conversations                  ← ✅ 완성 (목록)
        ↕  ❌ 여기 서버 브리지가 없음 (현재 404)
[서버] (a)대화 저장소  (b)공개 chat 2~3엔드포인트  (c)CHAT을 analysis-queue로 enqueue  (d)ai-messages type=chat 저장
        ↕  ✅ analysis-queue + ai-messages 내부 채널은 포트폴리오 자문이 매일 사용 중(검증됨)
[맥미니] GET /internal/ingest/analysis-queue?status=PENDING  ← ✅ CHAT 분기 완성
        POST /internal/ingest/ai-messages (type=chat)        ← ✅ 완성
```

신규 작업 = **(a) 대화 저장소 테이블 · (b) 공개 chat 엔드포인트 · (c) chat→analysis-queue enqueue · (d) ai-messages의 type=chat 저장.** 큐·complete 마킹·인증은 포트폴리오에서 쓰던 것 **재사용**.

---

## 1. 인증

모든 `/api/v1/chat/*` 는 **Django Token** 인증입니다 (포트폴리오 자문과 동일).

```
Authorization: Token <token>
Content-Type: application/json
```

근거: `chat_api_client.dart` — `'Authorization': 'Token $token'`, 토큰은 `AuthService.getAccessToken()`.

---

## 2. 공개 엔드포인트 (앱 → 서버)

### ① POST `/api/v1/chat/messages`  — 사용자 메시지 전송

**요청 body (앱이 보내는 정확한 키. 그대로 받을 것):**
```json
{
  "conversation_id": "c_1a2b3c...",
  "message": "그럼 언제 팔아?",
  "lang": "ko"
}
```
- `message` 입니다. `content`/`text` 아님 — **키명 일치 필수.**
- `conversation_id` 는 **앱이 생성**해 보냅니다(§4). 서버는 발급하지 말고 그대로 정본 저장.
- `lang` 는 앱 UI 언어코드(`ko`/`en`/`ja`/`zh`/`es`).

**서버가 할 일:**
1. user 메시지를 대화 저장소(정본)에 append.
2. 맥미니가 폴링하는 기존 `analysis-queue`에 enqueue (§3 형식).
3. 즉시 **202** 반환 — 맥미니 응답 기다리지 말 것.

**응답:** `200`/`201`/`202` 아무거나 OK (앱은 셋 다 수락). body 불필요.
근거: `chat_api_client.dart` — `statusCode != 200 && != 201 && != 202` 일 때만 에러 처리.

### ② GET `/api/v1/chat/conversations/{id}/messages`  — 대화 이력 (폴링/과거조회)

앱은 ① 전송 후 이 엔드포인트를 **백오프 폴링**하다가 assistant 턴이 늘면 화면에 반영합니다.

**응답 (둘 다 파싱 가능, 위 권장):**
```json
{ "messages": [
  { "role": "user",      "content": "그럼 언제 팔아?",            "turn_index": 1, "created_at": "2026-06-12T09:00:00Z" },
  { "role": "assistant", "content": "타깃가 도달 시 분할 매도를...", "turn_index": 2, "created_at": "2026-06-12T09:00:14Z" }
]}
```
- 최상위가 `{"messages":[...]}` 또는 **bare 배열** 둘 다 허용. (`body is Map ? body['messages'] : body`)
- 메시지 객체 키: `role`("user"|"assistant", 필수), `content`(필수), `turn_index`(int, nullable), `created_at`(ISO8601, nullable).
- 메시지 `id` 는 **앱 모델에 없음** — 추가는 선택사항.

> ⚠️ **서버 주의 2건 (반드시 지킬 것):**
> 1. **user턴 + assistant턴 모두** 반환할 것. user턴을 빠뜨리면 화면에서 사라집니다(앱이 서버 리스트로 통째 교체하므로 — §4).
> 2. **시간순(오름차순) 정렬**해 반환할 것. 앱은 받은 순서대로 그리며 **재정렬하지 않습니다**(`ai_chat_screen.dart`).

### ③ GET `/api/v1/chat/conversations`  — 대화 목록

```json
{ "conversations": [
  { "conversation_id": "c_...", "title": "애플 분석", "last_message": "...", "updated_at": "2026-06-12T09:00:14Z" },
  { "conversation_id": "c_...", "last_message": "테슬라?" }
]}
```
- 키: `conversation_id`(또는 `id`), `title`(nullable), `last_message`(nullable), `updated_at`(nullable).
- 실패해도 앱은 조용히 무시(채팅 흐름 안 막음). 우선순위 낮음 — ①②부터 구현 가능.

---

## 3. 내부 큐 중계 (서버 → 맥미니, 기존 analysis-queue 재사용)

POST ① 처리 시, 받은 메시지를 아래 형식으로 `analysis-queue`에 enqueue:

```json
{
  "user_id": "U123",
  "request_type": "CHAT",
  "trigger_data": { "conversation_id": "c_...", "message": "그럼 언제 팔아?", "lang": "ko" }
}
```
- 맥미니 CHAT 분기가 `trigger_data.{conversation_id, message, lang}` **3필드를 정확히 이 이름으로** 읽습니다. ①의 앱 body와 동일한 키이므로 그대로 옮겨 담으면 됩니다.

---

## 4. 맥미니 응답 수신 (맥미니 → 서버, 기존 ai-messages 재사용)

맥미니가 답을 만들면 기존 `POST /internal/ingest/ai-messages` 로 보냅니다. **`type == "chat"`** 이면 assistant 메시지를 대화 저장소에 append:

```json
{ "items": [{
  "type": "chat",
  "user_id": "U123",
  "conversation_id": "c_...",
  "date": "2026-06-12",
  "turn_index": 3,
  "model_used": "gpt-4o",
  "messages": [{ "role": "assistant", "content": "타깃가 도달 시 분할 매도를 권합니다..." }]
}]}
```
- 이어서 맥미니가 `POST .../analysis-queue/{id}/complete` 도 호출합니다(포트폴리오와 동일).

---

## 5. conversation_id / 중복 / 정본 (SoT)

- **정본(SoT) = 서버.** 앱은 폴링으로 받은 서버 리스트로 로컬을 **통째 교체**합니다(append 아님).
- 따라서 GET ②가 user 메시지를 다시 내려줘도 **중복 안 생김** — 서버는 dedupe 신경 쓸 필요 없음. 단 §2의 "user턴 포함 + 시간순"만 지킬 것.
- `conversation_id` = **앱 생성**(`c_<microsecondHex><8 random hex>`). 서버는 그대로 저장.

근거: `chat_provider.dart` — 폴링 성공 시 `_messages = server`, id `c_...` 생성기.

---

## 6. 에러 매핑 (앱이 기대하는 상태코드)

| 상황 | 서버 응답 | 앱 동작 |
|---|---|---|
| 정상 전송 | 202 | 폴링 시작 |
| 정상 이력 | 200 | 화면 반영 |
| 미인증/만료 | **401** | `sessionExpired` → 재로그인 유도 |
| 기타 실패 | 4xx/5xx | `aiChatErrorRetry` 안내 띠 |
| **미배포(현재)** | **404** | 에러 띠("응답 못 받음") — 크래시 없이 graceful |

앱은 미배포 상태에서도 크래시 없이 안내만 띄웁니다. 서버가 올라오면 **앱 코드 수정 없이** 즉시 동작합니다.

---

## 7. 알려진 지연 (latency)

서버 배포 후 동작하나 응답이 **~12~15초** 걸립니다(맥미니 큐 폴링 ~10s + GPT 2~4s). 앱 폴링 타임아웃(~50s) 안이라 기능엔 문제 없으나 체감이 느립니다. 맥미니 **Phase B(폴링 단축/우선순위)** 에서 개선 예정. Phase A 목표는 "느리지만 정확히 동작".

---

## 8. 서버 체크리스트

- [ ] 대화 저장소 테이블 (conversation_id PK 아님 — 앱 생성값 저장, user별)
- [ ] `POST /api/v1/chat/messages` — user append + analysis-queue enqueue(`request_type:"CHAT"`) + 202
- [ ] `GET /api/v1/chat/conversations/{id}/messages` — user+assistant 시간순 반환
- [ ] `GET /api/v1/chat/conversations` — 목록 (후순위)
- [ ] `ai-messages` 핸들러에 `type=="chat"` 분기 — assistant append
- [ ] 인증: Django Token 재사용
- [ ] 배포 후 앱에서 실제 1턴 왕복 확인
