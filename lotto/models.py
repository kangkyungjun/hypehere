import hashlib
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.conf import settings


class LottoDraw(models.Model):
    """회차별 로또 당첨 정보"""
    round_number = models.IntegerField(unique=True, verbose_name="회차 번호")
    draw_date = models.DateField(verbose_name="추첨일")

    # 1등 당첨 번호 (6개)
    number1 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 1"
    )
    number2 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 2"
    )
    number3 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 3"
    )
    number4 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 4"
    )
    number5 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 5"
    )
    number6 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 6"
    )
    bonus_number = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="보너스 번호"
    )

    # 1등 정보
    first_prize_amount = models.BigIntegerField(
        null=True,
        blank=True,
        verbose_name="1등 총당첨금"
    )
    first_prize_winners = models.IntegerField(
        null=True,
        blank=True,
        verbose_name="1등 당첨자수"
    )

    # 2등 정보
    second_prize_amount = models.BigIntegerField(
        null=True,
        blank=True,
        verbose_name="2등 총당첨금"
    )
    second_prize_winners = models.IntegerField(
        null=True,
        blank=True,
        verbose_name="2등 당첨자수"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-round_number']
        verbose_name = "로또 추첨"
        verbose_name_plural = "로또 추첨 목록"
        indexes = [
            models.Index(fields=['round_number']),
            models.Index(fields=['draw_date']),
        ]

    def __str__(self):
        return f"{self.round_number}회차 ({self.draw_date})"

    def get_numbers_as_list(self):
        """당첨 번호를 리스트로 반환"""
        return sorted([
            self.number1, self.number2, self.number3,
            self.number4, self.number5, self.number6
        ])

    def get_numbers_as_set(self):
        """당첨 번호를 집합으로 반환"""
        return set(self.get_numbers_as_list())

    def get_combination_hash(self):
        """당첨 번호 조합의 해시값 생성"""
        numbers = self.get_numbers_as_list()
        return hashlib.sha256(str(numbers).encode()).hexdigest()


class UserLottoNumber(models.Model):
    """사용자가 저장한 로또 번호"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='lotto_numbers',
        verbose_name="사용자"
    )
    round_number = models.IntegerField(verbose_name="회차 번호")

    # 선택한 6개 번호
    number1 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 1"
    )
    number2 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 2"
    )
    number3 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 3"
    )
    number4 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 4"
    )
    number5 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 5"
    )
    number6 = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호 6"
    )

    # 당첨 결과 (자동 계산)
    matched_round = models.IntegerField(
        null=True,
        blank=True,
        verbose_name="실제 당첨 회차"
    )  # 실제로 당첨된 회차 (round_number와 다를 수 있음)
    matched_rank = models.CharField(
        max_length=10,
        null=True,
        blank=True,
        verbose_name="당첨 등수"
    )
    matched_count = models.IntegerField(default=0, verbose_name="일치 개수")
    has_bonus = models.BooleanField(default=False, verbose_name="보너스 일치")

    # 생성 전략
    strategy_type = models.CharField(
        max_length=20,
        choices=[
            ('basic', '기본'),
            ('strategy1', '추가1'),
            ('strategy2', '추가2'),
            ('strategy3', '추가3'),
            ('strategy4', '추가4'),
        ],
        default='basic',
        verbose_name="생성 전략"
    )

    is_checked = models.BooleanField(default=False, verbose_name="확인 완료")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-round_number', '-created_at']
        verbose_name = "사용자 로또 번호"
        verbose_name_plural = "사용자 로또 번호 목록"
        indexes = [
            models.Index(fields=['user', 'round_number']),
            models.Index(fields=['round_number', 'is_checked']),
        ]

    def __str__(self):
        return f"{self.user.nickname} - {self.round_number}회차"

    def get_numbers_as_list(self):
        """선택한 번호를 리스트로 반환"""
        return sorted([
            self.number1, self.number2, self.number3,
            self.number4, self.number5, self.number6
        ])

    def get_numbers_as_set(self):
        """선택한 번호를 집합으로 반환"""
        return set(self.get_numbers_as_list())

    def get_combination_hash(self):
        """선택한 번호 조합의 해시값 생성"""
        numbers = self.get_numbers_as_list()
        return hashlib.sha256(str(numbers).encode()).hexdigest()

    def check_winning(self):
        """
        타겟 회차 이후 모든 추첨과 비교하여 당첨 여부 확인

        Returns:
            bool: 당첨되었으면 True, 아니면 False
        """
        # 타겟 회차 이후 모든 추첨 가져오기 (타겟 회차 포함)
        draws = LottoDraw.objects.filter(
            round_number__gte=self.round_number
        ).order_by('round_number')

        # 내 번호
        my_numbers = self.get_numbers_as_set()

        for draw in draws:
            # 당첨 번호
            winning_numbers = draw.get_numbers_as_set()

            # 일치 개수 계산
            matched = len(my_numbers & winning_numbers)

            # 보너스 번호 일치 여부
            has_bonus = draw.bonus_number in my_numbers

            # 등수 결정
            rank = None
            if matched == 6:
                rank = '1등'
            elif matched == 5 and has_bonus:
                rank = '2등'
            elif matched == 5 and not has_bonus:
                rank = '3등'
            elif matched == 4 and not has_bonus:
                rank = '4등'
            # 5등(3개 일치) 체크 제거 - 4등까지만 확인

            # 당첨된 경우
            if rank:
                self.matched_round = draw.round_number  # 실제 당첨 회차 저장
                self.matched_rank = rank
                self.matched_count = matched
                self.has_bonus = has_bonus
                self.is_checked = True
                self.save()
                return True

        # 당첨되지 않은 경우
        self.is_checked = True
        self.save()
        return False


class NumberStatistics(models.Model):
    """로또 번호별 출현 통계"""
    number = models.IntegerField(
        unique=True,
        validators=[MinValueValidator(1), MaxValueValidator(45)],
        verbose_name="번호"
    )

    # 출현 횟수
    first_prize_count = models.IntegerField(default=0, verbose_name="1등 출현 횟수")
    second_prize_count = models.IntegerField(default=0, verbose_name="2등 출현 횟수")
    bonus_count = models.IntegerField(default=0, verbose_name="보너스 출현 횟수")
    total_count = models.IntegerField(default=0, verbose_name="전체 출현 횟수")

    last_appeared_round = models.IntegerField(
        null=True,
        blank=True,
        verbose_name="마지막 출현 회차"
    )
    last_appeared_date = models.DateField(
        null=True,
        blank=True,
        verbose_name="마지막 출현일"
    )

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['number']
        verbose_name = "번호 통계"
        verbose_name_plural = "번호 통계 목록"

    def __str__(self):
        return f"번호 {self.number} (출현 {self.total_count}회)"


class NumberCombination(models.Model):
    """이미 나온 번호 조합 추적"""
    combination_hash = models.CharField(
        max_length=64,
        verbose_name="조합 해시"
    )
    numbers = models.JSONField(verbose_name="번호 조합")  # [1, 5, 12, 23, 34, 45]
    round_number = models.IntegerField(verbose_name="회차 번호")
    rank = models.CharField(max_length=10, verbose_name="등수")  # '1등', '2등', etc.

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-round_number']
        verbose_name = "번호 조합"
        verbose_name_plural = "번호 조합 목록"
        indexes = [
            models.Index(fields=['combination_hash']),
            models.Index(fields=['round_number']),
            models.Index(fields=['rank']),
        ]

    def __str__(self):
        return f"{self.round_number}회차 - {self.rank} ({self.numbers})"


class OverlapStatistics(models.Model):
    """등수 간 중복 통계 캐시 테이블"""
    rank_pair = models.CharField(
        max_length=10,
        unique=True,
        verbose_name="등수 쌍"
    )  # "1-2", "1-3", "1-4", "2-3", "2-4", "3-4"
    overlap_count = models.IntegerField(
        default=0,
        verbose_name="중복 개수"
    )
    last_updated = models.DateTimeField(auto_now=True, verbose_name="마지막 업데이트")

    class Meta:
        verbose_name = "중복 통계"
        verbose_name_plural = "중복 통계 목록"
        ordering = ['rank_pair']

    def __str__(self):
        return f"{self.rank_pair} 중복: {self.overlap_count}회"


class OverlapDetail(models.Model):
    """등수 간 중복 상세 정보 캐시 테이블"""
    rank_pair = models.CharField(
        max_length=10,
        verbose_name="등수 쌍",
        db_index=True
    )  # "1-2", "1-3", "1-4", "2-3", "2-4", "3-4"
    combination_hash = models.CharField(
        max_length=64,
        verbose_name="조합 해시"
    )
    numbers = models.JSONField(verbose_name="번호 조합")  # [1, 5, 12, 23, 34, 45]

    # 첫 번째 등수 정보
    first_rank = models.CharField(max_length=10, verbose_name="첫 번째 등수")
    first_rank_round = models.IntegerField(verbose_name="첫 번째 등수 회차")
    first_rank_date = models.DateField(verbose_name="첫 번째 등수 날짜")

    # 두 번째 등수 정보
    second_rank = models.CharField(max_length=10, verbose_name="두 번째 등수")
    second_rank_round = models.IntegerField(verbose_name="두 번째 등수 회차")
    second_rank_date = models.DateField(verbose_name="두 번째 등수 날짜")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "중복 상세 정보"
        verbose_name_plural = "중복 상세 정보 목록"
        ordering = ['rank_pair', '-first_rank_round']
        indexes = [
            models.Index(fields=['rank_pair']),
            models.Index(fields=['combination_hash']),
        ]

    def __str__(self):
        return f"{self.rank_pair} 중복: {self.numbers} ({self.first_rank_round}회, {self.second_rank_round}회)"


class StrategyStatistics(models.Model):
    """전략별 확률 통계 캐시 테이블"""
    strategy_type = models.CharField(
        max_length=20,
        unique=True,
        verbose_name="전략 타입"
    )  # 'strategy1', 'strategy2', 'strategy3', 'strategy4'
    round_number = models.IntegerField(
        verbose_name="계산 기준 회차"
    )
    total_theoretical = models.IntegerField(
        verbose_name="이론적 전체 조합 수"
    )
    excluded_count = models.IntegerField(
        verbose_name="제외된 조합 수"
    )
    remaining_count = models.IntegerField(
        verbose_name="남은 조합 수"
    )
    probability = models.FloatField(
        verbose_name="당첨 확률"
    )
    improvement_ratio = models.FloatField(
        verbose_name="일반 로또 대비 배수"
    )
    last_updated = models.DateTimeField(
        auto_now=True,
        verbose_name="마지막 업데이트"
    )

    class Meta:
        verbose_name = "전략 통계"
        verbose_name_plural = "전략 통계 목록"
        ordering = ['strategy_type']

    def __str__(self):
        return f"{self.strategy_type} - {self.round_number}회차 (확률: 1/{self.remaining_count:,})"


class StrategyStatisticsHistory(models.Model):
    """전략별 확률 통계 히스토리 - 회차별 변화 추적"""
    strategy_type = models.CharField(
        max_length=20,
        verbose_name="전략 타입"
    )
    round_number = models.IntegerField(
        verbose_name="회차"
    )

    # 통계 데이터
    total_theoretical = models.IntegerField(
        verbose_name="이론적 전체 조합 수"
    )
    excluded_count = models.IntegerField(
        verbose_name="제외된 조합 수"
    )
    remaining_count = models.IntegerField(
        verbose_name="남은 조합 수"
    )
    probability = models.FloatField(
        verbose_name="당첨 확률"
    )
    improvement_ratio = models.FloatField(
        verbose_name="일반 로또 대비 배수"
    )

    # 전 회차 대비 변화량 (첫 회차는 NULL)
    change_remaining = models.IntegerField(
        null=True,
        blank=True,
        verbose_name="조합 수 변화"
    )
    change_probability_pct = models.FloatField(
        null=True,
        blank=True,
        verbose_name="확률 변화 %"
    )
    change_ratio = models.FloatField(
        null=True,
        blank=True,
        verbose_name="개선 배수 변화"
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name="생성일시"
    )

    class Meta:
        unique_together = ['strategy_type', 'round_number']
        ordering = ['-round_number', 'strategy_type']
        verbose_name = "전략 통계 히스토리"
        verbose_name_plural = "전략 통계 히스토리 목록"
        indexes = [
            models.Index(fields=['strategy_type', '-round_number']),
        ]

    def __str__(self):
        return f"{self.strategy_type} - {self.round_number}회차"


