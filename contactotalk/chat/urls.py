from django.urls import path
from .views import (
    StartMatchingAPIView,
    CancelMatchingAPIView,
    MatchingStatusAPIView,
    ChatRoomListAPIView,
    ChatRoomDetailAPIView,
    LeaveChatRoomAPIView,
    MessageListAPIView,
    MessageCreateAPIView,
    MarkMessagesAsReadAPIView,
    BlockUserAPIView,
    UnblockUserAPIView,
    BlockedUserListAPIView,
    # 오픈 채팅
    OpenChatRoomListCreateAPIView,
    OpenChatRoomDetailAPIView,
    OpenChatRoomDeleteAPIView,
    OpenChatRoomJoinAPIView,
    OpenChatRoomLeaveAPIView,
    OpenChatRoomParticipantsAPIView,
    OpenChatMessageListAPIView,
    OpenChatMessageCreateAPIView,
    # 매칭 이력
    MatchHistoryListAPIView,
)

app_name = "chat"

urlpatterns = [
    # 매칭
    path("matching/start/", StartMatchingAPIView.as_view(), name="matching_start"),
    path("matching/cancel/", CancelMatchingAPIView.as_view(), name="matching_cancel"),
    path("matching/status/", MatchingStatusAPIView.as_view(), name="matching_status"),

    # 1:1 채팅방
    path("rooms/", ChatRoomListAPIView.as_view(), name="room_list"),
    path("rooms/<int:pk>/", ChatRoomDetailAPIView.as_view(), name="room_detail"),
    path("rooms/<int:room_id>/leave/", LeaveChatRoomAPIView.as_view(), name="room_leave"),

    # 1:1 메시지
    path("rooms/<int:room_id>/messages/", MessageListAPIView.as_view(), name="message_list"),
    path("rooms/<int:room_id>/messages/send/", MessageCreateAPIView.as_view(), name="message_send"),
    path("rooms/<int:room_id>/messages/read/", MarkMessagesAsReadAPIView.as_view(), name="message_read"),

    # 차단
    path("block/", BlockUserAPIView.as_view(), name="block_user"),
    path("unblock/<int:user_id>/", UnblockUserAPIView.as_view(), name="unblock_user"),
    path("blocked/", BlockedUserListAPIView.as_view(), name="blocked_list"),

    # 매칭 이력
    path("match-history/", MatchHistoryListAPIView.as_view(), name="match_history"),

    # 오픈 채팅방
    path("open/rooms/", OpenChatRoomListCreateAPIView.as_view(), name="open_room_list_create"),
    path("open/rooms/<int:pk>/", OpenChatRoomDetailAPIView.as_view(), name="open_room_detail"),
    path("open/rooms/<int:pk>/delete/", OpenChatRoomDeleteAPIView.as_view(), name="open_room_delete"),
    path("open/rooms/<int:pk>/join/", OpenChatRoomJoinAPIView.as_view(), name="open_room_join"),
    path("open/rooms/<int:pk>/leave/", OpenChatRoomLeaveAPIView.as_view(), name="open_room_leave"),
    path("open/rooms/<int:pk>/participants/", OpenChatRoomParticipantsAPIView.as_view(), name="open_room_participants"),

    # 오픈 채팅 메시지
    path("open/rooms/<int:room_id>/messages/", OpenChatMessageListAPIView.as_view(), name="open_message_list"),
    path("open/rooms/<int:room_id>/messages/send/", OpenChatMessageCreateAPIView.as_view(), name="open_message_send"),
]
