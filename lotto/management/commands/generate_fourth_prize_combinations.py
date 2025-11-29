import hashlib
from itertools import combinations
from django.core.management.base import BaseCommand
from django.db import transaction
from lotto.models import LottoDraw, NumberCombination


class Command(BaseCommand):
    help = '4등 조합 생성 (각 회차마다 10,545개 조합 생성: 4개 당첨번호 + 2개 일반번호)'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('4등 조합 생성 시작...'))

        # 모든 추첨 데이터 가져오기
        draws = LottoDraw.objects.all().order_by('round_number')
        total = draws.count()

        self.stdout.write(self.style.NOTICE(f'총 {total}개 회차 처리 중...'))
        self.stdout.write(self.style.NOTICE('각 회차당 10,545개 조합 (15 × 703) 생성 예상'))
        self.stdout.write(self.style.WARNING(f'총 {total * 10545:,}개 조합 생성 예정 (약 10-15분 소요)'))

        # 4등 조합 리스트
        fourth_prize_combinations = []
        batch_size = 5000

        # 각 회차별 처리
        for idx, draw in enumerate(draws, 1):
            winning_numbers = draw.get_numbers_as_list()
            bonus = draw.bonus_number

            # 당첨번호 6개 + 보너스 1개를 제외한 나머지 번호들 (38개)
            excluded_numbers = set(winning_numbers + [bonus])
            regular_numbers = [n for n in range(1, 46) if n not in excluded_numbers]

            # 당첨번호 6개 중 4개를 선택하는 모든 조합 (C(6,4) = 15)
            four_winning_combos = list(combinations(winning_numbers, 4))

            # 일반번호 38개 중 2개를 선택하는 모든 조합 (C(38,2) = 703)
            two_regular_combos = list(combinations(regular_numbers, 2))

            # 4개 당첨번호 + 2개 일반번호 조합 (15 × 703 = 10,545)
            for four_winning in four_winning_combos:
                for two_regular in two_regular_combos:
                    # 4등 조합: 당첨번호 4개 + 일반번호 2개
                    fourth_prize_numbers = sorted(list(four_winning) + list(two_regular))

                    # 해시 생성
                    combination_hash = hashlib.sha256(
                        str(fourth_prize_numbers).encode()
                    ).hexdigest()

                    fourth_prize_combinations.append(NumberCombination(
                        combination_hash=combination_hash,
                        numbers=fourth_prize_numbers,
                        round_number=draw.round_number,
                        rank='4등'
                    ))

                    # 배치 크기에 도달하면 데이터베이스에 저장
                    if len(fourth_prize_combinations) >= batch_size:
                        with transaction.atomic():
                            NumberCombination.objects.bulk_create(fourth_prize_combinations)

                        self.stdout.write(
                            self.style.SUCCESS(
                                f'{idx}/{total} 회차 처리 중... (누적 {idx * 10545:,}개 조합 저장 완료)'
                            )
                        )
                        fourth_prize_combinations = []

            # 진행 상황 출력 (50개마다)
            if idx % 50 == 0:
                self.stdout.write(
                    self.style.SUCCESS(f'{idx}/{total} 회차 처리 완료... (현재까지 {idx * 10545:,}개 조합 생성)')
                )

        # 남은 데이터 저장
        if fourth_prize_combinations:
            with transaction.atomic():
                NumberCombination.objects.bulk_create(fourth_prize_combinations)

            self.stdout.write(
                self.style.SUCCESS(f'마지막 배치 저장 완료 ({len(fourth_prize_combinations):,}개)')
            )

        # 최종 통계
        total_created = total * 10545

        self.stdout.write(
            self.style.SUCCESS(
                f'✅ 성공: {total_created:,}개의 4등 조합 생성 완료'
            )
        )

        # 통계 요약 출력
        first_prize_count = NumberCombination.objects.filter(rank='1등').count()
        second_prize_count = NumberCombination.objects.filter(rank='2등').count()
        third_prize_count = NumberCombination.objects.filter(rank='3등').count()
        fourth_prize_count = NumberCombination.objects.filter(rank='4등').count()

        self.stdout.write(
            self.style.SUCCESS(
                f'\n📊 통계 요약:'
            )
        )
        self.stdout.write(
            f'   1등 조합: {first_prize_count:,}개'
        )
        self.stdout.write(
            f'   2등 조합: {second_prize_count:,}개'
        )
        self.stdout.write(
            f'   3등 조합: {third_prize_count:,}개'
        )
        self.stdout.write(
            f'   4등 조합: {fourth_prize_count:,}개'
        )
        self.stdout.write(
            f'   총 조합: {first_prize_count + second_prize_count + third_prize_count + fourth_prize_count:,}개'
        )
