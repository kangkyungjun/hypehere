from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import User, Interest, UserInterest


class InterestSerializer(serializers.ModelSerializer):
    """관심사 Serializer"""

    class Meta:
        model = Interest
        fields = ["id", "category", "name", "name_ko", "name_en", "icon"]


class UserSerializer(serializers.ModelSerializer):
    """사용자 기본 정보 Serializer"""

    interests = serializers.SerializerMethodField()
    is_premium = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "nickname",
            "email",
            "country_code",
            "bio",
            "gender",
            "role",
            "is_premium",
            "daily_match_count",
            "is_banned",
            "created_at",
            "updated_at",  # Added for Flutter User model compatibility
            "interests",
        ]
        read_only_fields = [
            "id",
            "role",
            "daily_match_count",
            "is_banned",
            "created_at",
        ]

    def get_interests(self, obj):
        """사용자의 관심사 목록 반환"""
        user_interests = UserInterest.objects.filter(user=obj).select_related("interest")
        return InterestSerializer([ui.interest for ui in user_interests], many=True).data

    def get_is_premium(self, obj):
        """프리미엄 활성 상태 반환"""
        return obj.is_premium_active()


class RegisterSerializer(serializers.ModelSerializer):
    """회원가입 Serializer"""

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={"input_type": "password"}
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        style={"input_type": "password"}
    )
    interest_ids = serializers.PrimaryKeyRelatedField(
        queryset=Interest.objects.all(),
        many=True,
        required=True,
        help_text="최소 3개의 관심사를 선택해주세요"
    )

    class Meta:
        model = User
        fields = [
            "username",
            "password",
            "password2",
            "email",
            "nickname",
            "country_code",
            "bio",
            "gender",
            "interest_ids",
        ]

    def validate(self, attrs):
        """비밀번호 확인 및 관심사 개수 검증"""
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError(
                {"password": "비밀번호가 일치하지 않습니다."}
            )

        # 관심사 최소 3개, 최대 10개 검증
        interest_count = len(attrs.get("interest_ids", []))
        if interest_count < 3:
            raise serializers.ValidationError(
                {"interest_ids": "최소 3개의 관심사를 선택해주세요."}
            )
        if interest_count > 10:
            raise serializers.ValidationError(
                {"interest_ids": "최대 10개의 관심사만 선택할 수 있습니다."}
            )

        return attrs

    def validate_nickname(self, value):
        """닉네임 중복 확인"""
        if User.objects.filter(nickname=value).exists():
            raise serializers.ValidationError("이미 사용 중인 닉네임입니다.")
        return value

    def create(self, validated_data):
        """회원가입 처리"""
        # password2와 interest_ids 제거
        validated_data.pop("password2")
        interest_ids = validated_data.pop("interest_ids")

        # 사용자 생성 (role은 기본값 visitor에서 user로 변경)
        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data.get("email", ""),
            password=validated_data["password"],
            nickname=validated_data["nickname"],
            country_code=validated_data["country_code"],
            bio=validated_data.get("bio", ""),
            gender=validated_data.get("gender", None),
            role=User.Role.USER,  # 가입 시 USER 권한으로 설정
        )

        # 관심사 등록
        for interest in interest_ids:
            UserInterest.objects.create(user=user, interest=interest)

        return user


class LoginSerializer(serializers.Serializer):
    """로그인 Serializer"""

    email = serializers.CharField(required=True)
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={"input_type": "password"}
    )

    def validate(self, attrs):
        """로그인 검증"""
        email = attrs.get("email")
        password = attrs.get("password")

        if email and password:
            # email로 직접 인증 (USERNAME_FIELD가 email이므로)
            user = authenticate(
                request=self.context.get("request"),
                username=email,  # USERNAME_FIELD=email이므로 email 전달
                password=password
            )

            if not user:
                raise serializers.ValidationError(
                    "이메일 또는 비밀번호가 올바르지 않습니다."
                )

            # 계정 정지 확인
            if user.is_banned_now():
                raise serializers.ValidationError(
                    "정지된 계정입니다. 관리자에게 문의하세요."
                )

            attrs["user"] = user
            return attrs

        raise serializers.ValidationError(
            "이메일과 비밀번호를 모두 입력해주세요."
        )


class ProfileUpdateSerializer(serializers.ModelSerializer):
    """프로필 수정 Serializer"""

    interest_ids = serializers.PrimaryKeyRelatedField(
        queryset=Interest.objects.all(),
        many=True,
        required=False
    )

    class Meta:
        model = User
        fields = [
            "nickname",
            "bio",
            "gender",
            "country_code",
            "interest_ids",
        ]

    def validate_nickname(self, value):
        """닉네임 중복 확인 (본인 제외)"""
        user = self.context["request"].user
        if User.objects.filter(nickname=value).exclude(id=user.id).exists():
            raise serializers.ValidationError("이미 사용 중인 닉네임입니다.")
        return value

    def update(self, instance, validated_data):
        """프로필 업데이트"""
        interest_ids = validated_data.pop("interest_ids", None)

        # 기본 정보 업데이트
        instance.nickname = validated_data.get("nickname", instance.nickname)
        instance.bio = validated_data.get("bio", instance.bio)
        instance.gender = validated_data.get("gender", instance.gender)
        instance.country_code = validated_data.get("country_code", instance.country_code)
        instance.save()

        # 관심사 업데이트
        if interest_ids is not None:
            # 기존 관심사 삭제
            UserInterest.objects.filter(user=instance).delete()

            # 새 관심사 등록
            for interest in interest_ids:
                UserInterest.objects.create(user=instance, interest=interest)

        return instance


class ChangePasswordSerializer(serializers.Serializer):
    """비밀번호 변경 Serializer"""

    old_password = serializers.CharField(
        required=True,
        write_only=True,
        style={"input_type": "password"}
    )
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password],
        style={"input_type": "password"}
    )
    new_password2 = serializers.CharField(
        required=True,
        write_only=True,
        style={"input_type": "password"}
    )

    def validate(self, attrs):
        """비밀번호 확인"""
        if attrs["new_password"] != attrs["new_password2"]:
            raise serializers.ValidationError(
                {"new_password": "새 비밀번호가 일치하지 않습니다."}
            )
        return attrs

    def validate_old_password(self, value):
        """기존 비밀번호 확인"""
        user = self.context["request"].user
        if not user.check_password(value):
            raise serializers.ValidationError("기존 비밀번호가 올바르지 않습니다.")
        return value

    def save(self):
        """비밀번호 변경"""
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save()
        return user
