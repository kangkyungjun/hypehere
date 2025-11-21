import re
from rest_framework import serializers
from .models import Post, Hashtag, Like, Comment, PostFavorite, PostReport, CommentReport
from accounts.serializers import UserSerializer


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
    like_count = serializers.IntegerField(read_only=True)
    comment_count = serializers.IntegerField(read_only=True)
    is_liked = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'author', 'content',
            'native_language', 'target_language',
            'hashtags', 'like_count', 'comment_count', 'is_liked', 'is_favorited',
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


class PostCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Post data"""

    class Meta:
        model = Post
        fields = ['content', 'native_language', 'target_language']

    def create(self, validated_data):
        """Create post and extract hashtags from content"""
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
