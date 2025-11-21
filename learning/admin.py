from django.contrib import admin
from django.utils.html import format_html
from .models import (
    SituationCategory, SituationLesson, SituationExpression
)


# ============================================================================
# Situation-Based Learning Admin
# ============================================================================

@admin.register(SituationCategory)
class SituationCategoryAdmin(admin.ModelAdmin):
    """Admin interface for SituationCategory model"""
    list_display = ('icon_display', 'name_ko', 'name_en', 'code', 'lesson_count_display',
                    'order', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name_ko', 'name_en', 'code', 'description')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Basic Information', {
            'fields': ('code', 'name_ko', 'name_en', 'icon', 'description')
        }),
        ('Display', {
            'fields': ('order', 'is_active')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def icon_display(self, obj):
        """Display icon with larger size"""
        return format_html('<span style="font-size: 24px;">{}</span>', obj.icon)
    icon_display.short_description = 'Icon'

    def lesson_count_display(self, obj):
        """Display lesson count"""
        return obj.get_lesson_count()
    lesson_count_display.short_description = 'Lessons'


class SituationExpressionInline(admin.TabularInline):
    """Inline for situation expressions"""
    model = SituationExpression
    extra = 1
    fields = ('order', 'expression', 'translation', 'pronunciation')
    ordering = ('order',)


@admin.register(SituationLesson)
class SituationLessonAdmin(admin.ModelAdmin):
    """Admin interface for SituationLesson model"""
    list_display = ('title_ko', 'title_en', 'category', 'language', 'order',
                    'expression_count_display', 'view_count', 'is_published', 'created_at')
    list_filter = ('category', 'language', 'is_published', 'created_at')
    search_fields = ('title_ko', 'title_en', 'slug')
    prepopulated_fields = {'slug': ('title_ko',)}
    readonly_fields = ('view_count', 'created_at', 'updated_at')
    inlines = [SituationExpressionInline]

    fieldsets = (
        ('Basic Information', {
            'fields': ('category', 'title_ko', 'title_en', 'slug', 'language')
        }),
        ('Display', {
            'fields': ('order', 'is_published')
        }),
        ('Statistics', {
            'fields': ('view_count',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def expression_count_display(self, obj):
        """Display expression count"""
        return obj.get_expression_count()
    expression_count_display.short_description = 'Expressions'


@admin.register(SituationExpression)
class SituationExpressionAdmin(admin.ModelAdmin):
    """Admin interface for SituationExpression model"""
    list_display = ('expression_short', 'translation_short', 'lesson', 'order', 'created_at')
    list_filter = ('lesson__category', 'lesson__language', 'created_at')
    search_fields = ('expression', 'translation', 'pronunciation', 'lesson__title_ko')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Expression', {
            'fields': ('lesson', 'order', 'expression', 'translation', 'pronunciation')
        }),
        ('Context', {
            'fields': ('situation_context',)
        }),
        ('Vocabulary', {
            'fields': ('vocabulary',),
            'description': 'JSON array format: [{"word": "menu", "meaning": "메뉴", "example": "Can I see the menu?"}]'
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def expression_short(self, obj):
        """Display shortened expression"""
        return obj.expression[:30] + '...' if len(obj.expression) > 30 else obj.expression
    expression_short.short_description = 'Expression'

    def translation_short(self, obj):
        """Display shortened translation"""
        return obj.translation[:30] + '...' if len(obj.translation) > 30 else obj.translation
    translation_short.short_description = 'Translation'
