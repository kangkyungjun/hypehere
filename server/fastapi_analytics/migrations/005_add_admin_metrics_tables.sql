-- 어드민 대시보드: 광고수익(AdMob) / 설치(installs) 일자 지표 테이블.
-- 맥미니 admin_collector 가 /internal/ingest/admin-metrics 로 밀어넣는 데이터의 저장소.
-- analytics 스키마. 비파괴 — 신규 테이블만. 실행: python run_migration.py 005_add_admin_metrics_tables.sql
--
-- 소유: 이 두 테이블은 ingest(맥미니→서버) 단독 소유. admin_user_snapshot(활성지표)과 분리.
-- summary 응답은 조회 시 JOIN으로 합침. TZ 경계는 대시보드 전체와 동일(KST, 수집기·롤업 일치).

CREATE TABLE IF NOT EXISTS analytics.admin_admob_daily (
    date             date NOT NULL,
    app_platform     text NOT NULL,        -- 'ios' | 'android'
    ad_unit          text NOT NULL,
    revenue_usd      double precision,
    impressions      bigint,
    clicks           bigint,
    ad_requests      bigint,
    matched_requests bigint,
    ecpm             double precision,
    PRIMARY KEY (date, app_platform, ad_unit)
);

CREATE TABLE IF NOT EXISTS analytics.admin_install_daily (
    date           date NOT NULL,
    platform       text NOT NULL,          -- 'ios' | 'android'
    installs       bigint,
    uninstalls     bigint,
    active_devices bigint,
    PRIMARY KEY (date, platform)
);
