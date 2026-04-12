from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0008_add_email_verification'),
    ]

    operations = [
        migrations.AddField(
            model_name='notificationhistory',
            name='post_id',
            field=models.IntegerField(blank=True, null=True),
        ),
    ]
