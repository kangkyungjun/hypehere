from rest_framework import serializers
from django.utils.translation import gettext as _
from .models import Notification, NotificationSettings
from accounts.serializers import UserSerializer
from chat.models import Conversation


class NotificationSerializer(serializers.ModelSerializer):
    """알림 시리얼라이저 - 사용자 친화적 표시 텍스트와 이동 URL 제공"""

    sender = UserSerializer(read_only=True)
    notification_display = serializers.SerializerMethodField()
    target_url = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id',
            'notification_type',
            'sender',
            'text_preview',
            'is_read',
            'created_at',
            'notification_display',
            'target_url'
        ]

    def get_notification_display(self, obj):
        """
        알림 타입에 따라 사용자 친화적인 텍스트 생성

        Returns:
            str: 표시할 알림 텍스트
        """
        if not obj.sender:
            return _("알림")

        sender_name = obj.sender.nickname

        if obj.notification_type == 'MESSAGE':
            return _("%(sender)s님이 메시지를 보냈습니다") % {'sender': sender_name}
        elif obj.notification_type == 'FOLLOW':
            return _("%(sender)s님이 팔로우했습니다") % {'sender': sender_name}
        elif obj.notification_type == 'POST':
            return _("%(sender)s님이 새 게시글을 작성했습니다") % {'sender': sender_name}
        elif obj.notification_type == 'COMMENT':
            return _("%(sender)s님이 댓글을 남겼습니다") % {'sender': sender_name}
        elif obj.notification_type == 'LIKE':
            return _("%(sender)s님이 좋아요를 눌렀습니다") % {'sender': sender_name}
        elif obj.notification_type == 'REPORT':
            return _("%(sender)s님이 게시물을 신고했습니다") % {'sender': sender_name}

        return _("새 알림")

    def get_target_url(self, obj):
        """
        알림 클릭 시 이동할 URL 생성

        Returns:
            str: 이동할 URL 경로
        """
        # MESSAGE 타입: 대화방으로 이동
        if obj.notification_type == 'MESSAGE':
            if isinstance(obj.content_object, Conversation):
                return f"/messages/{obj.content_object.id}/"

        # FOLLOW 타입: 발신자 프로필로 이동
        elif obj.notification_type == 'FOLLOW':
            if obj.sender:
                return f"/accounts/profile/{obj.sender.id}/"

        # POST 타입: 홈페이지로 이동 + 쿼리 파라미터로 모달 오픈
        elif obj.notification_type == 'POST':
            if obj.object_id:
                return f"/?postId={obj.object_id}"

        # COMMENT, LIKE 타입: 홈페이지로 이동 + 쿼리 파라미터로 모달 오픈
        elif obj.notification_type in ['COMMENT', 'LIKE']:
            if obj.content_object:
                # Comment나 Like 객체에서 post_id 가져오기
                post_id = getattr(obj.content_object, 'post_id', None)
                if post_id:
                    return f"/?postId={post_id}"

        # REPORT 타입: 일반 알림 페이지에 표시
        elif obj.notification_type == 'REPORT':
            return "/notifications/"

        # 기본값: 홈페이지
        return "/"


class NotificationSettingsSerializer(serializers.ModelSerializer):
    """알림 설정 시리얼라이저"""

    class Meta:
        model = NotificationSettings
        fields = [
            'enable_all_notifications',
            'enable_message_notifications',
            'enable_follow_notifications',
            'enable_post_notifications',
            'enable_comment_notifications',
            'enable_like_notifications',
        ]

    def validate(self, data):
        """모든 알림이 비활성화되면 개별 알림도 모두 비활성화"""
        if 'enable_all_notifications' in data and not data['enable_all_notifications']:
            data.update({
                'enable_message_notifications': False,
                'enable_follow_notifications': False,
                'enable_post_notifications': False,
                'enable_comment_notifications': False,
                'enable_like_notifications': False,
            })
        return data
