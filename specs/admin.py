from django.contrib import admin
from .models import Specification


@admin.register(Specification)
class SpecificationAdmin(admin.ModelAdmin):
    """Admin interface for Specification model"""

    list_display = ('title', 'category', 'status', 'version', 'created_by', 'created_at', 'updated_at')
    list_filter = ('category', 'status', 'version', 'created_at')
    search_fields = ('title', 'content', 'created_by__username')
    ordering = ('-created_at',)
    date_hierarchy = 'created_at'

    fieldsets = (
        ('기본 정보', {
            'fields': ('title', 'category', 'status', 'version')
        }),
        ('내용', {
            'fields': ('content',)
        }),
        ('메타 정보', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = ('created_at', 'updated_at')

    def save_model(self, request, obj, form, change):
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
