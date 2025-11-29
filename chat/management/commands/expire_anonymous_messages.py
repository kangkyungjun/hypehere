"""
Django management command to expire anonymous chat messages older than 7 days.

Usage:
    python manage.py expire_anonymous_messages

This command can be run manually or scheduled via cron/Celery beat.
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from chat.models import Message


class Command(BaseCommand):
    help = '만료된 익명 채팅 메시지를 삭제합니다 (7일 이상 경과한 메시지)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='실제로 삭제하지 않고 시뮬레이션만 수행',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']

        # 만료된 메시지 조회 (expires_at이 현재 시각보다 이전)
        expired_messages = Message.objects.filter(
            expires_at__lte=timezone.now(),
            is_expired=False
        )

        count = expired_messages.count()

        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'[DRY RUN] {count}개의 메시지가 만료 처리될 예정입니다.'
                )
            )
            # 만료될 메시지 샘플 출력
            for msg in expired_messages[:5]:
                self.stdout.write(
                    f'  - ID: {msg.id}, Conversation: {msg.conversation_id}, '
                    f'Created: {msg.created_at}, Expires: {msg.expires_at}'
                )
            if count > 5:
                self.stdout.write(f'  ... 외 {count - 5}개')
        else:
            # 실제 만료 처리 (soft delete)
            expired_messages.update(
                is_expired=True,
                content='[만료된 메시지]'  # 내용 삭제
            )

            self.stdout.write(
                self.style.SUCCESS(
                    f'✅ {count}개의 메시지가 만료 처리되었습니다.'
                )
            )

        # 통계 출력
        total_expired = Message.objects.filter(is_expired=True).count()
        total_active = Message.objects.filter(is_expired=False).count()

        self.stdout.write(
            self.style.NOTICE(
                f'\n📊 통계:\n'
                f'  - 전체 만료된 메시지: {total_expired}개\n'
                f'  - 전체 활성 메시지: {total_active}개'
            )
        )
