from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# REST API Router
router = DefaultRouter()
router.register(r'conversations', views.ConversationViewSet, basename='conversation')
router.register(r'open-rooms', views.OpenChatRoomViewSet, basename='open-room')

app_name = 'chat'

urlpatterns = [
    # Template views - 1:1 Chat
    path('', views.messages_list_view, name='messages'),
    path('<int:conversation_id>/', views.conversation_detail_view, name='conversation_detail'),

    # Template views - Open Chat
    path('open/', views.open_chat_list_view, name='open_chat_list'),
    path('open/<int:room_id>/', views.open_chat_room_view, name='open_chat_room'),

    # API endpoints
    path('', include(router.urls)),
    path('conversations/<int:pk>/leave/', views.leave_conversation, name='leave_conversation'),
    path('unread-count/', views.get_total_unread_count, name='total_unread_count'),

    # Anonymous Chat API endpoints
    path('matching/preference/', views.matching_preference_view, name='matching_preference'),
    path('matching/start/', views.start_matching_view, name='start_matching'),
    path('matching/stop/', views.stop_matching_view, name='stop_matching'),
    path('anonymous/connection-request/', views.connection_request_view, name='connection_request'),
    path('anonymous/connection-respond/', views.connection_respond_view, name='connection_respond'),
    path('report/', views.report_user_view, name='report_user'),
    path('anonymous/follow/', views.follow_from_anonymous_view, name='follow_from_anonymous'),
]
