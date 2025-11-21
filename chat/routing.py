from django.urls import re_path
from . import consumers
from . import notification_consumer

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<conversation_id>\d+)/$', consumers.ChatConsumer.as_asgi()),
    re_path(r'ws/anonymous-chat/(?P<conversation_id>\d+)/$', consumers.AnonymousChatConsumer.as_asgi()),
    re_path(r'ws/matching/$', consumers.MatchingConsumer.as_asgi()),
    re_path(r'ws/notifications/$', notification_consumer.NotificationConsumer.as_asgi()),
    re_path(r'ws/open-chat/(?P<room_id>\d+)/$', consumers.OpenChatConsumer.as_asgi()),
]
