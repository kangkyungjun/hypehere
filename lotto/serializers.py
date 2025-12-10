"""
로또 모델 Serializers
"""
from rest_framework import serializers
from lotto.models import UserLottoNumber


class UserLottoNumberSerializer(serializers.ModelSerializer):
    """사용자 로또 번호 Serializer"""

    class Meta:
        model = UserLottoNumber
        fields = [
            'id',
            'round_number',  # 타겟 회차
            'number1',
            'number2',
            'number3',
            'number4',
            'number5',
            'number6',
            'matched_round',  # 실제 당첨 회차 (NEW!)
            'matched_rank',
            'matched_count',
            'has_bonus',
            'strategy_type',
            'created_at',
            'is_checked',
        ]
        read_only_fields = [
            'id',
            'matched_round',  # 자동 계산 필드
            'matched_rank',
            'matched_count',
            'has_bonus',
            'is_checked',
            'created_at',
        ]
