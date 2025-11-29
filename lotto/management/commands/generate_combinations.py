from django.core.management.base import BaseCommand
from django.db import transaction
from lotto.models import LottoDraw, NumberCombination, NumberStatistics
from collections import defaultdict


class Command(BaseCommand):
    help = '1등 조합 생성 및 번호 통계 업데이트'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('1등 조합 생성 및 통계 업데이트 시작...'))

        # 모든 추첨 데이터 가져오기
        draws = LottoDraw.objects.all().order_by('round_number')
        total = draws.count()

        self.stdout.write(self.style.NOTICE(f'총 {total}개 회차 처리 중...'))

        # 번호별 통계 수집용 딕셔너리
        stats_data = defaultdict(lambda: {
            'first_prize_count': 0,
            'bonus_count': 0,
            'total_count': 0,
            'last_appeared_round': None,
            'last_appeared_date': None,
        })

        # 1등 조합 리스트
        combinations = []

        # 각 회차별 처리
        for idx, draw in enumerate(draws, 1):
            # 1등 조합 생성
            combination_hash = draw.get_combination_hash()
            numbers = draw.get_numbers_as_list()

            combinations.append(NumberCombination(
                combination_hash=combination_hash,
                numbers=numbers,
                round_number=draw.round_number,
                rank='1등'
            ))

            # 당첨 번호 6개 통계 수집
            for number in numbers:
                stats_data[number]['first_prize_count'] += 1
                stats_data[number]['total_count'] += 1
                stats_data[number]['last_appeared_round'] = draw.round_number
                stats_data[number]['last_appeared_date'] = draw.draw_date

            # 보너스 번호 통계 수집
            bonus = draw.bonus_number
            stats_data[bonus]['bonus_count'] += 1
            stats_data[bonus]['total_count'] += 1
            stats_data[bonus]['last_appeared_round'] = draw.round_number
            stats_data[bonus]['last_appeared_date'] = draw.draw_date

            # 진행 상황 출력 (100개마다)
            if idx % 100 == 0:
                self.stdout.write(
                    self.style.SUCCESS(f'{idx}/{total} 회차 처리 완료...')
                )

        # 데이터베이스에 저장
        self.stdout.write(self.style.NOTICE('데이터베이스에 저장 중...'))

        with transaction.atomic():
            # 기존 데이터 삭제
            deleted_combinations = NumberCombination.objects.all().delete()[0]
            deleted_stats = NumberStatistics.objects.all().delete()[0]

            if deleted_combinations > 0:
                self.stdout.write(
                    self.style.WARNING(f'기존 조합 {deleted_combinations}개 삭제됨')
                )
            if deleted_stats > 0:
                self.stdout.write(
                    self.style.WARNING(f'기존 통계 {deleted_stats}개 삭제됨')
                )

            # NumberCombination 일괄 생성
            NumberCombination.objects.bulk_create(combinations)

            # NumberStatistics 일괄 생성
            statistics = []
            for number in range(1, 46):  # 1~45
                if number in stats_data:
                    data = stats_data[number]
                    statistics.append(NumberStatistics(
                        number=number,
                        first_prize_count=data['first_prize_count'],
                        bonus_count=data['bonus_count'],
                        total_count=data['total_count'],
                        last_appeared_round=data['last_appeared_round'],
                        last_appeared_date=data['last_appeared_date'],
                    ))
                else:
                    # 한 번도 안 나온 번호
                    statistics.append(NumberStatistics(
                        number=number,
                        first_prize_count=0,
                        bonus_count=0,
                        total_count=0,
                        last_appeared_round=None,
                        last_appeared_date=None,
                    ))

            NumberStatistics.objects.bulk_create(statistics)

        self.stdout.write(
            self.style.SUCCESS(
                f'✅ 성공: {len(combinations)}개의 1등 조합 생성 완료'
            )
        )
        self.stdout.write(
            self.style.SUCCESS(
                f'✅ 성공: {len(statistics)}개의 번호 통계 생성 완료'
            )
        )

        # 통계 요약 출력
        most_common = max(stats_data.items(), key=lambda x: x[1]['total_count'])
        least_common = min(
            ((num, data) for num, data in stats_data.items() if data['total_count'] > 0),
            key=lambda x: x[1]['total_count']
        )

        self.stdout.write(
            self.style.SUCCESS(
                f'\n📊 통계 요약:'
            )
        )
        self.stdout.write(
            f'   가장 많이 나온 번호: {most_common[0]}번 ({most_common[1]["total_count"]}회)'
        )
        self.stdout.write(
            f'   가장 적게 나온 번호: {least_common[0]}번 ({least_common[1]["total_count"]}회)'
        )
