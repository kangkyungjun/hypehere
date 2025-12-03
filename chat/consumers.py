import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.utils.translation import gettext as _
from .models import (
    Conversation, Message, ConversationParticipant,
    OpenChatRoom, OpenChatParticipant, OpenChatMessage,
    ConversationBuffer
)

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time chat messaging
    """

    async def connect(self):
        """사용자가 WebSocket에 연결될 때 호출"""
        self.user = self.scope['user']
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'

        # 인증되지 않은 사용자는 연결 거부
        if not self.user.is_authenticated:
            await self.close()
            return

        # 사용자가 이 대화의 참가자인지 확인
        is_participant = await self.check_participant()
        if not is_participant:
            await self.close()
            return

        # ConversationBuffer를 사전에 생성 (신고 증거 수집용)
        # 메시지가 없어도 신고 시 버퍼가 존재하도록 보장
        await self.create_conversation_buffer()

        # 대화 그룹에 참가
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        # WebSocket 연결 시 기존 안읽은 메시지 모두 읽음 처리
        await self.mark_messages_as_read()

    async def disconnect(self, close_code):
        """사용자가 WebSocket 연결을 끊을 때 호출"""
        # 대화 그룹에서 나가기
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """클라이언트로부터 메시지를 받을 때 호출"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'message')

            if message_type == 'message':
                content = data.get('content', '').strip()
                if not content:
                    return

                # 차단 관계 확인
                from accounts.models import Block
                from django.db.models import Q
                conversation = await database_sync_to_async(
                    Conversation.objects.get
                )(id=self.conversation_id)
                other_user = await database_sync_to_async(
                    conversation.get_other_user
                )(self.user)

                is_blocking = await database_sync_to_async(
                    Block.objects.filter(blocker=self.user, blocked=other_user, is_active=True).exists
                )()
                is_blocked_by = await database_sync_to_async(
                    Block.objects.filter(blocker=other_user, blocked=self.user, is_active=True).exists
                )()

                # 차단당한 사람이 메시지 보냄 - 저장하지만 차단한 사람에게 전달 안함
                if is_blocked_by:
                    # 메시지는 저장 (본인에게는 보임)
                    message = await self.save_message(content)

                    # 본인에게만 메시지 표시 (group_send 하지 않음)
                    await self.send(text_data=json.dumps({
                        'type': 'message',
                        'message_id': message.id,
                        'sender_id': self.user.id,
                        'sender_nickname': self.user.nickname,
                        'content': message.content,
                        'created_at': message.created_at.isoformat(),
                    }))
                    return

                # 차단 관계가 아님 - 정상적으로 메시지 전송
                # 메시지를 데이터베이스에 저장
                message = await self.save_message(content)

                # 대화 그룹의 모든 사용자에게 메시지 전송
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': message.id,
                        'sender_id': self.user.id,
                        'sender_nickname': self.user.nickname,
                        'content': message.content,
                        'created_at': message.created_at.isoformat(),
                    }
                )

                # 상대방에게 알림 전송
                notification_data = await self.get_notification_data(message)
                if notification_data:
                    await self.channel_layer.group_send(
                        f"user_notifications_{notification_data['other_user_id']}",
                        {
                            'type': 'new_message_notification',
                            'conversation_id': self.conversation_id,
                            'unread_count': notification_data['unread_count'],
                            'last_message': {
                                'content': message.content,
                                'created_at': message.created_at.isoformat(),
                            },
                            'sender': {
                                'id': self.user.id,
                                'nickname': self.user.nickname,
                            }
                        }
                    )

            elif message_type == 'read':
                # 읽음 상태 업데이트
                await self.mark_messages_as_read()

        except json.JSONDecodeError:
            pass

    async def chat_message(self, event):
        """그룹에서 메시지를 받아 클라이언트로 전송"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message_id': event['message_id'],
            'sender_id': event['sender_id'],
            'sender_nickname': event['sender_nickname'],
            'content': event['content'],
            'created_at': event['created_at'],
        }))

        # 메시지를 받으면 자동으로 읽음 처리 (실시간 읽음 처리)
        await self.mark_messages_as_read()

    @database_sync_to_async
    def check_participant(self):
        """현재 사용자가 대화의 참가자인지 확인"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            return conversation.participants.filter(id=self.user.id).exists()
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def create_conversation_buffer(self):
        """대화 연결 시 ConversationBuffer를 사전 생성 (신고 증거 수집용)"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            # 익명 채팅이 아닌 경우에만 버퍼 생성
            if not conversation.is_ephemeral:
                ConversationBuffer.objects.get_or_create(conversation=conversation)
        except Conversation.DoesNotExist:
            pass

    @database_sync_to_async
    def save_message(self, content):
        """메시지를 데이터베이스에 저장"""
        conversation = Conversation.objects.get(id=self.conversation_id)

        # 상대방이 나간 경우 자동 재입장 처리
        other_user = conversation.get_other_user(self.user)
        if other_user:
            try:
                other_participant = ConversationParticipant.objects.get(
                    conversation=conversation,
                    user=other_user
                )

                if not other_participant.is_active:
                    # 자동 재입장 (left_at은 유지하여 나간 시점 이후 메시지만 보이도록)
                    other_participant.is_active = True
                    # left_at은 None으로 설정하지 않음 - 나간 시점을 기억해야 함
                    other_participant.save()
            except ConversationParticipant.DoesNotExist:
                pass

        message = Message.objects.create(
            conversation=conversation,
            sender=self.user,
            content=content
        )

        # 메시지 버퍼에 저장 (신고 증거용)
        # 익명 채팅이 아닌 경우에만 버퍼 저장
        if not conversation.is_ephemeral:
            buffer, created = ConversationBuffer.objects.get_or_create(
                conversation=conversation
            )
            buffer.add_message(message)

        # 대화의 updated_at 자동 업데이트 (auto_now=True)
        conversation.save()
        return message

    @database_sync_to_async
    def get_notification_data(self, message):
        """알림에 필요한 데이터 가져오기"""
        from accounts.models import Block

        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            other_user = conversation.get_other_user(self.user)

            if other_user:
                # 차단 확인: other_user(수신자)가 self.user(발신자)를 차단했는지 확인
                is_blocked_by_recipient = Block.objects.filter(
                    blocker=other_user,
                    blocked=self.user
                ).exists()

                # 수신자가 발신자를 차단한 경우 알림을 보내지 않음
                if is_blocked_by_recipient:
                    print(f"[ChatConsumer] 🚫 Notification blocked: {other_user.nickname} is blocking {self.user.nickname}")
                    return None

                unread_count = conversation.get_unread_count(other_user)
                print(f"[ChatConsumer] 📊 Notification data prepared:")
                print(f"[ChatConsumer]   Other user: {other_user.id} ({other_user.nickname})")
                print(f"[ChatConsumer]   Unread count: {unread_count}")
                return {
                    'other_user_id': other_user.id,
                    'unread_count': unread_count
                }
            else:
                print(f"[ChatConsumer] ⚠️ No other user found in conversation {self.conversation_id}")
        except Exception as e:
            print(f"[ChatConsumer] ❌ Error getting notification data: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
        return None

    @database_sync_to_async
    def mark_messages_as_read(self):
        """현재 사용자가 받은 메시지를 읽음 상태로 표시"""
        Message.objects.filter(
            conversation_id=self.conversation_id,
            is_read=False
        ).exclude(sender=self.user).update(is_read=True)


class AnonymousChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for anonymous chat with ephemeral messages
    Messages are sent in real-time but not saved to database
    """

    async def connect(self):
        """사용자가 WebSocket에 연결될 때 호출"""
        self.user = self.scope['user']
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'anonymous_chat_{self.conversation_id}'

        # 인증되지 않은 사용자는 연결 거부
        if not self.user.is_authenticated:
            await self.close()
            return

        # 사용자가 이 익명 대화의 참가자인지 확인
        is_participant = await self.check_anonymous_participant()
        if not is_participant:
            await self.close()
            return

        # ConversationBuffer를 사전에 생성 (신고 증거 수집용)
        # 익명 대화도 7일간 보관되므로 메시지가 없어도 버퍼 생성
        await self.create_anonymous_conversation_buffer()

        # 대화 그룹에 참가
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        # 상대방 정보 전송
        other_user_info = await self.get_other_user_info()
        await self.send(text_data=json.dumps({
            'type': 'init',
            'other_user_id': other_user_info['id'],
            'other_user_username': other_user_info['username']
        }))

        # 상대방에게 연결 알림 전송
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_connected',
                'user_id': self.user.id
            }
        )

    async def disconnect(self, close_code):
        """사용자가 WebSocket 연결을 끊을 때 호출"""
        # 상대방에게 나간 알림 전송
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_left',
                'user_id': self.user.id
            }
        )

        # 대화 그룹에서 나가기
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

        # 익명 대화 정리
        await self.cleanup_anonymous_conversation()

    async def receive(self, text_data):
        """클라이언트로부터 메시지를 받을 때 호출"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'message')

            if message_type == 'message':
                content = data.get('content', '').strip()
                if not content:
                    return

                # 익명 대화 메시지를 7일간 임시 저장 (하이브리드 방식)
                message = await self.save_anonymous_message(content)

                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': message.id,
                        'sender_id': self.user.id,
                        'content': content,
                        'created_at': message.created_at.isoformat(),
                        'expires_at': message.expires_at.isoformat() if message.expires_at else None,
                    }
                )

            # WebRTC 시그널 중계 (P2P 연결용)
            elif message_type in ['video_offer', 'video_answer', 'ice_candidate', 'video_toggle']:
                # WebRTC 시그널을 상대방에게 중계
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'webrtc_signal',
                        'sender_id': self.user.id,
                        'signal_type': message_type,
                        'signal_data': data
                    }
                )

        except json.JSONDecodeError:
            pass

    async def chat_message(self, event):
        """그룹에서 메시지를 받아 클라이언트로 전송"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            'sender_id': event['sender_id'],
            'content': event['content'],
            'created_at': event['created_at'],
        }))

    async def user_connected(self, event):
        """상대방이 연결되었을 때 알림"""
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'partner_connected',
                'message': 'partnerConnected'
            }))

    async def user_left(self, event):
        """상대방이 나갔을 때 알림"""
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'partner_left',
                'message': 'partnerLeft'
            }))

    async def webrtc_signal(self, event):
        """WebRTC 시그널을 상대방에게 중계"""
        # 자신이 보낸 시그널은 받지 않음
        if event['sender_id'] != self.user.id:
            await self.send(text_data=json.dumps(event['signal_data']))

    async def connection_request(self, event):
        """연결 요청 알림 (수신자에게만)"""
        # 요청자가 아닌 수신자에게만 전송
        if self.user.id != event['requester_id']:
            await self.send(text_data=json.dumps({
                'type': 'connection_request',
                'request_id': event['request_id']
            }))

    async def connection_accepted(self, event):
        """연결 수락 알림 (요청자에게만)"""
        # 요청자에게만 전송
        if self.user.id == event['requester_id']:
            await self.send(text_data=json.dumps({
                'type': 'connection_accepted',
                'request_id': event['request_id']
            }))

    async def connection_rejected(self, event):
        """연결 거절 알림 (요청자에게만)"""
        # 요청자에게만 전송
        if self.user.id == event['requester_id']:
            await self.send(text_data=json.dumps({
                'type': 'connection_rejected',
                'request_id': event['request_id']
            }))

    @database_sync_to_async
    def check_anonymous_participant(self):
        """현재 사용자가 익명 대화의 참가자인지 확인"""
        try:
            conversation = Conversation.objects.get(
                id=self.conversation_id,
                is_anonymous=True
            )
            return conversation.participants.filter(id=self.user.id).exists()
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def create_anonymous_conversation_buffer(self):
        """익명 대화 연결 시 ConversationBuffer를 사전 생성 (신고 증거 수집용)"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            # 익명 대화도 7일간 보관되므로 버퍼 생성
            ConversationBuffer.objects.get_or_create(conversation=conversation)
        except Conversation.DoesNotExist:
            pass

    @database_sync_to_async
    def get_other_user_info(self):
        """익명 대화의 상대방 정보 가져오기"""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            other_user = conversation.participants.exclude(id=self.user.id).first()
            if other_user:
                return {
                    'id': other_user.id,
                    'username': other_user.username
                }
            return {'id': None, 'username': None}
        except Conversation.DoesNotExist:
            return {'id': None, 'username': None}

    @database_sync_to_async
    def save_anonymous_message(self, content):
        """익명 대화 메시지를 7일 만료 설정으로 저장"""
        from datetime import timedelta
        from .models import Message, Conversation

        conversation = Conversation.objects.get(id=self.conversation_id)
        expires_at = timezone.now() + timedelta(days=7)

        message = Message.objects.create(
            conversation=conversation,
            sender=self.user,
            content=content,
            expires_at=expires_at,
            is_expired=False
        )

        # 메시지 버퍼에 저장 (신고 증거용)
        # 익명 대화도 7일간 임시 저장되므로 버퍼에도 저장
        buffer, created = ConversationBuffer.objects.get_or_create(
            conversation=conversation
        )
        buffer.add_message(message)

        return message

    @database_sync_to_async
    def cleanup_anonymous_conversation(self):
        """사용자가 나갈 때 익명 대화 정리 (방 삭제)"""
        try:
            conversation = Conversation.objects.get(
                id=self.conversation_id,
                is_anonymous=True
            )

            # 현재 사용자 참가자 정보 비활성화
            participant = ConversationParticipant.objects.get(
                conversation=conversation,
                user=self.user
            )
            participant.is_active = False
            participant.left_at = timezone.now()
            participant.save()

            # 모든 참가자가 나간 경우 대화 삭제
            active_count = ConversationParticipant.objects.filter(
                conversation=conversation,
                is_active=True
            ).count()

            if active_count == 0:
                conversation.delete()

        except (Conversation.DoesNotExist, ConversationParticipant.DoesNotExist):
            pass


class MatchingConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time matching notifications
    Notifies users when a match is found
    """

    async def connect(self):
        """사용자가 WebSocket에 연결될 때 호출"""
        self.user = self.scope['user']

        # 인증되지 않은 사용자는 연결 거부
        if not self.user.is_authenticated:
            await self.close()
            return

        self.user_group_name = f'matching_{self.user.id}'

        # 사용자별 매칭 그룹에 참가
        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        """사용자가 WebSocket 연결을 끊을 때 호출"""
        # 매칭 그룹에서 나가기
        await self.channel_layer.group_discard(
            self.user_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """클라이언트로부터 메시지를 받을 때 호출 (필요시 확장 가능)"""
        pass

    async def match_found(self, event):
        """매칭이 성공했을 때 클라이언트에 알림"""
        await self.send(text_data=json.dumps({
            'type': 'match_found',
            'conversation_id': event['conversation_id'],
            'anonymous_room_id': event['anonymous_room_id']
        }))

    async def queue_update(self, event):
        """큐 상태 업데이트 알림"""
        await self.send(text_data=json.dumps({
            'type': 'queue_update',
            'position': event['position'],
            'queue_size': event['queue_size']
        }))


class OpenChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for open chat rooms
    Handles real-time messaging in group chat rooms
    """

    async def connect(self):
        """사용자가 WebSocket에 연결될 때 호출"""
        self.user = self.scope['user']
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'open_chat_{self.room_id}'

        # 인증되지 않은 사용자는 연결 거부
        if not self.user.is_authenticated:
            await self.close()
            return

        # 사용자가 이 방의 참가자인지 확인
        is_participant = await self.check_participant()
        if not is_participant:
            await self.close()
            return

        # 방 그룹에 참가
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

        # 입장 메시지 브로드캐스트
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_joined',
                'user_id': self.user.id,
                'user_nickname': self.user.nickname,
            }
        )

    async def disconnect(self, close_code):
        """사용자가 WebSocket 연결을 끊을 때 호출"""
        # 퇴장 메시지 브로드캐스트
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_left',
                'user_id': self.user.id,
                'user_nickname': self.user.nickname,
            }
        )

        # 방 그룹에서 나가기
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        """클라이언트로부터 메시지를 받을 때 호출"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'message')

            if message_type == 'message':
                content = data.get('content', '').strip()
                if not content:
                    return

                # 메시지를 데이터베이스에 저장
                message = await self.save_message(content)

                # 방의 모든 사용자에게 메시지 전송
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': message.id,
                        'sender_id': self.user.id,
                        'sender_nickname': self.user.nickname,
                        'sender_profile_picture': self.user.profile_picture.url if self.user.profile_picture else None,
                        'content': message.content,
                        'created_at': message.created_at.isoformat(),
                    }
                )

            elif message_type == 'typing':
                # 타이핑 상태 브로드캐스트
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'user_typing',
                        'user_id': self.user.id,
                        'user_nickname': self.user.nickname,
                    }
                )

        except json.JSONDecodeError:
            pass

    async def chat_message(self, event):
        """그룹에서 메시지를 받아 클라이언트로 전송"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            'message_id': event['message_id'],
            'sender_id': event['sender_id'],
            'sender_nickname': event['sender_nickname'],
            'sender_profile_picture': event.get('sender_profile_picture'),
            'content': event['content'],
            'created_at': event['created_at'],
        }))

    async def user_joined(self, event):
        """사용자 입장 알림"""
        # 자신의 입장 메시지는 받지 않음
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'user_joined',
                'user_id': event['user_id'],
                'user_nickname': event['user_nickname'],
            }))

    async def user_left(self, event):
        """사용자 퇴장 알림"""
        # 자신의 퇴장 메시지는 받지 않음
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'user_left',
                'user_id': event['user_id'],
                'user_nickname': event['user_nickname'],
            }))

    async def user_typing(self, event):
        """타이핑 상태 알림"""
        # 자신의 타이핑 상태는 받지 않음
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'user_nickname': event['user_nickname'],
            }))

    async def user_kicked(self, event):
        """사용자 강퇴 알림"""
        await self.send(text_data=json.dumps({
            'type': 'user_kicked',
            'kicked_user_id': event['kicked_user_id'],
            'kicked_user_nickname': event['kicked_user_nickname'],
            'kicked_by_nickname': event['kicked_by_nickname'],
            'reason': event.get('reason', ''),
        }))

    async def admin_changed(self, event):
        """관리자 권한 변경 알림"""
        await self.send(text_data=json.dumps({
            'type': 'admin_changed',
            'user_id': event['user_id'],
            'user_nickname': event['user_nickname'],
            'is_admin': event['is_admin'],
            'granted_by_nickname': event.get('granted_by_nickname'),
            'revoked_by_nickname': event.get('revoked_by_nickname'),
        }))

    @database_sync_to_async
    def check_participant(self):
        """현재 사용자가 방의 참가자인지 확인"""
        try:
            room = OpenChatRoom.objects.get(id=self.room_id, is_active=True)
            return room.is_participant(self.user)
        except OpenChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content):
        """메시지를 데이터베이스에 저장"""
        room = OpenChatRoom.objects.get(id=self.room_id)
        message = OpenChatMessage.objects.create(
            room=room,
            sender=self.user,
            content=content
        )

        # 방의 last_activity 업데이트
        room.last_activity = timezone.now()
        room.save()

        return message

    async def room_closed(self, event):
        """방 폐쇄 이벤트 전송"""
        await self.send(text_data=json.dumps({
            'type': 'room_closed',
            'message': event['message'],
            'room_name': event.get('room_name', '')
        }))
