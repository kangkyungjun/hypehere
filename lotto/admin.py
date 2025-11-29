from django.contrib import admin
from .models import LottoDraw, UserLottoNumber, NumberStatistics, NumberCombination


@admin.register(LottoDraw)
class LottoDrawAdmin(admin.ModelAdmin):
    list_display = ['round_number', 'draw_date', 'display_numbers', 'display_bonus',
                    'display_first_prize', 'display_second_prize', 'created_at']
    list_filter = ['draw_date', 'created_at']
    search_fields = ['round_number']
    ordering = ['-round_number']

    fieldsets = (
        ('회차 정보', {
            'fields': ('round_number', 'draw_date')
        }),
        ('당첨 번호', {
            'fields': (
                ('number1', 'number2', 'number3'),
                ('number4', 'number5', 'number6'),
            )
        }),
        ('보너스 번호', {
            'fields': ('bonus_number',)
        }),
        ('당첨 정보', {
            'fields': (
                ('first_prize_amount', 'first_prize_winners'),
                ('second_prize_amount', 'second_prize_winners'),
            )
        }),
    )

    def display_numbers(self, obj):
        """당첨 번호 6개를 보기 좋게 표시"""
        numbers = obj.get_numbers_as_list()
        return ', '.join(map(str, numbers))
    display_numbers.short_description = '당첨 번호'

    def display_bonus(self, obj):
        """보너스 번호 표시"""
        return obj.bonus_number
    display_bonus.short_description = '보너스'

    def display_first_prize(self, obj):
        """1등 당첨 정보 표시"""
        if obj.first_prize_amount and obj.first_prize_winners:
            return f"{obj.first_prize_amount:,}원 ({obj.first_prize_winners}명)"
        return '-'
    display_first_prize.short_description = '1등'

    def display_second_prize(self, obj):
        """2등 당첨 정보 표시"""
        if obj.second_prize_amount and obj.second_prize_winners:
            return f"{obj.second_prize_amount:,}원 ({obj.second_prize_winners}명)"
        return '-'
    display_second_prize.short_description = '2등'

    def save_model(self, request, obj, form, change):
        """저장 시 통계 자동 업데이트"""
        super().save_model(request, obj, form, change)

        # NumberStatistics 업데이트
        self.update_statistics(obj)

        # NumberCombination 저장
        self.save_combination(obj)

    def update_statistics(self, draw):
        """당첨 번호에 대한 통계 업데이트"""
        numbers = draw.get_numbers_as_list()

        for number in numbers:
            stat, created = NumberStatistics.objects.get_or_create(number=number)
            stat.first_prize_count += 1
            stat.total_count += 1
            stat.last_appeared_round = draw.round_number
            stat.last_appeared_date = draw.draw_date
            stat.save()

        # 보너스 번호 통계 업데이트
        bonus_stat, created = NumberStatistics.objects.get_or_create(number=draw.bonus_number)
        bonus_stat.bonus_count += 1
        bonus_stat.total_count += 1
        bonus_stat.last_appeared_round = draw.round_number
        bonus_stat.last_appeared_date = draw.draw_date
        bonus_stat.save()

    def save_combination(self, draw):
        """당첨 번호 조합 저장"""
        combination_hash = draw.get_combination_hash()
        numbers = draw.get_numbers_as_list()

        NumberCombination.objects.get_or_create(
            combination_hash=combination_hash,
            defaults={
                'numbers': numbers,
                'round_number': draw.round_number,
                'rank': '1등'
            }
        )


@admin.register(UserLottoNumber)
class UserLottoNumberAdmin(admin.ModelAdmin):
    list_display = ['user', 'round_number', 'display_numbers', 'matched_rank', 'is_checked', 'created_at']
    list_filter = ['round_number', 'matched_rank', 'is_checked', 'created_at']
    search_fields = ['user__email', 'user__nickname', 'round_number']
    ordering = ['-round_number', '-created_at']
    readonly_fields = ['matched_rank', 'matched_count', 'has_bonus', 'is_checked']

    fieldsets = (
        ('사용자 정보', {
            'fields': ('user', 'round_number')
        }),
        ('선택 번호', {
            'fields': (
                ('number1', 'number2', 'number3'),
                ('number4', 'number5', 'number6'),
            )
        }),
        ('당첨 결과', {
            'fields': ('matched_rank', 'matched_count', 'has_bonus', 'is_checked'),
            'classes': ('collapse',)
        }),
    )

    def display_numbers(self, obj):
        """선택한 번호 6개를 보기 좋게 표시"""
        numbers = obj.get_numbers_as_list()
        return ', '.join(map(str, numbers))
    display_numbers.short_description = '선택 번호'


@admin.register(NumberStatistics)
class NumberStatisticsAdmin(admin.ModelAdmin):
    list_display = ['number', 'total_count', 'first_prize_count', 'bonus_count', 'last_appeared_round', 'last_appeared_date']
    list_filter = ['last_appeared_date']
    search_fields = ['number']
    ordering = ['number']
    readonly_fields = ['first_prize_count', 'second_prize_count', 'bonus_count', 'total_count',
                       'last_appeared_round', 'last_appeared_date', 'updated_at']

    fieldsets = (
        ('번호 정보', {
            'fields': ('number',)
        }),
        ('출현 통계', {
            'fields': ('first_prize_count', 'second_prize_count', 'bonus_count', 'total_count')
        }),
        ('최근 출현', {
            'fields': ('last_appeared_round', 'last_appeared_date', 'updated_at')
        }),
    )


@admin.register(NumberCombination)
class NumberCombinationAdmin(admin.ModelAdmin):
    list_display = ['round_number', 'rank', 'display_numbers', 'created_at']
    list_filter = ['rank', 'round_number', 'created_at']
    search_fields = ['round_number']
    ordering = ['-round_number']
    readonly_fields = ['combination_hash', 'created_at']

    fieldsets = (
        ('조합 정보', {
            'fields': ('round_number', 'rank', 'numbers')
        }),
        ('해시 및 생성일', {
            'fields': ('combination_hash', 'created_at'),
            'classes': ('collapse',)
        }),
    )

    def display_numbers(self, obj):
        """저장된 번호 조합 표시"""
        return ', '.join(map(str, obj.numbers))
    display_numbers.short_description = '번호 조합'
