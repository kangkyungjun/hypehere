# MarketLens UI/UX 레퍼런스 리디자인 — 통합 계획서

> 레퍼런스: **헤이딜러(중고차) 3화면 전부** — ① 상세+예상시세 **그래프** 화면(170706) ② ③ "비슷한 차 견적결과" 카드 리스트·확장형 키밸류(170712/170724).
> ⚠️ 정정(2026-08-26): 초기 버전이 **홈택스 접수증을 레퍼런스로 오인**했음. 홈택스는 레퍼런스 아님 — 관련 "영수증/제출내역 섹션헤더" DNA 전면 폐기. 정본은 위 헤이딜러 3장.
> **핵심 시그니처: 블루가 주인공** — 히어로 가격 숫자·차트 곡선·강조점·인라인 링크(수정)·CTA 버튼이 전부 블루.
> 목표: **눈이 편안하고 스캔이 쉬운** 차분한 화면. 5인 전문가(타이포·여백·색상·컴포넌트·인터랙션) 병렬 진단 → 통합.
> 작성: 2026-08-26. 상태: **계획(코드 미변경)**. 사용자와 재차 조율하며 진행.

---

## 0. 한 줄 요약 (가장 중요한 재프레이밍)

**레퍼런스 룩의 60%는 이미 우리 앱에 구현돼 있다.** `lib/main.dart`가 앱 전체 배경을 `groupedBackground`(#F4F5F7)로 깔고, `lib/widgets/common/bento_card.dart`가 이미 **"테두리 없이 부드러운 그림자로 카드를 띄우는(오늘의집 톤)"** 프리미티브를 제공한다. 즉 "회색 위에 흰 카드가 떠 있는" 레퍼런스 구조는 이미 기본값이다.

진짜 격차는 **디자인 방향이 아니라 일관성**이다:
1. **BentoCard 기본 패딩이 8px로 굶주려 있음** → 카드가 답답해 보이는 최대 원인.
2. **손수 만든 테두리 카드(`Border.all`) 11곳**이 BentoCard와 섞여 씀 → 낡고 무거운 느낌.
3. **같은 프리미티브가 화면마다 재구현**됨: 키밸류 5벌, 섹션헤더 3벌, 확장로직 4벌, 두 색 체계(`mlColors` vs `colorScheme`) 충돌.
4. **여백 어휘(`section`=28px 토큰)가 死코드** — 긴 화면 섹션 분리에 안 쓰임.

결론: **전역 여백 확대가 아니라 토큰화된 재배치.** 안 쓰는 마이크로 간격 몇 px를 카드 패딩·섹션 리듬으로 옮기고, 5개 재사용 컴포넌트로 굿 디폴트를 한 번만 인코딩하면 — 사용자의 "타이트 선호"와 레퍼런스의 "편안함"이 **충돌하지 않고 양립**한다. 편안함의 원천은 대부분 **위계(크기·굵기·색 대비)**이지 여백이 아니기 때문.

---

## 1. 밀도 전략 — #1 결정 포인트 (사용자 승인 필요)

메모리상 사용자는 **"여백 타이트 선호, 과한 whitespace 금지"**. 레퍼런스는 더 넉넉함. 이 긴장을 어떻게 풀지가 전체 계획의 방향타.

| 전략 | 내용 | 장점 | 단점 | 추천 |
|---|---|---|---|---|
| **A. 토큰화 밀도** | `xl`≠`lg` 분리, ~4토큰 재조정, `cardPad=18` 등 밀도 상수 도입. 편안함이 **토큰에** 담겨 BentoCard·SectionHeader 통해 자동 전파 | 한 번 수정→49개 카드 자동 반영, 되돌리기 쉬움(토큰 한 줄), "타이트"가 기본값이자 전역 튜너블 | `xl≠lg` 분리 규율 필요 | ✅ **추천** |
| B. 타깃(읽기 화면만) | ticker_detail·settings·indexes만 여유, 리스트는 타이트 유지 | 리스트 최대 밀도 보존 | 두 가지 시각언어 공존, 레퍼런스의 "균일한 차분함"과 어긋남 | 대안 |
| C. 전역 확대 | 모든 토큰 +25% | 간단 | **사용자가 싫어하는 바로 그것** — 이미 타이트한 곳까지 낭비 | ❌ 반대 |

**추천: A(토큰화).** 이하 모든 표는 A를 전제로 함.

---

## 2. 5인 전문가 수렴 지도 (신뢰도 높은 합의)

| 발견 | 타이포#1 | 여백#2 | 색상#3 | 컴포넌트#4 | 인터랙션#5 |
|---|:--:|:--:|:--:|:--:|:--:|
| 카드를 BentoCard로 수렴(테두리 카드 은퇴) | | ✅ | ✅ | ✅ | ✅(리플) |
| BentoCard 패딩 8→18 등 "굶주린 곳만" 확충 | ✅ | ✅ | | ✅ | |
| 라벨=textSecondary / 값=textPrimary 대비 규율 | ✅ | | ✅ | ✅ | ✅(대비) |
| 재사용 프리미티브(KV·확장카드·헤더) | | ✅ | | ✅ | ✅(모션) |
| 3단 색 논리(검정=사실/녹적=방향/블루=행동) | ✅ | | ✅ | ✅ | |
| 死코드/미사용 토큰 활성화(section·모션) | | ✅ | | | ✅ |

→ **6개 항목 중 5개가 3인 이상 독립 합의.** 특히 "BentoCard 수렴 + 굶주린 패딩 확충 + 라벨/값 대비"는 거의 만장일치.

---

## 3. 토큰 변경 — BEFORE → AFTER

### 3.1 여백 (`lib/theme/app_spacing.dart`)

| 토큰 | BEFORE | AFTER | 근거 |
|---|--:|--:|---|
| xxs/xs/sm/md | 2/4/8/12 | 동일 | 유지 |
| lg | 16 | 16 | **카드 내부 패딩/리스트 구분자 전용**으로 의미 고정 |
| **xl** | **16 (==lg!)** | **20** | 핵심 수정. "화면 게터/큰 그룹 간격" 전용 — 게터를 카드패딩과 독립 조정 |
| xxl | 20 | 24 | 긴 화면 섹션 분리 |
| xxxl | 24 | 28 | 큰 섹션 간격 |
| section | 28(死코드) | 28 + **사용 시작** | 긴 화면 에디토리얼 리듬 활성화 |
| **NEW cardPad** | — | **18** | 레퍼런스 카드 내부 패딩(밀도 레버 단일 소스) |
| **NEW rowV** | — | **12** | 키밸류 행 세로 패딩 |

> ⚠️ `xl` 16→20은 **일괄치환 금지**. 현재 `xl`을 카드패딩/세로간격으로 오용한 ~17곳은 `lg`로 재배정해야 함. 호출부 개별 감사 필요.

### 3.2 카드 (`lib/widgets/common/bento_card.dart`)

| 요소 | BEFORE | AFTER | 근거 |
|---|---|---|---|
| **기본 패딩** | `fromLTRB(8,12,8,8)` | `all(cardPad=18)` | **단일 최대 임팩트** — 49개 카드 일괄 개선 |
| 반경 | 16 | 16 | 유지(레퍼런스 일치) |
| 테두리 vs 그림자 | 그림자, 무테두리 ✅ | 유지 | 이미 정답 |
| 카드 간 간격 | md=12 | lg=16 | 카드가 개별 부유 객체로 읽힘 |
| 테두리 카드 11곳 | `Border.all(subtleBorder)` | BentoCard로 이관 | 반쯤 된 마이그레이션 완료 |

### 3.3 타이포 (`lib/theme/app_typography.dart`)

타입 스케일(15단계)은 유지. **line-height 표준화 + 숫자 강조 idiom**이 핵심(대부분 여백 0 증가).

| 요소 | BEFORE | AFTER | 근거 |
|---|---|---|---|
| 숫자 토큰 height | 미지정(주변값 상속) | priceHero 1.05 / priceLarge 1.1 / priceCard 1.15 / changeBadge 1.1 / numericSecondary 1.2 | 들쭉날쭉 정렬 해소, **오히려 공간 회수** |
| "큰 값+작은 단위" | `4.25%` 균일 16 | **`4.25`** 16 bold + `%` 12 muted (Text.rich) | 레퍼런스 시그니처(3,230+만원). 여백 0 |
| body height | 1.45 | 1.5 | 다국어 산문 편안함(채팅/AI만, 리스트 X) |
| 라벨/값 | 혼재 | 라벨 12 medium `textSecondary` / 값 14 semiBold `textPrimary` | "둘 다 흐림" 행 제거 |
| bold 남용 | 값마다 bold | 값=semiBold, bold는 카드당 헤드라인 숫자 1개 | 차분한 스캔, 비용 0 |

### 3.4 색상 (`lib/theme/app_colors.dart`)

| 요소 | BEFORE | AFTER | 근거 |
|---|---|---|---|
| **neutralColor(L)** | `#8A94A6` (회색배경 **2.80:1 WCAG 실패**) | `#78828F` (3.57:1) | 실제 명암비 위반 수정 |
| textTertiary 용도 | 라벨에도 남용 | **힌트 전용**(타임스탬프/비활성/placeholder), 라벨은 textSecondary 승격 | 2단 위계 복원 |
| accentBlue 규율 | BULLISH가 blue(데이터 색 오염) | **내비게이션 전용**, BULLISH→gainColor(녹색) | 블루=탭 가능 신호 순수화 |
| 카드 구분 | 가시 테두리 `#D4D8DF`(1.43:1) | 그림자(라이트)/명도 스텝 #111 vs #0A0A0A(다크) | 저크롬 차분함 |
| 내부 구분선 | subtleBorder 풀강도 | `withValues(alpha:0.5)` | 부드러운 청킹 |
| 오렌지 4종 중복 | warning/report/gaugeCautious/eventOptions | 2종으로 통합 | 팔레트 진정 |

> **[정정] 블루는 브랜드 주 강조색**: 레퍼런스는 히어로 가격·차트 곡선·강조점·링크·CTA를 전부 블루로 쓴다. 따라서 **비방향성 히어로 숫자(예상시세/목표가/밸류에이션 레인지)·인라인 링크·주요 CTA·가격 차트 라인**은 `accentBlue`로 적극 강조한다.
> **재무 의미는 별도 보존**: **방향성 수치(가격 변동·손익·%)만 녹/적** 유지(자동차엔 방향성이 없어 블루였던 것). 즉 3단: **블루=히어로/행동/차트, 녹적=방향, 검정=사실**. 다크 테마 패리티 유지.

---

## 4. 컴포넌트 라이브러리 (재사용 프리미티브)

모두 `lib/widgets/common/`에, **오직 `mlColors` + 토큰만** 사용 → `colorScheme` 드리프트 제거. 밀도는 `MlDensity` 기본값 하나로 전역 튜너블.

| 컴포넌트 | 대체 대상(재구현 벌수) | 역할 |
|---|---|---|
| **MlKeyValueRow** | `_cell`·`_buildMetricTile`·`_InfoItem`·`_statRow`·`_GridCell` (**5벌**) | 라벨+값 단일 원자. 가로/세로 2레이아웃, emphasis(normal/strong/blue/gainLoss) |
| **MlCard**(BentoCard 진화) | BentoCard + 임시 Container/Card 4종 | 유일 카드 표면. style(flat/raised/outlined), density |
| **MlExpandableCard** | 손수 확장 4곳(valuation·company·detail_sheet·holdings) | 헤이딜러 견적카드 — 요약↔KV상세, chevron/AnimatedSize 내장 |
| **MlSectionHeader**(SectionHeader 진화) | `_buildSectionLabel` + 맨텍스트 헤더 (3벌) | 볼드 섹션 타이틀 + 작은 뮤트 자격태그("무사고 기준"풍), accentBar 옵션 |
| **MlMetaFooter** | 인라인 `·` 조인 3+곳 | "4일 전 · 딜러입찰 12명" 뮤트 메타줄 |
| **MlScreenHeader** | 수동 핸들/애드혹 닫기 | 타이틀+X+핸들 통합 상단바 |
| (선택) MlBadgePill | 시그널/등급 pill 4곳 | 배지 통일 |

---

## 5. 화면 전/후 (파일럿 2개)

### A. `holding_detail_sheet.dart` — 헤이딜러 상세(170706) 케이스
**BEFORE**: 수동 핸들 + `Card(colorScheme.surface*)` + `_InfoItem` 3개 + 맨텍스트 헤더 + 손수 거래내역 토글.
**AFTER**: `MlScreenHeader(title, onClose)` → `MlCard`에 **가로 KV행**(`MlKeyValueRow`: 주식수→값 / 평단가→값 / 평가액→값, 라벨 좌·값 우측정렬) + `MlKeyValueRow('평가손익', gainLoss)` + `더보기 ⌄` → `MlExpandableCard`(거래내역 요약 N건↔전체) + `MlMetaFooter`. **색 소스 단일화, 히어로 값은 블루, 라벨/값 가로 우측정렬 리듬.**

### 그래프 구성 (170706 — 사용자 강조 "이렇게 구성하라") — 티커 차트에 반영
우리 `ticker_price_chart`/`ticker_intraday_chart`를 레퍼런스 차트 언어로:
| 요소 | 레퍼런스 | 우리 적용 |
|---|---|---|
| 주 라인 | 굵은 블루 스무스 곡선 | 가격 라인 `accentBlue`, 두께 상향, 곡선 스무딩 |
| 비교 데이터 | 연한 반투명 블루 산점 | 보조 시계열/밴드를 저알파 블루 |
| 현재 위치 강조 | 큰 블루 점+헤일로 + x축까지 파란 점선 가이드 | 마지막가/선택점에 헤일로 마커 + 점선 가이드 |
| 축 | 아주 연한 회색 가로 그리드 + 뮤트 축라벨, 현재값만 블루 볼드 | 그리드 `chartGridLine` 저대비, 축 `textTertiary`, 현재가 라벨 블루 |
| 범례 | 블루 점 + 뮤트 라벨 | 동일 |
| 여백 | 넉넉 | 차트 상하 여백 확보 |

### B. `HoldingListItem` + `valuation_card` — 헤이딜러 견적카드 리스트
**BEFORE**: 홀딩 행은 탭하면 화면 이동만(제자리 상세 없음), valuation은 카드 장식/확장 손수 구현(~90줄).
**AFTER**: `MlExpandableCard`로 — 요약(점수박스=썸네일, 볼드 티커, `MlMetaFooter`, 큰 값, `MlBadgePill`, chevron) ↔ 상세(`MlKeyValueRow`: 평단가·평가손익·목표가·배당). valuation은 grid 요약↔상세 (~90줄→~25줄).

---

## 6. 인터랙션 · 접근성 (전/후)

| 항목 | BEFORE | AFTER | 근거 |
|---|---|---|---|
| indexes 카드 리플 | `GestureDetector`로 BentoCard 감쌈 → **리플 없음** | `BentoCard(onTap:)` | 원라인, 무위험, 탭 피드백 복원 |
| 탭 타깃 | 채팅 전송 38px·셔플 ~20px·nav"+" | ≥44–48px(히트영역만 확대, 시각크기 유지) | 타이트 유지하며 편안함 |
| 아이콘 버튼 | Semantics 없음 → 스크린리더 먹통 | `Semantics(button,label)`/`IconButton(tooltip)` | 최대 a11y 언락 |
| 모션 | 하드코딩 200ms | `AppDuration` 토큰(normal/emphasized) | 잘 만든 토큰 활용, 차분한 확장 |
| 확장 애니 | 급작스런 pop-in(insight/AI reveal) | `AnimatedSize`/`AnimatedSwitcher` | 재스캔 피로 감소 |
| 텍스트 스케일 1.3× | 밀집 고정행 클리핑 위험 | Flexible/wrap 감사 | 저시력 데이터 손실 방지 |
| reduce-motion | 미대응 | `MediaQuery.disableAnimations` 분기 | 모션 민감 배려 |
| 로딩 | 곳곳 스피너 | ShimmerLoading 스켈레톤 | 차분·레이아웃 프리뷰 |

---

## 7. 우선순위 로드맵 (단계별 · 위험도)

**Phase 0 — 토큰 기반 (1파일 단위, 저위험, 최대 파급)**
- `app_spacing`: xl≠lg 분리 + cardPad/rowV 추가 + section 활성 준비
- `bento_card` 기본 패딩 8→18, 카드간격 12→16
- `app_typography`: 숫자 토큰 height 주입, kvLabel/kvValue/unitSuffix 추가
- `app_colors`: neutralColor WCAG 수정, textTertiary→힌트전용, BULLISH→green, 구분선 alpha
→ 이 단계만으로 체감 큰 변화, 회귀 위험 최소.

**Phase 1 — 프리미티브 도입(비파괴)**
- MlKeyValueRow / MlMetaFooter / MlExpandableCard / MlScreenHeader 신설, BentoCard→MlCard 별칭, SectionHeader 파라미터 확장(기존 호출부 무변경).

**Phase 2 — 파일럿 2화면 이관** (holding_detail_sheet, holding_list_item+valuation_card) — 밀도 기본값 검증.

**Phase 3 — 프리미티브 단위 일괄 이관**
- KV 5벌 → MlKeyValueRow / 테두리 카드 11곳 → MlCard / 헤더 3벌 → MlSectionHeader.

**Phase 4 — 인터랙션/a11y 스윕** (리플·Semantics·탭타깃·모션·스케일 감사). 스티키 헤더는 별도(스크롤 리팩터 위험).

---

## 8. 위험 / 회귀

- **다크 테마(최대 위험)**: 그림자가 `#0A0A0A`에서 안 보임 → 다크는 카드 `#111` vs 배경 `#0A0A0A` **명도 스텝**으로 구분. 테두리 무작정 제거 금지(순흑 `#000` 섹션 위 카드는 테두리 유지).
- **재무 색 의미 불변**: 녹/적은 방향성 데이터 전용, 블루는 절대 가격에 안 씀.
- **`xl` 분리 일괄치환 금지**: 호출부 개별 감사(게터→xl20, 카드내부→lg16).
- **밀집 행 패딩 확대**: 히트영역만 확대(투명 패딩), 시각 크기·타이트감 유지.
- **두 색 체계 이관**: `colorScheme` 회색과 `mlColors` 회색 미세차 → 파일럿에서 라이트/다크 동시 diff.
- **넓은 스윕은 단계적으로**: 화면별 시각 QA, 대형 미검증 diff 금지. 현재 브랜치 `feat/uiux-readability-contrast`의 대기 변경과 조율.

---

## 9. 사용자 결정 포인트 (재차 조율)

1. **밀도 전략**: A(토큰화·추천) / B(타깃) / C(전역) — 방향 확정.
2. **착수 범위**: Phase 0(토큰만) 먼저 커밋해 체감 확인 후 진행? 아니면 Phase 0+1 함께?
3. **블루 강조 정책**: 목표가 등 "행동 유도 숫자"에 블루 선택 적용 OK? (가격/손익은 녹적 유지 확정)
4. **파일럿 화면**: 제안(holding_detail_sheet + holding_list_item/valuation) 동의? 다른 화면 우선?
5. **다크 테마**: 이번 리디자인에 라이트와 동시 진행? 라이트 먼저?
