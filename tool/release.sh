#!/bin/bash
# 앱 릴리스 — 버전업부터 양쪽 빌드까지 **한 번에** 끝낸다.
#
#   ./tool/release.sh 1.11.0 43
#   ./tool/release.sh 1.12.0 44 --skip-ios
#
# 중간에 멈추지 않는다. 막히면 어디서 왜 막혔는지 찍고 끝낸다.
# 사용자 손이 필요한 건 **마지막 한 가지뿐**이다(iOS 배포 인증서).
#
# 배경과 함정은 docs/DEPLOY.md 참조.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"

VERSION="${1:-}"
BUILD="${2:-}"
SKIP_IOS=false
SKIP_ANDROID=false
for a in "$@"; do
  [ "$a" = "--skip-ios" ] && SKIP_IOS=true
  [ "$a" = "--skip-android" ] && SKIP_ANDROID=true
done

if [ -z "$VERSION" ] || [ -z "$BUILD" ]; then
  echo "사용법: ./tool/release.sh <버전> <빌드번호> [--skip-ios] [--skip-android]"
  echo "현재: $(grep '^version:' pubspec.yaml)"
  exit 1
fi

step() { printf '\n\033[1m── %s\033[0m\n' "$*"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$*"; }

FAILED=()

# ─────────────────────────────────────────────────────────────
step "0. 환경 점검"
# ─────────────────────────────────────────────────────────────
# Xcode 라이선스 미동의는 **brew를 통째로 세운다** — Android 설치까지 죽는다.
# 원인을 Android 쪽에서 찾으면 한참 헤맨다. 그래서 맨 먼저 본다.
if ! brew config >/dev/null 2>&1; then
  fail "brew가 동작하지 않는다. Xcode 라이선스 미동의일 가능성이 높다:"
  echo "    sudo xcodebuild -license accept     ← sudo가 필요해 에이전트는 못 한다"
  exit 1
fi
ok "brew 정상 (Xcode 라이선스 통과)"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ "$SKIP_ANDROID" = false ] && [ ! -d "$ANDROID_HOME/platforms" ]; then
  fail "Android SDK가 없다 ($ANDROID_HOME). docs/DEPLOY.md §2 의 설치 절차를 먼저 실행할 것."
  exit 1
fi
[ "$SKIP_ANDROID" = false ] && ok "Android SDK: $ANDROID_HOME"

# ─────────────────────────────────────────────────────────────
step "1. 버전 $VERSION+$BUILD"
# ─────────────────────────────────────────────────────────────
# iOS·Android 모두 pubspec 하나를 참조한다. 스토어 버전과 **반드시** 일치시킨다
# (과거에 iOS 스토어 1.7 ↔ pubspec 1.3.x 로 갈려 업데이트 알림이 거짓양성을 냈다).
CUR=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [ "$CUR" = "$VERSION+$BUILD" ]; then
  ok "이미 $CUR"
else
  sed -i '' "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml
  ok "$CUR → $VERSION+$BUILD"
fi

# ─────────────────────────────────────────────────────────────
step "2. 의존성 + 테스트"
# ─────────────────────────────────────────────────────────────
flutter pub get >/dev/null 2>&1 || { fail "pub get 실패"; exit 1; }
if flutter test 2>&1 | tail -1 | grep -q "All tests passed"; then
  ok "테스트 통과"
else
  fail "테스트 실패 — 중단한다"
  flutter test 2>&1 | tail -20
  exit 1
fi

# ─────────────────────────────────────────────────────────────
if [ "$SKIP_ANDROID" = false ]; then
step "3. Android aab"
# ─────────────────────────────────────────────────────────────
  # GeneratedPluginRegistrant는 **지우고 간다.**
  # integration_test(dev_dependency)가 박힌 낡은 파일이 남아 있으면
  # 릴리스 컴파일이 "package ... does not exist"로 죽는다. Flutter는 이미
  # 존재하는 등록기를 항상 다시 쓰지는 않는다. (docs/DEPLOY.md §5)
  rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java

  if flutter build appbundle --release 2>&1 | tail -40 | grep -q "Built build/app"; then
    AAB="build/app/outputs/bundle/release/app-release.aab"
    ok "$AAB ($(du -h "$AAB" | cut -f1))"
  else
    fail "Android 빌드 실패"
    FAILED+=("android")
  fi
fi

# ─────────────────────────────────────────────────────────────
if [ "$SKIP_IOS" = false ]; then
step "4. iOS 아카이브"
# ─────────────────────────────────────────────────────────────
  # ⚠️ --no-codesign 을 쓰면 안 된다.
  # 아카이브의 Team·SigningIdentity가 비어서 **Xcode Organizer 목록에 안 뜬다.**
  # 개발 인증서로라도 서명해야 Organizer가 읽고, 거기서 배포용으로 재서명한다.
  rm -rf build/ios/archive
  (cd ios && pod install >/dev/null 2>&1)

  flutter build ipa --release --export-options-plist=ios/ExportOptions.plist > /tmp/ios_build.log 2>&1
  ARCHIVE="build/ios/archive/Runner.xcarchive"

  if [ -d "$ARCHIVE" ]; then
    TEAM=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:Team" "$ARCHIVE/Info.plist" 2>/dev/null)
    SIGN=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:SigningIdentity" "$ARCHIVE/Info.plist" 2>/dev/null)
    if [ -z "$TEAM" ]; then
      fail "아카이브에 Team이 비었다 — Organizer에 안 뜬다. 서명 설정 확인 필요."
      FAILED+=("ios-signing")
    else
      ok "아카이브 생성 (Team $TEAM / $SIGN)"
      # Organizer는 프로젝트 build/ 가 아니라 자기 폴더만 읽는다. 옮겨준다.
      DEST="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
      mkdir -p "$DEST"
      rm -rf "$DEST/MarketLens $VERSION ($BUILD).xcarchive"
      cp -R "$ARCHIVE" "$DEST/MarketLens $VERSION ($BUILD).xcarchive"
      ok "Organizer 폴더로 복사: $DEST"
    fi
  else
    fail "iOS 아카이브 생성 실패 — /tmp/ios_build.log 확인"
    grep -E "error:" /tmp/ios_build.log | sort -u | head -5
    FAILED+=("ios")
  fi

  if [ -f build/ios/ipa/*.ipa ] 2>/dev/null; then
    ok "IPA: $(ls build/ios/ipa/*.ipa)"
  else
    printf '\033[33m! IPA 없음 — Apple Distribution 인증서가 필요하다.\033[0m\n'
    echo "    Xcode Organizer → Distribute App 에서 Xcode가 자동 생성한다."
    echo "    (Xcode에 Apple ID 로그인이 되어 있어야 한다: Settings → Accounts)"
  fi
fi

# ─────────────────────────────────────────────────────────────
step "결과"
# ─────────────────────────────────────────────────────────────
[ "$SKIP_ANDROID" = false ] && [ -f build/app/outputs/bundle/release/app-release.aab ] \
  && ok "Android aab — Play Console 업로드 가능"
[ "$SKIP_IOS" = false ] && [ -d build/ios/archive/Runner.xcarchive ] \
  && ok "iOS 아카이브 — Organizer에서 Distribute App"

if [ ${#FAILED[@]} -gt 0 ]; then
  fail "실패: ${FAILED[*]}"
  exit 1
fi
echo
echo "다음: 릴리스 노트는 fastlane/metadata/<로케일>/release_notes.txt 를 갱신할 것."
