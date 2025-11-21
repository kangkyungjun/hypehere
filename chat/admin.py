from django.contrib import admin
from .models import (
    Conversation, Message, ConversationParticipant,
    OpenChatRoom, OpenChatParticipant, OpenChatMessage,
    OpenChatFavorite, OpenChatKick, Report
)


class ConversationParticipantInline(admin.TabularInline):
    model = ConversationParticipant
    extra = 0
    readonly_fields = ('joined_at', 'left_at')


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'get_participants', 'created_at', 'updated_at')
    list_filter = ('created_at', 'updated_at')
    search_fields = ('participants__username', 'participants__nickname')
    inlines = [ConversationParticipantInline]

    def get_participants(self, obj):
        return ", ".join([user.username for user in obj.participants.all()])
    get_participants.short_description = 'Participants'


@admin.register(ConversationParticipant)
class ConversationParticipantAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'conversation', 'is_active', 'joined_at', 'left_at')
    list_filter = ('is_active', 'joined_at', 'left_at')
    search_fields = ('user__username', 'user__nickname')
    readonly_fields = ('joined_at',)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'sender', 'content_preview', 'created_at', 'is_read')
    list_filter = ('is_read', 'created_at')
    search_fields = ('sender__username', 'sender__nickname', 'content')
    readonly_fields = ('created_at',)

    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


class OpenChatParticipantInline(admin.TabularInline):
    model = OpenChatParticipant
    extra = 0
    readonly_fields = ('joined_at', 'left_at', 'admin_granted_at')
    fields = ('user', 'is_active', 'is_admin', 'joined_at', 'admin_granted_at', 'left_at')


@admin.register(OpenChatRoom)
class OpenChatRoomAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'country_code', 'category', 'creator', 'get_participant_count', 'is_active', 'last_activity')
    list_filter = ('category', 'country_code', 'is_active', 'created_at')
    search_fields = ('name', 'country_code', 'creator__username', 'creator__nickname')
    readonly_fields = ('created_at', 'updated_at', 'last_activity')
    inlines = [OpenChatParticipantInline]

    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'country_code', 'category', 'creator')
        }),
        ('Settings', {
            'fields': ('is_active', 'max_participants')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'last_activity'),
            'classes': ('collapse',)
        }),
    )

    def get_participant_count(self, obj):
        return obj.get_participant_count()
    get_participant_count.short_description = 'Participants'


@admin.register(OpenChatParticipant)
class OpenChatParticipantAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'room', 'is_active', 'is_admin', 'joined_at', 'left_at')
    list_filter = ('is_active', 'is_admin', 'joined_at', 'room__country_code', 'room__category')
    search_fields = ('user__username', 'user__nickname', 'room__name')
    readonly_fields = ('joined_at', 'admin_granted_at')

    fieldsets = (
        (None, {
            'fields': ('user', 'room', 'is_active', 'is_admin')
        }),
        ('Timestamps', {
            'fields': ('joined_at', 'admin_granted_at', 'left_at'),
        }),
    )


@admin.register(OpenChatMessage)
class OpenChatMessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'room', 'sender', 'content_preview', 'created_at')
    list_filter = ('created_at', 'room__category', 'room__country_code')
    search_fields = ('sender__username', 'sender__nickname', 'content', 'room__name')
    readonly_fields = ('created_at',)

    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(OpenChatFavorite)
class OpenChatFavoriteAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'room', 'created_at')
    list_filter = ('created_at', 'room__category', 'room__country_code')
    search_fields = ('user__username', 'user__nickname', 'room__name')
    readonly_fields = ('created_at',)

    fieldsets = (
        (None, {
            'fields': ('user', 'room')
        }),
        ('Timestamps', {
            'fields': ('created_at',),
        }),
    )


@admin.register(OpenChatKick)
class OpenChatKickAdmin(admin.ModelAdmin):
    list_display = ('id', 'room', 'kicked_user', 'kicked_by', 'reason_preview', 'kicked_at', 'ban_status')
    list_filter = ('kicked_at', 'room__category', 'room__country_code')
    search_fields = ('kicked_user__username', 'kicked_user__nickname', 'kicked_by__username', 'room__name', 'reason')
    readonly_fields = ('kicked_at',)

    fieldsets = (
        ('Kick Information', {
            'fields': ('room', 'kicked_user', 'kicked_by', 'reason')
        }),
        ('Ban Settings', {
            'fields': ('ban_until',)
        }),
        ('Timestamps', {
            'fields': ('kicked_at',),
        }),
    )

    def reason_preview(self, obj):
        if obj.reason:
            return obj.reason[:50] + '...' if len(obj.reason) > 50 else obj.reason
        return '-'
    reason_preview.short_description = 'Reason'

    def ban_status(self, obj):
        if obj.is_ban_active():
            if obj.ban_until:
                return f'Active until {obj.ban_until.strftime("%Y-%m-%d %H:%M")}'
            return 'Permanent'
        return 'Expired'
    ban_status.short_description = 'Ban Status'


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    """Admin configuration for chat Report model"""
    list_display = ('id', 'reporter', 'reported_user', 'report_type', 'status', 'created_at')
    list_filter = ('status', 'report_type', 'created_at')
    search_fields = ('reporter__email', 'reporter__nickname', 'reported_user__email',
                     'reported_user__nickname', 'description')
    readonly_fields = ('created_at', 'reviewed_at')
    ordering = ('-created_at',)

    fieldsets = (
        ('Report Information', {
            'fields': ('reporter', 'reported_user', 'conversation', 'report_type', 'description')
        }),
        ('Status', {
            'fields': ('status', 'admin_note', 'created_at', 'reviewed_at')
        }),
    )
