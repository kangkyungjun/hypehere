from django.db import models
from django.conf import settings
from django.utils.text import slugify


# ============================================================================
# Situation-Based Learning Models
# ============================================================================

class SituationCategory(models.Model):
    """
    Main categories for situation-based learning
    Examples: Daily Life, Travel, Business, Academic, Social, Health, Work
    """
    code = models.CharField(
        max_length=50,
        unique=True,
        db_index=True,
        verbose_name='Category Code',
        help_text='Unique identifier (e.g., "daily", "travel", "business")'
    )
    name_ko = models.CharField(max_length=100, verbose_name='Korean Name')
    name_en = models.CharField(max_length=100, verbose_name='English Name')
    icon = models.CharField(
        max_length=10,
        verbose_name='Icon',
        help_text='Emoji icon (e.g., "🏠", "✈️", "💼")'
    )
    description = models.TextField(verbose_name='Description', blank=True)
    order = models.IntegerField(default=0, verbose_name='Display Order')
    is_active = models.BooleanField(default=True, db_index=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['order', 'name_ko']
        verbose_name = 'Situation Category'
        verbose_name_plural = 'Situation Categories'

    def __str__(self):
        return f"{self.icon} {self.name_ko} ({self.name_en})"

    def get_lesson_count(self):
        """Return number of lessons in this category"""
        return self.lessons.filter(is_published=True).count()


class SituationLesson(models.Model):
    """
    Individual lesson within a situation category
    Contains practical expressions for specific situations
    """
    category = models.ForeignKey(
        SituationCategory,
        on_delete=models.CASCADE,
        related_name='lessons',
        verbose_name='Category'
    )
    title_ko = models.CharField(max_length=200, verbose_name='Korean Title')
    title_en = models.CharField(max_length=200, verbose_name='English Title')
    slug = models.SlugField(unique=True, max_length=250, db_index=True)

    # Language and organization
    language = models.CharField(
        max_length=5,
        db_index=True,
        verbose_name='Target Language',
        help_text='Language code (e.g., "EN", "KO", "ES")'
    )
    order = models.IntegerField(default=0, verbose_name='Order in Category')

    # Status and visibility
    is_published = models.BooleanField(default=True, db_index=True)

    # Statistics
    view_count = models.IntegerField(default=0)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['category', 'order', 'title_ko']
        unique_together = [('category', 'slug')]
        verbose_name = 'Situation Lesson'
        verbose_name_plural = 'Situation Lessons'
        indexes = [
            models.Index(fields=['category', 'language', 'order']),
            models.Index(fields=['is_published', '-view_count']),
        ]

    def __str__(self):
        return f"{self.title_ko} ({self.title_en})"

    def save(self, *args, **kwargs):
        """Auto-generate slug from Korean title if not provided"""
        if not self.slug:
            self.slug = slugify(self.title_ko, allow_unicode=True)
        super().save(*args, **kwargs)

    def get_expression_count(self):
        """Return number of expressions in this lesson"""
        return self.expressions.count()


class SituationExpression(models.Model):
    """
    Individual expression within a lesson
    Includes translation, pronunciation, context, and vocabulary
    """
    lesson = models.ForeignKey(
        SituationLesson,
        on_delete=models.CASCADE,
        related_name='expressions',
        verbose_name='Lesson'
    )

    # Expression content
    expression = models.CharField(
        max_length=200,
        verbose_name='Expression',
        help_text='Korean expression'
    )
    translation = models.CharField(
        max_length=200,
        verbose_name='Translation',
        help_text='English translation'
    )
    pronunciation = models.CharField(
        max_length=200,
        verbose_name='Pronunciation',
        help_text='Pronunciation guide in Korean'
    )

    # Context and usage
    situation_context = models.TextField(
        verbose_name='Situation Context',
        help_text='When and how to use this expression'
    )

    # Vocabulary (JSON array)
    vocabulary = models.JSONField(
        default=list,
        verbose_name='Vocabulary',
        help_text='Array of vocabulary items: [{"word": "...", "meaning": "...", "example": "..."}]'
    )

    # Order
    order = models.IntegerField(default=0, verbose_name='Order in Lesson')

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['lesson', 'order']
        verbose_name = 'Situation Expression'
        verbose_name_plural = 'Situation Expressions'
        indexes = [
            models.Index(fields=['lesson', 'order']),
        ]

    def __str__(self):
        return f"{self.expression} → {self.translation}"
