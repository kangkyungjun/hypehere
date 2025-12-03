"""
Django management command to import lotto data from Excel file
Usage: python manage.py import_lotto_data <excel_file_path> [--dry-run] [--batch-size N] [--skip-stats]
"""
import openpyxl
from datetime import datetime, timedelta
from django.core.management.base import BaseCommand, CommandError
from django.core.management import call_command
from django.db import transaction
from lotto.models import LottoDraw


class Command(BaseCommand):
    help = '로또 당첨 데이터를 엑셀 파일에서 임포트합니다'

    def add_arguments(self, parser):
        parser.add_argument('excel_file', type=str, help='엑셀 파일 경로')
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='실제 저장 없이 검증만 수행'
        )
        parser.add_argument(
            '--batch-size',
            type=int,
            default=500,
            help='bulk_create 배치 크기 (기본값: 500)'
        )
        parser.add_argument(
            '--skip-stats',
            action='store_true',
            help='통계 생성 건너뛰기 (빠른 임포트)'
        )

    def handle(self, *args, **options):
        excel_file = options['excel_file']
        dry_run = options['dry_run']
        batch_size = options['batch_size']
        skip_stats = options['skip_stats']

        self.stdout.write('=' * 70)
        self.stdout.write(f'로또 데이터 임포트 시작')
        self.stdout.write(f'파일: {excel_file}')
        self.stdout.write(f'Dry-run: {dry_run}')
        self.stdout.write(f'배치 크기: {batch_size}')
        self.stdout.write(f'통계 생성: {"건너뛰기" if skip_stats else "자동"}')
        self.stdout.write('=' * 70)

        try:
            # 1. 엑셀 파일 읽기
            self.stdout.write('\n1️⃣  엑셀 파일 읽기 중...')
            draws_data = self.read_excel(excel_file)
            self.stdout.write(self.style.SUCCESS(f'   ✅ {len(draws_data)}개 행 읽기 완료'))

            # 2. 데이터 검증
            self.stdout.write('\n2️⃣  데이터 검증 중...')
            valid_draws, errors = self.validate_draws(draws_data)

            if errors:
                self.stdout.write(self.style.WARNING(f'   ⚠️  {len(errors)}개 오류 발견:'))
                for error in errors[:10]:
                    self.stdout.write(f'      - {error}')
                if len(errors) > 10:
                    self.stdout.write(f'      ... 외 {len(errors) - 10}개 오류')

            self.stdout.write(self.style.SUCCESS(f'   ✅ {len(valid_draws)}개 유효한 데이터'))

            if not valid_draws:
                raise CommandError('유효한 데이터가 없습니다')

            # 3. 중복 확인
            self.stdout.write('\n3️⃣  중복 데이터 확인 중...')
            existing_rounds = set(
                LottoDraw.objects.values_list('round_number', flat=True)
            )
            new_draws = [d for d in valid_draws if d.round_number not in existing_rounds]
            duplicate_count = len(valid_draws) - len(new_draws)

            if duplicate_count > 0:
                self.stdout.write(self.style.WARNING(f'   ⚠️  {duplicate_count}개 중복 회차 스킵'))
            self.stdout.write(self.style.SUCCESS(f'   ✅ {len(new_draws)}개 신규 데이터'))

            if not new_draws:
                self.stdout.write(self.style.WARNING('\n모든 데이터가 이미 존재합니다'))
                return

            # 4. 데이터베이스 저장
            if dry_run:
                self.stdout.write('\n4️⃣  DRY-RUN 모드: 실제 저장하지 않음')
                self.stdout.write(self.style.SUCCESS('   ✅ 검증 완료'))
            else:
                self.stdout.write('\n4️⃣  데이터베이스 저장 중...')
                saved_count = self.import_to_database(new_draws, batch_size)
                self.stdout.write(self.style.SUCCESS(f'   ✅ {saved_count}개 저장 완료'))

            # 5. 결과 요약
            self.stdout.write('\n' + '=' * 70)
            self.stdout.write('📊 임포트 결과 요약:')
            self.stdout.write(f'   - 읽은 데이터: {len(draws_data)}개')
            self.stdout.write(f'   - 유효한 데이터: {len(valid_draws)}개')
            self.stdout.write(f'   - 중복 스킵: {duplicate_count}개')
            self.stdout.write(f'   - 저장된 데이터: {len(new_draws) if not dry_run else 0}개')

            if errors:
                self.stdout.write(f'   - 오류: {len(errors)}개')

            self.stdout.write('=' * 70)

            if not dry_run:
                self.stdout.write(self.style.SUCCESS('\n✨ 임포트 완료!'))

                # 6. 통계 자동 생성
                if not skip_stats and len(new_draws) > 0:
                    self.stdout.write('\n' + '=' * 70)
                    self.stdout.write('📊 통계 데이터 자동 생성 시작...')
                    self.stdout.write('=' * 70)

                    try:
                        # 1등~4등 조합 생성
                        self.stdout.write('\n1️⃣  1등 조합 생성 중...')
                        call_command('generate_combinations')
                        self.stdout.write(self.style.SUCCESS('   ✅ 1등 조합 생성 완료'))

                        self.stdout.write('\n2️⃣  2등 조합 생성 중...')
                        call_command('generate_second_prize_combinations')
                        self.stdout.write(self.style.SUCCESS('   ✅ 2등 조합 생성 완료'))

                        self.stdout.write('\n3️⃣  3등 조합 생성 중...')
                        call_command('generate_third_prize_combinations')
                        self.stdout.write(self.style.SUCCESS('   ✅ 3등 조합 생성 완료'))

                        self.stdout.write('\n4️⃣  4등 조합 생성 중 (약 10-15분 소요)...')
                        call_command('generate_fourth_prize_combinations')
                        self.stdout.write(self.style.SUCCESS('   ✅ 4등 조합 생성 완료'))

                        # 중복 통계 계산
                        self.stdout.write('\n5️⃣  중복 통계 계산 중...')
                        call_command('calculate_overlaps')
                        self.stdout.write(self.style.SUCCESS('   ✅ 중복 통계 계산 완료'))

                        # 전략 통계 업데이트
                        self.stdout.write('\n6️⃣  전략 통계 업데이트 중...')
                        call_command('update_strategy_stats')
                        self.stdout.write(self.style.SUCCESS('   ✅ 전략 통계 업데이트 완료'))

                        self.stdout.write('\n' + '=' * 70)
                        self.stdout.write(self.style.SUCCESS('✨ 모든 통계 생성 완료!'))
                        self.stdout.write('=' * 70)

                    except Exception as e:
                        self.stdout.write(self.style.ERROR(f'\n❌ 통계 생성 중 오류: {str(e)}'))
                        self.stdout.write(self.style.WARNING('   수동으로 통계 생성 명령어를 실행하세요.'))

        except FileNotFoundError:
            raise CommandError(f'파일을 찾을 수 없습니다: {excel_file}')
        except Exception as e:
            raise CommandError(f'임포트 중 오류 발생: {str(e)}')

    def read_excel(self, excel_file):
        """엑셀 파일 읽기"""
        workbook = openpyxl.load_workbook(excel_file, read_only=True, data_only=True)
        sheet = workbook.active

        draws_data = []

        for idx, row in enumerate(sheet.iter_rows(values_only=True), start=1):
            # 헤더 행 스킵
            if idx == 1:
                continue

            # 빈 행 스킵
            if not any(row):
                continue

            # 데이터 파싱
            try:
                draws_data.append({
                    'round_number': int(row[0]) if row[0] else None,
                    'number1': int(row[1]) if row[1] else None,
                    'number2': int(row[2]) if row[2] else None,
                    'number3': int(row[3]) if row[3] else None,
                    'number4': int(row[4]) if row[4] else None,
                    'number5': int(row[5]) if row[5] else None,
                    'number6': int(row[6]) if row[6] else None,
                    'bonus_number': int(row[7]) if row[7] else None,
                    'first_prize_amount': int(row[8]) if row[8] else None,
                    'first_prize_winners': int(row[9]) if row[9] else None,
                    'second_prize_amount': int(row[10]) if row[10] else None,
                    'second_prize_winners': int(row[11]) if row[11] else None,
                })
            except (ValueError, IndexError):
                pass

        workbook.close()
        return draws_data

    def validate_draws(self, draws_data):
        """데이터 검증"""
        valid_draws = []
        errors = []

        for data in draws_data:
            error_msgs = []

            # 필수 필드 확인
            if not data.get('round_number'):
                errors.append(f"회차 누락된 데이터")
                continue

            round_num = data['round_number']

            # 당첨번호 검증
            numbers = [
                data.get('number1'), data.get('number2'), data.get('number3'),
                data.get('number4'), data.get('number5'), data.get('number6')
            ]

            if None in numbers:
                error_msgs.append(f"{round_num}회: 당첨번호 누락")
            elif not all(1 <= n <= 45 for n in numbers):
                error_msgs.append(f"{round_num}회: 당첨번호 범위 오류 (1-45)")
            elif len(numbers) != len(set(numbers)):
                error_msgs.append(f"{round_num}회: 당첨번호 중복")

            # 보너스 번호 검증
            bonus = data.get('bonus_number')
            if not bonus:
                error_msgs.append(f"{round_num}회: 보너스 번호 누락")
            elif not (1 <= bonus <= 45):
                error_msgs.append(f"{round_num}회: 보너스 번호 범위 오류 (1-45)")
            elif bonus in numbers:
                error_msgs.append(f"{round_num}회: 보너스 번호가 당첨번호와 중복")

            if error_msgs:
                errors.extend(error_msgs)
                continue

            # 유효한 데이터 객체 생성
            base_date = datetime(2000, 1, 1)
            draw_date = base_date + timedelta(days=round_num * 7)

            valid_draws.append(LottoDraw(
                round_number=round_num,
                draw_date=draw_date.date(),
                number1=numbers[0],
                number2=numbers[1],
                number3=numbers[2],
                number4=numbers[3],
                number5=numbers[4],
                number6=numbers[5],
                bonus_number=bonus,
                first_prize_amount=data.get('first_prize_amount'),
                first_prize_winners=data.get('first_prize_winners'),
                second_prize_amount=data.get('second_prize_amount'),
                second_prize_winners=data.get('second_prize_winners'),
            ))

        return valid_draws, errors

    def import_to_database(self, draws, batch_size):
        """데이터베이스에 저장"""
        saved_count = 0

        with transaction.atomic():
            for i in range(0, len(draws), batch_size):
                batch = draws[i:i + batch_size]
                LottoDraw.objects.bulk_create(batch, ignore_conflicts=True)
                saved_count += len(batch)

                progress = (i + len(batch)) / len(draws) * 100
                self.stdout.write(f'   진행: {progress:.1f}% ({i + len(batch)}/{len(draws)})', ending='\r')

            self.stdout.write('')

        return saved_count
