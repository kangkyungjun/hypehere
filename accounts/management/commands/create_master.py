"""
Django management command to create a Master account for MarketLens role system.

Usage:
    python manage.py create_master <email> <nickname> <password>

Example:
    python manage.py create_master master@marketlens.com "Master Admin" "secure_password123"
"""

from django.core.management.base import BaseCommand, CommandError
from accounts.models import User


class Command(BaseCommand):
    help = 'Create a Master account with highest privileges'

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help='Email address for Master account')
        parser.add_argument('nickname', type=str, help='Display nickname for Master account')
        parser.add_argument('password', type=str, help='Password for Master account')

    def handle(self, *args, **options):
        email = options['email']
        nickname = options['nickname']
        password = options['password']

        # Check if user already exists
        if User.objects.filter(email=email).exists():
            self.stdout.write(self.style.WARNING(f'\n⚠️  User with email {email} already exists.'))

            user = User.objects.get(email=email)
            self.stdout.write(f'   Current role: {user.role}')

            # Ask if we should update to master
            confirm = input('\n   Update this user to Master role? (yes/no): ')
            if confirm.lower() in ['yes', 'y']:
                user.role = 'master'
                user.save(update_fields=['role'])
                self.stdout.write(self.style.SUCCESS(f'\n✅ Updated {email} to Master role'))
                self._display_master_info(user)
            else:
                self.stdout.write(self.style.WARNING('\n❌ Operation cancelled'))
            return

        # Create new Master user
        try:
            user = User.objects.create_user(
                email=email,
                nickname=nickname,
                password=password
            )
            user.role = 'master'
            user.save(update_fields=['role'])

            self.stdout.write(self.style.SUCCESS(f'\n✅ Successfully created Master account'))
            self._display_master_info(user)

        except Exception as e:
            raise CommandError(f'Failed to create Master account: {str(e)}')

    def _display_master_info(self, user):
        """Display Master account information and permissions"""
        self.stdout.write('\n' + '=' * 60)
        self.stdout.write(self.style.SUCCESS('MASTER ACCOUNT DETAILS'))
        self.stdout.write('=' * 60)
        self.stdout.write(f'  Email:    {user.email}')
        self.stdout.write(f'  Nickname: {user.nickname}')
        self.stdout.write(f'  Role:     {user.role}')
        self.stdout.write(f'  ID:       {user.id}')

        self.stdout.write('\n' + '-' * 60)
        self.stdout.write(self.style.SUCCESS('MASTER PERMISSIONS'))
        self.stdout.write('-' * 60)
        self.stdout.write(f'  ✓ isMaster:             {user.is_master()}')
        self.stdout.write(f'  ✓ isManagerOrAbove:     {user.is_manager_or_above()}')
        self.stdout.write(f'  ✓ isGoldOrAbove:        {user.is_gold_or_above()}')
        self.stdout.write(f'  ✓ hasAdFreeAccess:      {user.has_ad_free_access()}')
        self.stdout.write(f'  ✓ canDeleteAnyPost:     {user.can_delete_any_post()}')
        self.stdout.write(f'  ✓ canPromoteToGold:     {user.can_promote_to_gold()}')
        self.stdout.write(f'  ✓ canPromoteToManager:  {user.can_promote_to_manager()}')
        self.stdout.write(f'  ✓ canManageUsers:       {user.can_manage_users()}')
        self.stdout.write('=' * 60 + '\n')
