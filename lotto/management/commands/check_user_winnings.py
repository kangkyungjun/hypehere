"""
사용자 로또 번호 당첨 확인 관리 명령어

사용법:
    python manage.py check_user_winnings

설명:
    is_checked=False인 모든 사용자 번호를 확인하여 당첨 여부를 체크합니다.
    타겟 회차 이후의 모든 추첨과 비교하여 첫 번째 당첨을 기록합니다.
"""
from django.core.management.base import BaseCommand
from lotto.models import UserLottoNumber


class Command(BaseCommand):
    help = '사용자가 저장한 로또 번호의 당첨 여부를 확인합니다'

    def add_arguments(self, parser):
        parser.add_argument(
            '--all',
            action='store_true',
            help='이미 확인된 번호도 다시 확인 (기본: 미확인 번호만)'
        )

    def handle(self, *args, **options):
        check_all = options['all']

        # 확인할 번호 가져오기
        if check_all:
            unchecked = UserLottoNumber.objects.all()
            self.stdout.write(f'\n=== 모든 사용자 번호 재확인 시작 ===')
        else:
            unchecked = UserLottoNumber.objects.filter(is_checked=False)
            self.stdout.write(f'\n=== 미확인 사용자 번호 확인 시작 ===')

        total_count = unchecked.count()
        self.stdout.write(f'확인할 번호: {total_count:,}개\n')

        if total_count == 0:
            self.stdout.write(self.style.SUCCESS('\n확인할 번호가 없습니다.'))
            return

        # 통계
        winning_count = 0
        winning_details = {
            '1등': 0,
            '2등': 0,
            '3등': 0,
            '4등': 0,
            '5등': 0,
        }
        target_match_count = 0  # 타겟 회차 일치
        target_mismatch_count = 0  # 타겟 회차 불일치

        # 각 번호 확인
        for idx, user_number in enumerate(unchecked, 1):
            is_winning = user_number.check_winning()

            if is_winning:
                winning_count += 1
                rank = user_number.matched_rank
                winning_details[rank] += 1

                # 타겟 일치 여부
                if user_number.matched_round == user_number.round_number:
                    target_match_count += 1
                    match_status = '✅ 타겟 일치'
                else:
                    target_mismatch_count += 1
                    match_status = '💜 타겟 불일치'

                self.stdout.write(
                    f'[{idx}/{total_count}] {match_status} - '
                    f'타겟:{user_number.round_number}회 → '
                    f'실제:{user_number.matched_round}회 {rank} 당첨!'
                )

            # 진행상황 출력 (100개마다)
            if idx % 100 == 0:
                self.stdout.write(f'[{idx}/{total_count}] 진행 중... (당첨: {winning_count}개)')

        # 결과 출력
        self.stdout.write('\n' + '='*60)
        self.stdout.write(self.style.SUCCESS(f'\n✅ 확인 완료!\n'))
        self.stdout.write(f'총 확인 번호: {total_count:,}개')
        self.stdout.write(f'총 당첨 번호: {winning_count:,}개\n')

        if winning_count > 0:
            self.stdout.write('당첨 등수별 분포:')
            for rank in ['1등', '2등', '3등', '4등', '5등']:
                count = winning_details[rank]
                if count > 0:
                    self.stdout.write(f'  - {rank}: {count}개')

            self.stdout.write('\n타겟 회차 일치 여부:')
            self.stdout.write(self.style.SUCCESS(f'  ✅ 타겟 일치: {target_match_count}개'))
            self.stdout.write(self.style.WARNING(f'  💜 타겟 불일치: {target_mismatch_count}개'))
            self.stdout.write(
                f'\n타겟 불일치 비율: '
                f'{target_mismatch_count/winning_count*100:.1f}% '
                f'(상금 수령 불가)'
            )

        self.stdout.write('\n' + '='*60 + '\n')
