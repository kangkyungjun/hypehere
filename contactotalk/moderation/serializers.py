from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from accounts.serializers import UserSerializer
from .models import Report, UserSanction, ModerationLog


class ReportSerializer(serializers.ModelSerializer):
    """신고 Serializer"""

    reporter = UserSerializer(read_only=True)
    reviewer = UserSerializer(read_only=True)

    class Meta:
        model = Report
        fields = [
            "id",
            "reporter",
            "report_type",
            "content_type",
            "object_id",
            "reason",
            "description",
            "status",
            "reviewer",
            "resolution",
            "resolved_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "reporter",
            "content_type",
            "object_id",
            "status",
            "reviewer",
            "resolution",
            "resolved_at",
            "created_at",
            "updated_at",
        ]


class ReportCreateSerializer(serializers.Serializer):
    """신고 생성 Serializer"""

    report_type = serializers.ChoiceField(choices=Report.ReportType.choices)
    object_id = serializers.IntegerField()
    reason = serializers.ChoiceField(choices=Report.ReportReason.choices)
    description = serializers.CharField(max_length=500)

    def validate_description(self, value):
        """상세 설명 검증"""
        if not value or len(value.strip()) == 0:
            raise serializers.ValidationError("신고 사유를 입력해주세요.")

        if len(value) > 500:
            raise serializers.ValidationError("신고 사유는 최대 500자까지 입력 가능합니다.")

        return value

    def validate(self, attrs):
        """전체 데이터 검증"""
        report_type = attrs.get("report_type")
        object_id = attrs.get("object_id")

        # ContentType 결정
        content_type_mapping = {
            Report.ReportType.USER: "accounts.user",
            Report.ReportType.POST: "social.post",
            Report.ReportType.COMMENT: "social.comment",
            Report.ReportType.MESSAGE: "chat.message",
            Report.ReportType.OPEN_CHAT_MESSAGE: "chat.openchatmessage",
        }

        app_label, model = content_type_mapping[report_type].split(".")

        try:
            content_type = ContentType.objects.get(app_label=app_label, model=model)
        except ContentType.DoesNotExist:
            raise serializers.ValidationError(
                {"report_type": "잘못된 신고 타입입니다."}
            )

        # 대상 객체 존재 여부 확인
        model_class = content_type.model_class()
        if not model_class.objects.filter(id=object_id).exists():
            raise serializers.ValidationError(
                {"object_id": "신고 대상이 존재하지 않습니다."}
            )

        attrs["content_type"] = content_type
        return attrs

    def create(self, validated_data):
        """신고 생성"""
        reporter = self.context["request"].user

        report = Report.objects.create(
            reporter=reporter,
            report_type=validated_data["report_type"],
            content_type=validated_data["content_type"],
            object_id=validated_data["object_id"],
            reason=validated_data["reason"],
            description=validated_data["description"],
        )

        return report


class UserSanctionSerializer(serializers.ModelSerializer):
    """사용자 제재 Serializer"""

    user = UserSerializer(read_only=True)
    sanctioned_by = UserSerializer(read_only=True)
    is_expired = serializers.SerializerMethodField()

    class Meta:
        model = UserSanction
        fields = [
            "id",
            "user",
            "sanction_type",
            "reason",
            "start_date",
            "end_date",
            "sanctioned_by",
            "related_report",
            "is_active",
            "is_expired",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "sanctioned_by",
            "is_active",
            "created_at",
            "updated_at",
        ]

    def get_is_expired(self, obj):
        """제재 만료 여부"""
        return obj.is_expired()


class ModerationLogSerializer(serializers.ModelSerializer):
    """관리 로그 Serializer"""

    moderator = UserSerializer(read_only=True)

    class Meta:
        model = ModerationLog
        fields = [
            "id",
            "moderator",
            "action_type",
            "description",
            "content_type",
            "object_id",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "moderator",
            "action_type",
            "description",
            "content_type",
            "object_id",
            "created_at",
        ]


class ModerationStatsSerializer(serializers.Serializer):
    """관리 통계 Serializer"""

    total_reports = serializers.IntegerField()
    pending_reports = serializers.IntegerField()
    reviewing_reports = serializers.IntegerField()
    resolved_reports = serializers.IntegerField()
    rejected_reports = serializers.IntegerField()

    total_sanctions = serializers.IntegerField()
    active_sanctions = serializers.IntegerField()
    warnings = serializers.IntegerField()
    temp_bans = serializers.IntegerField()
    perm_bans = serializers.IntegerField()

    total_actions = serializers.IntegerField()
    recent_actions = ModerationLogSerializer(many=True, read_only=True)
