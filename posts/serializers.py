import re
from rest_framework import serializers
from .models import Post, PostImage, Hashtag, Like, Comment, PostFavorite, PostReport, CommentReport
from accounts.serializers import UserSerializer


class PostImageSerializer(serializers.ModelSerializer):
    """Serializer for PostImage model"""

    class Meta:
        model = PostImage
        fields = ['id', 'image', 'order', 'created_at']
        read_only_fields = ['id', 'created_at']


class HashtagSerializer(serializers.ModelSerializer):
    """Serializer for Hashtag model"""

    class Meta:
        model = Hashtag
        fields = ['id', 'name', 'created_at']
        read_only_fields = ['id', 'created_at']


class PostSerializer(serializers.ModelSerializer):
    """Serializer for reading Post data"""
    author = UserSerializer(read_only=True)
    hashtags = HashtagSerializer(many=True, read_only=True)
    images = PostImageSerializer(many=True, read_only=True)
    like_count = serializers.IntegerField(read_only=True)
    comment_count = serializers.IntegerField(read_only=True)
    is_liked = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    is_deleted_by_admin = serializers.SerializerMethodField()
    deleted_info = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'author', 'title', 'content', 'ticker',
            'native_language', 'target_language',
            'hashtags', 'images', 'like_count', 'comment_count', 'is_liked', 'is_favorited',
            'can_edit', 'can_delete',
            'is_deleted_by_admin', 'deleted_info',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'author', 'created_at', 'updated_at']

    def get_is_liked(self, obj):
        """Check if current user has liked this post"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False

    def get_is_favorited(self, obj):
        """Check if current user has favorited this post"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.favorited_by.filter(user=request.user).exists()
        return False

    def get_can_edit(self, obj):
        """Check if current user can edit this post (author or admin)"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.author == request.user or request.user.is_admin()
        return False

    def get_can_delete(self, obj):
        """Check if current user can delete this post (author or admin)"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.author == request.user or request.user.is_admin()
        return False

    def get_is_deleted_by_admin(self, obj):
        """관리자에 의해 삭제되었는지 여부"""
        return obj.is_deleted_by_report

    def get_deleted_info(self, obj):
        """삭제 정보 반환 (관리자와 작성자에게만)"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            if obj.is_deleted_by_report:
                content_data = obj.get_content_for_user(request.user)
                return {
                    'deleted_at': obj.deleted_at,
                    'deleted_by': obj.deleted_by.nickname if obj.deleted_by else None,
                    'deletion_reason': obj.get_deletion_reason_display() if obj.deletion_reason else None,
                    'admin_view': content_data.get('admin_view', False)
                }
        return None

    def to_representation(self, instance):
        """content 필드를 사용자 역할에 따라 조건부 반환"""
        representation = super().to_representation(instance)

        request = self.context.get('request')
        if request and request.user.is_authenticated:
            if instance.is_deleted_by_report:
                content_data = instance.get_content_for_user(request.user)
                representation['content'] = content_data['content']

        return representation


class PostCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Post data with image uploads"""
    images = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=False,
        max_length=5,  # Maximum 5 images
        allow_empty=True
    )

    class Meta:
        model = Post
        fields = ['title', 'content', 'ticker', 'native_language', 'target_language', 'images']

    def validate_images(self, value):
        """Validate uploaded images"""
        if len(value) > 5:
            raise serializers.ValidationError("Maximum 5 images allowed per post")
        return value

    def create(self, validated_data):
        """Create post, extract hashtags, and associate images"""
        # Extract images from validated_data (if present)
        images_data = validated_data.pop('images', [])

        # Extract hashtags from content
        content = validated_data.get('content', '')
        hashtag_pattern = r'#([a-zA-Z0-9가-힣_]+)'
        hashtag_names = re.findall(hashtag_pattern, content)

        # Create the post
        post = Post.objects.create(**validated_data)

        # Create or get hashtags and associate with post
        for name in hashtag_names:
            hashtag, created = Hashtag.objects.get_or_create(name=name.lower())
            post.hashtags.add(hashtag)

        # Create PostImage instances for each uploaded image
        for index, image_file in enumerate(images_data):
            PostImage.objects.create(
                post=post,
                image=image_file,
                order=index
            )

        return post


class LikeSerializer(serializers.ModelSerializer):
    """Serializer for Like data"""
    user = UserSerializer(read_only=True)

    class Meta:
        model = Like
        fields = ['id', 'user', 'post', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class CommentSerializer(serializers.ModelSerializer):
    """Serializer for reading Comment data"""
    author = UserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'post', 'author', 'content', 'created_at', 'updated_at']
        read_only_fields = ['id', 'post', 'author', 'created_at', 'updated_at']


class CommentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Comment data"""

    class Meta:
        model = Comment
        fields = ['content']

    def validate_content(self, value):
        """Validate comment content is not empty"""
        if not value.strip():
            raise serializers.ValidationError("Comment cannot be empty")
        return value


class PostFavoriteSerializer(serializers.ModelSerializer):
    """Serializer for PostFavorite with nested post data"""
    post = PostSerializer(read_only=True)

    class Meta:
        model = PostFavorite
        fields = ['id', 'post', 'created_at']
        read_only_fields = ['id', 'created_at']


class PostReportSerializer(serializers.ModelSerializer):
    """Serializer for PostReport data"""
    reporter_nickname = serializers.CharField(source='reporter.nickname', read_only=True)
    reported_user_nickname = serializers.CharField(source='reported_user.nickname', read_only=True)

    class Meta:
        model = PostReport
        fields = [
            'id', 'reporter', 'reporter_nickname',
            'reported_user', 'reported_user_nickname',
            'post', 'report_type', 'description',
            'status', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'status', 'created_at']


class CommentReportSerializer(serializers.ModelSerializer):
    """Serializer for CommentReport data"""
    reporter_nickname = serializers.CharField(source='reporter.nickname', read_only=True)
    reported_user_nickname = serializers.CharField(source='reported_user.nickname', read_only=True)

    class Meta:
        model = CommentReport
        fields = [
            'id', 'reporter', 'reporter_nickname',
            'reported_user', 'reported_user_nickname',
            'comment', 'report_type', 'description',
            'status', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'status', 'created_at']
