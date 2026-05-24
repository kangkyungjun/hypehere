from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import EmailVerificationCode


class Command(BaseCommand):
    help = '만료 + 사용 완료된 EmailVerificationCode 중 7일 이상 경과한 레코드 삭제'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=7,
            help='삭제 기준 일수 (기본값: 7)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='실제 삭제 없이 대상 건수만 출력',
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']
        cutoff = timezone.now() - timedelta(days=days)

        qs = EmailVerificationCode.objects.filter(
            created_at__lt=cutoff,
        ).filter(
            # 만료됐거나 사용 완료된 코드
            expires_at__lt=timezone.now(),
        ) | EmailVerificationCode.objects.filter(
            created_at__lt=cutoff,
            is_used=True,
        )

        count = qs.count()

        if dry_run:
            self.stdout.write(f'[DRY RUN] 삭제 대상: {count}건')
            return

        deleted, _ = qs.delete()
        self.stdout.write(self.style.SUCCESS(f'삭제 완료: {deleted}건'))
