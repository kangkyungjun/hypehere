"""taitae@gmail.com 사용자를 Master 권한으로 승급.

해당 이메일 사용자가 아직 존재하지 않으면 noop (이후 가입 후 수동 실행 필요).
역방향 마이그레이션은 의도적으로 noop — 권한 강등은 운영 명령으로만.
"""
from django.db import migrations


TARGET_EMAIL = "taitae@gmail.com"


def forwards(apps, schema_editor):
    User = apps.get_model("accounts", "CustomUser")
    User.objects.filter(email__iexact=TARGET_EMAIL).update(role="master")


def backwards(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0012_recommendation_and_more"),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
