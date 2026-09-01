#!/usr/bin/env python3
"""앱스토어 스크린샷에 기기 목업 프레임을 씌운다.

## 왜 이런 방식인가
기존(1.9.0 이전) 스크린샷은 다이나믹 아일랜드·카메라까지 있는 **실사 목업**을
쓰는데, 원본 프레임 에셋이 레포에 없다. 그래서 **기존 스크린샷 자체를 템플릿으로
재사용**한다 — 화면 영역만 새 캡처로 덮어쓰면 베젤·배경은 그대로 유지된다.

## 역산한 규격 (기존 파일에서 측정)
| 규격 | 캔버스 | 화면 영역 | 종횡비 |
|---|---|---|---|
| 6.7" | 1290×2796 | (56, 264) 1178×2293 | 0.5137 |
| 6.5" | 1242×2688 | (54, 254) 1134×2204 | 0.5145 |

원본 캡처(1290×2796)에서 **상태바 186px + 홈인디케이터 102px**를 잘라내면
1290×2508 → 비 0.5144로 화면 영역과 일치한다. 즉 기존 워크플로가 그랬다.

## 사용
    python3 tool/frame_screenshots.py
      --raw fastlane/screenshots/_raw \
      --out fastlane/screenshots \
      --locales en-US,en-GB,en-AU,en-CA,es-ES,es-MX,ja,zh-Hans,zh-Hant,ko
"""

import argparse
import pathlib
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit('Pillow 필요: pip3 install Pillow')

REPO = pathlib.Path(__file__).resolve().parent.parent

# 규격별: (캔버스, 화면 영역 좌상단, 화면 영역 크기)
SPECS = {
    '6.7': ((1290, 2796), (56, 264), (1178, 2293)),
    '6.5': ((1242, 2688), (54, 254), (1134, 2204)),
}

# 원본 캡처에서 잘라낼 영역(3x 픽셀). 상태바와 홈인디케이터는 목업 베젤이
# 대신 표현하므로 앱 콘텐츠만 남긴다.
CROP_TOP = 186
CROP_BOTTOM = 102


def template(size_tag: str, out_root: pathlib.Path) -> Image.Image:
    """기존 스크린샷을 프레임 템플릿으로 쓴다."""
    for loc in ('en-US', 'en-GB', 'ja'):
        p = out_root / loc / f'iPhone_{size_tag}_01.png'
        if p.exists():
            return Image.open(p).convert('RGB')
    raise FileNotFoundError(
        f'{size_tag}" 템플릿을 찾지 못했다. 기존 스크린샷이 최소 1장 필요하다.')


def frame_one(raw: pathlib.Path, size_tag: str, tpl: Image.Image) -> Image.Image:
    canvas_size, origin, screen_size = SPECS[size_tag]
    shot = Image.open(raw).convert('RGB')

    if shot.size != canvas_size:
        # 다른 규격으로 찍혔으면 캔버스 비율에 맞춰 먼저 정규화한다.
        shot = shot.resize(canvas_size, Image.LANCZOS)

    w, h = shot.size
    content = shot.crop((0, CROP_TOP, w, h - CROP_BOTTOM))
    content = content.resize(screen_size, Image.LANCZOS)

    out = tpl.copy()
    out.paste(content, origin)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--raw', default='fastlane/screenshots/_raw')
    ap.add_argument('--out', default='fastlane/screenshots')
    ap.add_argument('--locales', default='en-US')
    args = ap.parse_args()

    raw_dir = REPO / args.raw
    out_root = REPO / args.out
    locales = [s.strip() for s in args.locales.split(',') if s.strip()]

    raws = sorted(raw_dir.glob('*.png'))
    if not raws:
        sys.exit(f'{raw_dir}에 캡처가 없다. integration_test를 먼저 돌려라.')
    if len(raws) != 8:
        print(f'⚠ 캡처가 {len(raws)}장이다(앱스토어 권장 8장).')

    for size_tag in SPECS:
        tpl = template(size_tag, out_root)
        for i, raw in enumerate(raws, start=1):
            img = frame_one(raw, size_tag, tpl)
            name = f'iPhone_{size_tag}_{i:02d}.png'
            for loc in locales:
                d = out_root / loc
                d.mkdir(parents=True, exist_ok=True)
                img.save(d / name)
        print(f'  {size_tag}" · {len(raws)}장 × {len(locales)}로케일 완료')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
