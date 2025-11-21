import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer

logger = logging.getLogger(__name__)


class NotificationConsumer(AsyncWebsocketConsumer):
    """
    사용자별 개인 알림 채널
    모든 대화방의 새 메시지 알림을 실시간으로 수신
    """

    async def connect(self):
        """WebSocket 연결 시 호출"""
        self.user = self.scope['user']

        logger.debug(f"🔌 Connection attempt")
        logger.debug(f"  User: {self.user}")
        logger.debug(f"  Authenticated: {self.user.is_authenticated}")

        # 인증되지 않은 사용자는 연결 거부
        if not self.user.is_authenticated:
            logger.warning("❌ Rejecting unauthenticated user")
            await self.close()
            return

        # 사용자별 개인 채널 그룹명
        self.notification_group_name = f'user_notifications_{self.user.id}'
        logger.info(f"✅ User {self.user.id} joining group: {self.notification_group_name}")

        # 그룹에 참가
        await self.channel_layer.group_add(
            self.notification_group_name,
            self.channel_name
        )

        await self.accept()
        logger.info(f"✅ Connection accepted for user {self.user.id}")

    async def disconnect(self, close_code):
        """WebSocket 연결 해제 시 호출"""
        # 그룹에서 나가기
        if hasattr(self, 'notification_group_name'):
            await self.channel_layer.group_discard(
                self.notification_group_name,
                self.channel_name
            )

    async def new_message_notification(self, event):
        """
        새 메시지 알림을 클라이언트로 전송
        ChatConsumer에서 group_send로 호출됨
        """
        logger.debug(f"📤 Sending message notification to user")
        logger.debug(f"  Conversation: {event['conversation_id']}")
        logger.debug(f"  Unread count: {event['unread_count']}")

        await self.send(text_data=json.dumps({
            'type': 'new_message',
            'conversation_id': event['conversation_id'],
            'unread_count': event['unread_count'],
            'last_message': event['last_message'],
            'sender': event['sender'],
        }))

        logger.debug("✅ Message notification sent successfully")

    async def notification_update(self, event):
        """
        일반 알림을 클라이언트로 전송
        Notification signal handler에서 group_send로 호출됨
        """
        logger.debug(f"📤 Sending general notification to user")
        logger.debug(f"  Notification ID: {event.get('notification_id')}")
        logger.debug(f"  Type: {event.get('notification_type')}")

        await self.send(text_data=json.dumps({
            'type': 'new_notification',
            'notification_id': event.get('notification_id'),
            'notification_type': event.get('notification_type'),
            'message': event.get('message', '새로운 알림이 있습니다'),
        }))

        logger.debug("✅ General notification sent successfully")
