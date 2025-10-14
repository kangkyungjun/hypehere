from rest_framework import serializers
from accounts.serializers import UserSerializer
from .models import Post, PostLike, Comment, CommentLike, Follow, UserProfile


class UserProfileSerializer(serializers.ModelSerializer):
    """사용자 프로필 Serializer"""

    user = UserSerializer(read_only=True)
    avatar_url = serializers.SerializerMethodField()
    cover_image_url = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = [
            "id",
            "user",
            "bio",
            "website",
            "location",
            "avatar",
            "avatar_url",
            "cover_image",
            "cover_image_url",
            "post_count",
            "follower_count",
            "following_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "post_count",
            "follower_count",
            "following_count",
            "created_at",
            "updated_at",
        ]

    def get_avatar_url(self, obj):
        """프로필 이미지 URL"""
        if obj.avatar:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.avatar.url)
            return obj.avatar.url
        return None

    def get_cover_image_url(self, obj):
        """커버 이미지 URL"""
        if obj.cover_image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.cover_image.url)
            return obj.cover_image.url
        return None


class PostSerializer(serializers.ModelSerializer):
    """게시글 Serializer"""

    author = UserSerializer(read_only=True)
    images = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_mine = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            "id",
            "author",
            "content",
            "images",
            "like_count",
            "comment_count",
            "view_count",
            "is_liked",
            "is_mine",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "like_count",
            "comment_count",
            "view_count",
            "is_active",
            "created_at",
            "updated_at",
        ]

    def get_images(self, obj):
        """이미지 URL 리스트"""
        request = self.context.get("request")
        images = obj.get_images()
        if request:
            return [request.build_absolute_uri(img) for img in images]
        return images

    def get_is_liked(self, obj):
        """현재 사용자가 좋아요 했는지"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return PostLike.objects.filter(post=obj, user=request.user).exists()
        return False

    def get_is_mine(self, obj):
        """내 게시글인지"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return obj.author == request.user
        return False


class PostCreateSerializer(serializers.ModelSerializer):
    """게시글 생성 Serializer"""

    class Meta:
        model = Post
        fields = ["content", "image1", "image2", "image3", "image4"]

    def validate_content(self, value):
        """내용 검증"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("게시글 내용을 입력해주세요.")

        if len(value) > 2000:
            raise serializers.ValidationError("게시글은 최대 2000자까지 입력 가능합니다.")

        return value


class CommentSerializer(serializers.ModelSerializer):
    """댓글 Serializer"""

    author = UserSerializer(read_only=True)
    is_liked = serializers.SerializerMethodField()
    is_mine = serializers.SerializerMethodField()
    reply_count = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            "id",
            "post",
            "author",
            "content",
            "parent",
            "like_count",
            "reply_count",
            "is_liked",
            "is_mine",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "like_count",
            "is_active",
            "created_at",
            "updated_at",
        ]

    def get_is_liked(self, obj):
        """현재 사용자가 좋아요 했는지"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return CommentLike.objects.filter(comment=obj, user=request.user).exists()
        return False

    def get_is_mine(self, obj):
        """내 댓글인지"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return obj.author == request.user
        return False

    def get_reply_count(self, obj):
        """대댓글 수"""
        return obj.replies.filter(is_active=True).count()


class CommentCreateSerializer(serializers.ModelSerializer):
    """댓글 생성 Serializer"""

    class Meta:
        model = Comment
        fields = ["content", "parent"]

    def validate_content(self, value):
        """내용 검증"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("댓글 내용을 입력해주세요.")

        if len(value) > 500:
            raise serializers.ValidationError("댓글은 최대 500자까지 입력 가능합니다.")

        return value

    def validate(self, attrs):
        """전체 데이터 검증"""
        parent = attrs.get("parent")

        # 대댓글의 대댓글은 불가능
        if parent and parent.parent:
            raise serializers.ValidationError(
                {"parent": "대댓글에는 답글을 달 수 없습니다."}
            )

        return attrs


class FollowSerializer(serializers.ModelSerializer):
    """팔로우 Serializer"""

    follower = UserSerializer(read_only=True)
    following = UserSerializer(read_only=True)

    class Meta:
        model = Follow
        fields = [
            "id",
            "follower",
            "following",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]
