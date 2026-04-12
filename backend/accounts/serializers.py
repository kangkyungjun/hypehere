from rest_framework import serializers
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.password_validation import validate_password
from .models import DeviceToken

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """사용자 정보 Serializer (Flutter CommunityUser 호환)"""

    class Meta:
        model = User
        fields = [
            'id', 'email', 'nickname', 'profile_picture', 'bio',
            'watchlist_tickers', 'role', 'is_email_verified', 'created_at'
        ]
        read_only_fields = ['id', 'email', 'role', 'is_email_verified', 'created_at']


class RegisterSerializer(serializers.ModelSerializer):
    """회원가입 Serializer (Flutter 호환: password_confirm)"""

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        label='비밀번호 확인'
    )

    class Meta:
        model = User
        fields = ['email', 'nickname', 'password', 'password_confirm']

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                'password_confirm': '비밀번호가 일치하지 않습니다.'
            })
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        email = validated_data['email']
        # username is required by create_user(); model.save() handles dedup
        base_username = email.split('@')[0]
        user = User.objects.create_user(
            username=base_username,
            email=email,
            nickname=validated_data['nickname'],
            password=validated_data['password'],
        )
        return user


class LoginSerializer(serializers.Serializer):
    """로그인 Serializer (Flutter 호환)"""

    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        # Django authenticate uses USERNAME_FIELD
        user = authenticate(
            request=self.context.get('request'),
            username=email,
            password=password,
        )
        if not user:
            raise serializers.ValidationError('이메일 또는 비밀번호가 올바르지 않습니다.')
        if not user.is_active:
            raise serializers.ValidationError('비활성화된 계정입니다.')

        attrs['user'] = user
        return attrs


class ChangePasswordSerializer(serializers.Serializer):
    """비밀번호 변경 Serializer (Flutter 호환: new_password_confirm)"""

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

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                'new_password_confirm': '새 비밀번호가 일치하지 않습니다.'
            })
        return attrs

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('기존 비밀번호가 올바르지 않습니다.')
        return value


class DeviceTokenSerializer(serializers.Serializer):
    """FCM 디바이스 토큰 등록/갱신 (uniqueness handled by view's update_or_create)"""
    token = serializers.CharField()
    platform = serializers.ChoiceField(choices=DeviceToken.PLATFORM_CHOICES)
    language = serializers.CharField(max_length=10, default='en')


class SubscriptionSyncSerializer(serializers.Serializer):
    """Watchlist 구독 동기화"""
    tickers = serializers.ListField(
        child=serializers.CharField(max_length=50),
        allow_empty=True,
    )


class SendVerificationCodeSerializer(serializers.Serializer):
    """인증코드 발송 요청"""
    email = serializers.EmailField(required=True)
    purpose = serializers.ChoiceField(choices=['signup', 'password_reset'], required=True)


class VerifyCodeSerializer(serializers.Serializer):
    """인증코드 확인"""
    email = serializers.EmailField(required=True)
    code = serializers.CharField(max_length=6, min_length=6, required=True)
    purpose = serializers.ChoiceField(choices=['signup', 'password_reset'], required=True)


class PasswordResetConfirmSerializer(serializers.Serializer):
    """비밀번호 재설정 확인"""
    email = serializers.EmailField(required=True)
    code = serializers.CharField(max_length=6, min_length=6, required=True)
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password],
        style={'input_type': 'password'},
    )
    new_password_confirm = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
    )

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                'new_password_confirm': '새 비밀번호가 일치하지 않습니다.'
            })
        return attrs
