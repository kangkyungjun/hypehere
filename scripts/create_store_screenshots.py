#!/usr/bin/env python3
"""
Generate App Store marketing screenshots with gradient background, badge,
title, subtitle, and phone mockup composite.

Reads phone mockups from v3_mockups/{lang}/ and produces marketing-ready images
for Apple App Store (6.5" and 6.7") and Google Play Store.

Usage:
    python scripts/create_store_screenshots.py
"""

import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR = Path("assets/screenshots")
MOCKUP_DIR = BASE_DIR / "v3_mockups"
OUT_DIR = BASE_DIR / "v3"

# ---------------------------------------------------------------------------
# Canvas sizes
# ---------------------------------------------------------------------------
CANVAS_6_7 = (1290, 2796)  # iPhone 6.7"
CANVAS_6_5 = (1242, 2688)  # iPhone 6.5"

# ---------------------------------------------------------------------------
# Colors (MarketLens brand blue palette)
# ---------------------------------------------------------------------------
BG_TOP = (219, 234, 254)       # #DBEAFE  blue-100
BG_BOTTOM = (240, 245, 255)    # #F0F5FF  near white
BADGE_BG = (191, 219, 254)     # #BFDBFE  blue-200
BADGE_TEXT = (30, 64, 175)     # #1E40AF  blue-800
TITLE_COLOR = (17, 24, 39)     # #111827  gray-900
SUBTITLE_COLOR = (75, 85, 99)  # #4B5563  gray-600

# ---------------------------------------------------------------------------
# Fonts (macOS system font paths with TTC indices)
# ---------------------------------------------------------------------------
FONT_APPLE_SD = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_HELVETICA = "/System/Library/Fonts/HelveticaNeue.ttc"
FONT_HIRAGINO = "/System/Library/Fonts/Hiragino Sans GB.ttc"

# (ttc_path, bold_index, regular_index)
FONT_MAP = {
    "ko": (FONT_APPLE_SD, 6, 0),    # Bold=idx6, Regular=idx0
    "en": (FONT_HELVETICA, 1, 0),    # Bold=idx1, Regular=idx0
    "ja": (FONT_HIRAGINO, 2, 0),     # W6=idx2, W3=idx0
    "zh": (FONT_HIRAGINO, 2, 0),     # W6=idx2, W3=idx0
    "es": (FONT_HELVETICA, 1, 0),    # Bold=idx1, Regular=idx0
}

# ---------------------------------------------------------------------------
# Text sizes (for 6.7" canvas)
# ---------------------------------------------------------------------------
TITLE_SIZE = 80
SUBTITLE_SIZE = 38
BADGE_FONT_SIZE = 32
BADGE_PADDING_H = 36  # horizontal padding inside pill
BADGE_PADDING_V = 14  # vertical padding inside pill

# ---------------------------------------------------------------------------
# Layout offsets (for 6.7" canvas)
# ---------------------------------------------------------------------------
TOP_MARGIN = 100
BADGE_GAP = 30       # gap between badge and title
TITLE_GAP = 20       # gap between title and subtitle
MOCKUP_GAP = 50      # gap between subtitle and mockup top
MOCKUP_SCALE = 0.78  # scale factor for phone mockup

# ---------------------------------------------------------------------------
# Language groups by timestamp ranges (same as organize_screenshots.py)
# ---------------------------------------------------------------------------
LANG_RANGES = [
    ("ko", "203241", "203523", 9),
    ("en", "203602", "203659", 9),
    ("zh", "203714", "203756", 9),
    ("ja", "203808", "203859", 10),
    ("es", "203911", "203958", 10),
]

TS_PATTERN = re.compile(r"Screenshot_\d{8}_(\d{6})_MarketLens")

# ---------------------------------------------------------------------------
# Screenshot text data: timestamp -> (badge, title, subtitle) per language
# Each timestamp key is the HHMMSS portion from the screenshot filename.
# This ensures correct title-screen matching regardless of capture order.
# ---------------------------------------------------------------------------
SCREENSHOT_TEXT = {
    "ko": {
        "203241": ("", "시장 대시보드", "AI가 분석한 거시경제 동향과\n주요 지수를 한눈에"),
        "203356": ("", "거래 동향", "거래대금 상위 종목과\n상승·하락 랭킹"),
        "203406": ("", "거시경제 지표", "금리·환율·물가 등\n핵심 경제지표 분석"),
        "203424": ("", "금리 차트", "장단기 금리 추이와\n금리차 변동 추적"),
        "203433": ("NEW", "경제 캘린더", "글로벌 경제 이벤트와\n실적 발표 일정 관리"),
        "203440": ("NEW", "AI 뉴스 분석", "24시간 핫 뉴스를\n감성 분석으로 시각화"),
        "203449": ("AI", "AI 시그널", "AI 매매 시그널 분포와\n종목별 추천 확인"),
        "203506": ("AI", "종목 AI 분석", "AI 목표가·투자의견\n종합 분석 리포트"),
        "203523": ("NEW", "포트폴리오 관리", "보유 종목 수익률과\nAI 포트폴리오 진단"),
    },
    "en": {
        "203602": ("", "Market Dashboard", "AI-analyzed macro trends\nand key indices at a glance"),
        "203612": ("", "Sector Overview", "Real-time sector heatmap\nand market cap rankings"),
        "203619": ("", "Trading Activity", "Top stocks by volume\nand gainers & losers"),
        "203623": ("", "Macro Indicators", "Interest rates, FX, CPI\nand key economic metrics"),
        "203633": ("", "Rate Charts", "Track long & short-term\nrate trends and spreads"),
        "203638": ("NEW", "Economic Calendar", "Global economic events\nand earnings schedule"),
        "203644": ("NEW", "AI News Analysis", "24h hot news visualized\nby sentiment analysis"),
        "203648": ("NEW", "Portfolio Manager", "Track holdings P&L\nwith AI portfolio insights"),
        "203659": ("NEW", "Earnings Calendar", "Track upcoming earnings\nand economic releases"),
    },
    "ja": {
        "203808": ("", "マーケット", "AIが分析したマクロ経済と\n主要指数を一目で確認"),
        "203813": ("", "セクター分析", "セクター別ヒートマップで\n市場全体を把握"),
        "203818": ("", "取引動向", "売買代金上位銘柄と\n上昇・下落ランキング"),
        "203822": ("", "マクロ経済指標", "金利・為替・物価など\n重要経済指標を分析"),
        "203827": ("", "金利チャート", "長短期金利の推移と\nスプレッド変動を追跡"),
        "203833": ("NEW", "経済カレンダー", "グローバル経済イベントと\n決算発表スケジュール"),
        "203843": ("NEW", "AIニュース分析", "24時間ホットニュースを\nセンチメント分析で可視化"),
        "203848": ("AI", "AIシグナル", "AI売買シグナル分布と\n銘柄別レコメンド"),
        "203852": ("NEW", "ポートフォリオ管理", "保有銘柄の収益率と\nAIポートフォリオ診断"),
        "203859": ("AI", "銘柄AI分析", "AI目標株価と投資意見\n総合分析レポート"),
    },
    "zh": {
        "203714": ("", "市场仪表盘", "AI分析的宏观经济趋势\n和主要指数一目了然"),
        "203722": ("", "板块概览", "实时板块热力图\n和市值排名"),
        "203726": ("", "交易动态", "成交量排名靠前的股票\n及涨跌排行榜"),
        "203731": ("", "宏观经济指标", "利率、汇率、物价等\n关键经济指标分析"),
        "203735": ("", "利率图表", "追踪长短期利率走势\n和利差变动"),
        "203741": ("NEW", "经济日历", "全球经济事件和\n财报发布日程管理"),
        "203746": ("NEW", "AI新闻分析", "24小时热门新闻\n情绪分析可视化"),
        "203751": ("AI", "AI信号", "AI交易信号分布与\n个股推荐一览"),
        "203756": ("NEW", "投资组合管理", "持仓收益率追踪\n与AI投资组合诊断"),
    },
    "es": {
        "203911": ("", "Panel del Mercado", "Tendencias macro analizadas\npor IA e índices clave"),
        "203917": ("", "Análisis Sectorial", "Mapa de calor sectorial\npara visión de mercado"),
        "203921": ("", "Actividad Bursátil", "Acciones más negociadas\ny ranking de alzas y bajas"),
        "203925": ("", "Indicadores Macro", "Tasas de interés, divisas\ne indicadores económicos"),
        "203929": ("", "Gráfico de Tasas", "Seguimiento de tasas\na corto y largo plazo"),
        "203937": ("NEW", "Calendario Económico", "Eventos económicos globales\ny calendario de resultados"),
        "203941": ("NEW", "Análisis de Noticias", "Noticias 24h visualizadas\npor análisis de sentimiento"),
        "203946": ("AI", "Señales IA", "Distribución de señales IA\ny recomendaciones"),
        "203953": ("AI", "Análisis IA", "Precio objetivo IA y\nanálisis integral"),
        "203958": ("NEW", "Gestión de Cartera", "Seguimiento de rentabilidad\ncon diagnóstico IA"),
    },
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def extract_hhmmss(filename: str) -> str | None:
    m = TS_PATTERN.search(filename)
    return m.group(1) if m else None


def group_by_language(files: list[Path]) -> dict[str, list[Path]]:
    lang_map = {lang: [] for lang, *_ in LANG_RANGES}
    for f in files:
        ts = extract_hhmmss(f.name)
        if ts is None:
            continue
        for lang, start, end, _ in LANG_RANGES:
            if start <= ts <= end:
                lang_map[lang].append(f)
                break
    return lang_map


def load_font(lang: str, bold: bool, size: int) -> ImageFont.FreeTypeFont:
    ttc_path, bold_idx, regular_idx = FONT_MAP[lang]
    idx = bold_idx if bold else regular_idx
    return ImageFont.truetype(ttc_path, size, index=idx)


def draw_gradient(img: Image.Image, top_color: tuple, bottom_color: tuple):
    """Draw a vertical linear gradient on the image."""
    w, h = img.size
    pixels = img.load()
    for y in range(h):
        ratio = y / (h - 1)
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * ratio)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * ratio)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * ratio)
        for x in range(w):
            pixels[x, y] = (r, g, b)


def draw_pill_badge(draw: ImageDraw.ImageDraw, text: str, cx: int, y: int,
                    font: ImageFont.FreeTypeFont):
    """Draw a pill-shaped badge centered at cx, top at y."""
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    pill_w = tw + BADGE_PADDING_H * 2
    pill_h = th + BADGE_PADDING_V * 2
    pill_r = pill_h // 2

    x0 = cx - pill_w // 2
    y0 = y
    x1 = x0 + pill_w
    y1 = y0 + pill_h

    draw.rounded_rectangle([x0, y0, x1, y1], radius=pill_r, fill=BADGE_BG)
    text_x = x0 + BADGE_PADDING_H - bbox[0]
    text_y = y0 + BADGE_PADDING_V - bbox[1]
    draw.text((text_x, text_y), text, fill=BADGE_TEXT, font=font)

    return pill_h


def create_marketing_screenshot(
    mockup_path: Path,
    badge: str,
    title: str,
    subtitle: str,
    lang: str,
    canvas_size: tuple[int, int] = CANVAS_6_7,
) -> Image.Image:
    """Create a single marketing screenshot image."""
    cw, ch = canvas_size

    # 1. Gradient background
    img = Image.new("RGB", canvas_size)
    draw_gradient(img, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    # Scale factor relative to 6.7" reference
    scale = cw / CANVAS_6_7[0]
    s = lambda v: int(v * scale)

    # Load fonts
    font_title = load_font(lang, bold=True, size=s(TITLE_SIZE))
    font_subtitle = load_font(lang, bold=False, size=s(SUBTITLE_SIZE))
    font_badge = load_font(lang, bold=True, size=s(BADGE_FONT_SIZE))

    cx = cw // 2
    cursor_y = s(TOP_MARGIN)

    # 2. Badge (if non-empty)
    if badge:
        pill_h = draw_pill_badge(draw, badge, cx, cursor_y, font_badge)
        cursor_y += pill_h + s(BADGE_GAP)

    # 3. Title (centered)
    title_bbox = draw.textbbox((0, 0), title, font=font_title)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text((cx - title_w // 2, cursor_y), title, fill=TITLE_COLOR, font=font_title)
    title_h = title_bbox[3] - title_bbox[1]
    cursor_y += title_h + s(TITLE_GAP)

    # 4. Subtitle (centered, multiline)
    for line in subtitle.split("\n"):
        line_bbox = draw.textbbox((0, 0), line, font=font_subtitle)
        line_w = line_bbox[2] - line_bbox[0]
        line_h = line_bbox[3] - line_bbox[1]
        draw.text((cx - line_w // 2, cursor_y), line,
                  fill=SUBTITLE_COLOR, font=font_subtitle)
        cursor_y += line_h + s(8)

    cursor_y += s(MOCKUP_GAP)

    # 5. Phone mockup
    mockup = Image.open(mockup_path)
    mock_w = int(mockup.width * MOCKUP_SCALE * scale)
    mock_h = int(mockup.height * MOCKUP_SCALE * scale)
    mockup = mockup.resize((mock_w, mock_h), Image.LANCZOS)

    # Center horizontally, place top at cursor_y (may extend below canvas = natural crop)
    mx = cx - mock_w // 2
    my = cursor_y

    # Paste with alpha if RGBA
    if mockup.mode == "RGBA":
        img.paste(mockup, (mx, my), mockup)
    else:
        img.paste(mockup, (mx, my))

    return img


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Collect raw JPGs from language subfolders for timestamp grouping
    raw_dir = BASE_DIR / "v3_raw"
    if not raw_dir.is_dir():
        print(f"Error: raw directory not found: {raw_dir}")
        sys.exit(1)

    # Support both flat and organized (lang subfolder) layouts
    raw_files = sorted(raw_dir.glob("*.jpg"))
    if not raw_files:
        raw_files = sorted(raw_dir.glob("*/*.jpg"))
    print(f"Found {len(raw_files)} raw screenshots")

    lang_map = group_by_language(raw_files)

    # Verify counts
    ok = True
    for lang, start, end, expected in LANG_RANGES:
        actual = len(lang_map[lang])
        if actual != expected:
            ok = False
            print(f"  {lang}: {actual}/{expected} files [MISMATCH]")
        else:
            print(f"  {lang}: {actual}/{expected} files [OK]")
    if not ok:
        print("Error: file count mismatch")
        sys.exit(1)

    # Verify text data counts
    for lang, _, _, expected in LANG_RANGES:
        text_count = len(SCREENSHOT_TEXT[lang])
        if text_count != expected:
            print(f"  Warning: {lang} has {text_count} text entries but {expected} screenshots")
    print()

    total = 0
    for lang, files in lang_map.items():
        texts = SCREENSHOT_TEXT[lang]

        # Create output directories
        for size_name in ("6.5", "6.7"):
            (OUT_DIR / "apple" / lang / "captures" / size_name).mkdir(
                parents=True, exist_ok=True)
        (OUT_DIR / "google" / lang / "captures").mkdir(parents=True, exist_ok=True)

        # Mockup dir: try lang subfolder first, then flat
        lang_mockup_dir = MOCKUP_DIR / lang
        if not lang_mockup_dir.is_dir():
            lang_mockup_dir = MOCKUP_DIR

        for raw_file in files:
            stem = raw_file.stem  # Screenshot_20260528_203241_MarketLens
            ts = extract_hhmmss(raw_file.name)
            if ts is None or ts not in texts:
                print(f"  Warning: no text mapping for {raw_file.name} (ts={ts})")
                continue

            mockup_src = lang_mockup_dir / f"{stem}-portrait.png"

            if not mockup_src.exists():
                print(f"  Warning: mockup not found: {mockup_src}")
                continue

            badge, title, subtitle = texts[ts]

            # 6.7" (primary)
            img_6_7 = create_marketing_screenshot(
                mockup_src, badge, title, subtitle, lang, CANVAS_6_7)
            out_6_7 = (OUT_DIR / "apple" / lang / "captures" / "6.7"
                       / f"{stem}-portrait.png")
            img_6_7.save(out_6_7, "PNG")

            # 6.5" (resized from 6.7")
            img_6_5 = img_6_7.resize(CANVAS_6_5, Image.LANCZOS)
            out_6_5 = (OUT_DIR / "apple" / lang / "captures" / "6.5"
                       / f"{stem}-portrait.png")
            img_6_5.save(out_6_5, "PNG")

            # Google (same as 6.7")
            out_google = (OUT_DIR / "google" / lang / "captures"
                          / f"{stem}.png")
            img_6_7.save(out_google, "PNG")

            total += 1

        count = len(files)
        print(f"  {lang}: {count} marketing screenshots -> "
              f"{count * 2} Apple captures + {count} Google captures")

    print(f"\nDone. Generated {total} marketing screenshots into {OUT_DIR}")

    # Verification
    print("\n--- Verification ---")
    apple_sizes = {"6.5": CANVAS_6_5, "6.7": CANVAS_6_7}
    for lang, _, _, _ in LANG_RANGES:
        for size_name, (w, h) in apple_sizes.items():
            cap_dir = OUT_DIR / "apple" / lang / "captures" / size_name
            pngs = sorted(cap_dir.glob("*.png"))
            if pngs:
                sample = Image.open(pngs[0])
                ok_str = ("OK" if sample.size == (w, h) and sample.mode == "RGB"
                          else f"MISMATCH size={sample.size} mode={sample.mode}")
                print(f"  apple/{lang}/captures/{size_name}: "
                      f"{len(pngs)} files, {sample.size} {sample.mode} [{ok_str}]")
            else:
                print(f"  apple/{lang}/captures/{size_name}: 0 files [EMPTY]")

        google_dir = OUT_DIR / "google" / lang / "captures"
        pngs = list(google_dir.glob("*.png"))
        if pngs:
            sample = Image.open(pngs[0])
            print(f"  google/{lang}/captures: {len(pngs)} files, "
                  f"{sample.size} {sample.mode}")


if __name__ == "__main__":
    main()
