"""
WebSocket URL routing for chat app
"""

from django.urls import path
from . import consumers

websocket_urlpatterns = [
    # 1:1 채팅방 WebSocket 연결: /ws/chat/<room_id>/
    path("ws/chat/<int:room_id>/", consumers.ChatConsumer.as_asgi()),
    # 오픈 채팅방 WebSocket 연결: /ws/open-chat/<room_id>/
    path("ws/open-chat/<int:room_id>/", consumers.OpenChatConsumer.as_asgi()),
]
