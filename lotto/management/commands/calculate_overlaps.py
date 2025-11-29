from django.core.management.base import BaseCommand
from django.db import transaction
from lotto.models import NumberCombination, LottoDraw, OverlapStatistics, OverlapDetail


class Command(BaseCommand):
    help = '등수 간 중복 통계 계산 및 캐시 테이블 생성'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('등수 간 중복 통계 계산 시작...'))

        # 계산할 등수 쌍 정의
        rank_pairs = [
            ('1등', '2등', '1-2'),
            ('1등', '3등', '1-3'),
            ('1등', '4등', '1-4'),
            ('2등', '3등', '2-3'),
            ('2등', '4등', '2-4'),
            ('3등', '4등', '3-4'),
        ]

        # 기존 데이터 삭제
        with transaction.atomic():
            deleted_stats = OverlapStatistics.objects.all().delete()[0]
            deleted_details = OverlapDetail.objects.all().delete()[0]

            if deleted_stats > 0 or deleted_details > 0:
                self.stdout.write(
                    self.style.WARNING(
                        f'기존 데이터 삭제: 통계 {deleted_stats}개, 상세 {deleted_details}개'
                    )
                )

        # 각 등수 쌍별로 중복 계산
        for first_rank, second_rank, pair_name in rank_pairs:
            self.stdout.write(
                self.style.NOTICE(f'\n{pair_name} 중복 분석 중...')
            )

            # 각 등수의 해시 집합 가져오기
            first_hashes = {}
            for combo in NumberCombination.objects.filter(rank=first_rank).select_related():
                combo_hash = combo.combination_hash
                if combo_hash not in first_hashes:
                    first_hashes[combo_hash] = []
                first_hashes[combo_hash].append(combo)

            second_hashes = {}
            for combo in NumberCombination.objects.filter(rank=second_rank).select_related():
                combo_hash = combo.combination_hash
                if combo_hash not in second_hashes:
                    second_hashes[combo_hash] = []
                second_hashes[combo_hash].append(combo)

            # 교집합 찾기
            overlap_hashes = set(first_hashes.keys()) & set(second_hashes.keys())
            overlap_count = len(overlap_hashes)

            self.stdout.write(
                self.style.SUCCESS(f'  교집합 발견: {overlap_count:,}개')
            )

            # 통계 저장
            OverlapStatistics.objects.create(
                rank_pair=pair_name,
                overlap_count=overlap_count
            )

            # 상세 정보 저장
            detail_list = []
            for hash_value in overlap_hashes:
                # 첫 번째 등수에서 첫 번째 조합 가져오기
                first_combo = first_hashes[hash_value][0]

                # 두 번째 등수에서 첫 번째 조합 가져오기
                second_combo = second_hashes[hash_value][0]

                # 회차 정보 가져오기
                first_draw = LottoDraw.objects.get(round_number=first_combo.round_number)
                second_draw = LottoDraw.objects.get(round_number=second_combo.round_number)

                detail_list.append(OverlapDetail(
                    rank_pair=pair_name,
                    combination_hash=hash_value,
                    numbers=first_combo.numbers,
                    first_rank=first_rank,
                    first_rank_round=first_combo.round_number,
                    first_rank_date=first_draw.draw_date,
                    second_rank=second_rank,
                    second_rank_round=second_combo.round_number,
                    second_rank_date=second_draw.draw_date,
                ))

            # 배치로 저장
            if detail_list:
                OverlapDetail.objects.bulk_create(detail_list, batch_size=1000)
                self.stdout.write(
                    self.style.SUCCESS(f'  상세 정보 {len(detail_list):,}개 저장 완료')
                )

        # 최종 요약
        self.stdout.write(
            self.style.SUCCESS('\n\n✅ 중복 통계 계산 완료!')
        )
        self.stdout.write(
            self.style.SUCCESS('\n📊 통계 요약:')
        )

        for stat in OverlapStatistics.objects.all().order_by('rank_pair'):
            self.stdout.write(f'   {stat.rank_pair}: {stat.overlap_count:,}회')

        total_details = OverlapDetail.objects.count()
        self.stdout.write(
            self.style.SUCCESS(f'\n   총 상세 정보: {total_details:,}개')
        )
