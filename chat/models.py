from django.db import models
from django.conf import settings
from django.db.models import Q
from django.utils import timezone


class ConversationParticipant(models.Model):
    """
    Through model for Conversation participants
    Tracks individual user status in conversations (active, left date, etc.)
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='conversation_participants'
    )
    conversation = models.ForeignKey(
        'Conversation',
        on_delete=models.CASCADE,
        related_name='participant_relations'
    )
    is_active = models.BooleanField(default=True, db_index=True)
    left_at = models.DateTimeField(null=True, blank=True)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'conversation')
        indexes = [
            models.Index(fields=['user', 'is_active']),
        ]

    def __str__(self):
        status = "Active" if self.is_active else "Left"
        return f"{self.user.username} in {self.conversation.id} ({status})"


class Conversation(models.Model):
    """
    Conversation between two users (1:1 chat)
    Supports both regular and anonymous chats
    """
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='ConversationParticipant',
        related_name='conversations'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Anonymous chat fields
    is_anonymous = models.BooleanField(default=False, db_index=True)
    is_ephemeral = models.BooleanField(default=False)  # Messages not saved to DB
    anonymous_room_id = models.CharField(max_length=20, blank=True, unique=True, null=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        participant_names = ", ".join([user.username for user in self.participants.all()])
        return f"Conversation: {participant_names}"

    def get_other_user(self, current_user):
        """주어진 사용자가 아닌 대화 상대 반환"""
        return self.participants.exclude(id=current_user.id).first()

    def get_last_message(self):
        """마지막 메시지 반환 (만료되지 않은 메시지만)"""
        return self.messages.filter(is_expired=False).order_by('-created_at').first()

    def get_unread_count(self, user):
        """특정 사용자의 읽지 않은 메시지 수 (left_at 이후만, 만료되지 않은 메시지만)"""
        try:
            participant = self.participant_relations.get(user=user)

            # 본인이 보내지 않은 읽지 않은 메시지 (만료되지 않은 것만)
            messages = self.messages.filter(
                ~Q(sender=user),
                is_read=False,
                is_expired=False
            )

            # 나간 적이 있으면 left_at 이후 메시지만 카운트
            if participant.left_at:
                messages = messages.filter(created_at__gt=participant.left_at)
                print(f"[Model] Conversation {self.id}: User {user.id} left_at={participant.left_at}, unread after left={messages.count()}")

            return messages.count()

        except ConversationParticipant.DoesNotExist:
            print(f"[Model] Conversation {self.id}: User {user.id} not a participant")
            return 0

    def get_anonymous_display_name(self, user):
        """익명 채팅에서 사용할 표시 이름 생성"""
        if self.is_anonymous and self.anonymous_room_id:
            return f"익명 사용자 #{self.anonymous_room_id[-6:]}"
        return user.nickname if hasattr(user, 'nickname') else user.username


class Message(models.Model):
    """
    Individual message in a conversation
    """
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages'
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    # Anonymous message expiration fields
    expires_at = models.DateTimeField(null=True, blank=True, db_index=True, verbose_name='만료 시간')
    is_expired = models.BooleanField(default=False, db_index=True, verbose_name='만료 여부')

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender.username}: {self.content[:50]}"


class AnonymousMatchingPreference(models.Model):
    """
    User's preferences for anonymous chat matching
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='matching_preference'
    )
    preferred_gender = models.CharField(
        max_length=20,
        choices=[
            ('any', '전체'),
            ('male', '남성'),
            ('female', '여성'),
            ('other', '기타')
        ],
        default='any'
    )
    preferred_country = models.CharField(
        max_length=100,
        blank=True,
        help_text='빈 값은 전체 국가를 의미합니다'
    )
    chat_mode = models.CharField(
        max_length=10,
        choices=[
            ('text', '글 채팅'),
            ('video', '영상 채팅')
        ],
        default='text',
        help_text='채팅 모드 선택 (글/영상)'
    )
    is_searching = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Anonymous Matching Preference'
        verbose_name_plural = 'Anonymous Matching Preferences'

    def __str__(self):
        return f"{self.user.username}'s matching preferences"


class Report(models.Model):
    """
    User report system for moderation
    """
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports_made'
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports_received'
    )
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports'
    )

    REPORT_TYPES = [
        ('abuse', '욕설/비방'),
        ('spam', '스팸/광고'),
        ('inappropriate', '부적절한 내용'),
        ('harassment', '성희롱'),
        ('other', '기타')
    ]
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES)
    description = models.TextField(blank=True)

    STATUS_CHOICES = [
        ('pending', '대기 중'),
        ('reviewing', '검토 중'),
        ('resolved', '처리 완료'),
        ('dismissed', '기각')
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    admin_note = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['reported_user', 'status']),
            models.Index(fields=['report_type', 'created_at']),
            models.Index(fields=['reporter', 'status']),
        ]

    def __str__(self):
        return f"Report: {self.reporter.username} → {self.reported_user.username} ({self.get_report_type_display()})"

    def is_active(self):
        """Check if report is active (resolved within 1 month)"""
        if self.status == 'resolved' and self.reviewed_at:
            from django.utils import timezone
            from datetime import timedelta
            return timezone.now() - self.reviewed_at < timedelta(days=30)
        return False

    def reset_date(self):
        """Get date when report will be reset (1 month after reviewed_at)"""
        if self.reviewed_at:
            from datetime import timedelta
            return self.reviewed_at + timedelta(days=30)
        return None


class ConnectionRequest(models.Model):
    """
    Connection/Follow request system for anonymous chat
    Requires mutual consent before establishing follow relationship
    """
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='connection_requests',
        help_text='익명 채팅방'
    )
    requester = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='connection_requests_sent',
        help_text='연결 요청을 보낸 사용자'
    )
    receiver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='connection_requests_received',
        help_text='연결 요청을 받은 사용자'
    )

    STATUS_CHOICES = [
        ('pending', '대기 중'),
        ('accepted', '수락됨'),
        ('rejected', '거절됨')
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        help_text='요청 상태'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['conversation', 'status']),
            models.Index(fields=['requester', 'status']),
            models.Index(fields=['receiver', 'status']),
        ]
        # Prevent duplicate requests in same conversation
        unique_together = [['conversation', 'requester', 'receiver']]

    def __str__(self):
        return f"ConnectionRequest: {self.requester.username} → {self.receiver.username} ({self.get_status_display()})"


class OpenChatRoom(models.Model):
    """
    Open chat room for group conversations
    Users can join/leave freely, rooms organized by country and category
    """
    CATEGORY_CHOICES = [
        ('language', '언어교환'),
        ('study', '스터디'),
        ('culture', '문화교류'),
        ('qa', '질문답변'),
        ('freetalk', '자유대화'),
    ]

    name = models.CharField(max_length=200, verbose_name='Room Name')
    country_code = models.CharField(max_length=2, db_index=True, verbose_name='Country Code')
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        default='language',
        db_index=True,
        verbose_name='Category'
    )

    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='OpenChatParticipant',
        related_name='open_chat_rooms'
    )

    # Creator and admin
    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_open_chat_rooms',
        verbose_name='Creator'
    )

    # Room settings
    is_active = models.BooleanField(default=True, db_index=True, verbose_name='Is Active')
    max_participants = models.IntegerField(default=100, verbose_name='Max Participants')
    is_public = models.BooleanField(default=True, verbose_name='Is Public')
    password = models.CharField(max_length=50, blank=True, null=True, verbose_name='Password')

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_activity = models.DateTimeField(auto_now=True, db_index=True, verbose_name='Last Activity')

    class Meta:
        ordering = ['-last_activity', '-created_at']
        verbose_name = 'Open Chat Room'
        verbose_name_plural = 'Open Chat Rooms'
        indexes = [
            models.Index(fields=['country_code', '-last_activity']),
            models.Index(fields=['category', '-last_activity']),
            models.Index(fields=['is_active', '-last_activity']),
        ]

    def __str__(self):
        return f"{self.name} ({self.get_category_display()})"

    def get_participant_count(self):
        """Return number of active participants"""
        return self.participant_relations.filter(is_active=True).count()

    def get_last_message(self):
        """Return the last message in this room"""
        return self.open_messages.order_by('-created_at').first()

    def can_join(self, user):
        """Check if user can join this room"""
        if not self.is_active:
            return False
        if self.is_kicked(user):
            return False
        current_count = self.get_participant_count()
        return current_count < self.max_participants

    def is_participant(self, user):
        """Check if user is an active participant"""
        return self.participant_relations.filter(
            user=user,
            is_active=True
        ).exists()

    def is_admin(self, user):
        """Check if user is admin or creator"""
        if self.creator == user:
            return True
        return self.participant_relations.filter(
            user=user,
            is_active=True,
            is_admin=True
        ).exists()

    def get_admins(self):
        """Get all admins including creator"""
        return self.participant_relations.filter(
            is_active=True,
            is_admin=True
        )

    def is_kicked(self, user):
        """Check if user is currently kicked/banned"""
        latest_kick = self.kick_records.filter(
            kicked_user=user
        ).order_by('-kicked_at').first()

        if latest_kick:
            return latest_kick.is_ban_active()
        return False

    def is_country_room(self):
        """Check if this is a country chat room (creator is None)"""
        return self.creator is None

    def should_delete_on_creator_leave(self):
        """Check if room should be deleted when creator leaves"""
        return not self.is_country_room()

    def deactivate_room(self):
        """Deactivate room and notify all participants"""
        from django.utils import timezone
        from notifications.models import Notification

        # 1. Deactivate room
        self.is_active = False
        self.save()

        # 2. Notify all active participants (except creator)
        active_participants = self.participant_relations.filter(
            is_active=True
        ).exclude(user=self.creator)

        for participant_relation in active_participants:
            # Create system notification
            Notification.create_room_closed_notification(
                recipient=participant_relation.user,
                room=self
            )

            # Update participant status
            participant_relation.is_active = False
            participant_relation.left_at = timezone.now()
            participant_relation.save()


class OpenChatParticipant(models.Model):
    """
    Through model for OpenChatRoom participants
    Tracks user participation in open chat rooms
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='open_chat_participants'
    )
    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name='participant_relations'
    )
    is_active = models.BooleanField(default=True, db_index=True)
    is_admin = models.BooleanField(default=False, db_index=True, verbose_name='Is Admin')
    admin_granted_at = models.DateTimeField(null=True, blank=True, verbose_name='Admin Granted At')
    joined_at = models.DateTimeField(auto_now_add=True)
    left_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('user', 'room')
        ordering = ['-joined_at']
        indexes = [
            models.Index(fields=['room', 'is_active', '-joined_at']),
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['room', 'is_admin']),
        ]

    def __str__(self):
        status = "Active" if self.is_active else "Left"
        admin_badge = " (Admin)" if self.is_admin else ""
        return f"{self.user.username} in {self.room.name} ({status}){admin_badge}"


class OpenChatMessage(models.Model):
    """
    Message in an open chat room
    """
    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name='open_messages'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='open_chat_messages'
    )
    content = models.TextField(verbose_name='Message Content')
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = 'Open Chat Message'
        verbose_name_plural = 'Open Chat Messages'
        indexes = [
            models.Index(fields=['room', '-created_at']),
        ]

    def __str__(self):
        return f"{self.sender.username} in {self.room.name}: {self.content[:50]}"


class OpenChatFavorite(models.Model):
    """
    User's favorite open chat rooms
    Allows users to bookmark frequently visited rooms
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorite_open_chats',
        verbose_name='User'
    )
    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name='favorited_by',
        verbose_name='Room'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Favorited At')

    class Meta:
        unique_together = ('user', 'room')
        ordering = ['-created_at']
        verbose_name = 'Open Chat Favorite'
        verbose_name_plural = 'Open Chat Favorites'
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user.username} favorited {self.room.name}"


class OpenChatKick(models.Model):
    """
    Record of kicked users in open chat rooms
    Tracks user kicks and bans for moderation purposes
    """
    room = models.ForeignKey(
        OpenChatRoom,
        on_delete=models.CASCADE,
        related_name='kick_records',
        verbose_name='Room'
    )
    kicked_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='open_chat_kicks_received',
        verbose_name='Kicked User'
    )
    kicked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='open_chat_kicks_performed',
        verbose_name='Kicked By'
    )
    reason = models.TextField(blank=True, verbose_name='Kick Reason')
    kicked_at = models.DateTimeField(auto_now_add=True, verbose_name='Kicked At')

    # Ban duration (null = permanent ban)
    ban_until = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Ban Until',
        help_text='Leave empty for permanent ban'
    )

    class Meta:
        ordering = ['-kicked_at']
        verbose_name = 'Open Chat Kick'
        verbose_name_plural = 'Open Chat Kicks'
        indexes = [
            models.Index(fields=['room', 'kicked_user']),
            models.Index(fields=['room', '-kicked_at']),
        ]

    def __str__(self):
        return f"{self.kicked_user.username} kicked from {self.room.name}"

    def is_ban_active(self):
        """Check if ban is still active"""
        if self.ban_until is None:
            return True  # Permanent ban
        return timezone.now() < self.ban_until
