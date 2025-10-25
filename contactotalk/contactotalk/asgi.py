"""
ASGI config for contactotalk project.

Django Channels를 사용한 WebSocket 지원 ASGI 설정
"""

import os

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "contactotalk.settings")

# Django ASGI application을 먼저 초기화 (ORM 사용을 위해)
django_asgi_app = get_asgi_application()

# WebSocket routing import (순환 참조 방지를 위해 django_asgi_app 초기화 후 import)
from chat import routing as chat_routing
from chat.middleware import JWTAuthMiddlewareStack

application = ProtocolTypeRouter(
    {
        # HTTP 요청은 Django의 ASGI application이 처리
        "http": django_asgi_app,
        # WebSocket 요청은 Channels가 처리 (JWT 인증 사용)
        "websocket": AllowedHostsOriginValidator(
            JWTAuthMiddlewareStack(URLRouter(chat_routing.websocket_urlpatterns))
        ),
    }
)
