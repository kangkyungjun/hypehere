"""
WebSocket consumers for real-time chat
"""

import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import ChatRoom, Message, OpenChatRoom, OpenChatParticipant, OpenChatMessage

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    """
    실시간 채팅을 위한 WebSocket Consumer

    URL: /ws/chat/<room_id>/
    """

    async def connect(self):
        """WebSocket 연결 시 호출"""

        # URL에서 room_id 가져오기
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.room_group_name = f"chat_{self.room_id}"

        # 사용자 인증 확인
        self.user = self.scope["user"]

        if not self.user.is_authenticated:
            # 인증되지 않은 사용자는 연결 거부
            await self.close()
            return

        # 채팅방 권한 확인
        is_member = await self.check_room_membership()

        if not is_member:
            # 채팅방 멤버가 아니면 연결 거부
            await self.close()
            return

        # 그룹에 참여
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)

        # WebSocket 연결 수락
        await self.accept()

        # 연결 성공 메시지 전송
        await self.send(
            text_data=json.dumps(
                {
                    "type": "connection_established",
                    "message": f"채팅방 {self.room_id}에 연결되었습니다.",
                }
            )
        )

        # 상대방에게 입장 알림 전송
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "user_joined_notification",
                "user_id": self.user.id,
                "user_nickname": self.user.nickname,
            }
        )

    async def disconnect(self, close_code):
        """WebSocket 연결 종료 시 호출"""

        # 상대방에게 퇴장 알림 전송
        if hasattr(self, 'room_group_name') and hasattr(self, 'user'):
            # DB에 사용자 퇴장 상태 기록
            await self.mark_user_as_left()

            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "user_left_notification",
                    "user_id": self.user.id,
                    "user_nickname": self.user.nickname,
                }
            )

        # 그룹에서 나가기
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        """클라이언트로부터 메시지 수신 시 호출"""

        try:
            data = json.loads(text_data)
            message_type = data.get("type", "message")

            if message_type == "message":
                # 일반 채팅 메시지
                content = data.get("content", "").strip()

                if not content:
                    await self.send(
                        text_data=json.dumps(
                            {"type": "error", "message": "메시지 내용을 입력해주세요."}
                        )
                    )
                    return

                # 메시지 DB에 저장
                message = await self.save_message(content)

                if message:
                    # 고스트 메시지 처리
                    if message.get("is_ghost", False):
                        # 차단 당한 경우: 본인에게만 전송 (상대방에게 전송 안 됨)
                        await self.send(
                            text_data=json.dumps(
                                {
                                    "type": "message",
                                    "message": {
                                        "id": message["id"],
                                        "room": int(self.room_id),
                                        "sender": {
                                            "id": message["sender_id"],
                                            "nickname": message["sender_nickname"],
                                            "username": "",
                                            "email": "",
                                            "country_code": ""
                                        },
                                        "message_type": "text",
                                        "content": message["content"],
                                        "is_read": False,
                                        "created_at": message["created_at"]
                                    }
                                }
                            )
                        )
                    else:
                        # 정상 메시지: 그룹 전체에 브로드캐스트
                        await self.channel_layer.group_send(
                            self.room_group_name,
                            {
                                "type": "chat_message",
                                "message_id": message["id"],
                                "content": message["content"],
                                "sender_id": message["sender_id"],
                                "sender_nickname": message["sender_nickname"],
                                "created_at": message["created_at"],
                            },
                        )

            elif message_type == "typing":
                # 타이핑 상태 전달
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "typing_indicator",
                        "user_id": self.user.id,
                        "user_nickname": self.user.nickname,
                        "is_typing": data.get("is_typing", False),
                    },
                )

            elif message_type == "read":
                # 메시지 읽음 처리
                await self.mark_messages_as_read()

                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "messages_read",
                        "user_id": self.user.id,
                    },
                )

        except json.JSONDecodeError:
            await self.send(
                text_data=json.dumps(
                    {"type": "error", "message": "잘못된 메시지 형식입니다."}
                )
            )
        except Exception as e:
            await self.send(
                text_data=json.dumps(
                    {"type": "error", "message": f"오류가 발생했습니다: {str(e)}"}
                )
            )

    async def chat_message(self, event):
        """채팅 메시지를 클라이언트에게 전송"""

        await self.send(
            text_data=json.dumps(
                {
                    "type": "message",
                    "message": {
                        "id": event["message_id"],
                        "room": int(self.room_id),
                        "sender": {
                            "id": event["sender_id"],
                            "nickname": event["sender_nickname"],
                            "username": "",
                            "email": "",
                            "country_code": ""
                        },
                        "message_type": "text",
                        "content": event["content"],
                        "is_read": False,
                        "created_at": event["created_at"]
                    }
                }
            )
        )


    async def typing_indicator(self, event):
        """타이핑 상태를 클라이언트에게 전송"""

        # 본인의 타이핑 상태는 전송하지 않음
        if event["user_id"] != self.user.id:
            await self.send(
                text_data=json.dumps(
                    {
                        "type": "typing",
                        "user_id": event["user_id"],
                        "user_nickname": event["user_nickname"],
                        "is_typing": event["is_typing"],
                    }
                )
            )

    async def messages_read(self, event):
        """메시지 읽음 상태를 클라이언트에게 전송"""

        await self.send(
            text_data=json.dumps(
                {
                    "type": "read",
                    "user_id": event["user_id"],
                }
            )
        )


    async def user_joined_notification(self, event):
        """사용자 입장 알림을 클라이언트에게 전송"""

        # 본인에게는 입장 알림을 보내지 않음
        if event["user_id"] != self.user.id:
            await self.send(
                text_data=json.dumps(
                    {
                        "type": "user_joined",
                        "user_nickname": event["user_nickname"],
                        "message": f"{event['user_nickname']}님이 입장했습니다.",
                    }
                )
            )

    async def user_left_notification(self, event):
        """사용자 퇴장 알림을 클라이언트에게 전송"""

        # 본인에게는 퇴장 알림을 보내지 않음
        if event["user_id"] != self.user.id:
            await self.send(
                text_data=json.dumps(
                    {
                        "type": "user_left",
                        "user_nickname": event["user_nickname"],
                        "message": f"{event['user_nickname']}님이 퇴장했습니다.",
                    }
                )
            )

    @database_sync_to_async
    def check_room_membership(self):
        """채팅방 멤버십 확인"""

        try:
            room = ChatRoom.objects.get(id=self.room_id)
            return room.user1 == self.user or room.user2 == self.user
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content):
        """메시지 DB에 저장"""
        from .models import BlockedUser

        try:
            room = ChatRoom.objects.get(id=self.room_id)

            # 사용자가 나간 채팅방인지 확인
            if (room.user1 == self.user and room.user1_left) or (
                room.user2 == self.user and room.user2_left
            ):
                return None

            # 상대방 확인
            other_user = room.user2 if room.user1 == self.user else room.user1

            # 상대방이 나를 차단했는지 확인
            is_blocked_by_other = BlockedUser.objects.filter(
                user=other_user,
                blocked_user=self.user
            ).exists()

            # 메시지 생성 (차단 당한 경우 blocked_for_user 설정)
            message = Message.objects.create(
                room=room,
                sender=self.user,
                content=content,
                blocked_for_user=other_user if is_blocked_by_other else None
            )

            return {
                "id": message.id,
                "content": message.content,
                "sender_id": message.sender.id,
                "sender_nickname": message.sender.nickname,
                "created_at": message.created_at.isoformat(),
                "is_ghost": is_blocked_by_other  # 고스트 메시지 플래그
            }

        except ChatRoom.DoesNotExist:
            return None

    @database_sync_to_async
    def mark_messages_as_read(self):
        """메시지 읽음 처리"""

        try:
            room = ChatRoom.objects.get(id=self.room_id)

            # 상대방이 보낸 읽지 않은 메시지를 모두 읽음 처리
            Message.objects.filter(room=room, is_read=False).exclude(
                sender=self.user
            ).update(is_read=True)

        except ChatRoom.DoesNotExist:
            pass

    @database_sync_to_async
    def mark_user_as_left(self):
        """사용자 퇴장 상태 DB에 기록"""

        try:
            room = ChatRoom.objects.get(id=self.room_id)
            room.mark_user_left(self.user)

            # 한 명이라도 나가면 즉시 비활성화
            room.is_active = False
            room.save(update_fields=['is_active', 'updated_at'])

        except ChatRoom.DoesNotExist:
            pass


class OpenChatConsumer(AsyncWebsocketConsumer):
    """
    오픈 채팅방을 위한 WebSocket Consumer

    URL: /ws/open-chat/<room_id>/
    """

    async def connect(self):
        """WebSocket 연결 시 호출"""

        # URL에서 room_id 가져오기
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.room_group_name = f"open_chat_{self.room_id}"

        # 사용자 인증 확인
        self.user = self.scope["user"]

        if not self.user.is_authenticated:
            # 인증되지 않은 사용자는 연결 거부
            await self.close()
            return

        # 채팅방 참여 확인
        is_participant = await self.check_room_participation()

        if not is_participant:
            # 참여자가 아니면 연결 거부
            await self.close()
            return

        # 그룹에 참여
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)

        # WebSocket 연결 수락
        await self.accept()

        # 연결 성공 메시지 전송
        await self.send(
            text_data=json.dumps(
                {
                    "type": "connection_established",
                    "message": f"오픈 채팅방 {self.room_id}에 연결되었습니다.",
                }
            )
        )

    async def disconnect(self, close_code):
        """WebSocket 연결 종료 시 호출"""

        # 상대방에게 퇴장 알림 전송
        if hasattr(self, 'room_group_name') and hasattr(self, 'user') and self.user.is_authenticated:
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "user_left_notification",
                    "user_id": self.user.id,
                    "user_nickname": self.user.nickname,
                }
            )

        # 그룹에서 나가기
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        """클라이언트로부터 메시지 수신 시 호출"""

        try:
            data = json.loads(text_data)
            message_type = data.get("type", "message")

            if message_type == "message":
                # 일반 채팅 메시지
                content = data.get("content", "").strip()

                if not content:
                    await self.send(
                        text_data=json.dumps(
                            {"type": "error", "message": "메시지 내용을 입력해주세요."}
                        )
                    )
                    return

                # 메시지 DB에 저장
                message = await self.save_message(content)

                if message:
                    # 그룹의 모든 클라이언트에게 메시지 브로드캐스트
                    await self.channel_layer.group_send(
                        self.room_group_name,
                        {
                            "type": "chat_message",
                            "message": message,
                        },
                    )

        except json.JSONDecodeError:
            await self.send(
                text_data=json.dumps(
                    {"type": "error", "message": "잘못된 메시지 형식입니다."}
                )
            )
        except Exception as e:
            await self.send(
                text_data=json.dumps(
                    {"type": "error", "message": f"오류가 발생했습니다: {str(e)}"}
                )
            )

    async def chat_message(self, event):
        """채팅 메시지를 클라이언트에게 전송"""

        await self.send(
            text_data=json.dumps(
                {
                    "type": "message",
                    "message": event["message"],
                }
            )
        )

    @database_sync_to_async
    def check_room_participation(self):
        """채팅방 참여 확인"""

        try:
            room = OpenChatRoom.objects.get(id=self.room_id)
            # 사용자가 참여자 목록에 있는지 확인
            return OpenChatParticipant.objects.filter(
                room=room, user=self.user
            ).exists()
        except OpenChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content):
        """메시지 DB에 저장"""

        try:
            room = OpenChatRoom.objects.get(id=self.room_id)

            # 메시지 생성
            message = OpenChatMessage.objects.create(
                room=room,
                sender=self.user,
                message_type=OpenChatMessage.MessageType.TEXT,
                content=content
            )

            return {
                "id": message.id,
                "room": message.room.id,
                "content": message.content,
                "message_type": message.message_type,
                "sender": {
                    "id": message.sender.id,
                    "nickname": message.sender.nickname,
                    "username": message.sender.username,
                    "email": message.sender.email,
                    "country_code": message.sender.country_code,
                    "bio": message.sender.bio,
                    "gender": message.sender.gender,
                    "role": message.sender.role,
                    "is_premium": False,
                    "interests": []
                } if message.sender else None,
                "is_mine": False,
                "created_at": message.created_at.isoformat(),
            }

        except OpenChatRoom.DoesNotExist:
            return None
