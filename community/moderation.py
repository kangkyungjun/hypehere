import re
import logging
from django.conf import settings
from rest_framework.exceptions import ValidationError

logger = logging.getLogger(__name__)


def check_openai_moderation(text):
    """
    OpenAI Moderation API로 텍스트 검사
    - 무료, ~200ms
    - flagged: true → ValidationError 발생
    - API 키 미설정 시 skip
    """
    api_key = getattr(settings, 'OPENAI_API_KEY', None)
    if not api_key:
        return

    try:
        import httpx
        response = httpx.post(
            'https://api.openai.com/v1/moderations',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            },
            json={'input': text},
            timeout=5.0,
        )
        response.raise_for_status()
        result = response.json()

        if result.get('results') and result['results'][0].get('flagged'):
            categories = result['results'][0].get('categories', {})
            flagged = [k for k, v in categories.items() if v]
            logger.warning(f"Content flagged by OpenAI moderation: {flagged}")
            raise ValidationError({
                'content': '부적절한 내용이 감지되었습니다. 내용을 수정해 주세요.'
            })
    except ValidationError:
        raise
    except Exception as e:
        logger.error(f"OpenAI moderation API error: {e}")
        # API 오류 시 게시글 허용 (fail-open)


def check_banned_keywords(text):
    """
    금칙어 DB 테이블에서 검사
    - 일반 텍스트: 대소문자 무시 포함 검사
    - 정규식: re.search
    """
    from .models import BannedKeyword

    keywords = BannedKeyword.objects.filter(is_active=True)
    text_lower = text.lower()

    for kw in keywords:
        if kw.is_regex:
            try:
                if re.search(kw.keyword, text, re.IGNORECASE):
                    raise ValidationError({
                        'content': '금칙어가 포함되어 있습니다. 내용을 수정해 주세요.'
                    })
            except re.error:
                logger.error(f"Invalid regex pattern in BannedKeyword: {kw.keyword}")
        else:
            if kw.keyword.lower() in text_lower:
                raise ValidationError({
                    'content': '금칙어가 포함되어 있습니다. 내용을 수정해 주세요.'
                })


def moderate_content(text):
    """
    콘텐츠 모더레이션 통합 함수
    1. 금칙어 필터 (DB)
    2. OpenAI Moderation API
    """
    check_banned_keywords(text)
    check_openai_moderation(text)
