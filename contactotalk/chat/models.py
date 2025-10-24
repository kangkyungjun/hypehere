from django.db import models
from django.conf import settings
from django.utils import timezone


class MatchingQueue(models.Model):
    """매칭 대기열"""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="matching_queue"
    )
    country_preference = models.CharField(
        max_length=3,
        null=True,
        blank=True,
        help_text="매칭 희망 국가 (null이면 전 세계)"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "매칭 대기열"
        verbose_name_plural = "매칭 대기열 목록"
        ordering = ["created_at"]  # FIFO (선입선출)

    def __str__(self):
        return f"{self.user.username} - {self.country_preference or 'Any'}"


class ChatRoom(models.Model):
    """1:1 랜덤 채팅방"""

    user1 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chatrooms_as_user1"
    )
    user2 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chatrooms_as_user2"
    )

    # 매칭 정보
    country_code = models.CharField(
        max_length=3,
        null=True,
        blank=True,
        help_text="매칭 기준 국가 (null이면 전 세계)"
    )
    matching_score = models.FloatField(
        default=0.0,
        help_text="매칭 점수 (관심사 기반)"
    )

    # 채팅방 상태
    is_active = models.BooleanField(default=True)
    user1_left = models.BooleanField(default=False)
    user2_left = models.BooleanField(default=False)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "채팅방"
        verbose_name_plural = "채팅방 목록"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Room #{self.id}: {self.user1.username} ↔ {self.user2.username}"

    def is_both_left(self):
        """양쪽 모두 나갔는지 확인"""
        return self.user1_left and self.user2_left

    def mark_user_left(self, user):
        """사용자가 채팅방을 나감 처리"""
        if self.user1 == user:
            self.user1_left = True
        elif self.user2 == user:
            self.user2_left = True
        else:
            return False

        self.save(update_fields=["user1_left", "user2_left", "updated_at"])
        return True

    def get_other_user(self, user):
        """상대방 사용자 반환"""
        if self.user1 == user:
            return self.user2
        elif self.user2 == user:
            return self.user1
        return None

    def get_unread_count(self, user):
        """읽지 않은 메시지 수 반환"""
        return self.messages.filter(is_read=False).exclude(sender=user).count()


class Message(models.Model):
    """채팅 메시지"""

    class MessageType(models.TextChoices):
        TEXT = 'text', '일반 텍스트'
        SYSTEM = 'system', '시스템 메시지'

    room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name="messages"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_messages"
    )
    message_type = models.CharField(
        max_length=20,
        choices=MessageType.choices,
        default=MessageType.TEXT
    )
    content = models.TextField(max_length=1000)
    is_read = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "메시지"
        verbose_name_plural = "메시지 목록"
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.sender.username}: {self.content[:30]}"

    def mark_as_read(self):
        """메시지를 읽음으로 표시"""
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=["is_read"])


class BlockedUser(models.Model):
    """차단된 사용자"""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocked_list"
    )
    blocked_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocked_by"
    )
    reason = models.TextField(
        max_length=200,
        blank=True,
        help_text="차단 사유"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "blocked_user")
        verbose_name = "차단 사용자"
        verbose_name_plural = "차단 사용자 목록"

    def __str__(self):
        return f"{self.user.username} blocked {self.blocked_user.username}"


class OpenChatRoom(models.Model):
    """오픈 채팅방 (국가별 기본방 + 사용자 생성방)"""

    class RoomType(models.TextChoices):
        DEFAULT = "default", "국가별 기본방"
        USER_CREATED = "user_created", "사용자 생성방"

    # 채팅방 타입
    room_type = models.CharField(
        max_length=20,
        choices=RoomType.choices,
        default=RoomType.USER_CREATED
    )

    # 채팅방 정보
    title = models.CharField(max_length=100, help_text="채팅방 제목")
    description = models.TextField(max_length=500, blank=True, help_text="채팅방 설명")
    country_code = models.CharField(
        max_length=3,
        blank=True,
        default="",
        help_text="국가 코드 (ISO 3166-1 alpha-3)"
    )

    # 생성자 (기본방은 null)
    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_open_rooms",
        help_text="채팅방 생성자 (기본방은 null)"
    )

    # 카테고리/주제
    category = models.CharField(
        max_length=50,
        blank=True,
        help_text="카테고리 (예: 스포츠, 음악, 게임 등)"
    )
    tags = models.CharField(
        max_length=200,
        blank=True,
        help_text="태그 (쉼표로 구분)"
    )

    # 참여자 수
    participant_count = models.IntegerField(default=0, help_text="현재 참여자 수")
    max_participants = models.IntegerField(
        default=100,
        help_text="최대 참여자 수 (0이면 무제한)"
    )

    # 공개 설정
    is_public = models.BooleanField(
        default=True,
        help_text="공개 채팅방 여부"
    )
    password = models.CharField(
        max_length=50,
        blank=True,
        default="",
        help_text="비공개 채팅방 비밀번호"
    )

    # 상태
    is_active = models.BooleanField(default=True)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "오픈 채팅방"
        verbose_name_plural = "오픈 채팅방 목록"
        ordering = ["-participant_count", "-created_at"]
        indexes = [
            models.Index(fields=["country_code", "room_type"]),
            models.Index(fields=["category"]),
            models.Index(fields=["-participant_count"]),
        ]

    def __str__(self):
        return f"[{self.country_code}] {self.title} ({self.participant_count}명)"

    def is_full(self):
        """채팅방이 가득 찼는지 확인"""
        if self.max_participants == 0:
            return False
        return self.participant_count >= self.max_participants

    def increment_participant_count(self):
        """참여자 수 증가"""
        self.participant_count += 1
        self.save(update_fields=["participant_count", "updated_at"])

    def decrement_participant_count(self):
        """참여자 수 감소"""
        if self.participant_count > 0:
            self.participant_count -= 1
            self.save(update_fields=["participant_count", "updated_at"])

    def get_tags_list(self):
        """태그 리스트 반환"""
        if not self.tags:
            return []
        return [tag.strip() for tag in self.tags.split(",") if tag.strip()]

    def get_next_owner(self):
        """다음 방장 후보 반환 (가장 오래 참여한 사람)"""
        from .models import OpenChatParticipant

        # 현재 방장을 제외하고 가장 오래된 참여자
        return OpenChatParticipant.objects.filter(
            room=self
        ).exclude(
            user=self.creator
        ).order_by('joined_at').first()

    def transfer_ownership(self, new_owner):
        """방장 승계"""
        old_owner = self.creator
        self.creator = new_owner
        self.save(update_fields=['creator', 'updated_at'])
        return old_owner


class OpenChatParticipant(models.Model):
    """오픈 채팅방 참여자"""

    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name="participants"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="open_chat_participants"
    )

    # 참여 정보
    joined_at = models.DateTimeField(auto_now_add=True)
    last_read_at = models.DateTimeField(default=timezone.now)

    # 상태
    is_active = models.BooleanField(default=True, help_text="현재 접속 중인지")

    class Meta:
        unique_together = ("room", "user")
        verbose_name = "오픈 채팅방 참여자"
        verbose_name_plural = "오픈 채팅방 참여자 목록"
        ordering = ["-joined_at"]

    def __str__(self):
        return f"{self.user.nickname} in {self.room.title}"

    def update_last_read(self):
        """마지막 읽은 시간 업데이트"""
        self.last_read_at = timezone.now()
        self.save(update_fields=["last_read_at"])


class OpenChatMessage(models.Model):
    """오픈 채팅방 메시지"""

    class MessageType(models.TextChoices):
        TEXT = "text", "텍스트"
        SYSTEM = "system", "시스템 알림"
        JOIN = "join", "입장 알림"
        LEAVE = "leave", "퇴장 알림"

    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name="messages"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="open_chat_messages"
    )

    # 메시지 정보
    message_type = models.CharField(
        max_length=20,
        choices=MessageType.choices,
        default=MessageType.TEXT
    )
    content = models.TextField(max_length=1000)

    # 타임스탬프
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "오픈 채팅 메시지"
        verbose_name_plural = "오픈 채팅 메시지 목록"
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["room", "-created_at"]),
        ]

    def __str__(self):
        sender_name = self.sender.nickname if self.sender else "System"
        return f"[{self.room.title}] {sender_name}: {self.content[:30]}"
