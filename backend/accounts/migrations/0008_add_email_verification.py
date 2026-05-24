from django.db import migrations, models


def set_existing_users_verified(apps, schema_editor):
    """기존 사용자 전원 is_email_verified=True 설정"""
    CustomUser = apps.get_model('accounts', 'CustomUser')
    CustomUser.objects.all().update(is_email_verified=True)


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_device_token_user_nullable'),
    ]

    operations = [
        # 0. db_table state를 실제 RDS 테이블명으로 맞춤 (DB는 이미 accounts_user)
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterModelTable(
                    name='customuser',
                    table='accounts_user',
                ),
            ],
            database_operations=[],  # DB에서는 이미 rename 완료
        ),

        # 1. CustomUser에 is_email_verified 필드 추가
        migrations.AddField(
            model_name='customuser',
            name='is_email_verified',
            field=models.BooleanField(default=False),
        ),

        # 2. 기존 사용자 전원 is_email_verified=True 설정
        migrations.RunPython(
            set_existing_users_verified,
            reverse_code=migrations.RunPython.noop,
        ),

        # 3. EmailVerificationCode 테이블 생성
        migrations.CreateModel(
            name='EmailVerificationCode',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('email', models.EmailField(db_index=True, max_length=254)),
                ('code', models.CharField(max_length=6)),
                ('purpose', models.CharField(choices=[('signup', 'Sign Up'), ('password_reset', 'Password Reset')], max_length=20)),
                ('is_used', models.BooleanField(default=False)),
                ('attempts', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('expires_at', models.DateTimeField()),
            ],
            options={
                'db_table': 'accounts_email_verification_code',
                'indexes': [
                    models.Index(fields=['email', 'purpose', '-created_at'], name='accounts_em_email_purpose_idx'),
                ],
            },
        ),
    ]
