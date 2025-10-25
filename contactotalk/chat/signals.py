"""
채팅 앱 Signal 핸들러
채팅방 생성 시 매칭 이력 자동 생성
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import ChatRoom, MatchHistory


@receiver(post_save, sender=ChatRoom)
def create_match_history(sender, instance, created, **kwargs):
    """
    채팅방 생성 시 양쪽 사용자의 매칭 이력 자동 생성

    Args:
        sender: ChatRoom 모델
        instance: 생성된 ChatRoom 인스턴스
        created: 새로 생성되었는지 여부 (True/False)
        **kwargs: 추가 인자
    """
    if created:
        # user1의 매칭 이력 생성
        MatchHistory.objects.create(
            user=instance.user1,
            matched_user=instance.user2,
            chat_room=instance
        )

        # user2의 매칭 이력 생성
        MatchHistory.objects.create(
            user=instance.user2,
            matched_user=instance.user1,
            chat_room=instance
        )
