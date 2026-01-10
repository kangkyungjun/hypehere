# Google Play Store 출시 체크리스트

## 📋 출시 전 필수 점검 사항

---

## ✅ 1. 법적 요구사항 (COMPLETED ✓)

### 이용약관 및 개인정보 보호 정책
- [x] 이용약관 작성 및 게시 (4개 언어)
- [x] 개인정보처리방침 작성 및 게시 (4개 언어)
- [x] 쿠키 정책 작성 및 게시 (4개 언어)
- [x] 커뮤니티 가이드라인 작성 및 게시 (4개 언어)
- [x] 회원가입 시 명시적 동의 체크박스 구현
- [x] 만 14세 이상 연령 확인 체크박스

**웹 URL:**
- https://hypehere.online/accounts/terms/
- https://hypehere.online/accounts/privacy/
- https://hypehere.online/accounts/cookies/

**상태:** ✅ 완료 (AWS 서버 배포됨)

---

## ⚠️ 2. 앱 서명 및 빌드 (CRITICAL - 미완료)

### 릴리스 빌드 서명
**현재 상태:** ❌ Debug 키로 서명됨 (Line 34: signingConfig = debug)

**필수 작업:**
```kotlin
// android/app/build.gradle.kts 수정 필요

// 1. 릴리스 키 생성
keytool -genkey -v -keystore ~/hypehere-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias hypehere-release

// 2. key.properties 파일 생성 (android/)
storePassword=<비밀번호>
keyPassword=<키 비밀번호>
keyAlias=hypehere-release
storeFile=/Users/kyungjunkang/hypehere-release-key.jks

// 3. build.gradle.kts 수정
signingConfigs {
    create("release") {
        val keystoreProperties = Properties()
        val keystorePropertiesFile = rootProject.file("key.properties")
        if (keystorePropertiesFile.exists()) {
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        }
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        minifyEnabled = true
        shrinkResources = true
    }
}
```

### AAB (Android App Bundle) 빌드
```bash
# 릴리스 AAB 생성
flutter build appbundle --release

# 생성 위치
# build/app/outputs/bundle/release/app-release.aab
```

**우선순위:** 🔴 CRITICAL (출시 필수)

---

## ⚠️ 3. 앱 아이콘 (REQUIRED - 미완료)

### 현재 상태
- [x] Android 기본 아이콘 사용 중 (ic_launcher)
- [ ] 커스텀 앱 아이콘 생성 필요

### 필수 아이콘 사이즈
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
└── mipmap-xxxhdpi/ic_launcher_foreground.png (필요시 Adaptive Icon)
```

### Google Play 요구사항
- 512x512 픽셀 고해상도 아이콘 (Play Console 업로드용)
- PNG 또는 JPG 형식
- 32비트 PNG (알파 채널 지원)

**도구 추천:**
- https://appicon.co/ (온라인 아이콘 생성기)
- https://romannurik.github.io/AndroidAssetStudio/ (Android Asset Studio)

**우선순위:** 🟠 HIGH (심사 통과 필수)

---

## ⚠️ 4. 스크린샷 및 그래픽 자료 (REQUIRED - 미완료)

### Google Play Console 필수 자료

#### 스크린샷 (최소 2개, 최대 8개)
- [ ] 휴대전화 스크린샷 (최소 2개 필수)
  - 최소 크기: 320px
  - 최대 크기: 3840px
  - 권장: 16:9 비율 (1080x1920 또는 1440x2560)

#### 그래픽 자산
- [ ] 고해상도 아이콘 (512x512, PNG, 필수)
- [ ] 기능 그래픽 (1024x500, JPG/PNG, 필수)
  - Play Store 상단 배너에 표시
  - 텍스트 포함 가능

#### 선택 자료
- [ ] 프로모션 동영상 (YouTube URL)
- [ ] 태블릿 스크린샷 (선택)

**생성 방법:**
```bash
# Flutter 앱 실행 후 스크린샷 촬영
flutter run --release

# 또는 에뮬레이터에서
flutter emulators --launch <emulator_id>
```

**우선순위:** 🟠 HIGH (Play Console 등록 필수)

---

## ⚠️ 5. 앱 메타데이터 (REQUIRED - 미완료)

### Google Play Console 입력 정보

#### 기본 정보
- [ ] **앱 이름:** HypeHere
- [ ] **짧은 설명:** (80자 이하)
  ```
  언어 교환 파트너를 만나 실시간 채팅과 학습을 즐기세요
  ```
- [ ] **자세한 설명:** (4000자 이하)
  ```
  HypeHere는 언어 학습자를 위한 소셜 플랫폼입니다.

  주요 기능:
  • 모국어와 학습 언어를 선택하여 맞춤형 피드 제공
  • 실시간 1:1 채팅 및 그룹 채팅
  • 익명 매칭을 통한 언어 교환
  • 게시물과 댓글로 다양한 언어 학습 콘텐츠 공유
  • 신고 및 차단 기능으로 안전한 커뮤니티 환경

  지원 언어: 한국어, 영어, 일본어, 스페인어
  ```

#### 카테고리
- [ ] **앱 카테고리:** 교육 (Education) 또는 소셜 (Social)
- [ ] **콘텐츠 등급:** 만 14세 이상

#### 연락처 정보
- [ ] **이메일:** (개발자 연락처)
- [ ] **웹사이트:** https://hypehere.online
- [ ] **전화번호:** (선택)
- [ ] **주소:** (개발자 주소, 선택)

#### 개인정보처리방침
- [ ] **URL:** https://hypehere.online/accounts/privacy/

**우선순위:** 🟠 HIGH (Play Console 등록 필수)

---

## ⚠️ 6. 콘텐츠 등급 설정 (REQUIRED - 미완료)

### IARC (International Age Rating Coalition) 설문 작성

#### 예상 질문 및 답변
- **폭력성:** 없음
- **성적 콘텐츠:** 없음 (사용자 생성 콘텐츠 신고 시스템 있음)
- **언어:** 욕설 가능성 있음 (사용자 생성 콘텐츠)
- **약물/음주:** 없음
- **도박:** 없음
- **사용자 간 상호작용:** 있음 (채팅, 게시물)
- **사용자 정보 공유:** 있음 (프로필, 채팅)
- **위치 정보 수집:** 없음

#### 예상 등급
- **한국:** 만 12세 또는 만 15세 이용가
- **미국:** Teen (13+)
- **유럽:** PEGI 12

**신고 시스템 강조:**
- 부적절한 콘텐츠 신고 기능
- 관리자 검토 시스템
- 차단 및 계정 정지 기능

**우선순위:** 🟠 HIGH (심사 통과 필수)

---

## ✅ 7. 기술적 요구사항 (MOSTLY COMPLETED)

### 앱 권한
- [x] INTERNET (네트워크 접근)
- [x] ACCESS_NETWORK_STATE (네트워크 상태 확인)
- [x] WRITE_EXTERNAL_STORAGE (Android 12 이하)
- [x] READ_EXTERNAL_STORAGE (Android 12 이하)

### API 레벨
- [x] minSdk: 21 (Android 5.0) ✅
- [x] targetSdk: 34 (Android 14) ✅
- [x] compileSdk: Flutter default ✅

### Google Play 정책 준수
- [x] 개인정보 보호 정책 URL 제공
- [x] 이용약관 URL 제공
- [x] 사용자 데이터 삭제 기능 (계정 삭제)
- [x] 신고 및 차단 시스템
- [ ] Data Safety 섹션 작성 (Play Console)

### 보안
- [x] HTTPS 사용 (hypehere.online)
- [x] Network Security Config 설정
- [ ] 난독화 (ProGuard/R8) 활성화 필요

**우선순위:** 🟢 MEDIUM (일부 작업 필요)

---

## ⚠️ 8. 테스트 및 QA (REQUIRED - 미완료)

### 내부 테스트
- [ ] 다양한 Android 기기에서 테스트
  - Galaxy S20/S21/S22 시리즈
  - Pixel 6/7/8 시리즈
  - 저가형 기기 (1~2대)
- [ ] Android 버전별 테스트
  - Android 12 (minSdk 21부터)
  - Android 13
  - Android 14

### 기능 테스트
- [ ] 회원가입/로그인 동작 확인
- [ ] 체크박스 동의 프로세스 확인
- [ ] 게시물 작성/조회/삭제
- [ ] 댓글 작성/삭제
- [ ] 1:1 채팅 (WebSocket 연결)
- [ ] 그룹 채팅
- [ ] 익명 매칭
- [ ] 신고 기능
- [ ] 차단 기능
- [ ] 프로필 수정
- [ ] 이용약관/개인정보 페이지 접근

### 성능 테스트
- [ ] 앱 시작 시간 (< 3초)
- [ ] 메모리 사용량 확인
- [ ] 배터리 소모 확인
- [ ] 네트워크 오류 처리

### 접근성 테스트
- [ ] TalkBack 호환성
- [ ] 폰트 크기 조정 대응
- [ ] 색상 대비 확인

**우선순위:** 🟠 HIGH (심사 통과 필수)

---

## ⚠️ 9. Play Console 설정 (REQUIRED - 미완료)

### 계정 준비
- [ ] Google Play Console 계정 생성 (1회 $25 등록비)
- [ ] 개발자 계정 정보 입력

### 앱 생성
- [ ] 새 앱 만들기
- [ ] 앱 이름: HypeHere
- [ ] 기본 언어: 한국어
- [ ] 앱 또는 게임: 앱
- [ ] 무료 또는 유료: 무료

### 스토어 등록정보
- [ ] 앱 세부정보 입력
- [ ] 그래픽 자산 업로드
- [ ] 스크린샷 업로드
- [ ] 앱 카테고리 선택

### 콘텐츠 등급
- [ ] 설문지 작성
- [ ] 등급 인증서 받기

### 앱 콘텐츠
- [ ] 개인정보처리방침 URL 입력
- [ ] Data Safety 섹션 작성
- [ ] 광고 여부 선택 (없음)
- [ ] 타겟 고객 및 콘텐츠 선택

### 가격 및 배포
- [ ] 가격: 무료
- [ ] 배포 국가 선택
  - 권장: 한국, 미국, 일본, 스페인
- [ ] 기기 카테고리 (휴대전화, 태블릿)

### 앱 릴리스
- [ ] 프로덕션 트랙 선택
- [ ] AAB 파일 업로드
- [ ] 출시 노트 작성

**우선순위:** 🔴 CRITICAL (출시 필수)

---

## ⚠️ 10. Data Safety 섹션 (REQUIRED - 미완료)

### 수집하는 데이터
**사용자가 제공하는 정보:**
- [x] 이메일 주소 (계정 생성)
- [x] 닉네임 (표시 이름)
- [x] 비밀번호 (암호화 저장)
- [x] 성별 (선택)
- [x] 국가 (선택)
- [x] 프로필 사진 (선택)

**자동으로 수집되는 데이터:**
- [x] IP 주소 (로그인 기록)
- [ ] 기기 정보 (선택)
- [ ] 앱 사용 통계 (선택)

### 데이터 사용 목적
- 계정 관리 및 인증
- 언어 교환 매칭
- 서비스 개선

### 데이터 공유
- 제3자와 공유 안 함 (명시)

### 데이터 보안
- HTTPS 암호화 전송
- 비밀번호 해싱
- 서버 보안

### 데이터 삭제
- 사용자가 계정 삭제 가능
- 30일 유예 기간 후 영구 삭제

**우선순위:** 🔴 CRITICAL (출시 필수)

---

## 📊 우선순위별 작업 목록

### 🔴 CRITICAL (출시 불가)
1. **앱 서명 설정** - 릴리스 키 생성 및 적용
2. **AAB 빌드 생성** - 최종 배포 파일
3. **Play Console 계정 및 앱 생성**
4. **Data Safety 섹션 작성**

### 🟠 HIGH (심사 통과 필수)
1. **앱 아이콘 제작** - 512x512 고해상도
2. **스크린샷 촬영** - 최소 2개
3. **기능 그래픽 제작** - 1024x500 배너
4. **앱 설명 작성** - 짧은 설명 + 자세한 설명
5. **콘텐츠 등급 설문** - IARC 등급 받기
6. **테스트 진행** - 주요 기능 및 기기 테스트

### 🟢 MEDIUM (권장)
1. **난독화 활성화** - ProGuard/R8
2. **성능 최적화** - 시작 시간, 메모리
3. **접근성 개선** - TalkBack 지원

### 🔵 LOW (선택)
1. 프로모션 동영상 제작
2. 태블릿 최적화
3. 다국어 앱 설명 (영어, 일본어, 스페인어)

---

## 📅 예상 일정

### 1주차: 기술 준비
- [ ] Day 1-2: 릴리스 키 생성 및 서명 설정
- [ ] Day 3-4: 앱 아이콘 제작 및 적용
- [ ] Day 5-7: AAB 빌드 및 테스트

### 2주차: 콘텐츠 준비
- [ ] Day 8-9: 스크린샷 촬영 및 편집
- [ ] Day 10-11: 기능 그래픽 및 설명 작성
- [ ] Day 12-14: Play Console 설정 및 Data Safety 작성

### 3주차: 테스트 및 제출
- [ ] Day 15-18: 내부 테스트 및 버그 수정
- [ ] Day 19-20: 콘텐츠 등급 설문 작성
- [ ] Day 21: 최종 제출

### 심사 대기
- Google: 일반적으로 1~7일 소요
- 추가 정보 요청 시 빠른 응대 필요

---

## ✅ 이미 완료된 항목

1. ✅ 백엔드 서버 배포 (hypehere.online)
2. ✅ HTTPS 설정
3. ✅ 법적 문서 4개 언어 준비
4. ✅ 회원가입 동의 체크박스
5. ✅ 만 14세 이상 연령 확인
6. ✅ 신고/차단 시스템
7. ✅ 계정 삭제 기능
8. ✅ 개인정보 보호 설정
9. ✅ 모달 접근성 (WCAG 2.1 AA)
10. ✅ Flutter 앱 기본 구조

---

## 🚨 주의사항

### Google Play 정책 위반 방지
1. **사용자 생성 콘텐츠 관리**
   - 신고 시스템 필수 (✅ 구현됨)
   - 부적절한 콘텐츠 신속 삭제
   - 반복 위반자 계정 정지

2. **개인정보 보호**
   - Data Safety 정확히 작성
   - 사용자 동의 명확히 받기 (✅ 구현됨)
   - 데이터 삭제 기능 제공 (✅ 구현됨)

3. **아동 보호**
   - 만 14세 미만 가입 차단 (✅ 구현됨)
   - 부적절한 콘텐츠 필터링

4. **지적재산권**
   - 앱 아이콘 저작권 확인
   - 기능 그래픽 원본 이미지 사용

### 거부 사유 예방
1. 충돌 또는 버그 → 철저한 테스트
2. 불완전한 정보 → 모든 필드 정확히 입력
3. 저품질 콘텐츠 → 고해상도 이미지 사용
4. 정책 위반 → 신고 시스템 강조

---

## 📞 참고 자료

- [Google Play Console](https://play.google.com/console/)
- [출시 체크리스트](https://developer.android.com/distribute/best-practices/launch/launch-checklist)
- [Data Safety 가이드](https://support.google.com/googleplay/android-developer/answer/10787469)
- [콘텐츠 등급 (IARC)](https://support.google.com/googleplay/android-developer/answer/9859655)
- [Flutter 배포 가이드](https://docs.flutter.dev/deployment/android)

---

## 📊 현재 진행률

```
총 10개 카테고리 중:
✅ 완료: 1개 (법적 요구사항)
⚠️ 진행 필요: 9개

CRITICAL 작업: 4개
HIGH 작업: 6개
MEDIUM 작업: 3개
LOW 작업: 3개

예상 소요 시간: 2~3주
```

**다음 단계:** 앱 서명 설정부터 시작하세요!
