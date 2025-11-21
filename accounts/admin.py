from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth import get_user_model
from .models import Follow, SupportTicket

User = get_user_model()


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom User admin interface"""

    list_display = ('username', 'email', 'nickname', 'is_verified',
                    'is_premium', 'is_staff', 'created_at')
    list_filter = ('is_staff', 'is_superuser', 'is_active',
                   'is_verified', 'is_premium', 'created_at')
    search_fields = ('username', 'email', 'nickname')
    ordering = ('-created_at',)

    fieldsets = (
        (None, {'fields': ('username', 'email', 'password')}),
        ('Personal info', {
            'fields': ('nickname', 'date_of_birth', 'bio', 'profile_picture')
        }),
        ('Address', {
            'fields': ('address', 'city', 'country', 'postal_code'),
            'classes': ('collapse',)
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser',
                       'groups', 'user_permissions')
        }),
        ('Account Status', {
            'fields': ('is_verified', 'is_premium', 'last_login_ip')
        }),
        ('Important dates', {
            'fields': ('last_login', 'created_at', 'updated_at')
        }),
    )

    readonly_fields = ('created_at', 'updated_at', 'last_login')

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'nickname', 'password1', 'password2'),
        }),
    )


@admin.register(Follow)
class FollowAdmin(admin.ModelAdmin):
    """Admin interface for Follow relationships"""
    list_display = ('follower', 'following', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('follower__username', 'follower__nickname',
                     'following__username', 'following__nickname')
    date_hierarchy = 'created_at'
    raw_id_fields = ('follower', 'following')
    ordering = ('-created_at',)

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('follower', 'following')


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    """Admin interface for Support Tickets"""
    list_display = ('id', 'user', 'category', 'title', 'status', 'has_response', 'created_at')
    list_filter = ('status', 'category', 'created_at', 'responded_at')
    search_fields = ('title', 'content', 'user__username', 'user__nickname', 'user__email')
    date_hierarchy = 'created_at'
    raw_id_fields = ('user', 'responded_by')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)

    fieldsets = (
        ('Ticket Information', {
            'fields': ('user', 'category', 'title', 'content', 'status')
        }),
        ('Admin Response', {
            'fields': ('admin_response', 'responded_by', 'responded_at')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('user', 'responded_by')

    def has_response(self, obj):
        """Display if ticket has admin response"""
        return obj.has_response()
    has_response.boolean = True
    has_response.short_description = 'Answered'
