-- 자산 처분 이력 / 계획 체크리스트(서브태스크) 추가.
-- 둘 다 JSONB 배열, 기본값 []. 작성자·처리자 스냅샷(닉네임/유저ID)을 항목 안에 보관 →
-- Django와 cross-DB 조인 없이 단일 원장에서 그대로 표시.
--
-- disposal_history 항목 스키마(권장):
--   { "kind": "disposed"|"unused"|"status_change",
--     "date": "YYYY-MM-DD",
--     "reason": "…",
--     "from_status": "사용중", "to_status": "폐기",     (status_change 시)
--     "by_user_id": 12, "by_nickname": "홍길동",
--     "by_role": "master", "at": "ISO8601" }
--
-- sub_tasks 항목 스키마(권장):
--   { "id": 1, "title": "…",
--     "done": false, "assignee": "박관리" | null,
--     "created_by_id": 12, "created_by_nickname": "홍길동",
--     "created_at": "ISO8601",
--     "done_by_id": 14, "done_by_nickname": "김매니",
--     "done_at": "ISO8601" | null }
-- 항목 id는 서버에서 부여(현재 배열 내 max(id)+1, 영구식별자).

ALTER TABLE analytics.management_records
    ADD COLUMN IF NOT EXISTS disposal_history JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE analytics.management_records
    ADD COLUMN IF NOT EXISTS sub_tasks JSONB NOT NULL DEFAULT '[]'::jsonb;
