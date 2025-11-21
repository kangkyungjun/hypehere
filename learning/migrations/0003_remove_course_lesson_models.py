# Generated manually to remove Course/Lesson models

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('learning', '0002_situationcategory_situationlesson_and_more'),
    ]

    operations = [
        # Drop all Course/Lesson tables directly (in order to avoid foreign key constraints)
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_lessonbookmark;",
            reverse_sql="",
        ),
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_lessoncomment;",
            reverse_sql="",
        ),
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_lessoncontributor;",
            reverse_sql="",
        ),
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_lessonversion;",
            reverse_sql="",
        ),
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_lesson;",
            reverse_sql="",
        ),
        migrations.RunSQL(
            sql="DROP TABLE IF EXISTS learning_course;",
            reverse_sql="",
        ),
    ]
