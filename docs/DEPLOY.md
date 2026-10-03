# EC2 Backend Deployment Guide

## Server Info

| 항목 | 값 |
|------|-----|
| IP | `43.201.45.60` |
| SSH User | `ubuntu` |
| SSH Key | **`secrets/ssh/hypehere-key.pem`** (레포 내부, gitignore됨) |
| App User | `django` |
| Project Path | `/home/django/marketlens/` |
| Service Name | `marketlens-django` |
| Port | `8002` |
| Workers | 3 (gunicorn) |

> ⚠️ **키 위치는 `secrets/ssh/hypehere-key.pem` 하나뿐이다.**
> 과거 이 문서는 `~/Downloads/`를 가리켰는데 그 파일은 없다. 다시 적지 말 것.
> `secrets/`는 `.gitignore` 53행으로 통째 제외되므로 커밋될 위험은 없다.
>
> ```bash
> K=secrets/ssh/hypehere-key.pem   # 모든 예시의 $K
> ```

## Quick Deploy (scp)

서버에 git repo가 없음. 파일 직접 전송 방식.

```bash
# 1. 파일 전송
scp -i secrets/ssh/hypehere-key.pem <local-file> ubuntu@43.201.45.60:/tmp/

# 2. 서버 배치 + 서비스 재시작
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo cp /tmp/<filename> /home/django/marketlens/<target-path> && \
   sudo chown django:django /home/django/marketlens/<target-path> && \
   sudo systemctl restart marketlens-django"

# 3. 상태 확인
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo systemctl status marketlens-django --no-pager"
```

## Example: accounts/views.py 배포

```bash
scp -i secrets/ssh/hypehere-key.pem backend/accounts/views.py ubuntu@43.201.45.60:/tmp/views.py

ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo cp /tmp/views.py /home/django/marketlens/accounts/views.py && \
   sudo chown django:django /home/django/marketlens/accounts/views.py && \
   sudo systemctl restart marketlens-django"
```

## Log Files

```bash
# access log
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "tail -50 /home/django/marketlens_django.log"

# error log
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "tail -50 /home/django/marketlens_django_error.log"
```

## Other Services

| Service | Path | Port |
|---------|------|------|
| `fastapi-analytics` | `/home/django/fastapi_analytics/` | `8001` |

## Directory Structure (Server)

```
/home/django/marketlens/
  accounts/
  community/
  marketlens_backend/
  moderation/
  templates/
  venv/
  manage.py
  requirements.txt
```

## Notes

- SSH user는 `ubuntu`이지, `django`가 아님 (django는 앱 실행 유저)
- 서버에 `.git` 없음 -> `git pull` 불가, `scp`로 배포
- `gunicorn` 서비스명은 `marketlens-django`
- Flutter 클라이언트 수정은 앱스토어 재배포 별도 필요

---

# 앱 빌드 환경 (2026-10-03 복구 기록)

1.11.0 빌드 때 **네 가지가 연달아** 막혔다. 같은 데서 또 멈추지 않도록 적는다.

## 1. Xcode 라이선스 미동의 → brew가 전부 멈춘다

```
Error: You have not agreed to the Xcode license.
```

이게 떠 있으면 `brew install`이 **무엇이든** 실패한다. Android 툴 설치도
CocoaPods 설치도 전부 이것 때문에 죽는다. 원인을 Android 쪽에서 찾으면
한참 헤맨다.

```bash
sudo xcodebuild -license accept   # sudo 필요 — 에이전트가 못 한다
```

## 2. Android SDK가 통째로 사라져 있었다

`~/Library/Android/sdk`가 존재하지 않았다. Android Studio 앱만 남아 있었다.
`local.properties`와 Android Studio 설정은 그 경로를 가리키고 있었다.

```bash
brew install --cask android-commandlinetools
export ANDROID_HOME="$HOME/Library/Android/sdk"
mkdir -p "$ANDROID_HOME"
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses
sdkmanager --sdk_root="$ANDROID_HOME" \
  "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "ndk;27.0.12077973" "cmdline-tools;latest"
flutter config --android-sdk "$ANDROID_HOME"
```

NDK 버전은 `android/app/build.gradle.kts`의 `ndkVersion`과 **정확히** 같아야
한다. compileSdk는 Flutter가 정한다(현재 36).

> ⚠️ `flutter doctor --android-licenses`는 이제 동작하지 않는다
> ("The --licenses option is no longer needed"). 그래서 doctor가 계속
> "Android license status unknown"이라고 한다. **라이선스는 이미 수락돼
> 있다** — `$ANDROID_HOME/licenses/`에 파일이 있으면 된 것이고 빌드도 통과한다.
> doctor 메시지만 보고 다시 설치하지 말 것.

## 3. Pod 배포 타깃 13.0 → Xcode 27이 거부

```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0,
but the range of supported deployment target versions is 15.0 to 27.0.x
```

`Podfile`의 `platform :ios, '15.0'`은 **pod 타깃까지 안 내려간다** —
`flutter_additional_ios_build_settings`가 Flutter 기본 최소값으로 덮어쓴다.
`post_install`에서 다시 올려야 한다(이미 `ios/Podfile`에 반영됨).

## 4. RevenueCat 5.67.1이 Xcode 27의 Swift에서 컴파일 불가

```
Invalid redeclaration of synthesized memberwise 'init(stringRepresentation:)'
Ambiguous use of 'init'
```

`purchases_flutter 9.16.1`이 `RevenueCat (= 5.67.1)`을 **정확히 고정**해서
Podfile에서 덮어쓸 수 없다. CocoaPods가 거부한다.

→ `purchases_flutter`를 **10.14.0**으로 올렸다. RevenueCat 5.92.0이 따라온다.

```bash
# 플러그인만 올리면 Podfile.lock이 옛 pod를 붙들고 있다
cd ios && pod update PurchasesHybridCommon RevenueCat
```

**앱 코드는 안 고쳤다.** 10.x에도 `Purchases.purchasePackage`가 남아 있다
(deprecated). 기기 테스트 없이 결제 호출을 바꾸는 게 더 위험하다고 봤다.
→ 후속 작업: `purchase(PurchaseParams)`로 이관.

## iOS 배포 — 여기서 사용자 손이 필요하다

아카이브는 만들어진다:

```bash
flutter build ipa --release --no-codesign
# → build/ios/archive/Runner.xcarchive
```

**IPA export는 안 된다.** 키체인에 `Apple Development`만 있고
`Apple Distribution` 인증서가 없다. 프로비저닝 프로파일도 0개다.

```bash
security find-identity -v -p codesigning   # 확인용
```

둘 중 하나가 필요하다:
- Xcode Organizer에서 직접 export (`open build/ios/archive/Runner.xcarchive`)
- 또는 배포 인증서 + 프로파일 설치 후 `flutter build ipa --export-method app-store`
