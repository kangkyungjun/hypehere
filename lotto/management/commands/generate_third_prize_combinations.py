import hashlib
from django.core.management.base import BaseCommand
from django.db import transaction
from lotto.models import LottoDraw, NumberCombination


class Command(BaseCommand):
    help = '3등 조합 생성 (각 회차마다 228개 조합 생성: 5개 당첨번호 + 38개 일반번호)'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('3등 조합 생성 시작...'))

        # 모든 추첨 데이터 가져오기
        draws = LottoDraw.objects.all().order_by('round_number')
        total = draws.count()

        self.stdout.write(self.style.NOTICE(f'총 {total}개 회차 처리 중...'))
        self.stdout.write(self.style.NOTICE('각 회차당 228개 조합 (6 × 38) 생성 예상'))

        # 3등 조합 리스트
        third_prize_combinations = []

        # 각 회차별 처리
        for idx, draw in enumerate(draws, 1):
            winning_numbers = draw.get_numbers_as_list()
            bonus = draw.bonus_number

            # 당첨번호 6개 + 보너스 1개를 제외한 나머지 번호들 (38개)
            excluded_numbers = set(winning_numbers + [bonus])
            regular_numbers = [n for n in range(1, 46) if n not in excluded_numbers]

            # 당첨번호 6개 중 5개를 선택 (각 번호를 하나씩 제외)
            for excluded_winning_number in winning_numbers:
                # 3등 조합의 당첨번호 5개
                five_winning = sorted(
                    [n for n in winning_numbers if n != excluded_winning_number]
                )

                # 5개 당첨번호 + 38개 일반번호 조합 (각각 6개 번호 조합 생성)
                for regular_number in regular_numbers:
                    # 3등 조합: 당첨번호 5개 + 일반번호 1개
                    third_prize_numbers = sorted(five_winning + [regular_number])

                    # 해시 생성
                    combination_hash = hashlib.sha256(
                        str(third_prize_numbers).encode()
                    ).hexdigest()

                    third_prize_combinations.append(NumberCombination(
                        combination_hash=combination_hash,
                        numbers=third_prize_numbers,
                        round_number=draw.round_number,
                        rank='3등'
                    ))

            # 진행 상황 출력 (100개마다)
            if idx % 100 == 0:
                self.stdout.write(
                    self.style.SUCCESS(f'{idx}/{total} 회차 처리 완료... (현재까지 {len(third_prize_combinations):,}개 조합 생성)')
                )

        # 데이터베이스에 저장
        self.stdout.write(self.style.NOTICE('데이터베이스에 저장 중...'))

        with transaction.atomic():
            # 기존 3등 조합 삭제
            deleted_count = NumberCombination.objects.filter(rank='3등').delete()[0]

            if deleted_count > 0:
                self.stdout.write(
                    self.style.WARNING(f'기존 3등 조합 {deleted_count}개 삭제됨')
                )

            # NumberCombination 일괄 생성
            NumberCombination.objects.bulk_create(third_prize_combinations)

        self.stdout.write(
            self.style.SUCCESS(
                f'✅ 성공: {len(third_prize_combinations)}개의 3등 조합 생성 완료'
            )
        )

        # 통계 요약 출력
        first_prize_count = NumberCombination.objects.filter(rank='1등').count()
        second_prize_count = NumberCombination.objects.filter(rank='2등').count()
        third_prize_count = NumberCombination.objects.filter(rank='3등').count()

        self.stdout.write(
            self.style.SUCCESS(
                f'\n📊 통계 요약:'
            )
        )
        self.stdout.write(
            f'   1등 조합: {first_prize_count}개'
        )
        self.stdout.write(
            f'   2등 조합: {second_prize_count}개'
        )
        self.stdout.write(
            f'   3등 조합: {third_prize_count}개'
        )
        self.stdout.write(
            f'   총 조합: {first_prize_count + second_prize_count + third_prize_count}개'
        )
