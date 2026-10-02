-- 경영·운영 관리 기록 (Master 전용). 재무/계획/메모를 한 테이블에.
-- analytics 스키마. 비파괴 — 신규 테이블만. 실행: python run_migration.py 007_add_management_records.sql
--
-- kind: finance(재무) | plan(계획) | note(메모) | asset(자산·물품 구매)
-- category: (finance)지출·수익·배당 / (plan·note)경영·운영·개발 / (asset)비품·소모품·장비·SW·기타
-- 금액은 KRW 기본. P&L 요약은 finance + direction(in/out)으로 집계.
--
-- 자산(kind='asset') 등록번호 규칙: {유형}-{구매연도}-{일련번호4자리}
--   유형 = AST(고정자산: 비품·장비 등) / SUP(소모품), asset_type 으로 결정
--   일련번호 = 해당 (유형, 연도) 내 순번 (서버 생성), 예: AST-2026-0001, SUP-2026-0003

CREATE TABLE IF NOT EXISTS analytics.management_records (
    id          BIGSERIAL PRIMARY KEY,
    kind        VARCHAR(16) NOT NULL,        -- finance | plan | note | asset
    category    VARCHAR(32) NOT NULL,
    title       TEXT NOT NULL,               -- 품명/제목
    content     TEXT,
    amount      NUMERIC(16,2),              -- finance 금액 / asset 구매가
    currency    VARCHAR(8) DEFAULT 'KRW',
    direction   VARCHAR(8),                  -- in(수익·배당) | out(지출·구매)
    occurred_on DATE,                        -- 발생일 / 계획 마감일 / 구매일
    status      VARCHAR(16),                 -- planned|in_progress|done|pending|paid|in_use|disposed
    recurring   VARCHAR(16) DEFAULT 'none',  -- none|monthly|yearly
    -- 자산(asset) 전용
    asset_no    VARCHAR(32),                 -- 등록번호 (서버 자동생성)
    asset_type  VARCHAR(16),                 -- fixed(고정자산) | consumable(소모품)
    quantity    INTEGER,                     -- 수량
    vendor      VARCHAR(128),                -- 구매처
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE, -- 소프트삭제(휴지통·증분백업 삭제전파)
    created_by  INTEGER,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_mgmt_category ON analytics.management_records (category);
CREATE INDEX IF NOT EXISTS ix_mgmt_occurred ON analytics.management_records (occurred_on DESC);
-- 증분 백업(맥미니): updated_at > since 만 전송하기 위한 인덱스
CREATE INDEX IF NOT EXISTS ix_mgmt_updated ON analytics.management_records (updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS ux_mgmt_asset_no
    ON analytics.management_records (asset_no) WHERE asset_no IS NOT NULL;
