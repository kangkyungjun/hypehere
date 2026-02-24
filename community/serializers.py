from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Post, Comment, PostLike, CommentLike, PostReport, CommentReport

User = get_user_model()


class CustomUserSerializer(serializers.ModelSerializer):
    """사용자 정보 Serializer (author 필드용 - Flutter CommunityUser 호환)"""

    class Meta:
        model = User
        fields = ['id', 'email', 'nickname', 'profile_picture', 'role', 'created_at']
        read_only_fields = ['id', 'email', 'nickname', 'profile_picture', 'role', 'created_at']


class PostListSerializer(serializers.ModelSerializer):
    """게시글 리스트 Serializer (간소화 버전)"""

    author = CustomUserSerializer(read_only=True)
    is_liked = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'ticker', 'title', 'content', 'author',
            'like_count', 'comment_count', 'view_count',
            'created_at', 'updated_at', 'is_liked',
            'can_edit', 'can_delete'
        ]
        read_only_fields = [
            'id', 'like_count', 'comment_count', 'view_count',
            'created_at', 'updated_at'
        ]

    def get_is_liked(self, obj):
        """
        현재 사용자가 좋아요를 눌렀는지 확인
        - 비회원: 항상 False
        - 회원: 실제 좋아요 여부 확인
        """
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return PostLike.objects.filter(post=obj, user=request.user).exists()

    def get_can_edit(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))

    def get_can_delete(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))


class PostSerializer(serializers.ModelSerializer):
    """게시글 상세 Serializer (전체 필드)"""

    author = CustomUserSerializer(read_only=True)
    is_liked = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'ticker', 'title', 'content', 'author',
            'like_count', 'comment_count', 'view_count',
            'created_at', 'updated_at', 'is_liked',
            'can_edit', 'can_delete'
        ]
        read_only_fields = [
            'id', 'author', 'like_count', 'comment_count', 'view_count',
            'created_at', 'updated_at'
        ]

    def get_is_liked(self, obj):
        """현재 사용자의 좋아요 여부"""
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return PostLike.objects.filter(post=obj, user=request.user).exists()

    def get_can_edit(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))

    def get_can_delete(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))

    def create(self, validated_data):
        """게시글 생성 시 author 자동 설정"""
        request = self.context.get('request')
        validated_data['author'] = request.user
        return super().create(validated_data)


class CommentSerializer(serializers.ModelSerializer):
    """댓글 Serializer (대댓글 포함)"""

    author = CustomUserSerializer(read_only=True)
    content = serializers.SerializerMethodField()  # 비회원에게는 숨김 처리
    is_liked = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            'id', 'post', 'content', 'author', 'parent',
            'like_count', 'created_at', 'updated_at',
            'is_liked', 'can_edit', 'can_delete', 'replies'
        ]
        read_only_fields = [
            'id', 'author', 'like_count',
            'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'post': {'required': False}  # Nested route에서는 URL에서 가져옴
        }

    def get_content(self, obj):
        """
        댓글 내용 반환
        - 비회원: "🔒 회원 전용 댓글입니다"
        - 회원: 실제 댓글 내용
        """
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return "🔒 회원 전용 댓글입니다"
        return obj.content

    def get_is_liked(self, obj):
        """현재 사용자의 좋아요 여부"""
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return CommentLike.objects.filter(comment=obj, user=request.user).exists()

    def get_can_edit(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))

    def get_can_delete(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return False
        return (obj.author == request.user
                or request.user.is_staff
                or getattr(request.user, 'role', None) in ('master', 'manager'))

    def get_replies(self, obj):
        """대댓글 리스트 (parent가 None인 경우에만)"""
        if obj.parent is not None:
            return []
        replies = obj.replies.filter(is_deleted=False).order_by('created_at')
        return CommentSerializer(replies, many=True, context=self.context).data

    def create(self, validated_data):
        """댓글 생성 시 author 자동 설정"""
        request = self.context.get('request')
        validated_data['author'] = request.user
        # content는 SerializerMethodField이므로 직접 가져와야 함
        validated_data['content'] = self.initial_data.get('content')
        return super().create(validated_data)

    def update(self, instance, validated_data):
        """댓글 수정 - content는 SerializerMethodField이므로 직접 처리"""
        content = self.initial_data.get('content')
        if content is not None:
            instance.content = content
        instance.save()
        return instance


class PostLikeSerializer(serializers.ModelSerializer):
    """게시글 좋아요 Serializer"""

    class Meta:
        model = PostLike
        fields = ['id', 'post', 'user', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class CommentLikeSerializer(serializers.ModelSerializer):
    """댓글 좋아요 Serializer"""

    class Meta:
        model = CommentLike
        fields = ['id', 'comment', 'user', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class PostReportSerializer(serializers.Serializer):
    """게시글 신고 Serializer"""
    report_type = serializers.ChoiceField(choices=PostReport.REPORT_TYPES)
    description = serializers.CharField(required=False, allow_blank=True, default='')


class CommentReportSerializer(serializers.Serializer):
    """댓글 신고 Serializer"""
    report_type = serializers.ChoiceField(choices=CommentReport.REPORT_TYPES)
    description = serializers.CharField(required=False, allow_blank=True, default='')
