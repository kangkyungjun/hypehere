#!/usr/bin/env python
"""
모바일 우선 UI 디자인 가이드를 specs 앱에 자동 등록하는 스크립트
실행 방법: python scripts/create_mobile_guide.py
"""

import os
import sys
import django

# Django 설정
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from specs.models import Specification
from django.contrib.auth import get_user_model

User = get_user_model()

# 모바일 우선 UI 가이드 내용
MOBILE_GUIDE_CONTENT = """
# HypeHere 모바일 우선 UI 디자인 가이드

> **작성 목적**: 웹앱으로 전환 예정이므로 모바일 사용 환경을 최우선으로 고려한 UI/UX 설계 가이드

---

## 📱 1. 반응형 브레이크포인트

### 정의된 브레이크포인트
```css
/* Mobile (기본) */
< 768px

/* Tablet */
768px ~ 1024px

/* Desktop */
> 1024px
```

### 구현 위치
- `static/css/layouts.css` (401-477번 라인)
- `static/css/base.css` (hide-mobile, hide-desktop 유틸리티)

### CSS 작성 원칙
**Mobile-First 접근**:
```css
/* ✅ 올바른 방법: 모바일 기본, 데스크톱 확장 */
.component {
  padding: var(--space-sm);  /* 모바일 기본값 */
}

@media (min-width: 768px) {
  .component {
    padding: var(--space-lg);  /* 태블릿 이상 확장 */
  }
}

/* ❌ 잘못된 방법: 데스크톱 기본, 모바일 축소 */
.component {
  padding: var(--space-lg);
}

@media (max-width: 768px) {
  .component {
    padding: var(--space-sm);
  }
}
```

---

## 👆 2. 터치 타겟 크기

### 최소 크기 기준
- **Apple Human Interface Guidelines**: 44x44 포인트
- **Material Design**: 48x48 dp
- **HypeHere 기준**: **최소 44x44px**

### 구현 예시
```css
.btn {
  padding: var(--space-sm) var(--space-lg);  /* 8px 16px */
  min-height: 44px;  /* 터치 영역 보장 */
  min-width: 44px;
}

.header-icon-btn {
  width: 40px;   /* 권장: 44px 이상 */
  height: 40px;
  padding: var(--space-sm);  /* 내부 여유 공간 */
}
```

### 터치 간격
- 버튼 간 최소 간격: **8px** (var(--space-sm))
- 권장 간격: **16px** (var(--space-md))

### 현재 적용 상태
- ✅ 버튼: `.btn` (base.css)
- ✅ 헤더 아이콘: `.header-icon-btn` (layouts.css)
- ✅ 모바일 네비게이션: `.mobile-nav-link` (layouts.css)

---

## 📝 3. 타이포그래피

### 모바일 최적화 폰트 크기
```css
/* 본문 텍스트 */
--font-size-base: 16px;  /* iOS 자동 확대 방지 */

/* 작은 텍스트 (최소) */
--font-size-sm: 14px;

/* 읽기 편한 줄 간격 */
--line-height-normal: 1.5;
--line-height-relaxed: 1.75;
```

### 가독성 원칙
1. **본문 최소 16px**: iOS Safari는 16px 미만 텍스트를 자동 확대
2. **줄 간격 1.5 이상**: 모바일에서 읽기 편한 간격
3. **최대 줄 길이**: 680px (한 줄 45-75자 권장)

### 구현 위치
- `static/css/variables.css` (타이포그래피 변수)
- `static/css/base.css` (기본 타이포그래피 스타일)

---

## 🧭 4. 모바일 네비게이션 패턴

### 하단 탭 바 (Bottom Tab Bar)
**적용 화면**: 로그인 후 모든 화면

**위치**: `templates/base.html` (모바일 네비게이션 섹션)

**구조**:
```
┌─────────────────────────┐
│                         │
│   메인 콘텐츠 영역        │
│                         │
└─────────────────────────┘
┌─[홈]─[탐색]─[알림]─[프로필]┐  ← 하단 고정
```

**장점**:
- ✅ 엄지 손가락으로 쉽게 접근
- ✅ 현재 위치 명확히 표시
- ✅ 주요 기능 빠른 전환

**권장 메뉴 개수**: 3-5개 (현재 4개)

### 햄버거 메뉴 (사용 안 함)
- ❌ 숨겨진 메뉴는 발견성 낮음
- ✅ 대신 하단 탭바로 주요 기능 노출

---

## 🎨 5. 레이아웃 조정

### 모바일 레이아웃 변경사항 (< 768px)

#### A. 헤더
- ❌ 검색바 숨김
- ❌ 네비게이션 텍스트 레이블 제거 (아이콘만)
- ✅ 로고 + 로그인/회원가입 버튼만 표시

#### B. 사이드바
- ❌ 완전히 숨김
- ✅ 하단 탭바로 대체

#### C. 메인 콘텐츠
- 패딩 축소: `var(--space-lg)` → `var(--space-md)`
- 전체 너비 사용 (사이드바 없음)

#### D. 푸터
- 그리드 레이아웃: 멀티 컬럼 → 1컬럼

### 구현 위치
`static/css/layouts.css` - Responsive Design 섹션

---

## 🚀 6. 성능 최적화

### 모바일 우선 로딩 전략

#### CSS 최적화
```html
<!-- Critical CSS inline -->
<style>
  /* 초기 렌더링에 필요한 최소 CSS */
</style>

<!-- Non-critical CSS 지연 로드 -->
<link rel="stylesheet" href="styles.css" media="print" onload="this.media='all'">
```

#### 이미지 최적화
```html
<!-- Lazy loading -->
<img src="..." loading="lazy" alt="...">

<!-- Responsive images -->
<img
  srcset="image-320w.jpg 320w,
          image-640w.jpg 640w,
          image-1024w.jpg 1024w"
  sizes="(max-width: 768px) 100vw, 680px"
  src="image-640w.jpg"
  alt="..."
>
```

### 현재 상태
- ✅ 바닐라 CSS (프레임워크 없음)
- ✅ 모듈화된 CSS 파일
- ⬜ 이미지 lazy loading (향후 구현)
- ⬜ PWA 준비 (향후 구현)

---

## ✅ 7. 개발 체크리스트

### 새 컴포넌트 개발 시

#### 디자인 단계
- [ ] 모바일 화면 (360px 기준)부터 디자인
- [ ] 터치 타겟 최소 44x44px 확인
- [ ] 텍스트 크기 16px 이상 확인
- [ ] 줄 간격 1.5 이상 확인

#### 구현 단계
- [ ] CSS는 모바일 기본값부터 작성
- [ ] 데스크톱은 `@media (min-width)` 사용
- [ ] Chrome DevTools 모바일 뷰 테스트
- [ ] 실제 기기에서 터치 테스트

#### 테스트 단계
- [ ] iPhone SE (375px) 테스트
- [ ] Tablet (768px) 테스트
- [ ] Desktop (1024px+) 테스트
- [ ] 가로/세로 모드 전환 테스트

---

## 📐 8. 디자인 토큰 (CSS Variables)

### 모바일 최적화 변수
```css
/* 간격 (모바일 친화적) */
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;

/* 터치 타겟 */
--touch-target-min: 44px;

/* 타이포그래피 */
--font-size-base: 16px;
--line-height-normal: 1.5;

/* 레이아웃 */
--header-height: 64px;
--mobile-nav-height: 56px;
```

### 위치
`static/css/variables.css`

---

## 🎯 9. 향후 개선 계획

### Phase 2 - 웹앱 전환
- [ ] PWA 설정 (manifest.json, service-worker.js)
- [ ] 오프라인 지원
- [ ] 홈 화면 추가 기능

### Phase 3 - 제스처 지원
- [ ] 스와이프 네비게이션
- [ ] Pull-to-refresh
- [ ] 롱 프레스 컨텍스트 메뉴

### Phase 4 - 성능 최적화
- [ ] 이미지 lazy loading
- [ ] Code splitting
- [ ] Critical CSS inline

---

## 📚 10. 참고 자료

### 디자인 가이드라인
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design](https://material.io/design)
- [Mobile Web Best Practices](https://www.w3.org/TR/mobile-bp/)

### 접근성
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Mobile Accessibility Guidelines](https://www.w3.org/WAI/mobile/)

### 성능
- [Web.dev Performance](https://web.dev/performance/)
- [Core Web Vitals](https://web.dev/vitals/)

---

## 📝 마무리

이 가이드는 HypeHere 프로젝트의 **모바일 우선 UI 디자인 원칙**을 정의합니다.

**핵심 원칙**:
1. 🎯 **Mobile-First**: 모바일부터 설계, 데스크톱으로 확장
2. 👆 **Touch-Friendly**: 44px 이상 터치 영역 보장
3. 📱 **Performance**: 빠른 로딩, 적은 데이터 사용
4. ♿ **Accessibility**: 모든 사용자가 접근 가능한 UI

**문의 사항**: 개발팀 또는 Django Admin의 Specifications 섹션 참조
"""

def main():
    print("🚀 모바일 우선 UI 가이드 등록 스크립트 시작...\n")

    # 관리자 계정 확인
    admin_user = User.objects.filter(is_superuser=True).first()

    if not admin_user:
        print("❌ 오류: 슈퍼유저가 존재하지 않습니다.")
        print("먼저 슈퍼유저를 생성하세요: python manage.py createsuperuser")
        sys.exit(1)

    print(f"✅ 관리자 계정 확인: {admin_user.username}\n")

    # Specification 생성 또는 업데이트
    spec, created = Specification.objects.get_or_create(
        title="모바일 우선 UI 디자인 가이드",
        defaults={
            'category': 'design',
            'content': MOBILE_GUIDE_CONTENT.strip(),
            'status': 'approved',
            'version': 'v1.0',
            'created_by': admin_user
        }
    )

    if created:
        print("✅ 모바일 우선 UI 디자인 가이드가 생성되었습니다!")
    else:
        # 이미 존재하면 내용 업데이트
        spec.content = MOBILE_GUIDE_CONTENT.strip()
        spec.save()
        print("ℹ️  가이드가 이미 존재하여 내용을 업데이트했습니다.")

    print(f"\n📋 등록 정보:")
    print(f"   - ID: {spec.id}")
    print(f"   - 제목: {spec.title}")
    print(f"   - 카테고리: {spec.get_category_display()}")
    print(f"   - 상태: {spec.get_status_display()}")
    print(f"   - 버전: {spec.version}")
    print(f"   - 작성자: {spec.created_by.username}")
    print(f"   - 생성일: {spec.created_at.strftime('%Y-%m-%d %H:%M:%S')}")

    print(f"\n🌐 Django Admin에서 확인:")
    print(f"   http://127.0.0.1:8001/admin/specs/specification/{spec.id}/change/")
    print("\n✨ 완료!")

if __name__ == "__main__":
    main()
