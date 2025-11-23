from rest_framework import serializers
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.password_validation import validate_password
from .models import Follow, Block

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Simple serializer for user info in posts and other contexts"""
    display_name = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'nickname', 'display_name', 'profile_picture')
        read_only_fields = ('id', 'username', 'email', 'nickname', 'display_name', 'profile_picture')


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration

    Fields:
        - email: Login ID (unique, required)
        - nickname: Display name (duplicates allowed, required)
        - password: User password (required)
        - password_confirm: Password confirmation (required)
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ('email', 'nickname', 'password', 'password_confirm')
        extra_kwargs = {
            'email': {'required': True},
            'nickname': {'required': True},
        }

    def validate(self, attrs):
        """Validate password confirmation"""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Password fields didn't match."
            })
        return attrs

    def create(self, validated_data):
        """Create and return a new user"""
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login

    Fields:
        - email: Login ID (replaces username)
        - password: User password
    """
    email = serializers.EmailField()
    password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )

    def validate(self, attrs):
        """Validate and authenticate user"""
        email = attrs.get('email')
        password = attrs.get('password')

        if email and password:
            # Django authenticate uses 'username' parameter even when USERNAME_FIELD is 'email'
            user = authenticate(
                request=self.context.get('request'),
                username=email,  # This gets mapped to USERNAME_FIELD internally
                password=password
            )

            if not user:
                raise serializers.ValidationError(
                    'Unable to log in with provided credentials.',
                    code='authorization'
                )

            if not user.is_active:
                raise serializers.ValidationError(
                    'User account is disabled.',
                    code='authorization'
                )

            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError(
                'Must include "email" and "password".',
                code='authorization'
            )


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile"""
    display_name = serializers.ReadOnlyField()
    follower_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'email', 'nickname', 'display_name',
                  'date_of_birth', 'bio', 'profile_picture', 'address',
                  'city', 'country', 'postal_code', 'is_verified', 'is_premium',
                  'follower_count', 'following_count',
                  'created_at', 'updated_at')
        read_only_fields = ('id', 'email', 'display_name', 'is_verified',
                            'is_premium', 'follower_count', 'following_count',
                            'created_at', 'updated_at')

    def get_follower_count(self, obj):
        return obj.get_follower_count()

    def get_following_count(self, obj):
        return obj.get_following_count()


class UserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile"""

    class Meta:
        model = User
        fields = ('nickname', 'date_of_birth', 'bio', 'profile_picture',
                  'address', 'city', 'country', 'postal_code', 'gender')

    # Email cannot be changed after registration for security reasons


class PasswordChangeSerializer(serializers.Serializer):
    """Serializer for changing password"""
    old_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    new_password_confirm = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )

    def validate_old_password(self, value):
        """Validate old password"""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect.")
        return value

    def validate(self, attrs):
        """Validate new password confirmation"""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                "new_password": "New password fields didn't match."
            })
        return attrs

    def save(self, **kwargs):
        """Update user password"""
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save()
        return user


class FollowSerializer(serializers.ModelSerializer):
    """Serializer for follow relationships"""
    follower = UserSerializer(read_only=True)
    following = UserSerializer(read_only=True)

    class Meta:
        model = Follow
        fields = ('id', 'follower', 'following', 'created_at')
        read_only_fields = ('id', 'follower', 'following', 'created_at')


class UserProfileDetailSerializer(serializers.ModelSerializer):
    """Extended profile serializer with follow counts and status"""
    display_name = serializers.ReadOnlyField()
    follower_count = serializers.SerializerMethodField()
    following_count = serializers.SerializerMethodField()
    is_following = serializers.SerializerMethodField()
    is_follower = serializers.SerializerMethodField()
    posts_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'nickname', 'display_name', 'bio',
                  'profile_picture', 'is_verified', 'is_premium',
                  'follower_count', 'following_count', 'is_following',
                  'is_follower', 'posts_count', 'created_at', 'updated_at')
        read_only_fields = ('id', 'email', 'display_name', 'is_verified',
                            'is_premium', 'created_at', 'updated_at')

    def get_follower_count(self, obj):
        return obj.get_follower_count()

    def get_following_count(self, obj):
        return obj.get_following_count()

    def get_is_following(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.is_following(obj)
        return False

    def get_is_follower(self, obj):
        """Check if the profile user follows the current user back"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.is_following(request.user)
        return False

    def get_posts_count(self, obj):
        return obj.posts.count()


class PrivacySettingsSerializer(serializers.ModelSerializer):
    """Serializer for user privacy settings"""

    class Meta:
        model = User
        fields = [
            'is_private',
            'show_followers_list',
            'show_following_list'
        ]

    def validate_is_private(self, value):
        """Validate privacy setting changes"""
        return value


class BlockSerializer(serializers.ModelSerializer):
    """Serializer for block relationships"""
    blocker = UserSerializer(read_only=True)
    blocked = UserSerializer(read_only=True)

    class Meta:
        model = Block
        fields = ['id', 'blocker', 'blocked', 'created_at']
        read_only_fields = ['id', 'blocker', 'created_at']


class AccountManagementSerializer(serializers.ModelSerializer):
    """Serializer for account management (deactivation/deletion)"""
    days_until_deletion = serializers.SerializerMethodField()
    can_cancel_deletion = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'is_deactivated',
            'deactivated_at',
            'deletion_requested_at',
            'days_until_deletion',
            'can_cancel_deletion'
        ]
        read_only_fields = ['deactivated_at', 'deletion_requested_at']

    def get_days_until_deletion(self, obj):
        """Get number of days until deletion"""
        return obj.days_until_deletion()

    def get_can_cancel_deletion(self, obj):
        """Check if deletion can be cancelled"""
        return obj.can_cancel_deletion()
