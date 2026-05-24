# MarketLens UI/UX 개선 계획서

## 진단일: 2026-04-11
## 상태: 진행 중

---

## Phase 1: 디자인 시스템 구축 (기반 작업)

### 1-1. 색상 시스템 확장 — `theme/app_colors.dart`
- [ ] gainColor / lossColor / neutralColor 추가
- [ ] signalBuyColor / signalSellColor / signalHoldColor 추가
- [ ] textPrimary / textSecondary / textTertiary 추가
- [ ] 하드코딩된 Color(0xFF...) 전수 교체

### 1-2. 타이포그래피 상수 — `theme/app_typography.dart` (신규)
- [ ] displayLarge ~ labelSmall 정의
- [ ] 인라인 TextStyle → 상수 참조로 교체

### 1-3. 간격 시스템 — `theme/app_spacing.dart` (신규)
- [ ] xs(4) ~ xxl(32) 정의
- [ ] 매직넘버 → 상수 참조로 교체

### 1-4. 공통 위젯 추출 — `widgets/common/`
- [ ] SectionHeader
- [ ] TimelineItem
- [ ] ModalHandleBar
- [ ] ContentActionMenu
- [ ] EmptyStateView / ErrorStateView
- [ ] ShimmerLoading

---

## Phase 2: Cardless 디자인 전환

### 2-1. Dashboard + Holdings 카드 제거
- [ ] news_card → Divider 구분
- [ ] earnings_week_card → Divider 구분
- [ ] watchlist_discovery_card → Divider 구분
- [ ] portfolio_summary_card → Cardless
- [ ] portfolio_ai_card → Cardless
- [ ] tax_estimate_card → Cardless

### 2-2. Ticker Detail + News
- [ ] ticker_detail 섹션 컨테이너 제거
- [ ] company_profile_card → Cardless
- [ ] valuation_metrics → Cardless

---

## Phase 3: 시각 계층 강화 + 마이크로 인터랙션

### 3-1. 타이포그래피 계층 재설계
### 3-2. 여백과 호흡 개선
### 3-3. 마이크로 인터랙션 추가
### 3-4. 스켈레톤 로딩 도입

---

## Phase 4: 접근성 + 코드 품질

### 4-1. 접근성 개선
- [ ] TextScaler.linear(1.0) 제거
- [ ] 최소 폰트 10px
- [ ] Semantics 추가
- [ ] 최소 터치 영역 48dp

### 4-2. 코드 분할
- [ ] ticker_detail_screen.dart → 7개 파일
- [ ] treemap_chart_widget.dart → 3개 파일
- [ ] macro_banner_widget.dart → 3개 파일

### 4-3. 코드 중복 제거
### 4-4. 로컬라이제이션 수정
