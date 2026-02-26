"""
Management command to hard-delete accounts past the grace period.

Usage:
    python manage.py delete_expired_accounts          # dry-run (default)
    python manage.py delete_expired_accounts --confirm # actual deletion

Cron (daily at 3 AM):
    0 3 * * * cd /home/ubuntu/hypehere && /home/ubuntu/venv/bin/python manage.py delete_expired_accounts --confirm >> /var/log/account_cleanup.log 2>&1
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class Command(BaseCommand):
    help = 'Hard-delete user accounts whose deletion grace period has expired'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Actually delete accounts (without this flag, dry-run only)',
        )

    def handle(self, *args, **options):
        grace_days = User.DELETION_GRACE_DAYS
        cutoff = timezone.now() - timedelta(days=grace_days)

        expired_users = User.objects.filter(
            deletion_requested_at__isnull=False,
            deletion_requested_at__lte=cutoff,
        )

        count = expired_users.count()

        if count == 0:
            self.stdout.write('No expired accounts found.')
            return

        self.stdout.write(f'Found {count} account(s) past {grace_days}-day grace period:')
        for user in expired_users:
            days_ago = (timezone.now() - user.deletion_requested_at).days
            self.stdout.write(f'  - {user.email} (requested {days_ago} days ago)')

        if not options['confirm']:
            self.stdout.write(self.style.WARNING(
                '\nDry-run mode. Add --confirm to actually delete.'
            ))
            return

        # Hard delete — CASCADE removes related posts, comments, likes, chats, etc.
        deleted_count, details = expired_users.delete()

        self.stdout.write(self.style.SUCCESS(
            f'\nDeleted {deleted_count} object(s):'
        ))
        for model, cnt in sorted(details.items()):
            self.stdout.write(f'  {model}: {cnt}')
