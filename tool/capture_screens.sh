#!/bin/bash
# integration_test가 띄우는 SHOT_READY 마커를 보고 simctl로 화면을 찍는다.
#
# iOS integration_test의 takeScreenshot이 매번 같은 이미지를 주는 한계 때문에
# 캡처만 외부로 분리했다. 테스트는 화면을 붙잡아 주고, 촬영은 여기서 한다.
#
#   ./tool/capture_screens.sh <simulator-udid> <log-path>
set -u
UDID="$1"; LOG="$2"
OUT="fastlane/screenshots/_raw"
mkdir -p "$OUT"; rm -f "$OUT"/*.png
seen=""
for _ in $(seq 1 600); do
  markers=$(grep -oE 'SHOT_READY:[0-9a-z_]+' "$LOG" 2>/dev/null | sed 's/SHOT_READY://')
  for m in $markers; do
    case " $seen " in *" $m "*) continue;; esac
    sleep 1.2   # 마커 직후 프레임이 안정될 시간
    xcrun simctl io "$UDID" screenshot "$OUT/$m.png" >/dev/null 2>&1 \
      && echo "  captured $m"
    seen="$seen $m"
  done
  grep -q "All tests passed\|Some tests failed" "$LOG" 2>/dev/null && break
  sleep 1
done
echo "총 $(ls "$OUT" | wc -l | tr -d ' ')장"
