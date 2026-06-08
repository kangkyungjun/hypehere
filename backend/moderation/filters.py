"""
콘텐츠 모더레이션 필터 (Apple Guideline 1.2 (b) 대응)

게시글/댓글 생성 시 객관적으로 부적절한 표현(욕설/혐오/성적 표현 등)을
탐지하여 차단한다. 다국어(영어/한국어) 핵심 금칙어를 기반으로 하며,
우회를 막기 위해 공백/특수문자/반복문자를 정규화한 뒤 매칭한다.

정책: 무관용(zero-tolerance). 금칙어가 탐지되면 생성을 거부한다.
"""

import re
import unicodedata

# 핵심 금칙어 (소문자 기준). 우회 방지를 위해 정규화 후 부분 매칭.
# 과도한 오탐(false positive)을 피하기 위해 명백한 욕설/혐오 표현 위주로 선별.
_BANNED_WORDS = {
    # English profanity / slurs
    "fuck", "fucker", "fucking", "motherfucker", "shit", "bullshit",
    "asshole", "bitch", "bastard", "cunt", "dick", "pussy", "slut", "whore",
    "faggot", "nigger", "nigga", "retard", "rape", "rapist",
    "kill yourself", "kys",
    # Korean profanity / slurs
    "시발", "씨발", "시바", "씨바", "씨발놈", "시발놈", "개새끼", "새끼",
    "병신", "지랄", "좆", "좇", "존나", "썅", "쌍놈", "닥쳐", "꺼져",
    "엿먹어", "보지", "자지", "creampie", "포르노", "야동",
    "죽어버려", "자살해", "꼴페미", "한남충", "김치녀", "맘충",
}

# 정규화 시 제거할 문자 (우회 방지: f.u.c.k, s h i t 등)
_NOISE_RE = re.compile(r"[\s\.\-_*~`'\"!@#$%^&()\[\]{}<>+=|\\/:;,?]+")
# 동일 문자 반복 → 1회로 축약 (fuuuuck → fuck, 시이이발 → 시발)
_REPEAT_RE = re.compile(r"(.)\1+")


def _strip_noise(text: str) -> str:
    return _NOISE_RE.sub("", text)


def _collapse(text: str) -> str:
    return _REPEAT_RE.sub(r"\1", text)


def find_objectionable(text: str):
    """탐지된 첫 금칙어를 반환. 없으면 None."""
    if not text:
        return None
    raw_lower = unicodedata.normalize("NFKC", text).lower()
    # 노이즈 제거 변형 + 반복문자 축약 변형 모두에서 검사 (우회 방지)
    no_noise = _strip_noise(raw_lower)
    collapsed = _collapse(no_noise)
    for word in _BANNED_WORDS:
        compact = _strip_noise(word)
        if word in raw_lower:
            return word
        if compact and (compact in no_noise or _collapse(compact) in collapsed):
            return word
    return None


def contains_objectionable(text: str) -> bool:
    """부적절 표현 포함 여부."""
    return find_objectionable(text) is not None
