"""
Django management command to clean up old notifications
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from notifications.models import Notification


class Command(BaseCommand):
    help = '7일 이상 된 알림을 삭제합니다'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=7,
            help='보관 기간 (일 단위, 기본값: 7)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='실제 삭제 없이 테스트만 수행'
        )

    def handle(self, *args, **options):
        days = options['days']
        dry_run = options['dry_run']

        # Calculate cutoff date
        cutoff_date = timezone.now() - timedelta(days=days)

        # Find old notifications
        old_notifications = Notification.objects.filter(created_at__lt=cutoff_date)
        count = old_notifications.count()

        if dry_run:
            # Dry run mode - just show what would be deleted
            self.stdout.write(
                self.style.WARNING(
                    f'[DRY RUN] {count}개의 알림이 삭제될 예정입니다 (생성일: {cutoff_date.strftime("%Y-%m-%d")} 이전)'
                )
            )

            # Show breakdown by type
            if count > 0:
                self.stdout.write('\n알림 타입별 삭제 예정 개수:')
                for notif_type, _ in Notification.NOTIFICATION_TYPES:
                    type_count = old_notifications.filter(notification_type=notif_type).count()
                    if type_count > 0:
                        self.stdout.write(f'  - {notif_type}: {type_count}개')
        else:
            # Actually delete old notifications
            old_notifications.delete()
            self.stdout.write(
                self.style.SUCCESS(
                    f'{count}개의 오래된 알림을 삭제했습니다 (생성일: {cutoff_date.strftime("%Y-%m-%d")} 이전)'
                )
            )
