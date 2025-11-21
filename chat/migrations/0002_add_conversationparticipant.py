# Generated manually for ConversationParticipant through model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


def migrate_participants_data(apps, schema_editor):
    """
    Migrate existing participants from old ManyToMany table to new ConversationParticipant model
    """
    Conversation = apps.get_model('chat', 'Conversation')
    ConversationParticipant = apps.get_model('chat', 'ConversationParticipant')

    # Get all conversations
    for conversation in Conversation.objects.all():
        # Get participants through the old m2m table (renamed to participants_old)
        participants = conversation.participants_old.all()
        # Create ConversationParticipant entries for each
        for user in participants:
            ConversationParticipant.objects.get_or_create(
                user=user,
                conversation=conversation,
                defaults={'is_active': True}
            )


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # Step 1: Rename existing participants field
        migrations.RenameField(
            model_name='conversation',
            old_name='participants',
            new_name='participants_old',
        ),

        # Step 2: Create ConversationParticipant model
        migrations.CreateModel(
            name='ConversationParticipant',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('is_active', models.BooleanField(db_index=True, default=True)),
                ('left_at', models.DateTimeField(blank=True, null=True)),
                ('joined_at', models.DateTimeField(auto_now_add=True)),
                ('conversation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='participant_relations', to='chat.conversation')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='conversation_participants', to=settings.AUTH_USER_MODEL)),
            ],
        ),

        # Step 3: Add indexes
        migrations.AddIndex(
            model_name='conversationparticipant',
            index=models.Index(fields=['user', 'is_active'], name='chat_conver_user_id_fe3c7f_idx'),
        ),

        # Step 4: Add unique constraint
        migrations.AlterUniqueTogether(
            name='conversationparticipant',
            unique_together={('user', 'conversation')},
        ),

        # Step 5: Migrate data from old to new
        migrations.RunPython(migrate_participants_data, reverse_code=migrations.RunPython.noop),

        # Step 6: Add new participants field with through model
        migrations.AddField(
            model_name='conversation',
            name='participants',
            field=models.ManyToManyField(
                related_name='conversations',
                through='chat.ConversationParticipant',
                to=settings.AUTH_USER_MODEL
            ),
        ),

        # Step 7: Remove old participants field
        migrations.RemoveField(
            model_name='conversation',
            name='participants_old',
        ),
    ]
