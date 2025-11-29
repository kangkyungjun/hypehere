import pandas as pd
from datetime import datetime, timedelta
from django.core.management.base import BaseCommand
from django.db import transaction
from lotto.models import LottoDraw


class Command(BaseCommand):
    help = '로또 추첨 데이터를 엑셀 파일에서 임포트합니다.'

    def add_arguments(self, parser):
        parser.add_argument(
            'excel_file',
            type=str,
            help='임포트할 엑셀 파일 경로'
        )

    def handle(self, *args, **options):
        excel_file = options['excel_file']

        self.stdout.write(self.style.NOTICE(f'엑셀 파일 읽는 중: {excel_file}'))

        try:
            # 엑셀 파일 읽기
            df = pd.read_excel(excel_file)

            # 컬럼명 확인
            self.stdout.write(self.style.NOTICE(f'발견된 컬럼: {df.columns.tolist()}'))
            self.stdout.write(self.style.NOTICE(f'총 {len(df)}개 데이터 발견'))

            # 1회차 기준일 (2002년 12월 7일)
            base_date = datetime(2002, 12, 7).date()

            # LottoDraw 객체 리스트 생성
            lotto_draws = []

            for idx, row in df.iterrows():
                round_number = int(row['회차'])

                # 회차별 날짜 계산 (매주 토요일, +7일)
                draw_date = base_date + timedelta(days=(round_number - 1) * 7)

                lotto_draw = LottoDraw(
                    round_number=round_number,
                    draw_date=draw_date,
                    number1=int(row['번호1']),
                    number2=int(row['번호2']),
                    number3=int(row['번호3']),
                    number4=int(row['번호4']),
                    number5=int(row['번호5']),
                    number6=int(row['번호6']),
                    bonus_number=int(row['보너스']),
                    first_prize_amount=int(row['1등 당첨금']) if pd.notna(row['1등 당첨금']) else None,
                    first_prize_winners=int(row['1등 당첨수']) if pd.notna(row['1등 당첨수']) else None,
                    second_prize_amount=int(row['2등 당첨금']) if pd.notna(row['2등 당첨금']) else None,
                    second_prize_winners=int(row['2등 당첨수']) if pd.notna(row['2등 당첨수']) else None,
                )

                lotto_draws.append(lotto_draw)

                # 진행 상황 출력 (100개마다)
                if (idx + 1) % 100 == 0:
                    self.stdout.write(
                        self.style.SUCCESS(f'{idx + 1}/{len(df)} 데이터 처리 중...')
                    )

            # 데이터베이스에 일괄 저장 (트랜잭션 사용)
            self.stdout.write(self.style.NOTICE('데이터베이스에 저장 중...'))

            with transaction.atomic():
                # 기존 데이터 삭제 (재실행 시)
                deleted_count = LottoDraw.objects.all().delete()[0]
                if deleted_count > 0:
                    self.stdout.write(
                        self.style.WARNING(f'기존 데이터 {deleted_count}개 삭제됨')
                    )

                # 일괄 생성
                LottoDraw.objects.bulk_create(lotto_draws)

            self.stdout.write(
                self.style.SUCCESS(
                    f'✅ 성공: {len(lotto_draws)}개의 로또 추첨 데이터가 임포트되었습니다.'
                )
            )

            # 임포트된 데이터 확인
            first_draw = LottoDraw.objects.order_by('round_number').first()
            last_draw = LottoDraw.objects.order_by('-round_number').first()

            self.stdout.write(
                self.style.SUCCESS(
                    f'회차 범위: {first_draw.round_number}회 ({first_draw.draw_date}) ~ '
                    f'{last_draw.round_number}회 ({last_draw.draw_date})'
                )
            )

        except FileNotFoundError:
            self.stdout.write(
                self.style.ERROR(f'❌ 오류: 파일을 찾을 수 없습니다 - {excel_file}')
            )
        except KeyError as e:
            self.stdout.write(
                self.style.ERROR(f'❌ 오류: 필요한 컬럼을 찾을 수 없습니다 - {e}')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ 오류: {str(e)}')
            )
